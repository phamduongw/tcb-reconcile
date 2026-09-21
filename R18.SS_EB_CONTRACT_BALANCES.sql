SET 'auto.offset.reset' = 'earliest';

-- ============================================================
-- DROP TABLE/STREAM
-- ============================================================

DROP STREAM IF EXISTS R18_FBNK_EB_C005_EXPLODED DELETE TOPIC;
DROP STREAM IF EXISTS R18_FBNK_EB_C005_MAPPED DELETE TOPIC;
DROP STREAM IF EXISTS R18_FBNK_EB_C005_PARSED DELETE TOPIC;
DROP STREAM IF EXISTS R18_FBNK_EB_C005_QUICKCHECK DELETE TOPIC;
DROP STREAM IF EXISTS R18_FBNK_EB_C005;

DROP TABLE IF EXISTS R18_F_DATES_MAPPED DELETE TOPIC;
DROP STREAM IF EXISTS R18_F_DATES_PARSED DELETE TOPIC;
DROP STREAM IF EXISTS R18_F_DATES;

DROP STREAM IF EXISTS R18_F_STANDARD_SELECTION_PARSED DELETE TOPIC;
DROP STREAM IF EXISTS R18_F_STANDARD_SELECTION;

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
-- R18_F_DATES
-- ============================================================

CREATE OR REPLACE STREAM R18_F_DATES (
    RECID      STRING,
    OP_TYPE    STRING,
    OP_TS      STRING,
    CURRENT_TS STRING,
    XMLRECORD  STRING
) WITH (
    KAFKA_TOPIC = 'R18.F_DATES',
    FORMAT      = 'AVRO'
);

-- ============================================================
-- R18_F_DATES_PARSED
-- ============================================================

CREATE OR REPLACE STREAM R18_F_DATES_PARSED
WITH (
    KAFKA_TOPIC = 'R18.F_DATES_PARSED'
) AS
SELECT
    ROWKEY,
    RECID,
    OP_TYPE,
    PARSE_TIMESTAMP(OP_TS, 'yyyy-MM-dd HH:mm:ss.SSSSSS')      AS COMMIT_TS,
    PARSE_TIMESTAMP(CURRENT_TS, 'yyyy-MM-dd HH:mm:ss.SSSSSS') AS REPLICAT_TS,
    PARSE_T24_RECORD(XMLRECORD, 6228)                         AS DATA -- R18.SS_DATES
FROM R18_F_DATES
WHERE RECID = 'VN0010001'
EMIT CHANGES;

-- ============================================================
-- R18_F_DATES_MAPPED
-- ============================================================

CREATE OR REPLACE TABLE R18_F_DATES_MAPPED
WITH (
    KAFKA_TOPIC = 'R18.F_DATES_MAPPED'
) AS
SELECT
    RECID,
    LATEST_BY_OFFSET(DATA['LAST_WORKING_DAY']) AS LAST_WORKING_DAY
FROM R18_F_DATES_PARSED
GROUP BY RECID
EMIT CHANGES;

-- ============================================================
-- R18_FBNK_EB_C005
-- ============================================================

CREATE OR REPLACE STREAM R18_FBNK_EB_C005 (
    RECID      STRING,
    OP_TYPE    STRING,
    OP_TS      STRING,
    CURRENT_TS STRING,
    XMLRECORD  STRING
) WITH (
    KAFKA_TOPIC = 'R18.FBNK_EB_C005',
    FORMAT      = 'AVRO'
);

-- ============================================================
-- R18_FBNK_EB_C005_QUICKCHECK
-- ============================================================

CREATE OR REPLACE STREAM R18_FBNK_EB_C005_QUICKCHECK
WITH (
    KAFKA_TOPIC = 'R18.FBNK_EB_C005_QUICKCHECK'
) AS
SELECT
    ROWKEY,
    RECID,
    OP_TYPE,
    PARSE_TIMESTAMP(OP_TS, 'yyyy-MM-dd HH:mm:ss.SSSSSS')      AS COMMIT_TS,
    PARSE_TIMESTAMP(CURRENT_TS, 'yyyy-MM-dd HH:mm:ss.SSSSSS') AS REPLICAT_TS,
    XMLRECORD
