-- ============================================================
-- DROP OBJECTS
-- ============================================================

DROP PROCEDURE CONFLUENT.P_COMPARE_DD_R18_DD_R25_FBNK_EB_C005;
DROP VIEW CONFLUENT.V_DD_R18_DD_R25_FBNK_EB_C005_DIFF;
DROP TABLE CONFLUENT.DD_R18_DD_R25_FBNK_EB_C005_DIFF CASCADE CONSTRAINTS PURGE;
DROP TABLE CONFLUENT.DD_R18_FBNK_EB_C005_EXPLODED CASCADE CONSTRAINTS PURGE;
DROP TABLE CONFLUENT.DD_R25_FBNK_EB_C005_EXPLODED CASCADE CONSTRAINTS PURGE;

-- ============================================================
-- DD_R18 EXPLODED
-- ============================================================

CREATE TABLE CONFLUENT.DD_R18_FBNK_EB_C005_EXPLODED (
    RECID            VARCHAR2(255) NOT NULL,
    ASSET_TYPE       VARCHAR2(255) NOT NULL,
    OP_TYPE          CHAR(1),
    COMMIT_TS        TIMESTAMP(3),
    REPLICAT_TS      TIMESTAMP(3),
    MAPPED_TS        TIMESTAMP(3),
    EXPLODED_TS      TIMESTAMP(3),
    APPLICATION      VARCHAR2(128),
    CUSTOMER         VARCHAR2(255),
    DATE_LAST_UPDATE VARCHAR2(8),
    OPEN_BAL         NUMBER(38,4),
    DR_MVT           NUMBER(38,4),
    CR_MVT           NUMBER(38,4),
    CLOSE_BAL        NUMBER(38,4),
    CONSTRAINT PK_DD_R18_FBNK_EB_C005_EXPLODED PRIMARY KEY (RECID, ASSET_TYPE)
);

-- ============================================================
-- DD_R25 EXPLODED
-- ============================================================

CREATE TABLE CONFLUENT.DD_R25_FBNK_EB_C005_EXPLODED (
    RECID            VARCHAR2(255) NOT NULL,
    ASSET_TYPE       VARCHAR2(255) NOT NULL,
    OP_TYPE          CHAR(1),
    COMMIT_TS        TIMESTAMP(3),
    REPLICAT_TS      TIMESTAMP(3),
    MAPPED_TS        TIMESTAMP(3),
    EXPLODED_TS      TIMESTAMP(3),
    APPLICATION      VARCHAR2(128),
    CUSTOMER         VARCHAR2(255),
    DATE_LAST_UPDATE VARCHAR2(8),
    OPEN_BAL         NUMBER(38,4),
    DR_MVT           NUMBER(38,4),
    CR_MVT           NUMBER(38,4),
    CLOSE_BAL        NUMBER(38,4),
    CONSTRAINT PK_DD_R25_FBNK_EB_C005_EXPLODED PRIMARY KEY (RECID, ASSET_TYPE)
);

-- ============================================================
-- DIFF VIEW
-- ============================================================

CREATE OR REPLACE VIEW CONFLUENT.V_DD_R18_DD_R25_FBNK_EB_C005_DIFF AS
SELECT
    COALESCE(r18.RECID, r25.RECID)           AS RECID,
    COALESCE(r18.ASSET_TYPE, r25.ASSET_TYPE) AS ASSET_TYPE,
    CASE
        WHEN r18.RECID IS NULL THEN
            CASE
                WHEN NOT EXISTS (
                    SELECT 1
                    FROM CONFLUENT.DD_R18_FBNK_EB_C005_EXPLODED x
                    WHERE x.RECID = r25.RECID
                ) THEN 'MISSING_RECID_IN_DD_R18'
                ELSE 'MISSING_ASSET_TYPE_IN_DD_R18'
            END
        WHEN r25.RECID IS NULL THEN
            CASE
                WHEN NOT EXISTS (
                    SELECT 1
                    FROM CONFLUENT.DD_R25_FBNK_EB_C005_EXPLODED x
                    WHERE x.RECID = r18.RECID
                ) THEN 'MISSING_RECID_IN_DD_R25'
                ELSE 'MISSING_ASSET_TYPE_IN_DD_R25'
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
    END                           AS DIFF_COLUMNS,
    r18.APPLICATION               AS DD_R18_APPLICATION,
    r25.APPLICATION               AS DD_R25_APPLICATION,
    r18.CUSTOMER                  AS DD_R18_CUSTOMER,
    r25.CUSTOMER                  AS DD_R25_CUSTOMER,
    r18.DATE_LAST_UPDATE          AS DD_R18_DATE_LAST_UPDATE,
    r25.DATE_LAST_UPDATE          AS DD_R25_DATE_LAST_UPDATE,
    r18.OPEN_BAL                  AS DD_R18_OPEN_BAL,
    r25.OPEN_BAL                  AS DD_R25_OPEN_BAL,
    r18.DR_MVT                    AS DD_R18_DR_MVT,
    r25.DR_MVT                    AS DD_R25_DR_MVT,
    r18.CR_MVT                    AS DD_R18_CR_MVT,
    r25.CR_MVT                    AS DD_R25_CR_MVT,
    r18.CLOSE_BAL                 AS DD_R18_CLOSE_BAL,
    r25.CLOSE_BAL                 AS DD_R25_CLOSE_BAL,
    r25.OPEN_BAL - r18.OPEN_BAL   AS DIFF_OPEN_BAL,
    r25.DR_MVT - r18.DR_MVT       AS DIFF_DR_MVT,
    r25.CR_MVT - r18.CR_MVT       AS DIFF_CR_MVT,
    r25.CLOSE_BAL - r18.CLOSE_BAL AS DIFF_CLOSE_BAL
