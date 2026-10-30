SET 'auto.offset.reset' = 'earliest';
SET 'ksql.streams.num.stream.threads' = '8';

-- ============================================================
-- DROP TABLE/STREAM
-- ============================================================

DROP STREAM IF EXISTS DDDR_R18_FBNK_EB_C005_EXPLODED DELETE TOPIC;
DROP STREAM IF EXISTS DDDR_R18_FBNK_EB_C005_MAPPED DELETE TOPIC;
DROP STREAM IF EXISTS DDDR_R18_FBNK_EB_C005_PARSED DELETE TOPIC;
DROP STREAM IF EXISTS DDDR_R18_FBNK_EB_C005_QUICKCHECK DELETE TOPIC;
DROP STREAM IF EXISTS DDDR_R18_FBNK_EB_C005_RAW;

-- ============================================================
-- DDDR_R18_FBNK_EB_C005_RAW
-- ============================================================

CREATE OR REPLACE STREAM DDDR_R18_FBNK_EB_C005_RAW (
    RECID      STRING,
    OP_TYPE    STRING,
    OP_TS      STRING,
    CURRENT_TS STRING,
    POS        STRING,
    XMLRECORD  STRING
) WITH (
    KAFKA_TOPIC = 'DDDR_R18.FBNK_EB_C005_RAW',
    FORMAT      = 'AVRO'
);

-- ============================================================
-- DDDR_R18_FBNK_EB_C005_QUICKCHECK
-- ============================================================

CREATE OR REPLACE STREAM DDDR_R18_FBNK_EB_C005_QUICKCHECK
WITH (
    KAFKA_TOPIC = 'DDDR_R18.FBNK_EB_C005_QUICKCHECK'
) AS
SELECT
    ROWKEY,
    RECID,
    OP_TYPE,
    OP_TS,
    CURRENT_TS,
    POS,
    XMLRECORD
FROM DDDR_R18_FBNK_EB_C005_RAW
WHERE XMLRECORD = '' OR XMLRECORD IS NULL
EMIT CHANGES;

-- ============================================================
-- DDDR_R18_FBNK_EB_C005_PARSED
-- ============================================================

CREATE OR REPLACE STREAM DDDR_R18_FBNK_EB_C005_PARSED
WITH (
    KAFKA_TOPIC = 'DDDR_R18.FBNK_EB_C005_PARSED'
) AS
SELECT
    ROWKEY,
    RECID,
    OP_TYPE,
    POS,
    PARSE_TIMESTAMP(OP_TS, 'yyyy-MM-dd HH:mm:ss.SSSSSS')      AS COMMIT_TS,
    PARSE_TIMESTAMP(CURRENT_TS, 'yyyy-MM-dd HH:mm:ss.SSSSSS') AS REPLICAT_TS,
    PARSE_T24_RECORD(XMLRECORD, 6223)                         AS DATA -- R18.SS_EB_CONTRACT_BALANCES
FROM DDDR_R18_FBNK_EB_C005_RAW
EMIT CHANGES;

-- ============================================================
-- DDDR_R18_FBNK_EB_C005_MAPPED
-- ============================================================

CREATE OR REPLACE STREAM DDDR_R18_FBNK_EB_C005_MAPPED
WITH (
    KAFKA_TOPIC = 'DDDR_R18.FBNK_EB_C005_MAPPED'
) AS
SELECT
    ROWKEY,
    RECID,
    OP_TYPE,
    POS,
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
        '20261107'
    ) AS BALANCE
FROM DDDR_R18_FBNK_EB_C005_PARSED
WHERE DATA['CURR_ASSET_TYPE'] IS NOT NULL
EMIT CHANGES;

-- ============================================================
-- DDDR_R18_FBNK_EB_C005_EXPLODED
-- ============================================================

CREATE OR REPLACE STREAM DDDR_R18_FBNK_EB_C005_EXPLODED
WITH (
    KAFKA_TOPIC = 'DDDR_R18.FBNK_EB_C005_EXPLODED'
) AS
SELECT
    ROWKEY,
    RECID,
    OP_TYPE,
    POS,
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
FROM DDDR_R18_FBNK_EB_C005_MAPPED
EMIT CHANGES;
