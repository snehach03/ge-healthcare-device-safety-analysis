# ---- Load Data ----
df <- read.csv(file.choose(), stringsAsFactors = FALSE)
str(df)
head(df)

# ---- Create Severity Column ----
# Reframe event_type (Malfunction/Injury/Death/Other) into a binary
# severity flag for cleaner statistical testing and business relevance
df$severity <- ifelse(df$event_type %in% c("Death", "Injury"), "Severe", "Non-Severe")
head(df)

# =============================================================
# TEST 1: Chi-Square Test - Device Type vs Severity
# H0: Device type and severity are independent (no relationship)
# H1: Device type and severity are related
# =============================================================
table_data <- table(df$device_name, df$severity)
table_data
chisq.test(table_data)
# INSIGHT: p-value < 2.2e-16 (highly significant) -> device type and
# severity are NOT independent. Confirms that certain devices are
# genuinely more prone to severe outcomes than others.
# NOTE: Warning on approximation appears because many devices have very
# few reported events (sparse cells) -> re-tested on top 10 devices below
# for a more reliable result.

top10_devices <- names(sort(table(df$device_name), decreasing = TRUE)[1:10])
df_top10 <- df[df$device_name %in% top10_devices, ]
table_top10 <- table(df_top10$device_name, df_top10$severity)
chisq.test(table_top10)
# INSIGHT: Even restricted to the top 10 highest-volume devices,
# X-squared = 52.1, p < 0.0001 -> association remains highly significant.
# This validates (statistically) the severity patterns already seen in
# the SQL/Tableau analysis - it is not a random sampling artifact.

# =============================================================
# TEST 2: Recall Patterns by Event Type (descriptive cross-tab)
# =============================================================
table_recall <- table(df$device_name %in% top10_devices, df$remedial_action)
# ya simpler version:
table(df$event_type, df$remedial_action)
# INSIGHT: Recalls are overwhelmingly linked to Malfunction reports
# (176 cases) and NOT to Death reports (0 cases). This suggests
# recalls are triggered by repeated/systemic malfunction patterns
# rather than individual fatal incidents - a useful quality/safety
# process insight for GE HealthCare's device monitoring approach.

# =============================================================
# TEST 3: T-Test - Patient Age vs Severity
# H0: Mean patient age is the same for Severe and Non-Severe events
# H1: Mean patient age differs between the two groups
# =============================================================

# Days ko years mein convert karo
# (raw patient_age mixes units - some in days "DA", some in years "YR" -
# without this cleaning step, ages like "14235 DA" get misread as 14235
# years, which invalidates any age-based comparison)
df$age_years <- ifelse(
  grepl("DA", df$patient_age), 
  as.numeric(gsub("[^0-9]", "", df$patient_age)) / 365,
  ifelse(
    grepl("YR", df$patient_age),
    as.numeric(gsub("[^0-9]", "", df$patient_age)),
    NA
  )
)
t.test(age_years ~ severity, data = df)
# INSIGHT: p-value = 0.886 (not significant). No meaningful age
# difference between Severe (48.8 yrs avg) and Non-Severe (49.4 yrs avg)
# groups. Severity appears to be driven by device-related factors,
# not by patient demographics.

# =============================================================
# TEST 4: Chi-Square Test - Year vs Severity (LIMITATION - see note)
# =============================================================
df$year <- as.numeric(substr(df$date_received, 1, 4))
chisq.test(table(df$year, df$severity))
# INSIGHT / CAVEAT: p < 2.2e-16 (significant), BUT this result is
# confounded by known API sampling bias - years 2011-2019 are almost
# entirely missing from the 1000-record sample pulled from openFDA.
# This test result should NOT be interpreted as a genuine time trend
# in severity. Documented here transparently as a data limitation
# rather than presented as a real finding.