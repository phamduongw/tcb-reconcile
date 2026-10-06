SET 'auto.offset.reset' = 'earliest';

-- Run F_STANDARD_SELECTION.sql once separately; do not drop shared streams per batch.

-- ============================================================
-- DROP TABLE/STREAM
-- ============================================================

DROP STREAM IF EXISTS RHS3_R25_FBNK_EB_C005_EXPLODED DELETE TOPIC;
DROP STREAM IF EXISTS RHS3_R25_FBNK_EB_C005_MAPPED DELETE TOPIC;
DROP STREAM IF EXISTS RHS3_R25_FBNK_EB_C005_DEBUG DELETE TOPIC;
DROP STREAM IF EXISTS RHS3_R25_FBNK_EB_C005_PARSED DELETE TOPIC;
DROP STREAM IF EXISTS RHS3_R25_FBNK_EB_C005_QUICKCHECK DELETE TOPIC;
DROP STREAM IF EXISTS RHS3_R25_FBNK_EB_C005;

-- ============================================================
-- RHS3_R25_FBNK_EB_C005
-- ============================================================

CREATE OR REPLACE STREAM RHS3_R25_FBNK_EB_C005 (
    RECID      STRING,
    OP_TYPE    STRING,
    OP_TS      STRING,
    CURRENT_TS STRING,
    XMLRECORD  STRING
) WITH (
    KAFKA_TOPIC = 'RHS3_R25.FBNK_EB_C005',
    FORMAT      = 'AVRO'
);

-- ============================================================
-- RHS3_R25_FBNK_EB_C005_QUICKCHECK
-- ============================================================

CREATE OR REPLACE STREAM RHS3_R25_FBNK_EB_C005_QUICKCHECK
WITH (
    KAFKA_TOPIC = 'RHS3_R25.FBNK_EB_C005_QUICKCHECK'
) AS
SELECT
    ROWKEY,
    RECID,
    OP_TYPE,
    OP_TS,
    CURRENT_TS,
    XMLRECORD
FROM RHS3_R25_FBNK_EB_C005
WHERE XMLRECORD = '' OR XMLRECORD IS NULL
EMIT CHANGES;

-- ============================================================
-- RHS3_R25_FBNK_EB_C005_PARSED
-- ============================================================

CREATE OR REPLACE STREAM RHS3_R25_FBNK_EB_C005_PARSED
WITH (
    KAFKA_TOPIC = 'RHS3_R25.FBNK_EB_C005_PARSED'
) AS
SELECT
    ROWKEY,
    RECID,
    OP_TYPE,
    PARSE_TIMESTAMP(OP_TS, 'yyyy-MM-dd HH:mm:ss.SSSSSS')      AS COMMIT_TS,
    PARSE_TIMESTAMP(CURRENT_TS, 'yyyy-MM-dd HH:mm:ss.SSSSSS') AS REPLICAT_TS,
    PARSE_T24_RECORD(XMLRECORD, 6226)                         AS DATA -- R25.SS_EB_CONTRACT_BALANCES
FROM RHS3_R25_FBNK_EB_C005
EMIT CHANGES;

-- ============================================================
-- RHS3_R25_FBNK_EB_C005_DEBUG: retain every parsed record without balance transformation.
-- ============================================================

CREATE OR REPLACE STREAM RHS3_R25_FBNK_EB_C005_DEBUG
WITH (
    KAFKA_TOPIC = 'RHS3_R25.FBNK_EB_C005_DEBUG'
) AS
SELECT
    ROWKEY,
    RECID,
    OP_TYPE,
    COMMIT_TS,
    REPLICAT_TS,
    DATA['APPLICATION']        AS APPLICATION,
    DATA['CUSTOMER']           AS CUSTOMER,
    DATA['DATE_LAST_UPDATE']   AS DATE_LAST_UPDATE,
    DATA['CURR_ASSET_TYPE']    AS CURR_ASSET_TYPE,
    DATA['OPEN_BALANCE']       AS OPEN_BALANCE,
    DATA['DEBIT_MVMT']         AS DEBIT_MVMT,
    DATA['CREDIT_MVMT']        AS CREDIT_MVMT,
    DATA['TYPE_SYSDATE']       AS TYPE_SYSDATE
FROM RHS3_R25_FBNK_EB_C005_PARSED
EMIT CHANGES;

-- ============================================================
-- RHS3_R25_FBNK_EB_C005_MAPPED
-- ============================================================

CREATE OR REPLACE STREAM RHS3_R25_FBNK_EB_C005_MAPPED
WITH (
    KAFKA_TOPIC = 'RHS3_R25.FBNK_EB_C005_MAPPED'
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
FROM RHS3_R25_FBNK_EB_C005_PARSED
WHERE DATA['CURR_ASSET_TYPE'] IS NOT NULL
EMIT CHANGES;

-- ============================================================
-- RHS3_R25_FBNK_EB_C005_EXPLODED
-- ============================================================

CREATE OR REPLACE STREAM RHS3_R25_FBNK_EB_C005_EXPLODED
WITH (
    KAFKA_TOPIC = 'RHS3_R25.FBNK_EB_C005_EXPLODED'
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
FROM RHS3_R25_FBNK_EB_C005_MAPPED
EMIT CHANGES;
