"""Build the cleaned Telco churn dataset used by SQL, Python and Power BI.

Input : Data/telco_churn_raw.csv   (7,043 customers, IBM Telco sample)
Output: Data/telco_churn_clean.csv (7,032 customers + engineered columns)

Run from the repository root:
    python Python/prepare_data.py
"""

import csv
from pathlib import Path

import pandas as pd

ROOT = Path(__file__).resolve().parents[1]
RAW_PATH = ROOT / "Data" / "telco_churn_raw.csv"
CLEAN_PATH = ROOT / "Data" / "telco_churn_clean.csv"

TENURE_BINS = [0, 6, 12, 24, float("inf")]
TENURE_LABELS = ["0-6 months", "7-12 months", "13-24 months", "25+ months"]


def risk_score(df: pd.DataFrame) -> pd.Series:
    """Final rule-based churn risk score (0-6): one point per churn signal.

    MonthlyCharges > 75 was tested as a 7th signal and dropped because it
    lowered ROC AUC (0.817 vs 0.825); see Python/02_churn_model.ipynb.
    """
    signals = [
        df["Contract"] == "Month-to-month",
        df["InternetService"] == "Fiber optic",
        df["PaymentMethod"] == "Electronic check",
        df["TechSupport"] == "No",
        df["OnlineSecurity"] == "No",
        df["tenure"] <= 6,
    ]
    return sum(s.astype(int) for s in signals)


def clean(raw: pd.DataFrame) -> pd.DataFrame:
    df = raw.copy()

    # TotalCharges is stored as text; 11 rows are blank. All 11 have tenure = 0
    # (brand-new customers who have not been billed yet and cannot have churned),
    # so they are removed rather than imputed.
    df["TotalCharges"] = pd.to_numeric(df["TotalCharges"], errors="coerce")
    df = df[df["tenure"] > 0].reset_index(drop=True)
    assert df["TotalCharges"].notna().all()

    df["churns"] = df.pop("Churn").map({"Yes": 1, "No": 0}).astype(int)
    df["risk_score"] = risk_score(df)
    df["tenure_group"] = pd.cut(df["tenure"], bins=TENURE_BINS, labels=TENURE_LABELS).astype(str)
    return df


def main() -> None:
    raw = pd.read_csv(RAW_PATH)
    df = clean(raw)
    df.to_csv(CLEAN_PATH, index=False, quoting=csv.QUOTE_NONNUMERIC)
    print(f"Wrote {len(df):,} rows x {df.shape[1]} columns to {CLEAN_PATH.relative_to(ROOT)}")
    print(f"Churn rate: {df['churns'].mean():.2%}")


if __name__ == "__main__":
    main()
