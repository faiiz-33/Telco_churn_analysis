/* ============================================================
   TELCO CUSTOMER CHURN ANALYSIS (SQL)
   ------------------------------------------------------------
   Dialect : MySQL 8+ (also runs unchanged on SQLite 3.25+)
   Table   : telco  <- Data/telco_churn_clean.csv (7,032 rows)
   Target  : churns  (0 = retained, 1 = churned)

   Sections
     A. Setup
     B. Churn rates by segment            (queries 1-5)
     C. Tenure and spending               (queries 6-10)
     D. High-churn segments and gaps      (queries 11-13)
     E. Risk scoring                      (queries 14-17)
     F. Revenue impact                    (queries 18-19)
   ============================================================ */


/* ============================================================
   A. SETUP
   ============================================================ */

/* ------------------------------------------------------------
   0a) Table schema. Load Data/telco_churn_clean.csv into it
       (MySQL Workbench: Table Data Import Wizard, or LOAD DATA).
   ------------------------------------------------------------ */
CREATE TABLE IF NOT EXISTS telco (
    customerID        VARCHAR(20) PRIMARY KEY,
    gender            VARCHAR(10),
    SeniorCitizen     INT,
    Partner           VARCHAR(5),
    Dependents        VARCHAR(5),
    tenure            INT,
    PhoneService      VARCHAR(5),
    MultipleLines     VARCHAR(20),
    InternetService   VARCHAR(20),
    OnlineSecurity    VARCHAR(20),
    OnlineBackup      VARCHAR(20),
    DeviceProtection  VARCHAR(20),
    TechSupport       VARCHAR(20),
    StreamingTV       VARCHAR(20),
    StreamingMovies   VARCHAR(20),
    Contract          VARCHAR(20),
    PaperlessBilling  VARCHAR(5),
    PaymentMethod     VARCHAR(30),
    MonthlyCharges    DECIMAL(8,2),
    TotalCharges      DECIMAL(10,2),
    churns            INT,
    risk_score        INT,
    tenure_group      VARCHAR(15)
);


/* ------------------------------------------------------------
   0b) Scored view: the final risk score is defined once here and
       reused by every query below, so the logic cannot drift.
       Final score = 6 signals, one point each (range 0-6):
         Month-to-month contract, Fiber optic, Electronic check,
         No tech support, No online security, tenure <= 6 months.
       It matches the risk_score column in the clean CSV.
   ------------------------------------------------------------ */
DROP VIEW IF EXISTS telco_scored;

CREATE VIEW telco_scored AS
SELECT
    t.*,
    (
        (Contract = 'Month-to-month') +
        (InternetService = 'Fiber optic') +
        (PaymentMethod = 'Electronic check') +
        (TechSupport = 'No') +
        (OnlineSecurity = 'No') +
        (tenure <= 6)
    ) AS risk_score_final
FROM telco t;


/* ============================================================
   B. CHURN RATES BY SEGMENT
   ============================================================ */

/* ------------------------------------------------------------
   1) Overall churn rate
   ------------------------------------------------------------ */
SELECT
    COUNT(*)                     AS customers,
    SUM(churns)                  AS churners,
    ROUND(AVG(churns) * 100, 2)  AS churn_rate_pct
FROM telco;


/* ------------------------------------------------------------
   2) Churn rate by contract type
   ------------------------------------------------------------ */
SELECT
    Contract,
    ROUND(AVG(churns) * 100, 2) AS churn_rate_pct,
    COUNT(*) AS customers
FROM telco
GROUP BY Contract
ORDER BY churn_rate_pct DESC;


/* ------------------------------------------------------------
   3) Churn rate by payment method
   ------------------------------------------------------------ */
SELECT
    PaymentMethod,
    ROUND(AVG(churns) * 100, 2) AS churn_rate_pct,
    COUNT(*) AS customers
FROM telco
GROUP BY PaymentMethod
ORDER BY churn_rate_pct DESC;


/* ------------------------------------------------------------
   4) Churn rate by internet service
   ------------------------------------------------------------ */
SELECT
    InternetService,
    ROUND(AVG(churns) * 100, 2) AS churn_rate_pct,
    COUNT(*) AS customers
FROM telco
GROUP BY InternetService
ORDER BY churn_rate_pct DESC;


/* ------------------------------------------------------------
   5) Churn rate by tech support
   ------------------------------------------------------------ */
SELECT
    TechSupport,
    ROUND(AVG(churns) * 100, 2) AS churn_rate_pct,
    COUNT(*) AS customers
FROM telco
GROUP BY TechSupport
ORDER BY churn_rate_pct DESC;


/* ============================================================
   C. TENURE AND SPENDING
   ============================================================ */

