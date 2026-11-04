-- ============================================================
-- LAG
-- ============================================================

-- Run ./DDAYDR/lag.sh connect-DDAYDR_R18_FBNK_EB_C005_EXPLODED connect-DDAYDR_R25_FBNK_EB_C005_EXPLODED from the repository root; start the report only after both lags stay at 0.

-- ============================================================
-- CPU
-- ============================================================

SELECT VALUE
FROM V$PARAMETER
WHERE NAME = 'cpu_count';

-- ============================================================
-- DROP OBJECTS
-- ============================================================

DROP PROCEDURE CONFLUENTDR.P_COMPARE_DDAYDR_R18_R25_FBNK_EB_C005;
DROP VIEW CONFLUENTDR.V_DDAYDR_R18_FBNK_EB_C005_EXPLODED;
DROP VIEW CONFLUENTDR.V_DDAYDR_R25_FBNK_EB_C005_EXPLODED;
DROP TABLE CONFLUENTDR.DDAYDR_R18_R25_FBNK_EB_C005_DIFF CASCADE CONSTRAINTS PURGE;
DROP TABLE CONFLUENTDR.DDAYDR_R18_FBNK_EB_C005_EXPLODED CASCADE CONSTRAINTS PURGE;
DROP TABLE CONFLUENTDR.DDAYDR_R25_FBNK_EB_C005_EXPLODED CASCADE CONSTRAINTS PURGE;

-- ============================================================
-- CONFLUENTDR.DDAYDR_R18_FBNK_EB_C005_EXPLODED
-- ============================================================

CREATE TABLE CONFLUENTDR.DDAYDR_R18_FBNK_EB_C005_EXPLODED (
    RECID            VARCHAR2(255) NOT NULL,
    ASSET_TYPE       VARCHAR2(255) NOT NULL,
    OP_TYPE          CHAR(1),
    POS              NUMBER(20),
    COMMIT_TS        TIMESTAMP(3),
    REPLICAT_TS      TIMESTAMP(3),
    MAPPED_TS        TIMESTAMP(3),
    EXPLODED_TS      TIMESTAMP(3),
    CHANGED_TS       TIMESTAMP(3) DEFAULT SYSTIMESTAMP NOT NULL,
    CURRENCY         VARCHAR2(255),
    APPLICATION      VARCHAR2(255),
    CUSTOMER         VARCHAR2(255),
    DATE_LAST_UPDATE VARCHAR2(255),
    HVT_FLAG         VARCHAR2(255),
    OPEN_BAL         NUMBER(38,4),
    DR_MVT           NUMBER(38,4),
    CR_MVT           NUMBER(38,4),
    CLOSE_BAL        NUMBER(38,4),
    CURR_ASSET_TYPE  CLOB,
    OPEN_BALANCE     CLOB,
    DEBIT_MVMT       CLOB,
    CREDIT_MVMT      CLOB,
    TYPE_SYSDATE     CLOB
);

CREATE INDEX CONFLUENTDR.IDX_DDAYDR_R18_FBNK_EB_C005_EXPLODED_RECID_COMMIT_TS_POS
ON CONFLUENTDR.DDAYDR_R18_FBNK_EB_C005_EXPLODED (RECID, COMMIT_TS, POS);

-- ============================================================
-- CONFLUENTDR.DDAYDR_R25_FBNK_EB_C005_EXPLODED
-- ============================================================

CREATE TABLE CONFLUENTDR.DDAYDR_R25_FBNK_EB_C005_EXPLODED (
    RECID            VARCHAR2(255) NOT NULL,
    ASSET_TYPE       VARCHAR2(255) NOT NULL,
    OP_TYPE          CHAR(1),
    POS              NUMBER(20),
    COMMIT_TS        TIMESTAMP(3),
    REPLICAT_TS      TIMESTAMP(3),
    MAPPED_TS        TIMESTAMP(3),
    EXPLODED_TS      TIMESTAMP(3),
    CHANGED_TS       TIMESTAMP(3) DEFAULT SYSTIMESTAMP NOT NULL,
    CURRENCY         VARCHAR2(255),
    APPLICATION      VARCHAR2(255),
    CUSTOMER         VARCHAR2(255),
    DATE_LAST_UPDATE VARCHAR2(255),
    HVT_FLAG         VARCHAR2(255),
    OPEN_BAL         NUMBER(38,4),
    DR_MVT           NUMBER(38,4),
    CR_MVT           NUMBER(38,4),
    CLOSE_BAL        NUMBER(38,4),
    CURR_ASSET_TYPE  CLOB,
    OPEN_BALANCE     CLOB,
    DEBIT_MVMT       CLOB,
    CREDIT_MVMT      CLOB,
    TYPE_SYSDATE     CLOB
);

