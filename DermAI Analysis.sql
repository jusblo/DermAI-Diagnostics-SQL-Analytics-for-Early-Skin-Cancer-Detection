--Cases & Malignancy by Age Band		 
WITH base AS (
  SELECT
      t1.age,
      CASE
        WHEN UPPER(t2.diagnostic) IN (
          'MEL','MELANOMA',
          'BCC','BASAL CELL CARCINOMA',
          'SCC','SQUAMOUS CELL CARCINOMA'
        ) THEN 1 ELSE 0
      END AS is_malignant
  FROM table1 t1
  JOIN table2 t2 USING (patient_id)
  WHERE t1.age IS NOT NULL
)
SELECT age_band,
       COUNT(*) AS cases,
       SUM(is_malignant) AS malignant_cases,
       ROUND(100.0 * SUM(is_malignant) / COUNT(*), 1) AS malignant_pct
FROM (
  SELECT CASE
           WHEN age < 30 THEN '<30'
           WHEN age BETWEEN 30 AND 44 THEN '30–44'
           WHEN age BETWEEN 45 AND 59 THEN '45–59'
           ELSE '60+'
         END AS age_band,
         is_malignant
  FROM base
) b
GROUP BY age_band
ORDER BY CASE age_band WHEN '<30' THEN 1 WHEN '30–44' THEN 2
                       WHEN '45–59' THEN 3 ELSE 4 END;

--Cases & Malignancy by Sex
WITH base AS (
  SELECT
    CASE
      WHEN UPPER(COALESCE( t1.gender)) IN ('M','MALE') THEN 'Male'
      WHEN UPPER(COALESCE(t1.gender)) IN ('F','FEMALE') THEN 'Female'
      ELSE 'Unknown'
    END AS sex,
    CASE
      WHEN UPPER(t2.diagnostic) IN (
        'MEL','MELANOMA',
        'BCC','BASAL CELL CARCINOMA',
        'SCC','SQUAMOUS CELL CARCINOMA'
      ) THEN 1 ELSE 0
    END AS is_malignant
  FROM table1 t1
  JOIN table2 t2 USING (patient_id)
)
SELECT
  sex,
  COUNT(*)                                  AS cases,
  SUM(is_malignant)                          AS malignant_cases,
  ROUND(100 * AVG(is_malignant::numeric), 1) AS malignant_pct,
  ROUND(100 - 100 * AVG(is_malignant::numeric), 1) AS benign_pct
FROM base
GROUP BY sex
ORDER BY CASE sex WHEN 'Female' THEN 1 WHEN 'Male' THEN 2 ELSE 3 END;


--prevalence of each exposure
WITH norm AS (
  SELECT
    CASE WHEN smoke     IS TRUE  THEN 'Exposed'
         WHEN smoke     IS FALSE THEN 'Not exposed'
         ELSE 'Unknown' END AS smoking,
    CASE WHEN drink   IS TRUE  THEN 'Exposed'
         WHEN drink   IS FALSE THEN 'Not exposed'
         ELSE 'Unknown' END AS alcohol,
    CASE WHEN pesticide IS TRUE  THEN 'Exposed'
         WHEN pesticide IS FALSE THEN 'Not exposed'
         ELSE 'Unknown' END AS pesticides
  FROM table1
),
stack AS (
  SELECT 'Smoking'    AS exposure, smoking    AS level FROM norm
  UNION ALL
  SELECT 'Alcohol'    AS exposure, alcohol    AS level FROM norm
  UNION ALL
  SELECT 'Pesticides' AS exposure, pesticides AS level FROM norm
)
SELECT
  exposure,
  level,
  COUNT(*) AS cases,
  ROUND(100::numeric * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY exposure), 1) AS pct
FROM stack
GROUP BY exposure, level
ORDER BY exposure,
         CASE level WHEN 'Exposed' THEN 1 WHEN 'Not exposed' THEN 2 ELSE 3 END;



