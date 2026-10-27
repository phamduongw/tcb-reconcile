-- ============================================================
-- DROP OBJECTS
-- ============================================================

DROP TABLE CONFLUENT.DDAY_R18_FBNK_EB_C005_RAW CASCADE CONSTRAINTS PURGE;
DROP TABLE CONFLUENT.DDAY_R25_FBNK_EB_C005_RAW CASCADE CONSTRAINTS PURGE;

-- ============================================================
-- CONFLUENT.DDAY_R18_FBNK_EB_C005_RAW
-- ============================================================

CREATE TABLE CONFLUENT.DDAY_R18_FBNK_EB_C005_RAW (
    TABLE_NAME VARCHAR2(255),
    OP_TYPE    VARCHAR2(16),
    OP_TS      VARCHAR2(64),
    CURRENT_TS VARCHAR2(64),
    POS        VARCHAR2(64),
    SCN        VARCHAR2(64),
    XID        VARCHAR2(64),
    LOOKUP_KEY VARCHAR2(255),
    RECID      VARCHAR2(255),
    XMLRECORD  CLOB,
    CONSOL_KEY VARCHAR2(255)
);

-- ============================================================
-- CONFLUENT.DDAY_R25_FBNK_EB_C005_RAW
-- ============================================================

CREATE TABLE CONFLUENT.DDAY_R25_FBNK_EB_C005_RAW (
    TABLE_NAME VARCHAR2(255),
    OP_TYPE    VARCHAR2(16),
    OP_TS      VARCHAR2(64),
    CURRENT_TS VARCHAR2(64),
    POS        VARCHAR2(64),
    SCN        VARCHAR2(64),
    XID        VARCHAR2(64),
    LOOKUP_KEY VARCHAR2(255),
    RECID      VARCHAR2(255),
    XMLRECORD  CLOB,
    CONSOL_KEY VARCHAR2(255)
);
