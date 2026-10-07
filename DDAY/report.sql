-- ============================================================
-- DROP OBJECTS
-- ============================================================

DROP PROCEDURE CONFLUENT.P_COMPARE_DDAY_R18_R25_FBNK_EB_C005;
DROP VIEW CONFLUENT.V_DDAY_R18_FBNK_EB_C005_EXPLODED;
DROP VIEW CONFLUENT.V_DDAY_R25_FBNK_EB_C005_EXPLODED;
DROP TABLE CONFLUENT.DDAY_R18_R25_FBNK_EB_C005_DIFF CASCADE CONSTRAINTS PURGE;
DROP TABLE CONFLUENT.DDAY_R18_FBNK_EB_C005_EXPLODED CASCADE CONSTRAINTS PURGE;
DROP TABLE CONFLUENT.DDAY_R25_FBNK_EB_C005_EXPLODED CASCADE CONSTRAINTS PURGE;

-- ============================================================
-- CONFLUENT.DDAY_R18_FBNK_EB_C005_EXPLODED
-- ============================================================

CREATE TABLE CONFLUENT.DDAY_R18_FBNK_EB_C005_EXPLODED (
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
    CONSTRAINT PK_DDAY_R18_FBNK_EB_C005_EXPLODED PRIMARY KEY (RECID, ASSET_TYPE)
);

CREATE INDEX CONFLUENT.IDX_DDAY_R18_FBNK_EB_C005_EXPLODED_RECID_COMMIT_TS
ON CONFLUENT.DDAY_R18_FBNK_EB_C005_EXPLODED (RECID, COMMIT_TS);

-- ============================================================
-- CONFLUENT.DDAY_R25_FBNK_EB_C005_EXPLODED
-- ============================================================

CREATE TABLE CONFLUENT.DDAY_R25_FBNK_EB_C005_EXPLODED (
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
    CONSTRAINT PK_DDAY_R25_FBNK_EB_C005_EXPLODED PRIMARY KEY (RECID, ASSET_TYPE)
);

CREATE INDEX CONFLUENT.IDX_DDAY_R25_FBNK_EB_C005_EXPLODED_RECID_COMMIT_TS
ON CONFLUENT.DDAY_R25_FBNK_EB_C005_EXPLODED (RECID, COMMIT_TS);

-- ============================================================
-- CONFLUENT.V_DDAY_R18_FBNK_EB_C005_EXPLODED
-- ============================================================

CREATE OR REPLACE VIEW CONFLUENT.V_DDAY_R18_FBNK_EB_C005_EXPLODED AS
SELECT t.*
FROM CONFLUENT.DDAY_R18_FBNK_EB_C005_EXPLODED t
JOIN (
    SELECT RECID, MAX(COMMIT_TS) AS MAX_COMMIT_TS
    FROM CONFLUENT.DDAY_R18_FBNK_EB_C005_EXPLODED
    GROUP BY RECID
) m ON t.RECID = m.RECID AND t.COMMIT_TS = m.MAX_COMMIT_TS;

-- ============================================================
-- CONFLUENT.V_DDAY_R25_FBNK_EB_C005_EXPLODED
-- ============================================================

CREATE OR REPLACE VIEW CONFLUENT.V_DDAY_R25_FBNK_EB_C005_EXPLODED AS
SELECT t.*
FROM CONFLUENT.DDAY_R25_FBNK_EB_C005_EXPLODED t
JOIN (
    SELECT RECID, MAX(COMMIT_TS) AS MAX_COMMIT_TS
    FROM CONFLUENT.DDAY_R25_FBNK_EB_C005_EXPLODED
    GROUP BY RECID
) m ON t.RECID = m.RECID AND t.COMMIT_TS = m.MAX_COMMIT_TS;

-- ============================================================
-- CONFLUENT.DDAY_R18_R25_FBNK_EB_C005_DIFF
-- ============================================================