--Age bands × lesion types (share within each age band)
WITH j AS (
  SELECT
    CASE WHEN t1.age IS NULL THEN 'UNK'
         WHEN t1.age < 20 THEN '0-19'
         WHEN t1.age < 30 THEN '20-29'
         WHEN t1.age < 40 THEN '30-39'
         WHEN t1.age < 50 THEN '40-49'
         WHEN t1.age < 60 THEN '50-59'
         WHEN t1.age < 70 THEN '60-69'
         ELSE '70+' END AS age_band,
    t1.gender,
    CASE
      WHEN UPPER(t2.diagnostic) IN ('MEL','MELANOMA') THEN 'MEL'
      WHEN UPPER(t2.diagnostic) IN ('BCC','BASAL CELL CARCINOMA') THEN 'BCC'
      WHEN UPPER(t2.diagnostic) IN ('SCC','SQUAMOUS CELL CARCINOMA') THEN 'SCC'
      WHEN UPPER(t2.diagnostic) = 'NEV' THEN 'NEV'
      WHEN UPPER(t2.diagnostic) = 'ACK' THEN 'ACK'
      WHEN UPPER(t2.diagnostic) = 'SEK' THEN 'SEK'
      ELSE 'OTHER' END AS lesion_type
  FROM table1 t1
  JOIN table2 t2 USING (patient_id)
)
SELECT
  age_band, lesion_type,
  COUNT(*) AS n,
  ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY age_band), 1) AS pct_within_age_band
FROM j
GROUP BY age_band, lesion_type
ORDER BY age_band, pct_within_age_band DESC;


--Gender × lesion types (share within each gender)
WITH j AS (
  SELECT
    t1.gender,
    CASE
      WHEN UPPER(t2.diagnostic) IN ('MEL','MELANOMA') THEN 'MEL'
      WHEN UPPER(t2.diagnostic) IN ('BCC','BASAL CELL CARCINOMA') THEN 'BCC'
      WHEN UPPER(t2.diagnostic) IN ('SCC','SQUAMOUS CELL CARCINOMA') THEN 'SCC'
      WHEN UPPER(t2.diagnostic) = 'NEV' THEN 'NEV'
      WHEN UPPER(t2.diagnostic) = 'ACK' THEN 'ACK'
      WHEN UPPER(t2.diagnostic) = 'SEK' THEN 'SEK'
      ELSE 'OTHER' END AS lesion_type
  FROM table1 t1
  JOIN table2 t2 USING (patient_id)
)
SELECT
  gender, lesion_type,
  COUNT(*) AS n,
  ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY gender), 1) AS pct_within_gender
FROM j
GROUP BY gender, lesion_type
ORDER BY gender, pct_within_gender DESC;


--Malignancy vs. Sewage SYSTEM
WITH j AS (
  SELECT
    CASE
      WHEN t1.has_sewage_system IS TRUE  THEN 'Has sewage system'
      WHEN t1.has_sewage_system IS FALSE THEN 'No sewage system'
      ELSE 'Unknown'
    END AS sewage_status,
    (UPPER(COALESCE(t2.diagnostic,'')) IN
       ('MEL','MELANOMA','BCC','BASAL CELL CARCINOMA','SCC','SQUAMOUS CELL CARCINOMA')
    )::int AS is_malignant
  FROM table1 t1
  JOIN table2 t2 USING (patient_id)
)
SELECT
  sewage_status,
  COUNT(*) AS cases,
  SUM(is_malignant) AS malignant_cases,
  ROUND(100::numeric * AVG(is_malignant::numeric), 1) AS malignant_pct
FROM j
GROUP BY sewage_status
ORDER BY CASE sewage_status WHEN 'Has sewage system' THEN 1
                             WHEN 'No sewage system'  THEN 2 ELSE 3 END;


--Environmental risk factors that correlate with specific skin lesions.
SELECT 
  	t1.smoke, t1.drink, t1.pesticide,
    t2.diagnostic,
    COUNT(*) AS N,
    ROUND(AVG((CASE WHEN t2.diagnostic IN ('MEL','BCC','SCC') THEN 1 ELSE 0 END)::numeric),3) AS cancer_rate
FROM table1 t1
JOIN table2 t2 ON t2.patient_id = t1.patient_id
GROUP BY t1.smoke, t1.drink, t1.pesticide, t2.diagnostic
ORDER BY cancer_rate DESC, n DESC;


