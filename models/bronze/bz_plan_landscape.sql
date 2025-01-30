{{
    config(
        unique_key = 'contract_id_plan_id_py_2024'
    )
}}

WITH raw_data AS (

    SELECT
        "crosswalkstatuspy2025"         AS crosswalk_status_py_2025,
        "crosswalkstatussubtypepy2025"  AS crosswalk_status_sub_type_py_2025,
        "contractidplanidpy2024"        AS contract_id_plan_id_py_2024,
        "contractidplanidpy2025"        AS contract_id_plan_id_py_2025,
        "contractidplanidcrosswalk"     AS contract_id_plan_id_crosswalk,
        "contractcategorytype"          AS contract_category_type,
        "parentorganizationname"        AS parent_organization_name,
        "organizationmarketingname"     AS organization_marketing_name,
        "organizationtype"              AS organization_type,
        "planname"                      AS plan_name,
        "plantype"                      AS plan_type,
        "specialneedsplanindicator"     AS special_needs_plan_indicator,
        "snptype"                       AS snp_type,
        "partdcoverageindicator"        AS part_d_coverage_indicator,
        "drugbenefitcategory"           AS drug_benefit_category,
        "drugbenefittype"               AS drug_benefit_type,
        'dummy'                         AS ingestion_date
    FROM {{ source('landing', 'plan_landscape') }}
    WHERE contractIDPlanIdPY2024 <> 'NA'

), deduped_data AS (

    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY
                contract_id_plan_id_py_2024
            ORDER BY
                ingestion_date desc
        ) AS row_index
    FROM raw_data

), final AS (

    SELECT
        contract_id_plan_id_py_2024,
        crosswalk_status_py_2025,
        crosswalk_status_sub_type_py_2025,
        contract_id_plan_id_py_2025,
        contract_id_plan_id_crosswalk,
        contract_category_type,
        parent_organization_name,
        organization_marketing_name,
        organization_type,
        plan_name,
        plan_type,
        special_needs_plan_indicator,
        snp_type,
        part_d_coverage_indicator,
        drug_benefit_category,
        drug_benefit_type
    FROM deduped_data
    WHERE row_index = 1

)

SELECT * FROM final