/* ------------------------------------------------------------
   6) Average tenure by churn status (months)
   ------------------------------------------------------------ */
SELECT
    churns,
    ROUND(AVG(tenure), 2) AS avg_tenure_months,
    COUNT(*) AS customers
FROM telco
GROUP BY churns;


/* ------------------------------------------------------------
   7) Spending: churners vs retained customers
      Churners pay more per month but generate less lifetime
      revenue because they leave earlier.
   ------------------------------------------------------------ */
SELECT
    churns,
    ROUND(AVG(MonthlyCharges), 2) AS avg_monthly_charges,
    ROUND(AVG(TotalCharges), 2)   AS avg_total_charges,
    ROUND(AVG(tenure), 2)         AS avg_tenure_months,
    COUNT(*)                      AS customers
FROM telco
GROUP BY churns;


/* ------------------------------------------------------------
   8) Top 10 customers by lifetime revenue (TotalCharges)
   ------------------------------------------------------------ */
SELECT *
FROM (
    SELECT
        customerID,
        TotalCharges,
        churns,
        RANK() OVER (ORDER BY TotalCharges DESC) AS revenue_rank
    FROM telco
) ranked
WHERE revenue_rank <= 10
ORDER BY revenue_rank;


/* ------------------------------------------------------------
   9) Top 10 customers by monthly charges
   ------------------------------------------------------------ */
SELECT *
FROM (
    SELECT
        customerID,
        MonthlyCharges,
        churns,
        RANK() OVER (ORDER BY MonthlyCharges DESC) AS monthly_rank
    FROM telco
) ranked
WHERE monthly_rank <= 10
ORDER BY monthly_rank;


/* ------------------------------------------------------------
   10) Churn rate by tenure group
       Buckets do not overlap: 0-6, 7-12, 13-24, 25+.
       (tenure 0 does not occur in the clean data.)
       Sorted by bucket order, not alphabetically.
   ------------------------------------------------------------ */
SELECT
    CASE
        WHEN tenure <= 6  THEN '0-6 months'
        WHEN tenure <= 12 THEN '7-12 months'
        WHEN tenure <= 24 THEN '13-24 months'
        ELSE '25+ months'
    END AS tenure_group,
    ROUND(AVG(churns) * 100, 2) AS churn_rate_pct,
    COUNT(*) AS customers
FROM telco
GROUP BY tenure_group
ORDER BY MIN(tenure);


/* ============================================================
   D. HIGH-CHURN SEGMENTS AND SERVICE GAPS
   ============================================================ */

/* ------------------------------------------------------------
   11) Highest-churn segments (InternetService x Contract x PaymentMethod)
      HAVING COUNT(*) > 50 drops segments too small to trust.
   ------------------------------------------------------------ */
SELECT
    InternetService,
    Contract,
    PaymentMethod,
    ROUND(AVG(churns) * 100, 2) AS churn_rate_pct,
    COUNT(*) AS customers
FROM telco
GROUP BY InternetService, Contract, PaymentMethod
HAVING COUNT(*) > 50
ORDER BY churn_rate_pct DESC
LIMIT 10;


/* ------------------------------------------------------------
   12) Share of churners missing each protection/support add-on
       100.0 forces decimal division in every SQL dialect.
   ------------------------------------------------------------ */
SELECT
    ROUND(100.0 * SUM(CASE WHEN OnlineSecurity   = 'No' THEN 1 ELSE 0 END) / COUNT(*), 2) AS pct_no_online_security,
    ROUND(100.0 * SUM(CASE WHEN TechSupport      = 'No' THEN 1 ELSE 0 END) / COUNT(*), 2) AS pct_no_tech_support,
    ROUND(100.0 * SUM(CASE WHEN OnlineBackup     = 'No' THEN 1 ELSE 0 END) / COUNT(*), 2) AS pct_no_online_backup,
    ROUND(100.0 * SUM(CASE WHEN DeviceProtection = 'No' THEN 1 ELSE 0 END) / COUNT(*), 2) AS pct_no_device_protection
FROM telco
WHERE churns = 1;


/* ------------------------------------------------------------
   13) Churn rate by contract x internet service
   ------------------------------------------------------------ */
SELECT
    Contract,
    InternetService,
    ROUND(AVG(churns) * 100, 2) AS churn_rate_pct,
    COUNT(*) AS customers
FROM telco
GROUP BY Contract, InternetService
ORDER BY churn_rate_pct DESC;


/* ============================================================
   E. RISK SCORING
   Goal: a transparent rule-based score that ranks customers by
   churn likelihood. Built in three iterations:
     v1  4 signals (contract, internet, payment, tech support)
     v2  + tenure <= 6, no online security, MonthlyCharges > 75
     v3  (final) v2 without MonthlyCharges > 75: dropping it
         raised ROC AUC from 0.817 to 0.825
         (validated in Python/02_churn_model.ipynb)
   ============================================================ */

