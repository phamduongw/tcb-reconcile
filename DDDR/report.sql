-- ============================================================
-- LAG
-- ============================================================

-- Run ./DDDR/lag.sh connect-DDDR_R18_FBNK_EB_C005_EXPLODED connect-DDDR_R25_FBNK_EB_C005_EXPLODED from the repository root; start the report only after both lags stay at 0.

-- ============================================================
-- CPU
-- ============================================================

SELECT VALUE
FROM V$PARAMETER
WHERE NAME = 'cpu_count';

-- ============================================================
-- DROP OBJECTS
-- ============================================================

DROP PROCEDURE CONFLUENTDR.P_COMPARE_DDDR_R18_R25_FBNK_EB_C005;
DROP VIEW CONFLUENTDR.V_DDDR_R18_FBNK_EB_C005_EXPLODED;
DROP VIEW CONFLUENTDR.V_DDDR_R25_FBNK_EB_C005_EXPLODED;
DROP TABLE CONFLUENTDR.DDDR_R18_R25_FBNK_EB_C005_DIFF CASCADE CONSTRAINTS PURGE;
DROP TABLE CONFLUENTDR.DDDR_R18_FBNK_EB_C005_EXPLODED CASCADE CONSTRAINTS PURGE;
DROP TABLE CONFLUENTDR.DDDR_R25_FBNK_EB_C005_EXPLODED CASCADE CONSTRAINTS PURGE;

-- ============================================================
-- CONFLUENTDR.DDDR_R18_FBNK_EB_C005_EXPLODED
-- ============================================================

CREATE TABLE CONFLUENTDR.DDDR_R18_FBNK_EB_C005_EXPLODED (
    RECID            VARCHAR2(255) NOT NULL,
    ASSET_TYPE       VARCHAR2(255) NOT NULL,
    OP_TYPE          CHAR(1),
    POS              NUMBER(20),
    COMMIT_TS        TIMESTAMP(3),
    REPLICAT_TS      TIMESTAMP(3),
    MAPPED_TS        TIMESTAMP(3),
    EXPLODED_TS      TIMESTAMP(3),
    CHANGED_TS       TIMESTAMP(3) DEFAULT SYSTIMESTAMP NOT NULL,
    APPLICATION      VARCHAR2(128),
    CUSTOMER         VARCHAR2(255),
    DATE_LAST_UPDATE VARCHAR2(8),
    OPEN_BAL         NUMBER(38,4),
    DR_MVT           NUMBER(38,4),
    CR_MVT           NUMBER(38,4),
    CLOSE_BAL        NUMBER(38,4)
);

CREATE INDEX CONFLUENTDR.IDX_DDDR_R18_FBNK_EB_C005_EXPLODED_RECID_COMMIT_TS_POS
ON CONFLUENTDR.DDDR_R18_FBNK_EB_C005_EXPLODED (RECID, COMMIT_TS, POS);

-- ============================================================
-- CONFLUENTDR.DDDR_R25_FBNK_EB_C005_EXPLODED
-- ============================================================

CREATE TABLE CONFLUENTDR.DDDR_R25_FBNK_EB_C005_EXPLODED (
    RECID            VARCHAR2(255) NOT NULL,
    ASSET_TYPE       VARCHAR2(255) NOT NULL,
    OP_TYPE          CHAR(1),
    POS              NUMBER(20),
    COMMIT_TS        TIMESTAMP(3),
    REPLICAT_TS      TIMESTAMP(3),
    MAPPED_TS        TIMESTAMP(3),
    EXPLODED_TS      TIMESTAMP(3),
    CHANGED_TS       TIMESTAMP(3) DEFAULT SYSTIMESTAMP NOT NULL,
    APPLICATION      VARCHAR2(128),
    CUSTOMER         VARCHAR2(255),
    DATE_LAST_UPDATE VARCHAR2(8),
    OPEN_BAL         NUMBER(38,4),
    DR_MVT           NUMBER(38,4),
    CR_MVT           NUMBER(38,4),
    CLOSE_BAL        NUMBER(38,4)
);

CREATE INDEX CONFLUENTDR.IDX_DDDR_R25_FBNK_EB_C005_EXPLODED_RECID_COMMIT_TS_POS
ON CONFLUENTDR.DDDR_R25_FBNK_EB_C005_EXPLODED (RECID, COMMIT_TS, POS);

-- ============================================================
-- CONFLUENTDR.V_DDDR_R18_FBNK_EB_C005_EXPLODED
-- ============================================================

CREATE OR REPLACE VIEW CONFLUENTDR.V_DDDR_R18_FBNK_EB_C005_EXPLODED AS
SELECT t.*
FROM CONFLUENTDR.DDDR_R18_FBNK_EB_C005_EXPLODED t
JOIN (
    SELECT
        RECID,
        MAX(COMMIT_TS)                                     AS MAX_COMMIT_TS,
        MAX(POS) KEEP (DENSE_RANK LAST ORDER BY COMMIT_TS) AS MAX_POS
    FROM CONFLUENTDR.DDDR_R18_FBNK_EB_C005_EXPLODED
    GROUP BY RECID
) m ON t.RECID = m.RECID AND t.COMMIT_TS = m.MAX_COMMIT_TS AND t.POS = m.MAX_POS;

