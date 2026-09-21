-- ============================================================
-- DROP OBJECTS
-- ============================================================

DROP PROCEDURE CONFLUENT.P_COMPARE_R18_R25_FBNK_EB_C005;
DROP VIEW CONFLUENT.V_R18_R25_FBNK_EB_C005_DIFF;
DROP TABLE CONFLUENT.R18_R25_FBNK_EB_C005_DIFF CASCADE CONSTRAINTS PURGE;
DROP TABLE CONFLUENT.R18_FBNK_EB_C005_EXPLODED CASCADE CONSTRAINTS PURGE;
DROP TABLE CONFLUENT.R25_FBNK_EB_C005_EXPLODED CASCADE CONSTRAINTS PURGE;

-- ============================================================
-- R18 EXPLODED
-- ============================================================

CREATE TABLE CONFLUENT.R18_FBNK_EB_C005_EXPLODED (
    RECID             VARCHAR2(255) NOT NULL,
    ASSET_TYPE        VARCHAR2(255) NOT NULL,
    OP_TYPE           CHAR(1),
    COMMIT_TS         TIMESTAMP(3),
    REPLICAT_TS       TIMESTAMP(3),
    MAPPED_TS         TIMESTAMP(3),
    EXPLODED_TS       TIMESTAMP(3),
    APPLICATION       VARCHAR2(128),
    CUSTOMER          VARCHAR2(255),
    DATE_LAST_UPDATE  VARCHAR2(8),
    OPEN_BAL          NUMBER(38,4),
    DR_MVT            NUMBER(38,4),
    CR_MVT            NUMBER(38,4),
    CLOSE_BAL         NUMBER(38,4),
    CONSTRAINT PK_R18_FBNK_EB_C005_EXPLODED PRIMARY KEY (RECID, ASSET_TYPE)
);

-- ============================================================
-- R25 EXPLODED
-- ============================================================

CREATE TABLE CONFLUENT.R25_FBNK_EB_C005_EXPLODED (
    RECID             VARCHAR2(255) NOT NULL,
    ASSET_TYPE        VARCHAR2(255) NOT NULL,
    OP_TYPE           CHAR(1),
    COMMIT_TS         TIMESTAMP(3),
    REPLICAT_TS       TIMESTAMP(3),
    MAPPED_TS         TIMESTAMP(3),
    EXPLODED_TS       TIMESTAMP(3),
    APPLICATION       VARCHAR2(128),
    CUSTOMER          VARCHAR2(255),
    DATE_LAST_UPDATE  VARCHAR2(8),
    OPEN_BAL          NUMBER(38,4),
    DR_MVT            NUMBER(38,4),
    CR_MVT            NUMBER(38,4),
    CLOSE_BAL         NUMBER(38,4),
    CONSTRAINT PK_R25_FBNK_EB_C005_EXPLODED PRIMARY KEY (RECID, ASSET_TYPE)
);

-- ============================================================
-- DIFF HISTORY
-- ============================================================

CREATE TABLE CONFLUENT.R18_R25_FBNK_EB_C005_DIFF (
    COMPARE_RUN_ID        VARCHAR2(255),
    RECID                 VARCHAR2(255),
    ASSET_TYPE            VARCHAR2(255),
    DIFF_TYPE             VARCHAR2(32),
    DIFF_COLUMNS          VARCHAR2(4000),
    R18_APPLICATION       VARCHAR2(128),
    R25_APPLICATION       VARCHAR2(128),
    R18_CUSTOMER          VARCHAR2(255),
    R25_CUSTOMER          VARCHAR2(255),
    R18_DATE_LAST_UPDATE  VARCHAR2(8),
    R25_DATE_LAST_UPDATE  VARCHAR2(8),
    R18_OPEN_BAL          NUMBER(38,4),
    R25_OPEN_BAL          NUMBER(38,4),
    R18_DR_MVT            NUMBER(38,4),
    R25_DR_MVT            NUMBER(38,4),
    R18_CR_MVT            NUMBER(38,4),
    R25_CR_MVT            NUMBER(38,4),
    R18_CLOSE_BAL         NUMBER(38,4),
    R25_CLOSE_BAL         NUMBER(38,4)
);

CREATE INDEX CONFLUENT.IDX_R18_R25_FBNK_EB_C005_DIFF_RUN
    ON CONFLUENT.R18_R25_FBNK_EB_C005_DIFF (COMPARE_RUN_ID, RECID);

-- ============================================================
-- DIFF VIEW
-- ============================================================