CREATE INDEX CONFLUENTDR.IDX_DDAYDR_R25_FBNK_EB_C005_EXPLODED_RECID_COMMIT_TS_POS
ON CONFLUENTDR.DDAYDR_R25_FBNK_EB_C005_EXPLODED (RECID, COMMIT_TS, POS);

-- ============================================================
-- CONFLUENTDR.V_DDAYDR_R18_FBNK_EB_C005_EXPLODED
-- ============================================================

CREATE OR REPLACE VIEW CONFLUENTDR.V_DDAYDR_R18_FBNK_EB_C005_EXPLODED AS
SELECT t.*
FROM CONFLUENTDR.DDAYDR_R18_FBNK_EB_C005_EXPLODED t
JOIN (
    SELECT
        RECID,
        MAX(COMMIT_TS)                                     AS MAX_COMMIT_TS,
        MAX(POS) KEEP (DENSE_RANK LAST ORDER BY COMMIT_TS) AS MAX_POS
    FROM CONFLUENTDR.DDAYDR_R18_FBNK_EB_C005_EXPLODED
    GROUP BY RECID
) m ON t.RECID = m.RECID AND t.COMMIT_TS = m.MAX_COMMIT_TS AND t.POS = m.MAX_POS;

-- ============================================================
-- CONFLUENTDR.V_DDAYDR_R25_FBNK_EB_C005_EXPLODED
-- ============================================================

CREATE OR REPLACE VIEW CONFLUENTDR.V_DDAYDR_R25_FBNK_EB_C005_EXPLODED AS
SELECT t.*
FROM CONFLUENTDR.DDAYDR_R25_FBNK_EB_C005_EXPLODED t
JOIN (
    SELECT
        RECID,
        MAX(COMMIT_TS)                                     AS MAX_COMMIT_TS,
        MAX(POS) KEEP (DENSE_RANK LAST ORDER BY COMMIT_TS) AS MAX_POS
    FROM CONFLUENTDR.DDAYDR_R25_FBNK_EB_C005_EXPLODED
    GROUP BY RECID
) m ON t.RECID = m.RECID AND t.COMMIT_TS = m.MAX_COMMIT_TS AND t.POS = m.MAX_POS;

-- ============================================================
-- CONFLUENTDR.DDAYDR_R18_R25_FBNK_EB_C005_DIFF
-- ============================================================

CREATE TABLE CONFLUENTDR.DDAYDR_R18_R25_FBNK_EB_C005_DIFF (
    RECID                VARCHAR2(255),
    ASSET_TYPE           VARCHAR2(255),
    DIFF_COLUMNS         VARCHAR2(37),
    DIFF_TYPE            VARCHAR2(32),
    R18_CURRENCY         VARCHAR2(255),
    R25_CURRENCY         VARCHAR2(255),
    R18_APPLICATION      VARCHAR2(255),
    R25_APPLICATION      VARCHAR2(255),
    R18_CUSTOMER         VARCHAR2(255),
    R25_CUSTOMER         VARCHAR2(255),
    R18_DATE_LAST_UPDATE VARCHAR2(255),
    R25_DATE_LAST_UPDATE VARCHAR2(255),
    R18_HVT_FLAG         VARCHAR2(255),
    R25_HVT_FLAG         VARCHAR2(255),
    R18_OPEN_BAL         NUMBER(38,4),
    R25_OPEN_BAL         NUMBER(38,4),
    R18_DR_MVT           NUMBER(38,4),
    R25_DR_MVT           NUMBER(38,4),
    R18_CR_MVT           NUMBER(38,4),
    R25_CR_MVT           NUMBER(38,4),
    R18_CLOSE_BAL        NUMBER(38,4),
    R25_CLOSE_BAL        NUMBER(38,4),
    DIFF_OPEN_BAL        NUMBER,
    DIFF_DR_MVT          NUMBER,
    DIFF_CR_MVT          NUMBER,
    DIFF_CLOSE_BAL       NUMBER
);