-- ============================================================
-- CONFLUENTDR.V_DDDR_R25_FBNK_EB_C005_EXPLODED
-- ============================================================

CREATE OR REPLACE VIEW CONFLUENTDR.V_DDDR_R25_FBNK_EB_C005_EXPLODED AS
SELECT t.*
FROM CONFLUENTDR.DDDR_R25_FBNK_EB_C005_EXPLODED t
JOIN (
    SELECT
        RECID,
        MAX(COMMIT_TS)                                     AS MAX_COMMIT_TS,
        MAX(POS) KEEP (DENSE_RANK LAST ORDER BY COMMIT_TS) AS MAX_POS
    FROM CONFLUENTDR.DDDR_R25_FBNK_EB_C005_EXPLODED
    GROUP BY RECID
) m ON t.RECID = m.RECID AND t.COMMIT_TS = m.MAX_COMMIT_TS AND t.POS = m.MAX_POS;

-- ============================================================
-- CONFLUENTDR.DDDR_R18_R25_FBNK_EB_C005_DIFF
-- ============================================================

CREATE TABLE CONFLUENTDR.DDDR_R18_R25_FBNK_EB_C005_DIFF (
    RECID                     VARCHAR2(255),
    ASSET_TYPE                VARCHAR2(255),
    DIFF_TYPE                 VARCHAR2(32),
    DIFF_COLUMNS              VARCHAR2(37),
    DDDR_R18_APPLICATION      VARCHAR2(128),
    DDDR_R25_APPLICATION      VARCHAR2(128),
    DDDR_R18_CUSTOMER         VARCHAR2(255),
    DDDR_R25_CUSTOMER         VARCHAR2(255),
    DDDR_R18_DATE_LAST_UPDATE VARCHAR2(8),
    DDDR_R25_DATE_LAST_UPDATE VARCHAR2(8),
    DDDR_R18_OPEN_BAL         NUMBER(38,4),
    DDDR_R25_OPEN_BAL         NUMBER(38,4),
    DDDR_R18_DR_MVT           NUMBER(38,4),
    DDDR_R25_DR_MVT           NUMBER(38,4),
    DDDR_R18_CR_MVT           NUMBER(38,4),
    DDDR_R25_CR_MVT           NUMBER(38,4),
    DDDR_R18_CLOSE_BAL        NUMBER(38,4),
    DDDR_R25_CLOSE_BAL        NUMBER(38,4),
    DIFF_OPEN_BAL             NUMBER,
    DIFF_DR_MVT               NUMBER,
    DIFF_CR_MVT               NUMBER,
    DIFF_CLOSE_BAL            NUMBER
);

-- ============================================================
-- CONFLUENTDR.P_COMPARE_DDDR_R18_R25_FBNK_EB_C005
-- ============================================================