CREATE OR REPLACE VIEW CONFLUENT.V_R18_R25_FBNK_EB_C005_DIFF AS
SELECT
    COALESCE(r18.RECID, r25.RECID) AS RECID,
    COALESCE(r18.ASSET_TYPE, r25.ASSET_TYPE) AS ASSET_TYPE,
    CASE
        WHEN r18.RECID IS NULL THEN
            CASE
                WHEN NOT EXISTS (
                    SELECT 1
                    FROM CONFLUENT.R18_FBNK_EB_C005_EXPLODED x
                    WHERE x.RECID = r25.RECID
                ) THEN 'MISSING_RECID_IN_R18'
                ELSE 'MISSING_ASSET_TYPE_IN_R18'
            END
        WHEN r25.RECID IS NULL THEN
            CASE
                WHEN NOT EXISTS (
                    SELECT 1
                    FROM CONFLUENT.R25_FBNK_EB_C005_EXPLODED x
                    WHERE x.RECID = r18.RECID
                ) THEN 'MISSING_RECID_IN_R25'
                ELSE 'MISSING_ASSET_TYPE_IN_R25'
            END
        ELSE 'VALUE_MISMATCH'
    END AS DIFF_TYPE,
    CASE
        WHEN r18.RECID IS NULL OR r25.RECID IS NULL THEN NULL
        ELSE RTRIM(
              CASE WHEN DECODE(r18.OPEN_BAL,  r25.OPEN_BAL,  0, 1) = 1 THEN 'OPEN_BAL, '  END
            || CASE WHEN DECODE(r18.DR_MVT,    r25.DR_MVT,    0, 1) = 1 THEN 'DR_MVT, '    END
            || CASE WHEN DECODE(r18.CR_MVT,    r25.CR_MVT,    0, 1) = 1 THEN 'CR_MVT, '    END
            || CASE WHEN DECODE(r18.CLOSE_BAL, r25.CLOSE_BAL, 0, 1) = 1 THEN 'CLOSE_BAL, ' END,
            ', '
        )
    END AS DIFF_COLUMNS,
    r18.APPLICATION      AS R18_APPLICATION,
    r25.APPLICATION      AS R25_APPLICATION,
    r18.CUSTOMER         AS R18_CUSTOMER,
    r25.CUSTOMER         AS R25_CUSTOMER,
    r18.DATE_LAST_UPDATE AS R18_DATE_LAST_UPDATE,
    r25.DATE_LAST_UPDATE AS R25_DATE_LAST_UPDATE,
    r18.OPEN_BAL         AS R18_OPEN_BAL,
    r25.OPEN_BAL         AS R25_OPEN_BAL,
    r18.DR_MVT           AS R18_DR_MVT,
    r25.DR_MVT           AS R25_DR_MVT,
    r18.CR_MVT           AS R18_CR_MVT,
    r25.CR_MVT           AS R25_CR_MVT,
    r18.CLOSE_BAL        AS R18_CLOSE_BAL,
    r25.CLOSE_BAL        AS R25_CLOSE_BAL
FROM CONFLUENT.R18_FBNK_EB_C005_EXPLODED r18
FULL OUTER JOIN CONFLUENT.R25_FBNK_EB_C005_EXPLODED r25
    ON r18.RECID = r25.RECID
   AND r18.ASSET_TYPE = r25.ASSET_TYPE
WHERE r18.RECID IS NULL
   OR r25.RECID IS NULL
   OR DECODE(r18.OPEN_BAL,  r25.OPEN_BAL,  0, 1) = 1
   OR DECODE(r18.DR_MVT,    r25.DR_MVT,    0, 1) = 1
   OR DECODE(r18.CR_MVT,    r25.CR_MVT,    0, 1) = 1
   OR DECODE(r18.CLOSE_BAL, r25.CLOSE_BAL, 0, 1) = 1;

-- ============================================================
-- COMPARE PROCEDURE
-- ============================================================

CREATE OR REPLACE PROCEDURE CONFLUENT.P_COMPARE_R18_R25_FBNK_EB_C005
AS
    V_COMPARE_RUN_ID VARCHAR2(255);
BEGIN
    V_COMPARE_RUN_ID := 'RUN_' || TO_CHAR(SYSTIMESTAMP, 'YYYYMMDD_HH24MISSFF3');

    INSERT /*+ APPEND ENABLE_PARALLEL_DML PARALLEL(16) */
    INTO CONFLUENT.R18_R25_FBNK_EB_C005_DIFF (
        COMPARE_RUN_ID,
        RECID,
        ASSET_TYPE,
        DIFF_TYPE,
        DIFF_COLUMNS,
        R18_APPLICATION,
        R25_APPLICATION,
        R18_CUSTOMER,
        R25_CUSTOMER,
        R18_DATE_LAST_UPDATE,
        R25_DATE_LAST_UPDATE,
        R18_OPEN_BAL,
        R25_OPEN_BAL,
        R18_DR_MVT,
        R25_DR_MVT,
        R18_CR_MVT,
        R25_CR_MVT,
        R18_CLOSE_BAL,
        R25_CLOSE_BAL
    )
    SELECT
        V_COMPARE_RUN_ID,
        RECID,
        ASSET_TYPE,
        DIFF_TYPE,
        DIFF_COLUMNS,
        R18_APPLICATION,
        R25_APPLICATION,
        R18_CUSTOMER,
        R25_CUSTOMER,
        R18_DATE_LAST_UPDATE,
        R25_DATE_LAST_UPDATE,
        R18_OPEN_BAL,
        R25_OPEN_BAL,
        R18_DR_MVT,
        R25_DR_MVT,
        R18_CR_MVT,
        R25_CR_MVT,
        R18_CLOSE_BAL,
        R25_CLOSE_BAL
    FROM CONFLUENT.V_R18_R25_FBNK_EB_C005_DIFF;

    COMMIT;
END;

-- ============================================================
-- EXECUTE
-- ============================================================

BEGIN
    CONFLUENT.P_COMPARE_R18_R25_FBNK_EB_C005;
END;

-- ============================================================
-- COUNT LATEST RUN
-- ============================================================

SELECT /*+ PARALLEL(16) */ COUNT(*)
FROM CONFLUENT.R18_R25_FBNK_EB_C005_DIFF
WHERE COMPARE_RUN_ID = (
    SELECT MAX(COMPARE_RUN_ID)
    FROM CONFLUENT.R18_R25_FBNK_EB_C005_DIFF
);

-- ============================================================
-- SELECT LATEST RUN
-- ============================================================

SELECT /*+ PARALLEL(16) */ *
FROM CONFLUENT.R18_R25_FBNK_EB_C005_DIFF
WHERE COMPARE_RUN_ID = (
    SELECT MAX(COMPARE_RUN_ID)
    FROM CONFLUENT.R18_R25_FBNK_EB_C005_DIFF
)
ORDER BY RECID;
