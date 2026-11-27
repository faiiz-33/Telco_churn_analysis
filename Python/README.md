# Python Analysis

| File | Purpose |
|---|---|
| [prepare_data.py](prepare_data.py) | Builds `Data/telco_churn_clean.csv` from the raw file: numeric `TotalCharges`, removal of 11 not-yet-billed customers, churn flag, tenure groups, risk score |
| [01_eda.ipynb](01_eda.ipynb) | Exploratory analysis: correlations, churn by tenure, charges, and Cramér's V ranking of categorical drivers |
| [02_churn_model.ipynb](02_churn_model.ipynb) | Risk-score validation, model comparison, evaluation, driver analysis, targeting efficiency and scoring of active customers |

Run from the repository root:

```bash
pip install -r requirements.txt
python Python/prepare_data.py
jupyter notebook Python/
```

## 01: Exploratory analysis

- **Tenure** is the strongest numeric driver (r = -0.35). Churn peaks at 62% in the first month.
- **Cramér's V** ranks contract (0.41), online security (0.35), tech support (0.34), internet service (0.32) and payment method (0.30) as the strongest categorical drivers. Gender, phone service and multiple lines show no meaningful effect.
- These results decided which visuals went into the Power BI dashboard and which signals went into the SQL risk score.

## 02: Predictive model

| Model | CV ROC AUC | Test ROC AUC | Test PR AUC |
|---|---:|---:|---:|
| **Logistic regression** (chosen) | 0.846 | 0.836 | 0.623 |
| Random forest | 0.849 | 0.837 | 0.640 |
| Gradient boosting | 0.849 | 0.838 | 0.653 |
| Rule-based risk score (baseline) | n/a | 0.815 | 0.564 |

- Logistic regression was chosen because it matches the tree models within cross-validation noise and is fully interpretable.
- Decision threshold (0.32) was tuned on out-of-fold training predictions: it catches **73% of churners** in the test set (vs 58% at the default 0.5).
- Contacting the **top 30%** highest-risk customers reaches **66% of churners**, more than twice what random targeting would catch.
- **Drivers:** tenure, contract and internet service dominate. Payment method and missing support / security add little once those are known.
- Scoring active customers identifies **1,134 high-risk customers** carrying **$86K** of monthly revenue.