CREATE TABLE CONFLUENT.DDAY_R18_R25_FBNK_EB_C005_DIFF (
    RECID                     VARCHAR2(255),
    ASSET_TYPE                VARCHAR2(255),
    DIFF_TYPE                 VARCHAR2(30),
    DIFF_COLUMNS              VARCHAR2(37),
    DDAY_R18_APPLICATION      VARCHAR2(128),
    DDAY_R25_APPLICATION      VARCHAR2(128),
    DDAY_R18_CUSTOMER         VARCHAR2(255),
    DDAY_R25_CUSTOMER         VARCHAR2(255),
    DDAY_R18_DATE_LAST_UPDATE VARCHAR2(8),
    DDAY_R25_DATE_LAST_UPDATE VARCHAR2(8),
    DDAY_R18_OPEN_BAL         NUMBER(38,4),
    DDAY_R25_OPEN_BAL         NUMBER(38,4),
    DDAY_R18_DR_MVT           NUMBER(38,4),
    DDAY_R25_DR_MVT           NUMBER(38,4),
    DDAY_R18_CR_MVT           NUMBER(38,4),
    DDAY_R25_CR_MVT           NUMBER(38,4),
    DDAY_R18_CLOSE_BAL        NUMBER(38,4),
    DDAY_R25_CLOSE_BAL        NUMBER(38,4),
    DIFF_OPEN_BAL             NUMBER,
    DIFF_DR_MVT               NUMBER,
    DIFF_CR_MVT               NUMBER,
    DIFF_CLOSE_BAL            NUMBER
);

-- ============================================================
-- CONFLUENT.P_COMPARE_DDAY_R18_R25_FBNK_EB_C005
-- ============================================================

