SET 'auto.offset.reset' = 'earliest';
SET 'ksql.streams.num.stream.threads' = '8';

-- ============================================================
-- DROP TABLE/STREAM
-- ============================================================

DROP STREAM IF EXISTS RHS_R18_FBNK_EB_C005_RAW DELETE TOPIC;
DROP STREAM IF EXISTS RHS_R18_FBNK_EB_C005_RAW_SOURCE;

-- ============================================================
-- RHS_R18_FBNK_EB_C005_RAW_SOURCE
-- ============================================================

CREATE OR REPLACE STREAM RHS_R18_FBNK_EB_C005_RAW_SOURCE (
    `TABLE`    STRING,
    OP_TYPE    STRING,
    OP_TS      STRING,
    CURRENT_TS STRING,
    POS        STRING,
    SCN        STRING,
    XID        STRING,
    LOOKUP_KEY STRING,
    RECID      STRING,
    XMLRECORD  STRING,
    CONSOL_KEY STRING
) WITH (
    KAFKA_TOPIC = 'RHS_R18.FBNK_EB_C005',
    FORMAT      = 'AVRO'
);

-- ============================================================
-- RHS_R18_FBNK_EB_C005_RAW
-- ============================================================

CREATE OR REPLACE STREAM RHS_R18_FBNK_EB_C005_RAW
WITH (
    KAFKA_TOPIC = 'RHS_R18.FBNK_EB_C005_RAW'
) AS
SELECT
    ROWKEY,
    `TABLE` AS TABLE_NAME,
    OP_TYPE,
    PARSE_TIMESTAMP(OP_TS, 'yyyy-MM-dd HH:mm:ss.SSSSSS') AS OP_TS,
    CURRENT_TS,
    POS,
    SCN,
    XID,
    LOOKUP_KEY,
    RECID,
    XMLRECORD,
    CONSOL_KEY
FROM RHS_R18_FBNK_EB_C005_RAW_SOURCE
EMIT CHANGES;
