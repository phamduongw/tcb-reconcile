SET 'auto.offset.reset' = 'earliest';
SET 'ksql.streams.num.stream.threads' = '8';

-- Run once per cluster if schema discovery/registration is required (DC: DD/RHS; DR: DDDR/RHSDR).
-- Business streams use fixed schema ID 6226 on DC and 6223 on DR, not these parsed streams directly.
-- Do not recreate this branch between groups on the same cluster; verify the target registry ID.
-- Source/parsed topic names are shared within each cluster, not prefixed per business group.

-- ============================================================
-- DROP TABLE/STREAM
-- ============================================================

DROP STREAM IF EXISTS R18_F_STANDARD_SELECTION_PARSED DELETE TOPIC;
DROP STREAM IF EXISTS R18_F_STANDARD_SELECTION;
DROP STREAM IF EXISTS R25_F_STANDARD_SELECTION_PARSED DELETE TOPIC;
DROP STREAM IF EXISTS R25_F_STANDARD_SELECTION;

-- ============================================================
-- R18_F_STANDARD_SELECTION
-- ============================================================

CREATE OR REPLACE STREAM R18_F_STANDARD_SELECTION (
    RECID      STRING,
    OP_TYPE    STRING,
    OP_TS      STRING,
    CURRENT_TS STRING,
    XMLRECORD  STRING
) WITH (
    KAFKA_TOPIC = 'R18.F_STANDARD_SELECTION',
    FORMAT      = 'AVRO'
);

-- ============================================================
-- R18_F_STANDARD_SELECTION_PARSED
-- ============================================================

CREATE OR REPLACE STREAM R18_F_STANDARD_SELECTION_PARSED
WITH (
    KAFKA_TOPIC = 'R18.F_STANDARD_SELECTION_PARSED'
) AS
SELECT
    ROWKEY,
    RECID,
    OP_TYPE,
    PARSE_TIMESTAMP(OP_TS, 'yyyy-MM-dd HH:mm:ss.SSSSSS')      AS COMMIT_TS,
    PARSE_TIMESTAMP(CURRENT_TS, 'yyyy-MM-dd HH:mm:ss.SSSSSS') AS REPLICAT_TS,
    PARSE_T24_SCHEMA(XMLRECORD, 'R18')                        AS SCHEMA_ID
FROM R18_F_STANDARD_SELECTION
EMIT CHANGES;

-- ============================================================
-- R25_F_STANDARD_SELECTION
-- ============================================================

CREATE OR REPLACE STREAM R25_F_STANDARD_SELECTION (
    RECID      STRING,
    OP_TYPE    STRING,
    OP_TS      STRING,
    CURRENT_TS STRING,
    XMLRECORD  STRING
) WITH (
    KAFKA_TOPIC = 'R25.F_STANDARD_SELECTION',
    FORMAT      = 'AVRO'
);

-- ============================================================
-- R25_F_STANDARD_SELECTION_PARSED
-- ============================================================

CREATE OR REPLACE STREAM R25_F_STANDARD_SELECTION_PARSED
WITH (
    KAFKA_TOPIC = 'R25.F_STANDARD_SELECTION_PARSED'
) AS
SELECT
    ROWKEY,
    RECID,
    OP_TYPE,
    PARSE_TIMESTAMP(OP_TS, 'yyyy-MM-dd HH:mm:ss.SSSSSS')      AS COMMIT_TS,
    PARSE_TIMESTAMP(CURRENT_TS, 'yyyy-MM-dd HH:mm:ss.SSSSSS') AS REPLICAT_TS,
    PARSE_T24_SCHEMA(XMLRECORD, 'R25')                        AS SCHEMA_ID
FROM R25_F_STANDARD_SELECTION
EMIT CHANGES;