/* ------------------------------------------------------------
   14) v1 score (0-4): top 5 retained customers with the maximum
       score, ranked by monthly charges
   ------------------------------------------------------------ */
SELECT *
FROM (
    SELECT
        customerID,
        Contract,
        InternetService,
        PaymentMethod,
        TechSupport,
        MonthlyCharges,
        churns,
        (
            (Contract = 'Month-to-month') +
            (InternetService = 'Fiber optic') +
            (PaymentMethod = 'Electronic check') +
            (TechSupport = 'No')
        ) AS risk_score_v1
    FROM telco
) t
WHERE churns = 0
  AND risk_score_v1 = 4
ORDER BY MonthlyCharges DESC
LIMIT 5;


/* ------------------------------------------------------------
   15) v2 vs final score: churn rate at each score level
       A good score shows churn rising steadily with the score.
   ------------------------------------------------------------ */
SELECT
    risk_score_final,
    COUNT(*) AS customers,
    SUM(churns) AS churners,
    ROUND(AVG(churns) * 100, 2) AS churn_rate_pct
FROM telco_scored
GROUP BY risk_score_final
ORDER BY risk_score_final;

SELECT
    (
        (Contract = 'Month-to-month') +
        (InternetService = 'Fiber optic') +
        (PaymentMethod = 'Electronic check') +
        (TechSupport = 'No') +
        (OnlineSecurity = 'No') +
        (tenure <= 6) +
        (MonthlyCharges > 75)
    ) AS risk_score_v2,
    COUNT(*) AS customers,
    ROUND(AVG(churns) * 100, 2) AS churn_rate_pct
FROM telco
GROUP BY risk_score_v2
ORDER BY risk_score_v2;


/* ------------------------------------------------------------
   16) Retained customers to target first: final score >= 5,
       highest monthly charges first
   ------------------------------------------------------------ */
SELECT
    customerID,
    Contract,
    InternetService,
    PaymentMethod,
    tenure,
    MonthlyCharges,
    risk_score_final
FROM telco_scored
WHERE churns = 0
  AND risk_score_final >= 5
ORDER BY risk_score_final DESC, MonthlyCharges DESC
LIMIT 10;


/* ------------------------------------------------------------
   17) Churn drivers summary: churners vs retained
   ------------------------------------------------------------ */
SELECT
    churns,
    ROUND(AVG(tenure), 2)           AS avg_tenure,
    ROUND(AVG(MonthlyCharges), 2)   AS avg_monthly_charges,
    ROUND(AVG(risk_score_final), 2) AS avg_risk_score,
    SUM(CASE WHEN Contract = 'Month-to-month' THEN 1 ELSE 0 END) AS month_to_month_customers,
    SUM(CASE WHEN InternetService = 'Fiber optic' THEN 1 ELSE 0 END) AS fiber_optic_customers
FROM telco_scored
GROUP BY churns;


/* ============================================================
   F. REVENUE IMPACT
   ============================================================ */

/* ------------------------------------------------------------
   18) Revenue already lost to churn
       - monthly_revenue_lost: recurring revenue that left with
         churned customers (sum of their MonthlyCharges)
       - lifetime_revenue_churners: what churners paid before
         leaving (TotalCharges); the average is their customer value
   ------------------------------------------------------------ */
SELECT
    ROUND(SUM(CASE WHEN churns = 1 THEN MonthlyCharges ELSE 0 END), 2)                    AS monthly_revenue_lost,
    ROUND(100.0 * SUM(CASE WHEN churns = 1 THEN MonthlyCharges ELSE 0 END)
          / SUM(MonthlyCharges), 2)                                                     AS pct_of_monthly_revenue,
    ROUND(SUM(CASE WHEN churns = 1 THEN TotalCharges ELSE 0 END), 2)                      AS lifetime_revenue_churners,
    ROUND(AVG(CASE WHEN churns = 1 THEN TotalCharges END), 2)                             AS avg_lifetime_revenue_churner,
    ROUND(AVG(CASE WHEN churns = 0 THEN TotalCharges END), 2)                             AS avg_lifetime_revenue_retained
FROM telco;


/* ------------------------------------------------------------
   19) Monthly revenue at risk: recurring revenue from customers
       who are still active (churns = 0) but score high (>= 5).
       Churned customers are excluded: their revenue is already
       lost (query 18), not at risk.
   ------------------------------------------------------------ */
SELECT
    COUNT(*)                     AS high_risk_active_customers,
    ROUND(SUM(MonthlyCharges), 2) AS monthly_revenue_at_risk
FROM telco_scored
WHERE churns = 0
  AND risk_score_final >= 5;
