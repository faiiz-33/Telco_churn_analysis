# Telco Customer Churn Analysis (SQL)

## Project Overview
This project analyzes customer churn in a Telco dataset using SQL. The goal is to:
- Measure overall churn and churn by key dimensions
- Identify high-risk customer segments
- Compare churners vs. non-churners in tenure and revenue
- Build a simple SQL-based risk score to flag customers likely to churn

**Dataset table:** `telco`  
**Churn field:** `churns` (0 = No churn, 1 = Churn)

---

## Key Findings

### Overall Churn
- **Overall churn rate:** **26.6%**

---

## Churn Breakdown

### Churn Rate by Contract Type
| Contract        | Churn Rate |
|----------------|-----------:|
| Month-to-month | 42.7%      |
| One year       | 11.3%      |
| Two years      | 2.8%       |

✅ Month-to-month customers churn at a much higher rate.

---

### Churn Rate by Payment Method
| Payment Method              | Churn Rate |
|----------------------------|-----------:|
| Electronic check           | 45.29%     |
| Mailed check               | 19.20%     |
| Bank transfer (automatic)  | 16.73%     |
| Credit card (automatic)    | 15.25%     |

✅ Electronic check is the strongest churn signal among payment methods.

---

### Churn Rate by Internet Service
| Internet Service     | Churn Rate |
|---------------------|-----------:|
| Fiber optic         | 41.89%     |
| DSL                 | 19.00%     |
| No internet service | 7.43%      |

✅ Fiber optic users churn the most.

---

### Churn Rate by Tech Support
| Tech Support         | Churn Rate |
|---------------------|-----------:|
| No                  | 41.65%     |
| Yes                 | 15.20%     |
| No internet service | 7.43%      |

✅ Lack of tech support is strongly associated with churn.

---

## Tenure & Spending Differences

### Average Tenure (Months)
| Churn | Avg Tenure (months) |
|------:|---------------------:|
| 0     | 37.65                |
| 1     | 17.98                |

✅ Churners typically leave much earlier.

---

### Revenue Comparison: Churners vs. Non-churners
| Churn | Avg Monthly Charges ($) | Avg Total Charges ($) | Avg Tenure (months) | Customers |
|------:|-------------------------:|-----------------------:|---------------------:|----------:|
| 0     | 61.30                    | 2555.34               | 37.60                | 5163      |
| 1     | 74.40                    | 1531.80               | 17.90                | 1869      |

Insight: churners pay more per month, but their total value is lower because they leave sooner.

---

## High-Churn Customer Segments

### High-risk Segment (≥ 60% churn, min segment size > 50)
Top churning segment identified:
- **Month-to-month + Electronic check + Fiber optic**
- **1307 customers**
- **~60% churn rate**

---

## Churn by Tenure Group
> **Note:** Use a normal hyphen `-` (not an en dash `–`) to avoid export/encoding issues.

| Tenure Group | Churn Rate | Customers |
|-------------|-----------:|----------:|
| 0-6 months  | 53.33%     | 1470      |
| 7-12 months | 35.89%     | 705       |
| 13-24 months| 28.71%     | 1024      |
| 24+ months  | 14.04%     | 3833      |

✅ Biggest churn happens early (first 6 months).

---

## Missing Services Among Churners
(Percent of churners who are missing the service)

| Missing Service       | % of Churners |
|----------------------|--------------:|
| No Online Security   | 78.17%        |
| No Tech Support      | 77.37%        |
| No Backups           | 65.97%        |
| No Device Protection | 64.79%        |

✅ Churners are most commonly missing security + support.

---

## Revenue Impact
- **Avg total charges for churners (estimated revenue lost per churner):** **$1531.80**
- **Monthly revenue at risk (risk_score ≥ 5):** **$168,343.90**

---

## Risk Scoring Model (SQL)
A simple risk score was created using churn drivers. Each condition adds **+1 point**.

### Base Risk Score (0–4)
**Signals**
- Month-to-month contract
- Fiber optic
- Electronic check
- No tech support

This was used to find **non-churned customers** with **max risk_score = 4** (top 5 by `MonthlyCharges`).

**Top 5 at-risk customers (risk_score=4, churns=0):**
| Customer ID  | Contract        | Internet Service | Payment Method    | Monthly Charge ($) |
|-------------|-----------------|------------------|-------------------|-------------------:|
| 2587-EKXTS   | Month-to-month  | Fiber optic      | Electronic check  | 111.50             |
| 4176-FXYBO   | Month-to-month  | Fiber optic      | Electronic check  | 109.55             |
| 9278-VZKCD   | Month-to-month  | Fiber optic      | Electronic check  | 109.10             |
| 0114-PEGZZ   | Month-to-month  | Fiber optic      | Electronic check  | 107.55             |
| 2615-YVMYX   | Month-to-month  | Fiber optic      | Electronic check  | 107.50             |

---

### Extended Risk Score (0–7)
Added additional churn-related conditions:
- tenure ≤ 6
- OnlineSecurity = 'No'
- MonthlyCharges > 75

**Risk distribution (non-churn customers):**
| Risk Score | Customers |
|----------:|----------:|
| 7         | 244       |
| 6         | 784       |
| 5         | 983       |
| 4         | 942       |
| 3         | 924       |
| 2         | 1080      |
| 1         | 867       |
| 0         | 1208      |

---

## Combined Drivers Snapshot
| Churn | Avg Tenure | Avg Monthly | Avg Risk | Month-to-month Count | Fiber Count |
|------:|-----------:|------------:|---------:|----------------------:|-----------:|
| 0     | 37.65      | 61.31       | 2.34     | 2220                  | 1799       |
| 1     | 17.98      | 74.44       | 4.71     | 1655                  | 1297       |

✅ Churners have higher risk scores, shorter tenure, and higher monthly spend.

---

## Additional Notes
- **Month-to-month contracts:** ~**55%** of all customers (**3875 / 7032**)
