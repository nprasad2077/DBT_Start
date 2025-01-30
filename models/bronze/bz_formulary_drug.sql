{{
    config(
        unique_key = [
            'formulary_id',
            'plan_id',
            'tier_number'
        ]
    )
}}



WITH raw_data AS (

    SELECT

        -- # keys
        DRUG_DSG_ID AS DrugId,
        Formulary_ID AS FormularyId,
        CAST(planyear AS integer) AS PlanYear,

        -- # features
        CAST(CASE WHEN STARTS_WITH(isAvailableByMail, 'N\A') OR STARTS_WITH(isAvailableByMail, 'NA') THEN NULL ELSE isAvailableByMail END AS BOOLEAN) AS isAvailableByMail,
        CAST(CASE WHEN STARTS_WITH(isCappedBenefit, 'N\A') OR STARTS_WITH(isCappedBenefit, 'NA') THEN NULL ELSE isCappedBenefit END AS BOOLEAN) AS isCappedBenefit,
        CAST(CASE WHEN STARTS_WITH(isExcludedFormulary, 'N\A') OR STARTS_WITH(isExcludedFormulary, 'NA') THEN NULL ELSE isExcludedFormulary END AS BOOLEAN) AS isExcludedFormulary,
        CAST(CASE WHEN STARTS_WITH(isFreeFirstFill, 'N\A') OR STARTS_WITH(isFreeFirstFill, 'NA') THEN NULL ELSE isFreeFirstFill END AS BOOLEAN) AS isFreeFirstFill,
        CAST(CASE WHEN STARTS_WITH(isFRFExcludedCombo, 'N\A') OR STARTS_WITH(isFRFExcludedCombo, 'NA') THEN NULL ELSE isFRFExcludedCombo END AS BOOLEAN) AS isFRFExcludedCombo,
        CAST(CASE WHEN STARTS_WITH(isHomeInfusionDrug, 'N\A') OR STARTS_WITH(isHomeInfusionDrug, 'NA') THEN NULL ELSE isHomeInfusionDrug END AS BOOLEAN) AS isHomeInfusionDrug,
        CAST(CASE WHEN STARTS_WITH(isPartialGapCoverage, 'N\A') OR STARTS_WITH(isPartialGapCoverage, 'NA') THEN NULL ELSE isPartialGapCoverage END AS BOOLEAN) AS isPartialGapCoverage,
        CAST(CASE WHEN STARTS_WITH(isPriorAuthorization, 'N\A') OR STARTS_WITH(isPriorAuthorization, 'NA') THEN NULL ELSE isPriorAuthorization END AS BOOLEAN) AS isPriorAuthorization,
        CAST(CASE WHEN STARTS_WITH(isQuantityLimit, 'N\A') OR STARTS_WITH(isQuantityLimit, 'NA') THEN NULL ELSE isQuantityLimit END AS BOOLEAN) AS isQuantityLimit,
        CAST(CASE WHEN STARTS_WITH(isSpecialtyDrug, 'N\A') OR STARTS_WITH(isSpecialtyDrug, 'NA') THEN NULL ELSE isSpecialtyDrug END AS BOOLEAN) AS isSpecialtyDrug,
        CAST(CASE WHEN STARTS_WITH(isStepTherapy, 'N\A') OR STARTS_WITH(isStepTherapy, 'NA') THEN NULL ELSE isStepTherapy END AS BOOLEAN) AS isStepTherapy,
        CAST(CASE WHEN STARTS_WITH(isSupplementalFormulary, 'N\A') OR STARTS_WITH(isSupplementalFormulary, 'NA') THEN NULL ELSE isSupplementalFormulary END AS BOOLEAN) AS isSupplementalFormulary,
        TRY_CAST(QuantityLimitAmount AS integer) AS QuantityLimitAmount,
        TRY_CAST(QuantityLimitDays AS integer) AS QuantityLimitDays,
        TRY_CAST(TierNumber AS DECIMAL(12,2)) AS TierNumber,
        TRY_CAST(TierNumber_Grouped AS DECIMAL(12,2)) AS TierNumberGrouped

        -- # removed fields
        -- STEP_THERAPY_X
        -- StepTherapyDescription

    FROM {{
        source(
            'landing',
            'formulary_drug'
        )
    }}

    WHERE DRUG_DSG_ID <> ''
        AND Formulary_ID <> ''
        AND PlanYear <> ''

), deduped_data AS (

    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY
                DrugId,
                FormularyId,
                PlanYear
            ORDER BY
                DrugId,
                FormularyId,
                PlanYear
        ) AS row_index
    FROM raw_data
)

SELECT *
FROM deduped_data
WHERE row_index = 1