CREATE OR REPLACE PROCEDURE CONFLUENT.P_COMPARE_DDAY_R18_R25_FBNK_EB_C005
AS
BEGIN
    SAVEPOINT BEFORE_COMPARE;
    LOCK TABLE CONFLUENT.DDAY_R18_R25_FBNK_EB_C005_DIFF IN EXCLUSIVE MODE;

    DELETE FROM CONFLUENT.DDAY_R18_R25_FBNK_EB_C005_DIFF;

    INSERT INTO CONFLUENT.DDAY_R18_R25_FBNK_EB_C005_DIFF (
        RECID,
        ASSET_TYPE,
        DIFF_TYPE,
        DIFF_COLUMNS,
        DDAY_R18_APPLICATION,
        DDAY_R25_APPLICATION,
        DDAY_R18_CUSTOMER,
        DDAY_R25_CUSTOMER,
        DDAY_R18_DATE_LAST_UPDATE,
        DDAY_R25_DATE_LAST_UPDATE,
        DDAY_R18_OPEN_BAL,
        DDAY_R25_OPEN_BAL,
        DDAY_R18_DR_MVT,
        DDAY_R25_DR_MVT,
        DDAY_R18_CR_MVT,
        DDAY_R25_CR_MVT,
        DDAY_R18_CLOSE_BAL,
        DDAY_R25_CLOSE_BAL,
        DIFF_OPEN_BAL,
        DIFF_DR_MVT,
        DIFF_CR_MVT,
        DIFF_CLOSE_BAL
    )
    SELECT /*+ PARALLEL(8) */
        COALESCE(r18.RECID, r25.RECID)           AS RECID,
        COALESCE(r18.ASSET_TYPE, r25.ASSET_TYPE) AS ASSET_TYPE,
        CASE
            WHEN r18.RECID IS NULL THEN
                CASE
                    WHEN NOT EXISTS (
                        SELECT 1
                        FROM CONFLUENT.V_DDAY_R18_FBNK_EB_C005_EXPLODED x
                        WHERE x.RECID = r25.RECID
                    ) THEN 'MISSING_RECID_IN_DDAY_R18'
                    ELSE 'MISSING_ASSET_TYPE_IN_DDAY_R18'
                END
            WHEN r25.RECID IS NULL THEN
                CASE
                    WHEN NOT EXISTS (
                        SELECT 1
                        FROM CONFLUENT.V_DDAY_R25_FBNK_EB_C005_EXPLODED x
                        WHERE x.RECID = r18.RECID
                    ) THEN 'MISSING_RECID_IN_DDAY_R25'
                    ELSE 'MISSING_ASSET_TYPE_IN_DDAY_R25'
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
        r18.APPLICATION               AS DDAY_R18_APPLICATION,
        r25.APPLICATION               AS DDAY_R25_APPLICATION,
        r18.CUSTOMER                  AS DDAY_R18_CUSTOMER,
        r25.CUSTOMER                  AS DDAY_R25_CUSTOMER,
        r18.DATE_LAST_UPDATE          AS DDAY_R18_DATE_LAST_UPDATE,
        r25.DATE_LAST_UPDATE          AS DDAY_R25_DATE_LAST_UPDATE,
        r18.OPEN_BAL                  AS DDAY_R18_OPEN_BAL,
        r25.OPEN_BAL                  AS DDAY_R25_OPEN_BAL,
        r18.DR_MVT                    AS DDAY_R18_DR_MVT,
        r25.DR_MVT                    AS DDAY_R25_DR_MVT,
        r18.CR_MVT                    AS DDAY_R18_CR_MVT,
        r25.CR_MVT                    AS DDAY_R25_CR_MVT,
        r18.CLOSE_BAL                 AS DDAY_R18_CLOSE_BAL,
        r25.CLOSE_BAL                 AS DDAY_R25_CLOSE_BAL,
        r25.OPEN_BAL - r18.OPEN_BAL   AS DIFF_OPEN_BAL,
        r25.DR_MVT - r18.DR_MVT       AS DIFF_DR_MVT,
        r25.CR_MVT - r18.CR_MVT       AS DIFF_CR_MVT,
        r25.CLOSE_BAL - r18.CLOSE_BAL AS DIFF_CLOSE_BAL
    FROM CONFLUENT.V_DDAY_R18_FBNK_EB_C005_EXPLODED r18
    FULL OUTER JOIN CONFLUENT.V_DDAY_R25_FBNK_EB_C005_EXPLODED r25 ON r18.RECID = r25.RECID AND r18.ASSET_TYPE = r25.ASSET_TYPE
    WHERE r18.RECID IS NULL
       OR r25.RECID IS NULL
       OR DECODE(r18.OPEN_BAL,  r25.OPEN_BAL,  0, 1) = 1
       OR DECODE(r18.DR_MVT,    r25.DR_MVT,    0, 1) = 1
       OR DECODE(r18.CR_MVT,    r25.CR_MVT,    0, 1) = 1
       OR DECODE(r18.CLOSE_BAL, r25.CLOSE_BAL, 0, 1) = 1;

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK TO BEFORE_COMPARE;
        RAISE;
END;

-- ============================================================
-- REPORT
-- ============================================================

BEGIN
    CONFLUENT.P_COMPARE_DDAY_R18_R25_FBNK_EB_C005;
END;

SELECT /*+ PARALLEL(8) */ COUNT(*)
FROM CONFLUENT.DDAY_R18_R25_FBNK_EB_C005_DIFF;

-- ============================================================
-- COUNT
-- ============================================================

SELECT /*+ PARALLEL(8) INDEX_FFS(t) */ COUNT(*)
FROM CONFLUENT.DDAY_R18_FBNK_EB_C005_EXPLODED t;

SELECT /*+ PARALLEL(8) INDEX_FFS(t) */ COUNT(*)
FROM CONFLUENT.DDAY_R25_FBNK_EB_C005_EXPLODED t;

-- ============================================================
-- INSPECT
-- ============================================================

SELECT /*+ PARALLEL(8) */ *
FROM CONFLUENT.V_DDAY_R18_FBNK_EB_C005_EXPLODED
WHERE RECID = '';

SELECT /*+ PARALLEL(8) */ *
FROM CONFLUENT.V_DDAY_R25_FBNK_EB_C005_EXPLODED
WHERE RECID = '';

SELECT /*+ PARALLEL(8) */ *
FROM CONFLUENT.DDAY_R18_R25_FBNK_EB_C005_DIFF
WHERE RECID = '';
