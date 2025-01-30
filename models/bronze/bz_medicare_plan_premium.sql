
WITH raw_data AS (
    SELECT

        (External_ID || '-' || LPAD(External_PlanID,3,'0') || '-' || LPAD(External_SegmentID,3,'0')) AS PlanCode,
        CarrierId,
        CAST(PlanYear AS INT) AS PlanYear,
        plan_id AS PlanId,
        Formulary_ID AS FormularyId,
        CarrierName,
        External_ID AS ExternalId,
        LPAD(External_PlanID,3,'0') AS ExternalPlanID,
        LPAD(External_SegmentID,3,'0') AS ExternalSegmentID,
        CAST(
        CASE
            WHEN IsSBPlan = 'Yes' THEN 1
            WHEN IsSBPlan = 'No' THEN 0
            ELSE NULL END AS BOOLEAN
        ) AS IsSBPlan,
        CAST(PlanPremium AS DECIMAL(12,2)) AS PlanPremium,
        PlanType
    FROM {{
        source(
            'landing',
            'medicare_plan_premium'
        )
    }}

), deduped_data AS (

    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY
                PlanCode,
                PlanYear
            ORDER BY
                PlanId
        ) AS row_index
    FROM raw_data

)

SELECT *
FROM deduped_data
WHERE row_index = 1
