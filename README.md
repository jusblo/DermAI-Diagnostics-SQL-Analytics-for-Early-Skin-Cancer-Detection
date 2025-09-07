# DermAI-Diagnostics-SQL-Analytics-for-Early-Skin-Cancer-Detection
This repo contains SQL, analysis notes, and slide-ready visuals for exploring a skin-lesion dataset (n = 1,088 lesions) to identify who gets lesions, what becomes malignant, and how to triage efficiently.
Dataset (two tables)

Patients: patient_id, age, gender, smoke, drink, pesticide, skin_cancer_history, cancer_history, has_piped_water, has_sewage_system, …

Lesions: patient_id, lesion_id, diagnostic (NEV/BCC/SCC/MEL/…), region, fitzpatrick, diameter_1, diameter_2, itch, grew, hurt, changed, bleed, biopsed, … 

Skin_Cancer_Analysis

Objectives

Build core KPIs (total lesions, median age, age-band distribution).

Analyze malignancy rates by age, sex, exposures, and lesion characteristics.

Create a lightweight SQL triage score for early detection and ops planning. 

Skin_Cancer_Analysis

Key findings (from the analysis)

Age drives volume & risk: 60+ = 50.9% of lesions; 45–59 = 30.2% → 81.1% in 45+. Malignancy rises 3.5% (<30) → 20.3% (30–44) → 33.7% (45–59) → 36.6% (60+); ~90.8% of cancers are in 45+.

Sex modifies risk: Female 43.4% malignant vs Male 26.0% → higher biopsy yield per female lesion.

Exposures are modest: Pesticides 20.5%, Alcohol 12.7%, Smoking 5.7% prevalence.

Infrastructure correlate (likely confounded): “Has sewage” 62.6% vs 21.5% without—monitor, don’t triage on it.

Lesion features separate best: Size ≥6 mm and recent change/growth/bleeding/pain on sun-exposed regions strongly signal malignancy.

Triage score works: Tier 1 = 61.9% malignant, capturing ~88.7% of cancers while screening ~45.6% of lesions (NNB ≈ 1.6). Tiers 2–4 are low-yield. 

Skin_Cancer_Analysis

What’s included
/sql
  kpis.sql
  malignancy_by_age.sql
  malignancy_by_sex.sql
  exposure_prevalence.sql
  sewage_vs_malignancy.sql
  lesion_characteristics.sql
  triage_score.sql
/viz
  exposure_stacked.png
  sewage_dumbbell.png
  triage_lollipop.png
/slides
  Skin_Cancer_Analysis.pdf

Recommendations (from the deck)

Prioritize Tier 1 and patients 45+ (esp. 60+); give extra attention to female patients.

Auto-flag lesions ≥6 mm or with change/growth/bleed/pain/itch for urgent review.

Tighten/split Tier 2; route low-signal cases to telederm/routine.

Track NNB and time-to-biopsy by tier; treat “sewage access” as an equity monitoring metric, not a rule. 

Skin_Cancer_Analysis

Note: Research/analytics only; not medical advice.
