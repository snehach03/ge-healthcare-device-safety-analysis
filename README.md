# GE HealthCare Medical Device Safety Analytics

An end-to-end data analytics project analyzing real-world adverse event data for GE HealthCare medical devices (MRI, ultrasound, patient monitors, anesthesia machines, etc.), sourced from the FDA's public MAUDE database. The project spans data engineering, SQL analytics, statistical testing, visualization, and machine learning.

## Business Problem

Medical device manufacturers need to understand which device categories carry the highest risk of severe patient outcomes (death or injury) versus routine malfunctions, in order to prioritize quality control, maintenance, and regulatory response. This project analyzes ~1,000 real adverse event reports for GE HealthCare devices to surface these risk patterns and validate them statistically.

## Data Source

- **openFDA MAUDE Database** (Manufacturer and User Facility Device Experience) — a public FDA database of medical device adverse event reports.
- API: `https://api.fda.gov/device/event.json`
- Filtered to `manufacturer_d_name: "GE HEALTHCARE"`
- **Limitation:** Due to API sampling limits, this analysis is based on a 1,000-record sample. Years 2011–2019 are underrepresented as a result of the default API sort order — this is documented and accounted for throughout the analysis rather than presented as a true year-over-year trend.

## Tech Stack

| Tool | Purpose |
|---|---|
| Python | Data extraction (openFDA API), cleaning, EDA, NLP, machine learning |
| SQL (MySQL) | Data storage and core business-question queries |
| Excel | Quick pivot summaries and manual validation |
| Tableau | Interactive dashboard for stakeholder-facing visualization |
| R | Statistical hypothesis testing (chi-square, t-test) |

## Project Workflow

### 1. Data Extraction (Python)
Pulled adverse event records via the openFDA REST API, flattened nested JSON fields (`device`, `patient`, `mdr_text`) into structured columns, and handled missing values with a documented, column-by-column rationale (drop vs. impute vs. leave as-is) rather than blanket removal.

### 2. SQL Analysis
Loaded the cleaned dataset into MySQL and answered core business questions:
- Which devices generate the most reported events?
- Which devices have the highest proportion of severe (Death/Injury) outcomes?
- How does the severity mix vary by device category?

**Key finding:** Central Monitoring Systems had the highest event *volume* (62 events), but MRI/NMR imaging systems had the highest event *severity rate* (89–100% of their reported events were Death or Injury) — showing that volume and risk are not the same thing.

### 3. Tableau Dashboard
An interactive dashboard summarizing:
- Top 10 devices by reported event count, broken down by event type
- Event trend over time (with the sampling-bias caveat clearly noted)

**[View Live Dashboard on Tableau Public](https://public.tableau.com/views/ge_dashboard/Dashboard1?:language=en-US&publish=yes)**

### 4. Python — EDA, NLP & Machine Learning
- Visual EDA confirming the SQL findings (event type distribution, top devices, severity breakdown, heatmaps)
- Keyword analysis on free-text event descriptions after removing dataset-specific boilerplate terms (e.g. "reported," "healthcare")
- **Classification models** predicting event severity from device type and description text:
  - 4-class model (Malfunction/Injury/Death/Other): ~84% accuracy, but limited recall on rare classes (Death, Other) due to severe class imbalance (only 10 Death cases in the test set)
  - Reframed as **binary severity classification** (Severe vs. Non-Severe): ~86% weighted F1 — a more balanced and business-relevant framing for risk triage
  - Tried both Random Forest and XGBoost; performance plateaued around 85–86%, which was treated as an honest ceiling given dataset size, rather than pushed further with synthetic oversampling.

### 5. R — Statistical Validation
Used hypothesis testing to check whether the patterns found via SQL/Python were statistically meaningful or could be due to chance:

1. **Device type vs. severity (chi-square test):** Significant association found (χ² = 52.1, p < 0.0001 on top 10 devices) — confirming that certain devices are genuinely more prone to severe outcomes, not just by random variation.
2. **Recall patterns:** Device recalls were overwhelmingly linked to Malfunction reports (176 cases), not fatal incidents (0 of the Death reports triggered a recall) — suggesting recalls follow patterns of repeated failures rather than isolated severe events.
3. **Patient age vs. severity (t-test):** No significant difference in mean patient age between severe and non-severe cases (p = 0.886) — indicating severity is driven more by device factors than patient demographics.
4. **Year vs. severity:** Found statistically significant, but explicitly **not reported as a reliable finding** due to the known API sampling bias affecting the year distribution.

### 6. Deployment (FastAPI)
The binary severity model (Severe vs. Non-Severe) was deployed as a live REST API, allowing real-time predictions from new device event reports rather than being limited to a static notebook.
- **Live API:** [https://ge-healthcare-device-safety-analysis.onrender.com](https://ge-healthcare-device-safety-analysis.onrender.com)
- **Interactive docs:** [https://ge-healthcare-device-safety-analysis.onrender.com/docs](https://ge-healthcare-device-safety-analysis.onrender.com/docs) — try predictions directly in the browser via the auto-generated Swagger UI
- Input: `device_name`, `event_description` → Output: predicted severity + confidence score

## Key Takeaways

- Event **volume** and event **severity** are distinct signals — high-frequency devices are not necessarily the highest-risk ones.
- MRI/NMR imaging systems, while reported less often, show a disproportionately high rate of severe outcomes and warrant closer monitoring.
- Statistical testing (R) independently validated the patterns observed through SQL and visualization, adding confidence that these are real signals rather than artifacts of the sample.
- Model performance limitations (particularly on rare severity classes) are documented transparently rather than masked — reflecting a realistic, defensible analysis rather than an inflated one.

## Repository Structure

```
├── data/
│   └── ge_final_clean_v3.csv          # Cleaned dataset
├── notebooks/
│   └── ge_healthcare_analysis.ipynb   # Python EDA, NLP, ML
├── sql/
│   └── queries.sql                    # Core SQL analysis
├── r/
│   └── ge_healthcare_r_analysis.R     # Statistical tests
├── tableau/
│   └── dashboard_link.md              # Link to published dashboard
└── README.md
```

## Limitations & Future Work

- Sample size (1,000 records) is small for rare-event (Death) prediction; a full-scale pull across all available years would improve model reliability.
- Year-over-year trend analysis is not currently reliable due to API sampling order; a stratified pull across years would fix this.
- Future iterations could include a deployed prediction API (FastAPI) allowing real-time severity risk scoring for new incoming reports.
