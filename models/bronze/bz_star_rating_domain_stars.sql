{{
    config(
        unique_key = [
            'contract_number'
        ]
    )
}}

WITH raw_data AS (

    SELECT
        "contract number"                                       AS contract_number,
        "organization type"                                     AS organization_type,
        "contract name"                                         AS "contract_name",
        "organization marketing name"                           AS organization_marketing_name,
        "parent organization"                                   AS parent_organization,
        "hd1: staying healthy: screenings tests and vaccines"   AS hd1_staying_healthy_screenings_tests_and_vaccines,
        "hd2: managing chronic (long term) conditions"          AS hd2_managing_chronic_long_term_conditions,
        "hd3: member experience with health plan"               AS hd3_member_experience_with_health_plan,
        "hd4: member complaints and changes in the health plan's performance"
            AS hd4_member_complaints_and_changes_in_the_health_plans_performance,
        "hd5: health plan customer service"                     AS hd5_health_plan_customer_service,
        "dd1: drug plan customer service"                       AS dd1_drug_plan_customer_service,
        "dd2: member complaints and changes in the drug plans performance"
            AS dd2_member_complaints_and_changes_in_the_drug_plans_performance,
        "dd3: member experience with the drug plan"             AS dd3_member_experience_with_the_drug_plan,
        "dd4: drug safety and accuracy of drug pricing"         AS dd4_drug_safety_and_accuracy_of_drug_pricing,
        'dummy'                                                 AS ingestion_date
    FROM {{ source( 'landing', 'star_rating_domain_stars' ) }}

), deduped_data AS (

    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY
                contract_number
            ORDER BY
                ingestion_date desc
        ) AS row_index
    FROM raw_data

), final AS (

    SELECT
        contract_number,
        "contract_name",
        organization_type,
        organization_marketing_name,
        parent_organization,
        hd1_staying_healthy_screenings_tests_and_vaccines,
        hd2_managing_chronic_long_term_conditions,
        hd3_member_experience_with_health_plan,
        hd4_member_complaints_and_changes_in_the_health_plans_performance,
        hd5_health_plan_customer_service,
        dd1_drug_plan_customer_service,
        dd2_member_complaints_and_changes_in_the_drug_plans_performance,
        dd3_member_experience_with_the_drug_plan,
        dd4_drug_safety_and_accuracy_of_drug_pricing
    FROM deduped_data
    WHERE row_index = 1

)

SELECT * FROM final
