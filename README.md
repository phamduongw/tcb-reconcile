# Reconciliation deployment

This repository reconciles `FBNK_EB_C005` contract balances between T24 R18 and R25. Each group runs a Kafka/ksqlDB pipeline per side (RAW -> PARSED -> MAPPED -> EXPLODED), sinks the EXPLODED rows into Oracle through Kafka Connect, and compares the latest R18 and R25 rows in an Oracle procedure that saves a DIFF snapshot.

## Groups and environments

| Setting | RHS (DC) | DDAY (DC) | DDAYDR (DR) |
| --- | --- | --- | --- |
| Directory / namespace | `RHS/` / `RHS` | `DDAY/` / `DDAY` | `DDAYDR/` / `DDAYDR` |
| `PARSE_T24_RECORD` schema ID | `6257` | `6257` | `6232` |
| Oracle login and object owner | `CONFLUENT` | `CONFLUENT` | `CONFLUENTDR` |
| Key and value Schema Registry | `http://10.35.222.247:8081` | `http://10.35.222.247:8081` | `http://10.35.222.233:8081` |
| Lag bootstrap broker | `10.35.222.247:9092` | `10.35.222.247:9092` | `10.35.222.233:9092` |
| Lag script, from repository root | `./lag.sh` | `./lag.sh` | `./DDAYDR/lag.sh` |
| Balance business date | `20261031` | `20261107` | `20261107` |
| MAPPED cutoff | `COMMIT_TS < 2026-11-01 10:10:00` | none | none |

The groups are independent: each has its own streams, topics, connectors, DLQs, Oracle tables, views, DIFF snapshot and procedure, and no object references another group. There is no cross-group or cross-DC/DR comparison. The business date and the RHS cutoff are the only intended logic differences between groups; schema ID, Oracle owner, password, registry and broker addresses are environment configuration.

Each group directory contains `R18_FBNK_EB_C005.sql`, `R25_FBNK_EB_C005.sql`, `report.sql` and two connector files `connector_<group>_<side>_FBNK_EB_C005_EXPLODED_config.json`. `DDAYDR/` also contains its own `lag.sh`. The repository root holds the DC [lag.sh](lag.sh), the optional schema-discovery script `F_STANDARD_SELECTION.sql` and the local parser schema `schema.json`.

Inventory: 24 business streams, 24 topics (6 RAW inputs and 18 derived), 6 connectors with 6 DLQs, and 24 Oracle objects (per group: two EXPLODED tables, two indexes, two latest views, one DIFF table and one procedure).

## Fresh deployment

Run the steps per cluster: DC for RHS and DDAY, DR for DDAYDR.

1. Optional: if schema discovery or registration is required, run `F_STANDARD_SELECTION.sql` once per cluster. Its DROP statements recreate the shared parsed topics, so do not rerun it between groups on the same cluster.
2. Make sure the upstream OGG feed publishes to `<group>_R18.FBNK_EB_C005_RAW` and `<group>_R25.FBNK_EB_C005_RAW` and that the topics retain the complete input to be reconciled.
3. Run `<group>/R18_FBNK_EB_C005.sql` and `<group>/R25_FBNK_EB_C005.sql` on the cluster's ksqlDB.
4. Run `<group>/report.sql` on Oracle as the group's owner (`CONFLUENT` or `CONFLUENTDR`) **before** deploying the connectors, because the connectors do not create tables. On a schema where the objects do not exist yet, the DROP statements fail with expected missing-object errors. The procedure call at the end of the script runs against empty tables and is not a valid result.
5. Deploy the two connector files of the group to the cluster's Kafka Connect.
6. Run the group's lag command from the report's LAG section until both lags stay at 0, verify RECID and asset coverage on both sides, then run only the comparison procedure and read the DIFF snapshot.

Before deploying a connector whose name already exists on the cluster (RHS keeps its connector names), delete the connector and its consumer group `connect-<connector name>` or reset its offsets. The stream scripts recreate the EXPLODED topics, so committed offsets from earlier topics would make the sink skip new records.

## Kafka and ksqlDB pipeline

