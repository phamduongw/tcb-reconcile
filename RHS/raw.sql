-- ============================================================
-- DROP OBJECTS
-- ============================================================

DROP TABLE CONFLUENT.RHS_R18_FBNK_EB_C005_RAW CASCADE CONSTRAINTS PURGE;
DROP TABLE CONFLUENT.RHS_R25_FBNK_EB_C005_RAW CASCADE CONSTRAINTS PURGE;

-- ============================================================
-- CONFLUENT.RHS_R18_FBNK_EB_C005_RAW
-- ============================================================

CREATE TABLE CONFLUENT.RHS_R18_FBNK_EB_C005_RAW (
    TABLE_NAME VARCHAR2(255),
    OP_TYPE    VARCHAR2(16),
    OP_TS      TIMESTAMP(3),
    CURRENT_TS VARCHAR2(64),
    POS        VARCHAR2(64),
    SCN        VARCHAR2(64),
    XID        VARCHAR2(64),
    LOOKUP_KEY VARCHAR2(255),
    RECID      VARCHAR2(255),
    XMLRECORD  CLOB,
    CONSOL_KEY VARCHAR2(255)
)
PARTITION BY RANGE (OP_TS)
INTERVAL (NUMTODSINTERVAL(1, 'DAY'))
(
    PARTITION P_INITIAL VALUES LESS THAN (TIMESTAMP '2026-01-01 00:00:00')
);

-- ============================================================
-- CONFLUENT.RHS_R25_FBNK_EB_C005_RAW
-- ============================================================

CREATE TABLE CONFLUENT.RHS_R25_FBNK_EB_C005_RAW (
    TABLE_NAME VARCHAR2(255),
    OP_TYPE    VARCHAR2(16),
    OP_TS      TIMESTAMP(3),
    CURRENT_TS VARCHAR2(64),
    POS        VARCHAR2(64),
    SCN        VARCHAR2(64),
    XID        VARCHAR2(64),
    LOOKUP_KEY VARCHAR2(255),
    RECID      VARCHAR2(255),
    XMLRECORD  CLOB,
    CONSOL_KEY VARCHAR2(255)
)
PARTITION BY RANGE (OP_TS)
INTERVAL (NUMTODSINTERVAL(1, 'DAY'))
(
    PARTITION P_INITIAL VALUES LESS THAN (TIMESTAMP '2026-01-01 00:00:00')
);