--Analyze lesion characteristics to find patterns that indicate cancerous vs. benign lesions.
WITH lesion_size AS (
    SELECT *,
           CASE 
               WHEN diameter_1 >= 6 OR diameter_2 >= 6 THEN '>=6mm'
               ELSE '<6mm'
           END AS size_band
    FROM vw_lesions_labeled
)
SELECT 
    size_band,
    region,
    fitspatrick,
    itch, grew, hurt, changed,
    COUNT(*) AS total_lesions,
    SUM(is_cancerous::int) AS cancerous_lesions,
    ROUND(AVG(is_cancerous::int),3) AS cancer_rate
FROM lesion_size
GROUP BY size_band, region, fitspatrick, itch, grew, hurt, changed
HAVING COUNT(*) >= 3
ORDER BY cancer_rate DESC, total_lesions DESC;


-- What patterns support early detection and triage?
WITH base AS (
  SELECT
    t1.patient_id,

    /* DEMOGRAPHICS (table1) */
    t1.age,
    CASE
      WHEN UPPER(COALESCE(t1.gender, '')) IN ('F','FEMALE') THEN 'Female'
      WHEN UPPER(COALESCE(t1.gender, '')) IN ('M','MALE')   THEN 'Male'
      ELSE 'Unknown'
    END AS sex,

    /* LESION FEATURES (table2) */
    GREATEST(COALESCE(t2.diameter_1::numeric,0),
             COALESCE(t2.diameter_2::numeric,0)) AS max_diameter_mm,
    COALESCE(t2.itch,    FALSE) AS itch,
    COALESCE(t2.grew,    FALSE) AS grew,
    COALESCE(t2.hurt,    FALSE) AS hurt,
    COALESCE(t2.changed, FALSE) AS changed,
    COALESCE(t2.bleed,   FALSE) AS bleed,
    t2.region,
    t2.fitspatrick,

    /* EXPOSURES (table1) */
    COALESCE(t1.pesticide, FALSE) AS pesticide,
    COALESCE(t1.smoke,     FALSE) AS smoke,
    COALESCE(t1.drink,     FALSE) AS alcohol,   -- <-- was t1.alcohol

    /* carry diagnosis */
    t2.diagnostic
  FROM table1 t1
  JOIN table2 t2 USING (patient_id)
),
flags AS (
  SELECT
    *,
    (max_diameter_mm > 6) AS gt6,
    (itch OR grew OR changed OR bleed OR hurt) AS any_symptom
  FROM base
),
score AS (
  SELECT
    *,
    (CASE
       WHEN age IS NULL THEN 0
       WHEN age >= 60 THEN 3
       WHEN age BETWEEN 45 AND 59 THEN 2
       WHEN age BETWEEN 30 AND 44 THEN 1
       ELSE 0
     END)
    + (CASE WHEN sex = 'Female' THEN 2 ELSE 0 END)
    + (CASE WHEN gt6 THEN 2 ELSE 0 END)
    + (CASE WHEN any_symptom THEN 2 ELSE 0 END)
    + (CASE WHEN pesticide THEN 1 ELSE 0 END) AS risk_score
  FROM flags
),
y AS (
  SELECT
    s.*,
    (UPPER(COALESCE(s.diagnostic,'')) IN
      ('MEL','MELANOMA','BCC','BASAL CELL CARCINOMA','SCC','SQUAMOUS CELL CARCINOMA')
    )::int AS is_malignant
  FROM score s
),
bands AS (
  SELECT
    *,
    CASE
      WHEN risk_score >= 6 THEN 'Tier 1: urgent (high yield)'
      WHEN risk_score >= 4 THEN 'Tier 2: fast-track'
      WHEN risk_score >= 2 THEN 'Tier 3: routine+short f/u'
      ELSE 'Tier 4: routine'
    END AS triage_band
  FROM y
)
SELECT
  triage_band,
  COUNT(*)                                           AS cases,
  SUM(is_malignant)                                  AS malignant_cases,
  ROUND(100::numeric * AVG(is_malignant::numeric),1) AS malignant_pct,
  ROUND(AVG(risk_score)::numeric,1)                  AS avg_score
FROM bands
GROUP BY triage_band
ORDER BY CASE triage_band
           WHEN 'Tier 1: urgent (high yield)' THEN 1
           WHEN 'Tier 2: fast-track'          THEN 2
           WHEN 'Tier 3: routine+short f/u'   THEN 3
           ELSE 4 END;
