{{
    config(
        unique_key = [
            'MemberID', 'NDC'
        ]
    )
}}

WITH final AS (

    SELECT
        member_drug.MemberID,
        member_drug.NDC,
        member_drug.DrugList,
        member_drug.Quantity,
        member_drug.DaysSupply,
        drug_list.drug_dsg_id,
        drug_list.label_name                    AS drug_name,
        drug_list.drug_type,
        drug_list.ahfs_level_2_name,
        drug_list.ahfs_level_4_name,
        drug_list.has_therapeutic_alternative,
        drug_list.unit_cost                     AS retail_unit_cost
    FROM {{ ref('bz_member_drug') }} AS member_drug
    INNER JOIN {{ ref('bz_drug_list') }} AS drug_list
       ON member_drug.NDC = drug_list.ndc

)

SELECT * FROM final
