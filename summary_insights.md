# Telco Customer Churn: Summary of Insights

This analysis combines SQL, Python and Power BI to answer four questions: **who churns, when, why, and what it costs.** The findings move from the overall picture, to drivers, to risk identification and action.

---

## 1. Overall churn

- **Churn rate: 26.6%** (1,869 of 7,032 customers).
- Churn is not spread evenly: it is concentrated in specific segments and in the first months of tenure.

## 2. When do customers churn?

- **Churn happens early.** It peaks in the first month (62%), and 53.3% of customers in their first 6 months churn.
- It falls steadily with tenure: 35.9% (7-12 months), 28.7% (13-24 months), 14.0% (25+ months).
- Average tenure: **18 months** for churners vs **38 months** for retained customers.

> **Insight:** the first 6 months are the critical retention window.

## 3. What drives churn?

Ranked by Cramér's V (Python) and confirmed with SQL churn rates:

| Driver | Highest-churn group | Comparison |
|---|---|---|
| Contract (V = 0.41) | Month-to-month: **42.7%** | Two year: 2.8% |
| Online security (V = 0.35) | None: **41.8%** | With it: 14.6% |
| Tech support (V = 0.34) | None: **41.6%** | With it: 15.2% |
| Internet service (V = 0.32) | Fiber optic: **41.9%** | DSL: 19.0% |
| Payment method (V = 0.30) | Electronic check: **45.3%** | Other methods: 15-19% |

**Weak or no effect:** gender, phone service and multiple lines (V < 0.04).

The predictive model (section 6) adds an important nuance: once **tenure, contract and internet service** are known, payment method and missing support / security add little. They are markers of the same high-risk profile (new, month-to-month, fiber customers) and remain useful flags for targeting.

> **Insight:** churn is driven by commitment (contract, tenure) and by fiber optic service, not by basic phone features.

## 4. Spending behaviour

| | Avg monthly charges | Avg lifetime revenue |
|---|---:|---:|
| Churned | $74.44 | $1,531.80 |
| Retained | $61.31 | $2,555.34 |

> **Insight:** churners pay more per month but are worth 40% less over their lifetime because they leave early. Short tenure, not price alone, is what destroys customer value.

## 5. High-risk segment and risk score

**Fiber optic + month-to-month + electronic check** is the highest-churn segment: **60.4% churn** across 1,307 customers, large enough to matter commercially.

A transparent SQL risk score adds one point per churn signal (month-to-month, fiber optic, electronic check, no tech support, no online security, tenure ≤ 6 months):

- Churn rises with every point: **2% at score 0 → 43% at 4 → 60% at 5 → 79% at 6**.
- Removing a seventh signal, `MonthlyCharges > 75`, **improved** ROC AUC from 0.817 to 0.825, because price overlaps with fiber optic service.

> **Insight:** a simple, explainable score works well when redundant signals are removed.

## 6. Predictive model

- **Logistic regression** reaches a test ROC AUC of **0.836**, matching random forest and gradient boosting (all about 0.85 in cross-validation), while staying interpretable.
- The 6-signal rule score is close behind (0.815): most of the signal is captured by simple rules.
- **Targeting efficiency:** contacting the **top 30%** of customers by predicted risk reaches **66% of churners**, more than twice what random selection would.

## 7. Revenue impact

| Measure | Value |
|---|---:|
| Monthly recurring revenue lost with churned customers | **$139.1K** (30.5% of all monthly revenue) |
| Lifetime revenue collected from churned customers | $2.86M |
| Monthly revenue at risk: active customers flagged by the model | **$86.0K** (1,134 customers) |
| Monthly revenue at risk: active customers with risk score 5-6 (conservative) | $36.8K (463 customers) |

> **Insight:** even a small reduction in churn among high-risk active customers protects meaningful recurring revenue.

---

## Business takeaways

1. **Churn happens early:** focus retention on the first 6 months.
2. **Lock in commitment:** move month-to-month customers to 1- or 2-year contracts with a loyalty incentive.
3. **Fix the fiber experience:** fiber customers churn far more than DSL customers even at similar prices, which points to service quality or competition.
4. **Use cheap levers on high-risk customers:** automatic payment and bundled tech support / online security.
5. **Target, don't blanket:** a ranked list of 1,134 high-risk active customers lets the retention team reach two-thirds of likely churners with a third of the effort.