-- ============================================================
-- CONFLUENTDR.P_COMPARE_DDAYDR_R18_R25_FBNK_EB_C005
-- ============================================================

CREATE OR REPLACE PROCEDURE CONFLUENTDR.P_COMPARE_DDAYDR_R18_R25_FBNK_EB_C005
AS
BEGIN
    SAVEPOINT BEFORE_COMPARE;
    LOCK TABLE CONFLUENTDR.DDAYDR_R18_R25_FBNK_EB_C005_DIFF IN EXCLUSIVE MODE;

    DELETE FROM CONFLUENTDR.DDAYDR_R18_R25_FBNK_EB_C005_DIFF;

    INSERT INTO CONFLUENTDR.DDAYDR_R18_R25_FBNK_EB_C005_DIFF (
        RECID,
        ASSET_TYPE,
        DIFF_COLUMNS,
        DIFF_TYPE,
        R18_CURRENCY,
        R25_CURRENCY,
        R18_APPLICATION,
        R25_APPLICATION,
        R18_CUSTOMER,
        R25_CUSTOMER,
        R18_DATE_LAST_UPDATE,
        R25_DATE_LAST_UPDATE,
        R18_HVT_FLAG,
        R25_HVT_FLAG,
        R18_OPEN_BAL,
        R25_OPEN_BAL,
        R18_DR_MVT,
        R25_DR_MVT,
        R18_CR_MVT,
        R25_CR_MVT,
        R18_CLOSE_BAL,
        R25_CLOSE_BAL,
        DIFF_OPEN_BAL,
        DIFF_DR_MVT,
        DIFF_CR_MVT,
        DIFF_CLOSE_BAL
    )
    SELECT /*+ PARALLEL(64) */
        c.RECID                           AS RECID,
        c.ASSET_TYPE                      AS ASSET_TYPE,
        RTRIM(
               CASE WHEN DECODE(c.R18_OPEN_BAL, c.R25_OPEN_BAL, 0, CASE WHEN ABS(c.R25_OPEN_BAL - c.R18_OPEN_BAL) <= c.DIFF_THRESHOLD THEN 0 ELSE 1 END) = 1 THEN 'OPEN_BAL, ' END
            || CASE WHEN DECODE(c.R18_DR_MVT, c.R25_DR_MVT, 0, CASE WHEN ABS(c.R25_DR_MVT - c.R18_DR_MVT) <= c.DIFF_THRESHOLD THEN 0 ELSE 1 END) = 1 THEN 'DR_MVT, ' END
            || CASE WHEN DECODE(c.R18_CR_MVT, c.R25_CR_MVT, 0, CASE WHEN ABS(c.R25_CR_MVT - c.R18_CR_MVT) <= c.DIFF_THRESHOLD THEN 0 ELSE 1 END) = 1 THEN 'CR_MVT, ' END
            || CASE WHEN DECODE(c.R18_CLOSE_BAL, c.R25_CLOSE_BAL, 0, CASE WHEN ABS(c.R25_CLOSE_BAL - c.R18_CLOSE_BAL) <= c.DIFF_THRESHOLD THEN 0 ELSE 1 END) = 1 THEN 'CLOSE_BAL, ' END,
            ', '
        ) AS DIFF_COLUMNS,
        CASE
            WHEN c.R18_RECID_COUNT = 0 THEN 'MISSING_RECID_IN_R18'
            WHEN c.R25_RECID_COUNT = 0 THEN 'MISSING_RECID_IN_R25'
            WHEN c.MISSING_SIDE = 'R18' THEN 'MISSING_ASSET_TYPE_IN_R18'
            WHEN c.MISSING_SIDE = 'R25' THEN 'MISSING_ASSET_TYPE_IN_R25'
            ELSE 'VALUE_MISMATCH'
        END AS DIFF_TYPE,
        c.R18_CURRENCY                    AS R18_CURRENCY,
        c.R25_CURRENCY                    AS R25_CURRENCY,
        c.R18_APPLICATION                 AS R18_APPLICATION,
        c.R25_APPLICATION                 AS R25_APPLICATION,
        c.R18_CUSTOMER                    AS R18_CUSTOMER,
        c.R25_CUSTOMER                    AS R25_CUSTOMER,
        c.R18_DATE_LAST_UPDATE            AS R18_DATE_LAST_UPDATE,
        c.R25_DATE_LAST_UPDATE            AS R25_DATE_LAST_UPDATE,
        c.R18_HVT_FLAG                    AS R18_HVT_FLAG,
        c.R25_HVT_FLAG                    AS R25_HVT_FLAG,
        c.R18_OPEN_BAL                    AS R18_OPEN_BAL,
        c.R25_OPEN_BAL                    AS R25_OPEN_BAL,
        c.R18_DR_MVT                      AS R18_DR_MVT,
        c.R25_DR_MVT                      AS R25_DR_MVT,
        c.R18_CR_MVT                      AS R18_CR_MVT,
        c.R25_CR_MVT                      AS R25_CR_MVT,
        c.R18_CLOSE_BAL                   AS R18_CLOSE_BAL,
        c.R25_CLOSE_BAL                   AS R25_CLOSE_BAL,
        c.R25_OPEN_BAL - c.R18_OPEN_BAL   AS DIFF_OPEN_BAL,
        c.R25_DR_MVT - c.R18_DR_MVT       AS DIFF_DR_MVT,
        c.R25_CR_MVT - c.R18_CR_MVT       AS DIFF_CR_MVT,
        c.R25_CLOSE_BAL - c.R18_CLOSE_BAL AS DIFF_CLOSE_BAL
    FROM (
        SELECT
            COALESCE(r18.RECID, r25.RECID)                                      AS RECID,
            COALESCE(r18.ASSET_TYPE, r25.ASSET_TYPE)                            AS ASSET_TYPE,
            CASE
                WHEN r18.RECID IS NULL THEN 'R18'
                WHEN r25.RECID IS NULL THEN 'R25'
            END AS MISSING_SIDE,
            COUNT(r18.RECID) OVER (PARTITION BY COALESCE(r18.RECID, r25.RECID)) AS R18_RECID_COUNT,
            COUNT(r25.RECID) OVER (PARTITION BY COALESCE(r18.RECID, r25.RECID)) AS R25_RECID_COUNT,
            CASE WHEN (r18.RECID IS NULL OR r18.CURRENCY = 'VND')
                       AND (r25.RECID IS NULL OR r25.CURRENCY = 'VND')
                 THEN 1 ELSE 0
            END AS DIFF_THRESHOLD,
            r18.CURRENCY                                                        AS R18_CURRENCY,
            r25.CURRENCY                                                        AS R25_CURRENCY,
            r18.APPLICATION                                                     AS R18_APPLICATION,
            r25.APPLICATION                                                     AS R25_APPLICATION,
            r18.CUSTOMER                                                        AS R18_CUSTOMER,
            r25.CUSTOMER                                                        AS R25_CUSTOMER,
            r18.DATE_LAST_UPDATE                                                AS R18_DATE_LAST_UPDATE,
            r25.DATE_LAST_UPDATE                                                AS R25_DATE_LAST_UPDATE,
            r18.HVT_FLAG                                                        AS R18_HVT_FLAG,
            r25.HVT_FLAG                                                        AS R25_HVT_FLAG,
            CASE WHEN r18.RECID IS NULL OR r25.RECID IS NULL
                 THEN NVL(r18.OPEN_BAL, 0)
                 ELSE r18.OPEN_BAL
            END AS R18_OPEN_BAL,
            CASE WHEN r18.RECID IS NULL OR r25.RECID IS NULL
                 THEN NVL(r25.OPEN_BAL, 0)
                 ELSE r25.OPEN_BAL
            END AS R25_OPEN_BAL,
            CASE WHEN r18.RECID IS NULL OR r25.RECID IS NULL
                 THEN NVL(r18.DR_MVT, 0)
                 ELSE r18.DR_MVT
            END AS R18_DR_MVT,
            CASE WHEN r18.RECID IS NULL OR r25.RECID IS NULL
                 THEN NVL(r25.DR_MVT, 0)
                 ELSE r25.DR_MVT
            END AS R25_DR_MVT,
            CASE WHEN r18.RECID IS NULL OR r25.RECID IS NULL
                 THEN NVL(r18.CR_MVT, 0)
                 ELSE r18.CR_MVT
            END AS R18_CR_MVT,
            CASE WHEN r18.RECID IS NULL OR r25.RECID IS NULL
                 THEN NVL(r25.CR_MVT, 0)
                 ELSE r25.CR_MVT
            END AS R25_CR_MVT,
            CASE WHEN r18.RECID IS NULL OR r25.RECID IS NULL
                 THEN NVL(r18.CLOSE_BAL, 0)
                 ELSE r18.CLOSE_BAL
            END AS R18_CLOSE_BAL,
            CASE WHEN r18.RECID IS NULL OR r25.RECID IS NULL
                 THEN NVL(r25.CLOSE_BAL, 0)
                 ELSE r25.CLOSE_BAL
            END AS R25_CLOSE_BAL
        FROM CONFLUENTDR.V_DDAYDR_R18_FBNK_EB_C005_EXPLODED r18
        FULL OUTER JOIN CONFLUENTDR.V_DDAYDR_R25_FBNK_EB_C005_EXPLODED r25 ON r18.RECID = r25.RECID AND r18.ASSET_TYPE = r25.ASSET_TYPE
    ) c
    WHERE DECODE(c.R18_OPEN_BAL, c.R25_OPEN_BAL, 0, CASE WHEN ABS(c.R25_OPEN_BAL - c.R18_OPEN_BAL) <= c.DIFF_THRESHOLD THEN 0 ELSE 1 END) = 1
       OR DECODE(c.R18_DR_MVT, c.R25_DR_MVT, 0, CASE WHEN ABS(c.R25_DR_MVT - c.R18_DR_MVT) <= c.DIFF_THRESHOLD THEN 0 ELSE 1 END) = 1
       OR DECODE(c.R18_CR_MVT, c.R25_CR_MVT, 0, CASE WHEN ABS(c.R25_CR_MVT - c.R18_CR_MVT) <= c.DIFF_THRESHOLD THEN 0 ELSE 1 END) = 1
       OR DECODE(c.R18_CLOSE_BAL, c.R25_CLOSE_BAL, 0, CASE WHEN ABS(c.R25_CLOSE_BAL - c.R18_CLOSE_BAL) <= c.DIFF_THRESHOLD THEN 0 ELSE 1 END) = 1;

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
    CONFLUENTDR.P_COMPARE_DDAYDR_R18_R25_FBNK_EB_C005;
