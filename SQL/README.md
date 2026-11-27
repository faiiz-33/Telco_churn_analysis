# SQL Analysis

All queries are in **[churn_analysis.sql](churn_analysis.sql)** (MySQL 8; also runs unchanged on SQLite 3.25+).

- **Table:** `telco`, loaded from `Data/telco_churn_clean.csv` (7,032 customers)
- **Target:** `churns` (0 = retained, 1 = churned)
- **View:** `telco_scored` adds `risk_score_final` so the risk-score logic is defined in one place

Every number below comes from running the queries against the clean dataset.

---

## 1. Overall churn (query 1)

**26.58%** of customers churned (1,869 of 7,032).

## 2. Churn by segment (queries 2-5)

| Contract | Churn rate | Customers |
|---|---:|---:|
| Month-to-month | 42.71% | 3,875 |
| One year | 11.28% | 1,472 |
| Two year | 2.85% | 1,685 |

| Payment method | Churn rate | Customers |
|---|---:|---:|
| Electronic check | 45.29% | 2,365 |
| Mailed check | 19.20% | 1,604 |
| Bank transfer (automatic) | 16.73% | 1,542 |
| Credit card (automatic) | 15.25% | 1,521 |

| Internet service | Churn rate | Customers |
|---|---:|---:|
| Fiber optic | 41.89% | 3,096 |
| DSL | 19.00% | 2,416 |
| No internet | 7.43% | 1,520 |

| Tech support | Churn rate | Customers |
|---|---:|---:|
| No | 41.65% | 3,472 |
| Yes | 15.20% | 2,040 |
| No internet service | 7.43% | 1,520 |

Month-to-month contracts make up 55% of the customer base (3,875 of 7,032), which is why their churn rate drives the overall number.

## 3. Tenure and spending (queries 6-10)

| | Avg tenure (months) | Avg monthly charges | Avg total charges | Customers |
|---|---:|---:|---:|---:|
| Retained | 37.65 | $61.31 | $2,555.34 | 5,163 |
| Churned | 17.98 | $74.44 | $1,531.80 | 1,869 |

Churners pay more each month but are worth less over their lifetime because they leave early.

| Tenure group | Churn rate | Customers |
|---|---:|---:|
| 0-6 months | 53.33% | 1,470 |
| 7-12 months | 35.89% | 705 |
| 13-24 months | 28.71% | 1,024 |
| 25+ months | 14.04% | 3,833 |

## 4. High-churn segments and service gaps (queries 11-13)

**Highest-churn segment** (minimum 50 customers): **Fiber optic + Month-to-month + Electronic check**: **60.37% churn** across 1,307 customers. Every one of the top four segments is fiber optic on a month-to-month contract.

| Contract x internet service | Churn rate | Customers |
|---|---:|---:|
| Month-to-month, Fiber optic | 54.61% | 2,128 |
| Month-to-month, DSL | 32.22% | 1,223 |
| One year, Fiber optic | 19.29% | 539 |
| Two year, Fiber optic | 7.23% | 429 |

**Add-ons missing among churners:**

| Missing add-on | % of churners |
|---|---:|
| Online security | 78.17% |
| Tech support | 77.37% |
| Online backup | 65.97% |
| Device protection | 64.79% |

## 5. Risk scoring (queries 14-17)

A transparent score that adds one point per churn signal. It was built in three iterations:

| Version | Signals | ROC AUC |
|---|---|---:|
| v1 | Month-to-month, fiber optic, electronic check, no tech support (0-4) | 0.800 |
| v2 | v1 + tenure ≤ 6, no online security, MonthlyCharges > 75 (0-7) | 0.817 |
| **Final** | **v2 without MonthlyCharges > 75 (0-6)** | **0.825** |

Removing the price signal *improved* the score: price overlaps with fiber optic service and added noise. The AUC comparison is in [02_churn_model.ipynb](../Python/02_churn_model.ipynb).

**Final score vs actual churn (query 15):**

| Risk score | Customers | Churn rate |
|---:|---:|---:|
| 0 | 1,437 | 1.95% |
| 1 | 1,010 | 7.43% |
| 2 | 1,160 | 16.12% |
| 3 | 981 | 23.55% |
| 4 | 1,106 | 42.77% |
| 5 | 950 | 60.00% |
| 6 | 388 | 78.61% |

Churn rises steadily with every point. Churners average **4.13** points vs **1.95** for retained customers (query 17).

## 6. Revenue impact (queries 18-19)

| Measure | Value |
|---|---:|
| Monthly recurring revenue lost with churned customers | **$139,130.85** (30.53% of all monthly revenue) |
| Lifetime revenue collected from churned customers | $2,862,926.90 |
| Average lifetime revenue per churner | $1,531.80 (vs $2,555.34 per retained customer) |
| **Monthly revenue at risk:** active customers with risk score ≥ 5 | **$36,804.30** from 463 customers |

"At risk" counts only customers who are **still active**. Churned customers' revenue is already lost, so it is reported separately rather than counted as at risk. Query 16 lists the active high-risk customers to contact first.