FROM R18_FBNK_EB_C005
WHERE XMLRECORD = '' OR XMLRECORD IS NULL
EMIT CHANGES;

-- ============================================================
-- R18_FBNK_EB_C005_PARSED
-- ============================================================

CREATE OR REPLACE STREAM R18_FBNK_EB_C005_PARSED
WITH (
    KAFKA_TOPIC = 'R18.FBNK_EB_C005_PARSED'
) AS
SELECT
    ROWKEY,
    RECID,
    OP_TYPE,
    PARSE_TIMESTAMP(OP_TS, 'yyyy-MM-dd HH:mm:ss.SSSSSS')      AS COMMIT_TS,
    PARSE_TIMESTAMP(CURRENT_TS, 'yyyy-MM-dd HH:mm:ss.SSSSSS') AS REPLICAT_TS,
    PARSE_T24_RECORD(XMLRECORD, 6229)                         AS DATA -- R18.SS_EB_CONTRACT_BALANCES
FROM R18_FBNK_EB_C005
EMIT CHANGES;

-- ============================================================
-- R18_FBNK_EB_C005_MAPPED
-- ============================================================

CREATE OR REPLACE STREAM R18_FBNK_EB_C005_MAPPED
WITH (
    KAFKA_TOPIC = 'R18.FBNK_EB_C005_MAPPED'
) AS
SELECT
    ROWKEY,
    RECID,
    OP_TYPE,
    COMMIT_TS,
    REPLICAT_TS,
    PARSE_TIMESTAMP(
        TIMESTAMPTOSTRING(UNIX_TIMESTAMP(), 'yyyy-MM-dd HH:mm:ss.SSSSSS'),
        'yyyy-MM-dd HH:mm:ss.SSSSSS'
    ) AS MAPPED_TS,
    DATA['APPLICATION']      AS APPLICATION,
    DATA['CUSTOMER']         AS CUSTOMER,
    DATA['DATE_LAST_UPDATE'] AS DATE_LAST_UPDATE,
    EXPLODE_ASSET_BALANCES(
        DATA['CURR_ASSET_TYPE'],
        DATA['OPEN_BALANCE'],
        DATA['DEBIT_MVMT'],
        DATA['CREDIT_MVMT'],
        DATA['TYPE_SYSDATE'],
        '20261003'
    ) AS BALANCE
FROM R18_FBNK_EB_C005_PARSED
WHERE DATA['CURR_ASSET_TYPE'] IS NOT NULL
EMIT CHANGES;

-- ============================================================
-- R18_FBNK_EB_C005_EXPLODED
-- ============================================================

CREATE OR REPLACE STREAM R18_FBNK_EB_C005_EXPLODED
WITH (
    KAFKA_TOPIC = 'R18.FBNK_EB_C005_EXPLODED'
) AS
SELECT
    ROWKEY,
    RECID,
    OP_TYPE,
    COMMIT_TS,
    REPLICAT_TS,
    MAPPED_TS,
    PARSE_TIMESTAMP(
        TIMESTAMPTOSTRING(UNIX_TIMESTAMP(), 'yyyy-MM-dd HH:mm:ss.SSSSSS'),
        'yyyy-MM-dd HH:mm:ss.SSSSSS'
    ) AS EXPLODED_TS,
    APPLICATION,
    CUSTOMER,
    DATE_LAST_UPDATE,
    BALANCE->ASSET_TYPE AS ASSET_TYPE,
    BALANCE->OPEN_BAL   AS OPEN_BAL,
    BALANCE->DR_MVT     AS DR_MVT,
    BALANCE->CR_MVT     AS CR_MVT,
    BALANCE->CLOSE_BAL  AS CLOSE_BAL
FROM R18_FBNK_EB_C005_MAPPED
EMIT CHANGES;