FROM CONFLUENT.DD_R18_FBNK_EB_C005_EXPLODED r18
FULL OUTER JOIN CONFLUENT.DD_R25_FBNK_EB_C005_EXPLODED r25
    ON r18.RECID = r25.RECID
   AND r18.ASSET_TYPE = r25.ASSET_TYPE
WHERE r18.RECID IS NULL
   OR r25.RECID IS NULL
   OR DECODE(r18.OPEN_BAL,  r25.OPEN_BAL,  0, 1) = 1
   OR DECODE(r18.DR_MVT,    r25.DR_MVT,    0, 1) = 1
   OR DECODE(r18.CR_MVT,    r25.CR_MVT,    0, 1) = 1
   OR DECODE(r18.CLOSE_BAL, r25.CLOSE_BAL, 0, 1) = 1;

-- ============================================================
-- CREATE CURRENT SNAPSHOT (ONE-TIME SETUP)
-- ============================================================

CREATE TABLE CONFLUENT.DD_R18_DD_R25_FBNK_EB_C005_DIFF AS
SELECT
    RECID,
    ASSET_TYPE,
    DIFF_TYPE,
    DIFF_COLUMNS,
    DD_R18_APPLICATION,
    DD_R25_APPLICATION,
    DD_R18_CUSTOMER,
    DD_R25_CUSTOMER,
    DD_R18_DATE_LAST_UPDATE,
    DD_R25_DATE_LAST_UPDATE,
    DD_R18_OPEN_BAL,
    DD_R25_OPEN_BAL,
    DD_R18_DR_MVT,
    DD_R25_DR_MVT,
    DD_R18_CR_MVT,
    DD_R25_CR_MVT,
    DD_R18_CLOSE_BAL,
    DD_R25_CLOSE_BAL,
    DIFF_OPEN_BAL,
    DIFF_DR_MVT,
    DIFF_CR_MVT,
    DIFF_CLOSE_BAL
FROM CONFLUENT.V_DD_R18_DD_R25_FBNK_EB_C005_DIFF
WHERE 1 = 0;

-- ============================================================
-- REFRESH CURRENT SNAPSHOT PROCEDURE
-- ============================================================
-- Call from a dedicated reconciliation session: COMMIT also commits caller changes.
-- The shared snapshot is replaced on every successful call; it is not session-local.

CREATE OR REPLACE PROCEDURE CONFLUENT.P_COMPARE_DD_R18_DD_R25_FBNK_EB_C005
AS
BEGIN
    SAVEPOINT BEFORE_COMPARE;
    LOCK TABLE CONFLUENT.DD_R18_DD_R25_FBNK_EB_C005_DIFF IN EXCLUSIVE MODE;

    DELETE FROM CONFLUENT.DD_R18_DD_R25_FBNK_EB_C005_DIFF;

    INSERT INTO CONFLUENT.DD_R18_DD_R25_FBNK_EB_C005_DIFF (
        RECID,
        ASSET_TYPE,
        DIFF_TYPE,
        DIFF_COLUMNS,
        DD_R18_APPLICATION,
        DD_R25_APPLICATION,
        DD_R18_CUSTOMER,
        DD_R25_CUSTOMER,
        DD_R18_DATE_LAST_UPDATE,
        DD_R25_DATE_LAST_UPDATE,
        DD_R18_OPEN_BAL,
        DD_R25_OPEN_BAL,
        DD_R18_DR_MVT,
        DD_R25_DR_MVT,
        DD_R18_CR_MVT,
        DD_R25_CR_MVT,
        DD_R18_CLOSE_BAL,
        DD_R25_CLOSE_BAL,
        DIFF_OPEN_BAL,
        DIFF_DR_MVT,
        DIFF_CR_MVT,
        DIFF_CLOSE_BAL
    )
    SELECT /*+ PARALLEL(16) */
        RECID,
        ASSET_TYPE,
        DIFF_TYPE,
        DIFF_COLUMNS,
        DD_R18_APPLICATION,
        DD_R25_APPLICATION,
        DD_R18_CUSTOMER,
        DD_R25_CUSTOMER,
        DD_R18_DATE_LAST_UPDATE,
        DD_R25_DATE_LAST_UPDATE,
        DD_R18_OPEN_BAL,
        DD_R25_OPEN_BAL,
        DD_R18_DR_MVT,
        DD_R25_DR_MVT,
        DD_R18_CR_MVT,
        DD_R25_CR_MVT,
        DD_R18_CLOSE_BAL,
        DD_R25_CLOSE_BAL,
        DIFF_OPEN_BAL,
        DIFF_DR_MVT,
        DIFF_CR_MVT,
        DIFF_CLOSE_BAL
    FROM CONFLUENT.V_DD_R18_DD_R25_FBNK_EB_C005_DIFF;

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK TO BEFORE_COMPARE;
        RAISE;
END;
/

-- ============================================================
-- EXECUTE (RUN FOR EACH COMPARISON)
-- ============================================================

BEGIN
    CONFLUENT.P_COMPARE_DD_R18_DD_R25_FBNK_EB_C005;
END;
/

-- ============================================================
-- COUNT CURRENT DIFF
-- ============================================================

SELECT /*+ PARALLEL(16) */ COUNT(*)
FROM CONFLUENT.DD_R18_DD_R25_FBNK_EB_C005_DIFF;

-- ============================================================
-- SELECT CURRENT DIFF
-- ============================================================

SELECT /*+ PARALLEL(16) */ *
FROM CONFLUENT.DD_R18_DD_R25_FBNK_EB_C005_DIFF
ORDER BY RECID, ASSET_TYPE;
