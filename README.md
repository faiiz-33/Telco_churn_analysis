Customer Churn Analysis – End-to-End Project

This project analyzes customer churn using a full analytics workflow:
SQL → Python → Power BI, with a strong focus on business interpretation and decision-ready insights.

The goal is to understand who churns, why they churn, and the financial impact of churn, using structured analysis and clear visual storytelling.

⸻

Repository Structure

Data/   
raw.csv  
clean.csv  

SQL/    
Queries.sql  
README.md  

Python/  
Telco_churn.ipynb  

Power BI/  
churners_profile.png  
churn_overview.png  
README.md  

Summary/  
insights.md  
README.md  


⸻

Data

Folder: Data/
	•	raw.csv
Original Telco customer churn dataset.
	•	clean.csv
Cleaned and prepared dataset used across SQL, Python, and Power BI.
	•	Fixed data types
	•	Removed inconsistencies
	•	Created tenure groups, churn flags, and risk score

⸻

SQL Analysis  

Folder: SQL/
	•	Queries.sql
Contains all SQL queries used for:
	•	Data exploration
	•	Risk score construction
	•	Churn segmentation
	•	Validation of Power BI metrics
	•	README.md
Documents all insights derived from SQL, including:
	•	Churn patterns by tenure, contract, services
	•	Risk score design and refinement
	•	Feature selection decisions

SQL was used as the primary analytical engine for logic validation and metric accuracy.

⸻

Perfect — here’s the small, precise update to the repo README that reflects that work without making it long or messy.
You only need to replace the Python Analysis section with this version.

⸻

Python Analysis  

Folder: Python/
	•	Telco_churn.ipynb

Python was used for feature relevance validation and exploratory analysis before building the Power BI dashboard.

Key work includes:
	•	Computing Cramér’s V scores for all categorical variables to quantify their relationship with churn
→ Results were used to decide which categorical features to visualize in Power BI.
	•	Creating two heatmaps:
	•	One for numerical features (correlation matrix)
	•	One for categorical features using Cramér’s V
	•	Visual exploration of numerical variables (MonthlyCharges and TotalCharges) to assess their impact on churn.

Note:
All Python-derived insights are summarized as text at the bottom of the notebook to keep the analysis concise and readable.


⸻

Power BI Dashboard  

Folder: Power BI/

Contains a two-page interactive dashboard:

Page 1 – Churners Profile
	•	Focuses only on churned customers
	•	Highlights customer characteristics and service patterns

Page 2 – Churn Overview
	•	Covers all customers
	•	Compares churned vs retained
	•	Quantifies revenue at risk
	•	README.md
Explains dashboard design, visuals, and analytical intent.
	•	churners_profile.png, churn_overview.png
Dashboard screenshots for quick viewing without opening Power BI.

⸻

Summary Insights

File: Summary insights.md

This file consolidates all key findings from:
	•	SQL
	•	Python
	•	Power BI

It provides a high-level executive summary

⸻

Key Skills Demonstrated
	•	SQL (advanced querying, validation)
	•	Python (EDA and analytical reasoning)
	•	Power BI (data modeling, DAX, dashboard design)
	•	Business-focused insight generation
	•	End-to-end analytical workflow

⸻

Notes
	•	All metrics are internally validated across tools.
	•	The churn risk score was iteratively refined using statistical testing.
	•	Design choices prioritize clarity, consistency, and business value.