Every stream script starts with `SET 'auto.offset.reset' = 'earliest'` and `SET 'ksql.streams.num.stream.threads' = '8'`. The thread setting applies to runtimes created by later statements in the same session, does not resize running queries, and can be rejected by server override restrictions ([configuration restrictions](https://docs.confluent.io/platform/current/ksqldb/reference/server-configuration.html#ksql-properties-overrides-denylist)). Over REST, submit the SET together with the query or use `streamsProperties`.

The DROP section removes EXPLODED, MAPPED and PARSED with their topics, then the RAW stream without its topic, so RAW input data is kept. `DROP STREAM IF EXISTS` does not terminate running queries: terminate the group's persistent queries first.

| Stage | Content |
| --- | --- |
| RAW | Avro source declaring `RECID`, `OP_TYPE`, `POS`, `OP_TS`, `CURRENT_TS`, `XMLRECORD` |
| PARSED | `ROWKEY`, `RECID`, `OP_TYPE`, `POS`, `COMMIT_TS` and `REPLICAT_TS` parsed from `OP_TS`/`CURRENT_TS` with `yyyy-MM-dd HH:mm:ss.SSSSSS`, and `DATA = PARSE_T24_RECORD(XMLRECORD, <schema ID>)` |
| MAPPED | The PARSED prefix, `MAPPED_TS`, the five S fields, `BALANCE` and the five A fields; only rows with `DATA['CURR_ASSET_TYPE'] IS NOT NULL` (RHS also applies its cutoff) |
| EXPLODED | `ROWKEY`, `RECID`, `ASSET_TYPE`, `OP_TYPE`, `POS`, `COMMIT_TS`, `REPLICAT_TS`, `MAPPED_TS`, `EXPLODED_TS`, the five S fields, `OPEN_BAL`, `DR_MVT`, `CR_MVT`, `CLOSE_BAL` and the five A fields |

- S fields are `CURRENCY`, `APPLICATION`, `CUSTOMER`, `DATE_LAST_UPDATE` and `HVT_FLAG`, copied from `DATA[...]` as strings. They are metadata: they never create a DIFF row by themselves, and only CURRENCY affects the comparison threshold.
- A fields are `CURR_ASSET_TYPE`, `OPEN_BALANCE`, `DEBIT_MVMT`, `CREDIT_MVMT` and `TYPE_SYSDATE`, the unmodified multivalue strings returned by the parser. They are kept for diagnosis and are distinct from the calculated `ASSET_TYPE`, `OPEN_BAL`, `DR_MVT` and `CR_MVT`.
- `BALANCE` is the table function `EXPLODE_ASSET_BALANCES(CURR_ASSET_TYPE, OPEN_BALANCE, DEBIT_MVMT, CREDIT_MVMT, TYPE_SYSDATE, <business date>)`. It emits one row per asset, so a record's S and A fields repeat on every asset row ([table functions](https://docs.confluent.io/platform/current/ksqldb/developer-guide/ksqldb-reference/table-functions.html)). Records filtered by MAPPED or producing no assets do not reach EXPLODED, and parser failures are not captured.
- The RHS cutoff `COMMIT_TS < PARSE_TIMESTAMP('2026-11-01 10:10:00.000000', 'yyyy-MM-dd HH:mm:ss.SSSSSS')` is a fixed constant that excludes 10:10:00 and later. It uses the same format as `COMMIT_TS` without time-zone conversion and is not a rolling daily rule.
- Each derived stream projects `ROWKEY` to preserve the Kafka message key. `ROWKEY` is not an Oracle column.
- `MAPPED_TS` and `EXPLODED_TS` record when each stage processed the row.

`schema.json` is the local copy of the `EB_CONTRACT_BALANCES` parser schema: CURRENCY (`c1`), APPLICATION (`c19`), DATE_LAST_UPDATE (`c21`), CUSTOMER (`c22`) and HVT_FLAG (`c100`) use `doc: S`; TYPE_SYSDATE (`c2`), OPEN_BALANCE (`c5`), CREDIT_MVMT (`c7`), DEBIT_MVMT (`c9`) and CURR_ASSET_TYPE (`c13`) use `doc: A`; all are `["null", "string"]` with default NULL. Editing this file neither registers a schema nor changes a running parser. The owner-supplied IDs `6257` (DC) and `6232` (DR) must resolve to this schema in the target registry.

`F_STANDARD_SELECTION.sql` is an optional schema-discovery branch per cluster over `R18.F_STANDARD_SELECTION` and `R25.F_STANDARD_SELECTION`, using unprefixed topic names shared by all groups on the cluster. The business pipelines do not read it.

## Kafka Connect sinks

Each EXPLODED stream has one JDBC sink connector named `<group>_<side>_FBNK_EB_C005_EXPLODED`, reading topic `<group>_<side>.FBNK_EB_C005_EXPLODED` with consumer group `connect-<connector name>` and writing to `<owner>.<group>_<side>_FBNK_EB_C005_EXPLODED`. All six use Avro key/value converters, `tasks.max=48`, `insert.mode=insert`, `pk.mode=none` without `pk.fields`, `auto.create=false`, `auto.evolve=false`, `errors.tolerance=none`, `max.retries=1` and `retry.backoff.ms=10000`. DR connectors set both `connection.user` and `table.name.format` to `CONFLUENTDR`.

- Verify 48 partitions per EXPLODED topic and Connect/Oracle capacity: up to 192 sink tasks on DC and 96 on DR, 288 in total against the same Oracle service, plus reporting sessions.
- The sinks append every record. A replay into tables that still hold rows inserts the records again, so whenever the stream scripts are rerun, recreate the tables with `report.sql` and reset offsets or use fresh connector identities. `earliest` is not an offset reset, and it cannot restore expired records.
- The connector files contain database credentials: restrict access to them and rotate a password if it is exposed. The Oracle wallet must exist at `/u01/kafka-connect/wallet/cwallet.sso` on every Connect worker.

### DLQ policy

Each connector reports failed records to `<group>_<side>.SINK_ERROR` with context headers (original topic/partition/offset, connector/task, stage, exception). The DLQ keeps the original key/value bytes, not an Oracle error table; restrict access because it contains customer and balance data. With `errors.tolerance=none` a failure stops the task instead of silently skipping data: a record may reach the DLQ before the task fails, so a failed task does not prove the DLQ is empty. Connection failures can stop a task without DLQ records, and ksqlDB parser/UDF failures happen upstream. There is no automatic DLQ consumer or replay: diagnose with the headers and worker logs, fix the cause, replay through supported offset management, then verify coverage. The DLQ replication factor `1` applies only when Connect creates the topic. See [JDBC sink DLQ](https://docs.confluent.io/kafka-connectors/jdbc/current/sink-connector/overview.html#dead-letter-queue).

## Oracle objects

`report.sql` creates the group's objects in dependency order and drops them in reverse order.

- **EXPLODED tables** `<group>_<side>_FBNK_EB_C005_EXPLODED`: the 22 EXPLODED value fields in stream order plus `CHANGED_TS TIMESTAMP(3) DEFAULT SYSTIMESTAMP NOT NULL` after `EXPLODED_TS`, 23 columns. `RECID` and `ASSET_TYPE` are `NOT NULL`, `OP_TYPE` is `CHAR(1)`, `POS` is `NUMBER(20)`, timestamps are `TIMESTAMP(3)`, S fields are `VARCHAR2(255)`, calculated balances are `NUMBER(38,4)` and A fields are `CLOB`. There is no primary key. `CHANGED_TS` is the Oracle insert time in the server time zone, not a version order.
- **Index** `IDX_<group>_<side>_FBNK_EB_C005_EXPLODED_RECID_COMMIT_TS_POS` on `(RECID, COMMIT_TS, POS)`, nonunique.
- **Latest views** `V_<group>_<side>_FBNK_EB_C005_EXPLODED`: every stored row at the greatest `COMMIT_TS` of its `RECID` and, among those, the greatest `POS` (`MAX(POS) KEEP (DENSE_RANK LAST ORDER BY COMMIT_TS)`). All assets emitted by that latest record are returned. R18 and R25 select their latest versions independently.
- **DIFF snapshot** `<group>_R18_R25_FBNK_EB_C005_DIFF`, 26 columns in this order: `RECID`, `ASSET_TYPE`, `DIFF_TYPE VARCHAR2(32)`, `DIFF_COLUMNS VARCHAR2(37)`, the ten paired S fields `R18_<field>`/`R25_<field>`, the eight per-side balances `R18_<balance>`/`R25_<balance>` as `NUMBER(38,4)`, and `DIFF_OPEN_BAL`, `DIFF_DR_MVT`, `DIFF_CR_MVT`, `DIFF_CLOSE_BAL` as `NUMBER`. The DDL, the procedure's INSERT list and its SELECT list use the same order.
- **Procedure** `P_COMPARE_<group>_R18_R25_FBNK_EB_C005`: sets a savepoint, locks the DIFF table in exclusive mode, deletes it, inserts the comparison result and commits; on error it rolls back to the savepoint and re-raises. The COMMIT also commits other work in the session, so run it from a dedicated reporting session. The lock serializes refreshes, not ingestion.

Identifiers reach 56 bytes (`IDX_DDAYDR_<side>_FBNK_EB_C005_EXPLODED_RECID_COMMIT_TS_POS`), so the database must allow identifiers longer than 30 bytes.

## Comparison rules

The two latest views are combined with one `FULL OUTER JOIN` on `(RECID, ASSET_TYPE)`. An inner query computes, per pair:

- **Matched pair** (both rows exist): the four balances are compared as stored. NULL equals NULL; NULL against any number, including 0, is a mismatch and its delta is NULL.
- **Missing pair** (one row absent): every NULL balance on either side becomes 0 before comparison, display and subtraction. Metadata is never normalized, so the absent side's metadata stays NULL.
- **Threshold**: `DIFF_THRESHOLD` is 1 only when every existing side has `CURRENCY = 'VND'`, otherwise 0. There is no FX conversion.
- **RECID presence**: `COUNT(side.RECID) OVER (PARTITION BY COALESCE(r18.RECID, r25.RECID))` per side, computed before the outer filter, so another asset of the same RECID still proves the RECID exists.

A balance is reported when `DECODE(R18, R25, 0, CASE WHEN ABS(R25 - R18) <= DIFF_THRESHOLD THEN 0 ELSE 1 END) = 1`. The same predicate is used for `OPEN_BAL`, `DR_MVT`, `CR_MVT` and `CLOSE_BAL` in the WHERE clause and in DIFF_COLUMNS, and a pair is saved only if at least one balance is reported. For VND this reports `ABS(delta) > 1` (0.5 and exactly 1 are excluded, 1.0001 is reported); for other currencies it reports any non-zero delta.

| DIFF_TYPE | Meaning (checked in this order) |
| --- | --- |
| `MISSING_RECID_IN_R18` | The R18 latest view has no row for this RECID. |
| `MISSING_RECID_IN_R25` | The R25 latest view has no row for this RECID. |
| `MISSING_ASSET_TYPE_IN_R18` | R18 has the RECID but not this ASSET_TYPE. |
| `MISSING_ASSET_TYPE_IN_R25` | R25 has the RECID but not this ASSET_TYPE. |
| `VALUE_MISMATCH` | Both rows exist and at least one balance is reported. |

`DIFF_COLUMNS` lists the reported balances in the order `OPEN_BAL, DR_MVT, CR_MVT, CLOSE_BAL`. The deltas are always `R25 - R18` of the compared values and are kept for every saved row. Example: a missing VND pair with R18 balances `(200, NULL, 1, -1)` is saved as `MISSING_RECID_IN_R25` (when R25 has no row for the RECID) with R18 `(200, 0, 1, -1)`, R25 `(0, 0, 0, 0)`, deltas `(-200, 0, -1, 1)` and DIFF_COLUMNS `OPEN_BAL`; in USD, DIFF_COLUMNS is `OPEN_BAL, CR_MVT, CLOSE_BAL`.

## Report script

`report.sql` has these sections:

- **LAG**: the lag command for the group's two connector consumer groups. The lag scripts take consumer group names as arguments, describe all groups in one `kafka-consumer-groups` call per refresh, show the capture time and total lag per group, and wait 2 seconds between refreshes. A partition without a committed offset counts its full log-end offset, and a group with no offsets is shown as such. Stop with Ctrl+C. Zero connector lag does not prove that ksqlDB processed all source records.
- **CPU**: reads `cpu_count` from `V$PARAMETER` to size the `PARALLEL` hints; it needs SELECT access to that view.
- **DROP OBJECTS** and the object definitions: a destructive rebuild without existence checks. Tables are dropped with `CASCADE CONSTRAINTS PURGE`, which deletes their data permanently and does not reset connector offsets.
- **REPORT**: runs the procedure, then counts the DIFF snapshot.
- **COUNT**: one `UNION ALL` query counting all stored rows per side in the raw EXPLODED tables, including older versions.
- **INSPECT**: one `UNION ALL` query over both latest views ordered by `SIDE, CHANGED_TS`, and one query over the DIFF snapshot ordered by `RECID, ASSET_TYPE`. Replace `RECID = ''` with the RECID to inspect: Oracle treats `''` as NULL, so the unchanged placeholder matches no rows.

The comparison, COUNT and INSPECT statements carry one statement-level `/*+ PARALLEL(64) */` hint each ([statement-level hint](https://docs.oracle.com/en/database/oracle/oracle-database/19/sqlrf/Comments.html#GUID-D25225CE-2DCE-4D9F-8E82-401839690A6E)); Oracle decides whether to honor it, and concurrent reports multiply resource demand. Verify plans, memory and TEMP usage on the target database.

For recurring reconciliation run only the procedure and the result queries, never the whole script. COUNT and INSPECT read the saved snapshot, which changes only when the procedure runs; another refresh between two reads replaces it. Standalone `/` delimiters are omitted for DBeaver: execute each complete `CREATE ... PROCEDURE ... END;` or `BEGIN ... END;` block as one statement, and add `/` after each PL/SQL block in SQL*Plus or SQLcl.

## Conventions

- **Naming**: the environment appears only in object names. Streams are `<group>_<side>_FBNK_EB_C005_<stage>`, topics `<group>_<side>.FBNK_EB_C005_<stage>`, DLQs `<group>_<side>.SINK_ERROR`, and Oracle objects follow the patterns above. Field names never carry the environment: paired DIFF columns are `R18_<field>`/`R25_<field>` and DIFF_TYPE labels are identical in every group. `SIDE` and `MISSING_SIDE` values are `'R18'` and `'R25'`.
- **Symmetry**: R18 and R25 scripts of a group are identical after replacing the side; the three groups are identical after replacing the namespace, except for the configuration and the two logic differences listed in the group table.
- **Layout**: SQL section headings are a title between two `-- ============================================================` lines with one blank line before and after the block, except before a heading at the start of a file. Independent statements are separated by one blank line, and logical blocks use four-space indentation. Column lists, DIFF definitions and INSERT/SELECT lists put one column per line. JOIN predicates keep the joined alias, `ON` and `AND` on one line.
- **Alignment**: within each SELECT list, every single-line `expression AS alias` item aligns its AS after the longest single-line expression of that list plus one space, even when multi-line items sit between them; a multi-line expression closes with `) AS alias` or `END AS alias` and one space. Within each column or property list, column types and WITH property assignments align after the longest name plus one space. Continuation lines of the DIFF_COLUMNS expression stay vertically aligned.

## Topology

Confirmed by the owner; not verified from this repository.

- DC and DR use the same Oracle database and service with separate schemas, `CONFLUENT` for DC and `CONFLUENTDR` for DR; DR connectors use their own password.
- DR runs on its own all-in-one Confluent cluster on `10.35.222.233`; DC is on `10.35.222.247`. Kafka bootstrap, ksqlDB and UDF configuration belong to the deployed runtimes, not to these files.
- A separate OGG feed supplies the DR RAW topics. No DC-to-DR replication is required.

## Operating assumptions and limits

- `COMMIT_TS` and `POS` are non-NULL, and `POS` (the GoldenGate trail position) increases with source order within a side while the trail sequence is not reset. `POS` is sent as a string and converted by Oracle on insert; a non-numeric value fails the sink task. `COMMIT_TS` must distinguish versions at `TIMESTAMP(3)` precision, with `POS` breaking ties.
- Each record must emit a complete asset snapshot. A newer record hides all older assets of its RECID, while a record emitting no rows or a delete does not advance the view; `OP_TYPE` is data, not a delete instruction.
- Both sides must have complete batches up to equivalent business cutoffs before comparing. There is no batch-completion marker; a single newer asset advances the live view before the remaining assets arrive. Two equally incomplete or empty sides can produce an empty DIFF.
- Delivery is at least once: a restart can insert a record twice, and the latest view then returns both copies, repeating affected DIFF rows. The tables keep every version, so plan retention.
- Balances are `NUMBER(38,4)`: more than four decimals are rounded and more than 34 integer digits do not fit.
- Validate on the target environment: registry schemas and UDF contracts, Avro types, time-zone handling, Oracle compilation, direct grants (EXECUTE on the procedure, SELECT on the DIFF table and views), plans and capacity. Review the embedded credentials, disabled TLS DN matching, HTTP Schema Registry access and message-inclusive error logging against the security policy.

The repository files have been checked for consistency and the comparison SQL has been exercised on SQLite with adapted syntax. No Kafka, ksqlDB, Connect or Oracle runtime was available, so live compilation, connectivity and data completeness remain deployment checks.
