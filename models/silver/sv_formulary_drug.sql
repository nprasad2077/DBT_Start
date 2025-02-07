{{
    config(
        unique_key = [
            'FormularyId', 'PlanYear', 'DrugId'
        ]
    )
}}

WITH final AS (

    SELECT
        formulary_drug.FormularyId,
        formulary_drug.PlanYear,
        formulary_drug.DrugId,
        drug_list.ndc,
        drug_list.label_name                    AS drug_name,
        drug_list.drug_type,
        -- drug_list.ahfsLevel2Name                AS Condition,
        drug_list.ahfs_level_2_name,
        drug_list.ahfs_level_4_name,
        drug_list.has_therapeutic_alternative,
        drug_list.unit_cost                     AS retail_unit_cost,
        formulary_drug.isAvailableByMail,
        formulary_drug.isCappedBenefit,
        formulary_drug.isExcludedFormulary,
        formulary_drug.isFreeFirstFill,
        formulary_drug.isFRFExcludedCombo,
        formulary_drug.isHomeInfusionDrug,
        formulary_drug.isPartialGapCoverage,
        formulary_drug.isPriorAuthorization,
        formulary_drug.isQuantityLimit,
        formulary_drug.isSpecialtyDrug,
        formulary_drug.isStepTherapy,
        formulary_drug.isSupplementalFormulary,
        formulary_drug.QuantityLimitAmount,
        formulary_drug.QuantityLimitDays,
        formulary_drug.TierNumber,
        formulary_drug.TierNumberGrouped
    FROM {{ ref('bz_formulary_drug') }} AS formulary_drug
    INNER JOIN {{ ref('bz_drug_list') }} AS drug_list
       ON drug_list.drug_dsg_id = formulary_drug.DrugId

)

SELECT * FROM final