CREATE OR REPLACE PROCEDURE CONFLUENTDR.P_COMPARE_DDDR_R18_R25_FBNK_EB_C005
AS
BEGIN
    SAVEPOINT BEFORE_COMPARE;
    LOCK TABLE CONFLUENTDR.DDDR_R18_R25_FBNK_EB_C005_DIFF IN EXCLUSIVE MODE;

    DELETE FROM CONFLUENTDR.DDDR_R18_R25_FBNK_EB_C005_DIFF;

    INSERT INTO CONFLUENTDR.DDDR_R18_R25_FBNK_EB_C005_DIFF (
        RECID,
        ASSET_TYPE,
        DIFF_TYPE,
        DIFF_COLUMNS,
        DDDR_R18_APPLICATION,
        DDDR_R25_APPLICATION,
        DDDR_R18_CUSTOMER,
        DDDR_R25_CUSTOMER,
        DDDR_R18_DATE_LAST_UPDATE,
        DDDR_R25_DATE_LAST_UPDATE,
        DDDR_R18_OPEN_BAL,
        DDDR_R25_OPEN_BAL,
        DDDR_R18_DR_MVT,
        DDDR_R25_DR_MVT,
        DDDR_R18_CR_MVT,
        DDDR_R25_CR_MVT,
        DDDR_R18_CLOSE_BAL,
        DDDR_R25_CLOSE_BAL,
        DIFF_OPEN_BAL,
        DIFF_DR_MVT,
        DIFF_CR_MVT,
        DIFF_CLOSE_BAL
    )
    SELECT /*+ PARALLEL(64) */
        COALESCE(r18.RECID, r25.RECID)           AS RECID,
        COALESCE(r18.ASSET_TYPE, r25.ASSET_TYPE) AS ASSET_TYPE,
        CASE
            WHEN r18.RECID IS NULL THEN
                CASE
                    WHEN NOT EXISTS (
                        SELECT 1
                        FROM CONFLUENTDR.V_DDDR_R18_FBNK_EB_C005_EXPLODED x
                        WHERE x.RECID = r25.RECID
                    ) THEN 'MISSING_RECID_IN_DDDR_R18'
                    ELSE 'MISSING_ASSET_TYPE_IN_DDDR_R18'
                END
            WHEN r25.RECID IS NULL THEN
                CASE
                    WHEN NOT EXISTS (
                        SELECT 1
                        FROM CONFLUENTDR.V_DDDR_R25_FBNK_EB_C005_EXPLODED x
                        WHERE x.RECID = r18.RECID
                    ) THEN 'MISSING_RECID_IN_DDDR_R25'
                    ELSE 'MISSING_ASSET_TYPE_IN_DDDR_R25'
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
        r18.APPLICATION               AS DDDR_R18_APPLICATION,
        r25.APPLICATION               AS DDDR_R25_APPLICATION,
        r18.CUSTOMER                  AS DDDR_R18_CUSTOMER,
        r25.CUSTOMER                  AS DDDR_R25_CUSTOMER,
        r18.DATE_LAST_UPDATE          AS DDDR_R18_DATE_LAST_UPDATE,
        r25.DATE_LAST_UPDATE          AS DDDR_R25_DATE_LAST_UPDATE,
        r18.OPEN_BAL                  AS DDDR_R18_OPEN_BAL,
        r25.OPEN_BAL                  AS DDDR_R25_OPEN_BAL,
        r18.DR_MVT                    AS DDDR_R18_DR_MVT,
        r25.DR_MVT                    AS DDDR_R25_DR_MVT,
        r18.CR_MVT                    AS DDDR_R18_CR_MVT,
        r25.CR_MVT                    AS DDDR_R25_CR_MVT,
        r18.CLOSE_BAL                 AS DDDR_R18_CLOSE_BAL,
        r25.CLOSE_BAL                 AS DDDR_R25_CLOSE_BAL,
        r25.OPEN_BAL - r18.OPEN_BAL   AS DIFF_OPEN_BAL,
        r25.DR_MVT - r18.DR_MVT       AS DIFF_DR_MVT,
        r25.CR_MVT - r18.CR_MVT       AS DIFF_CR_MVT,
        r25.CLOSE_BAL - r18.CLOSE_BAL AS DIFF_CLOSE_BAL
    FROM CONFLUENTDR.V_DDDR_R18_FBNK_EB_C005_EXPLODED r18
    FULL OUTER JOIN CONFLUENTDR.V_DDDR_R25_FBNK_EB_C005_EXPLODED r25 ON r18.RECID = r25.RECID AND r18.ASSET_TYPE = r25.ASSET_TYPE
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
    CONFLUENTDR.P_COMPARE_DDDR_R18_R25_FBNK_EB_C005;
END;

SELECT /*+ PARALLEL(64) */ COUNT(*)
FROM CONFLUENTDR.DDDR_R18_R25_FBNK_EB_C005_DIFF;

-- ============================================================
-- COUNT
-- ============================================================

SELECT /*+ PARALLEL(64) INDEX_FFS(t) */ 'R18' AS SIDE, COUNT(*) AS ROW_COUNT
FROM CONFLUENTDR.DDDR_R18_FBNK_EB_C005_EXPLODED t
UNION ALL
SELECT /*+ PARALLEL(64) INDEX_FFS(t) */ 'R25' AS SIDE, COUNT(*) AS ROW_COUNT
FROM CONFLUENTDR.DDDR_R25_FBNK_EB_C005_EXPLODED t;

-- ============================================================
-- INSPECT
-- ============================================================

SELECT /*+ PARALLEL(64) */ *
FROM CONFLUENTDR.DDDR_R18_FBNK_EB_C005_EXPLODED
FETCH FIRST 10 ROWS ONLY;

SELECT /*+ PARALLEL(64) */ *
FROM CONFLUENTDR.DDDR_R25_FBNK_EB_C005_EXPLODED
FETCH FIRST 10 ROWS ONLY;

SELECT /*+ PARALLEL(64) */ *
FROM (
    SELECT 'R18' AS SIDE, v.*
    FROM CONFLUENTDR.V_DDDR_R18_FBNK_EB_C005_EXPLODED v
    WHERE v.RECID = ''
    UNION ALL
    SELECT 'R25' AS SIDE, v.*
    FROM CONFLUENTDR.V_DDDR_R25_FBNK_EB_C005_EXPLODED v
    WHERE v.RECID = ''
)
ORDER BY CHANGED_TS;

SELECT /*+ PARALLEL(64) */ *
FROM CONFLUENTDR.DDDR_R18_R25_FBNK_EB_C005_DIFF
WHERE RECID = '';