END;

SELECT /*+ PARALLEL(64) */ COUNT(*)
FROM CONFLUENTDR.DDAYDR_R18_R25_FBNK_EB_C005_DIFF;

-- ============================================================
-- COUNT
-- ============================================================

SELECT /*+ PARALLEL(64) */ 'R18' AS SIDE, COUNT(*) AS ROW_COUNT
FROM CONFLUENTDR.DDAYDR_R18_FBNK_EB_C005_EXPLODED t
UNION ALL
SELECT 'R25' AS SIDE, COUNT(*) AS ROW_COUNT
FROM CONFLUENTDR.DDAYDR_R25_FBNK_EB_C005_EXPLODED t;

-- ============================================================
-- INSPECT
-- ============================================================

SELECT /*+ PARALLEL(64) */ *
FROM (
    SELECT 'R18' AS SIDE, v.*
    FROM CONFLUENTDR.V_DDAYDR_R18_FBNK_EB_C005_EXPLODED v
    WHERE v.RECID = ''
    UNION ALL
    SELECT 'R25' AS SIDE, v.*
    FROM CONFLUENTDR.V_DDAYDR_R25_FBNK_EB_C005_EXPLODED v
    WHERE v.RECID = ''
)
ORDER BY SIDE, CHANGED_TS;

SELECT /*+ PARALLEL(64) */ *
FROM CONFLUENTDR.DDAYDR_R18_R25_FBNK_EB_C005_DIFF
WHERE RECID = ''
ORDER BY RECID, ASSET_TYPE;
