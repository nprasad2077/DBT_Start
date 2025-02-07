{{
    config(
        s3_data_naming='schema_table'
    )
}}

WITH member_drug AS (

    SELECT

        m.MemberID                              AS member_id,
        count(DISTINCT d.drug_dsg_id)           AS drugs_total,
        SUM(IF(f1.DrugId IS NOT NULL, 1,0))     AS drugs_on_formulary_prior_year,
        SUM(IF(f2.DrugId IS NOT NULL, 1,0))     AS drugs_on_formulary_current_year,
        SUM(IF(f1.DrugId IS NULL, 1,0))         AS drugs_off_formulary_prior_year,
        SUM(IF(f2.DrugId IS NULL, 1,0))         AS drugs_off_formulary_current_year,
        SUM(IF((
            f1.DrugId IS NULL
            AND d.drug_type = 'BRAND'
        ), 1, 0))                               AS brand_name_drugs_off_formulary_prior_year,
        SUM(IF((
            f2.DrugId IS NULL
            AND d.drug_type = 'BRAND'
        ), 1,0))                                AS brand_name_drugs_off_formulary_current_year

    FROM {{ ref('sv_member_plan') }} m

    INNER JOIN {{ ref('sv_member_drug') }} d
        ON d.MemberID = m.MemberID

    INNER JOIN {{ ref('sv_plan') }} p1 ON
        p1.PlanCode = m.PlanCode
        AND p1.PlanYear = 2024 -- TODO: UNHARDCODE

    LEFT JOIN {{ ref('sv_plan') }} p2 ON
        p2.PlanCode = p1.PlanCode
        AND p2.PlanYear = p1.PlanYear + 1

    LEFT JOIN {{ ref('sv_formulary_drug') }} f1 ON
        f1.FormularyId = p1.FormularyId
        AND f1.DrugId = d.drug_dsg_id

    LEFT JOIN {{ ref('sv_formulary_drug') }} f2 ON
        f2.FormularyId = p2.FormularyId
        AND f2.DrugId = d.drug_dsg_id

    WHERE m.PlanYear IN (2024, 2025) -- TODO: UNHARDCODE
    GROUP BY m.MemberID

), plan_drug AS (

    SELECT

    -- form 'sv_member_plan'

    m.MemberID                  AS cnx_member_id,
    m.CustomerID                AS member_customer_id,
    m.FirstName                 AS member_first_name,
    m.LastName                  AS member_last_name,
    m.PhoneNumber               AS member_phone_number,
    m.PrimaryEmailAddress       AS member_primary_email_address,
    m.DateOfBirth               AS member_date_of_birth,
    m.Gender                    AS member_gender,

    m.StateId                   AS state_id,
    m.Zipcode                   AS zip_code,
    m.CountyFIPSCode            AS county_fips_code,
    m.county_name               AS county_name,
    m.metro_area                AS metro_area,
    m.central_or_outlying       AS central_or_outlying,
    m.population                AS "population",

    m.PharmacyNPI               AS pharmacy_npi,
    m.PharmacyIsPrimary         AS pharmacy_is_primary,

    m.ProviderExternalNPI       AS provider_external_npi,
    m.ProviderIsPrimary         AS provider_is_primary,
    m.ProviderAddress1          AS provider_address1,
    m.ProviderAddress2          AS provider_address2,
    m.ProviderCity              AS provider_city,
    m.ProviderStateId           AS provider_state_id,
    m.ProviderZipCode           AS provider_zip_code,

    m.agent_email               AS agent_email,
    m.agent_npn                 AS agent_npn,
    m.agentusername             AS agent_user_name,
    m.agent_first_name          AS agent_first_name,
    m.agent_last_name           AS agent_last_name,

    d.drug_name                     AS drug_name,
    d.DrugList                      AS drug_list,
    d.NDC                           AS drug_ndc,
    d.drug_dsg_id                   AS drug_dsg_id,
    d.drug_type                     AS drug_type,
    d.ahfs_level_2_name             AS drug_ahfs_level_2_name,
    d.ahfs_level_4_name             AS drug_ahfs_level_4_name,
    d.has_therapeutic_alternative   AS drug_has_therapeutic_alternative,

    p1.CarrierId                AS carrier_id,
    p1.CarrierName              AS carrier_name,
    p1.PlanType                 AS plan_type,
    p1.PlanCode                 AS current_plan_code,

    IF(m.PlanYear = 2025, 'Yes', 'No')      AS py_2025_plan,
    IF(p2.PlanCode IS NULL, 'Yes', 'No')    AS discontinued_plan,

    --
    IF(p1.crosswalk_status_py_2025 = 'New Plan', NULL, p1.PlanId) AS plan_id_prior_year,
    IF(p1.crosswalk_status_py_2025 = 'Terminated Plan', NULL, p2.PlanId) AS plan_id_current_year,

    IF(p1.crosswalk_status_py_2025 = 'New Plan', NULL, p1.FormularyId) AS formulary_id_prior_year,
    IF(p1.crosswalk_status_py_2025 = 'Terminated Plan', NULL, p2.FormularyId) AS formulary_id_current_year,

    IF(p1.crosswalk_status_py_2025 = 'New Plan', NULL, f1.TierNumber) AS formulary_tier_number_prior_year,
    IF(p1.crosswalk_status_py_2025 = 'Terminated Plan', NULL, f2.TierNumber) AS formulary_tier_number_current_year,

    IF(p1.crosswalk_status_py_2025 = 'New Plan', NULL, f1.TierNumberGrouped) AS formulary_tier_group_prior_year,
    IF(p1.crosswalk_status_py_2025 = 'Terminated Plan', NULL, f2.TierNumberGrouped) AS formulary_tier_group_current_year,

    CASE
        WHEN d.drug_dsg_id IS NULL THEN NULL
        WHEN f1.DrugId IS NOT NULL THEN 'On Formulary'
        ELSE 'Off Formulary'
    END                         AS _formulary_status_prior_year, -- NOT

    CASE
        WHEN d.drug_dsg_id IS NULL THEN NULL
        WHEN f2.DrugId IS NOT NULL THEN 'On Formulary'
        WHEN
            f2.DrugId IS NULL
            AND p2.FormularyId IS NOT NULL
        THEN 'Off Formulary'
        ELSE NULL
    END                             AS _formulary_status_current_year, -- CHECK -- NOT

    IF(p1.crosswalk_status_py_2025 = 'New Plan', NULL, b1.cost_type_label) AS cost_type_prior_year,
    IF(p1.crosswalk_status_py_2025 = 'Terminated Plan', NULL, b2.cost_type_label) AS cost_type_current_year,

    IF(p1.crosswalk_status_py_2025 = 'New Plan', NULL, b1.cost_amount) AS formulary_rate_prior_year,
    IF(p1.crosswalk_status_py_2025 = 'Terminated Plan', NULL, b2.cost_amount) AS formulary_rate_current_year,

    IF(p1.crosswalk_status_py_2025 = 'New Plan', NULL, p1.PlanPremium) AS plan_premium_monthly_prior_year,
    IF(p1.crosswalk_status_py_2025 = 'Terminated Plan', NULL, p2.PlanPremium) AS plan_premium_monthly_current_year,

    IF(p1.crosswalk_status_py_2025 = 'New Plan', NULL, (p1.PlanPremium * 12)) AS plan_premium_annualized_prior_year,
    IF(p1.crosswalk_status_py_2025 = 'Terminated Plan', NULL, (p2.PlanPremium * 12)) AS plan_premium_annualized_current_year,

    ( p2.PlanPremium - p1.PlanPremium ) * 12    AS plan_premium_annualized_yoy_change,

    bs.drugs_on_formulary_prior_year    AS _member_total_drugs_on_formulary_prior_year, -- NOT
    IF(p2.PlanCode IS NULL, NULL,bs.drugs_on_formulary_current_year)
        AS _member_total_drugs_on_formulary_current_year, -- NOT
    IF(p2.PlanCode IS NULL, NULL, bs.drugs_on_formulary_current_year - drugs_on_formulary_prior_year)
        AS member_total_drugs_on_formulary_yoy_change,

    bs.drugs_off_formulary_prior_year AS _member_total_drugs_off_formulary_prior_year, -- NOT
    IF(p2.PlanCode IS NULL, NULL, bs.drugs_off_formulary_current_year)
        AS _member_total_drugs_off_formulary_current_year, -- NOT
    IF(p2.PlanCode IS NULL, NULL, bs.drugs_off_formulary_current_year - drugs_off_formulary_prior_year)
        AS member_total_drugs_off_formulary_yoy_change,

    bs.brand_name_drugs_off_formulary_prior_year AS _member_brand_name_drugs_off_formulary_prior_year, -- NOT
    IF(p2.PlanCode IS NULL, NULL, bs.brand_name_drugs_off_formulary_current_year)
        AS _member_brand_name_drugs_off_formulary_current_year, -- NOT
    IF(p2.PlanCode IS NULL, NULL, bs.brand_name_drugs_off_formulary_current_year - brand_name_drugs_off_formulary_prior_year)
        AS member_brand_name_drugs_off_formulary_yoy_change,

    p1.crosswalk_status_py_2025                         AS crosswalk_status_py_2025,
    p1.crosswalk_status_sub_type_py_2025                AS crosswalk_status_sub_type_py_2025,
    p1.contract_id_plan_id_py_2024                      AS crosswalk_contract_id_plan_id_py_2024,
    p1.contract_id_plan_id_py_2025                      AS crosswalk_contract_id_plan_id_py_2025,
    p1.contract_id_plan_id_crosswalk                    AS crosswalk_contract_id_plan_id_crosswalk,
    p1.contract_category_type                           AS crosswalk_contract_category_type,
    p1.parent_organization_name                         AS crosswalk_parent_organization_name,
    p1.organization_marketing_name                      AS crosswalk_organization_marketing_name,
    p1.organization_type                                AS crosswalk_organization_type,
    p1.plan_name                                        AS crosswalk_plan_name,
    p1.plan_type                                        AS crosswalk_plan_type,
    p1.special_needs_plan_indicator                     AS crosswalk_special_needs_plan_indicator,
    p1.snp_type                                         AS crosswalk_snp_type,
    p1.part_d_coverage_indicator                        AS crosswalk_part_d_coverage_indicator,
    p1.drug_benefit_category                            AS crosswalk_drug_benefit_category,
    p1.drug_benefit_type                                AS crosswalk_drug_benefit_type,
    --
    p1."2025_part_c_summary"                            AS star_rating_2025_part_c_summary,
    p1."2025_part_d_summary"                            AS star_rating_2025_part_d_summary,
    p1."2025_overall"                                   AS star_rating_2025_overall,
    --
    p1.hd1_staying_healthy_screenings_tests_and_vaccines                    AS star_rating_hd1_staying_healthy_screenings_tests_and_vaccines,
    p1.hd2_managing_chronic_long_term_conditions                            AS star_rating_hd2_managing_chronic_long_term_conditions,
    p1.hd3_member_experience_with_health_plan                               AS star_rating_hd3_member_experience_with_health_plan,
    p1.hd4_member_complaints_and_changes_in_the_health_plans_performance    AS star_rating_hd4_member_complaints_and_changes_in_the_health_plans_performance,
    p1.hd5_health_plan_customer_service                                     AS star_rating_hd5_health_plan_customer_service,
    p1.dd1_drug_plan_customer_service                                       AS star_rating_dd1_drug_plan_customer_service,
    p1.dd2_member_complaints_and_changes_in_the_drug_plans_performance      AS star_rating_dd2_member_complaints_and_changes_in_the_drug_plans_performance,
    p1.dd3_member_experience_with_the_drug_plan                             AS star_rating_dd3_member_experience_with_the_drug_plan,
    p1.dd4_drug_safety_and_accuracy_of_drug_pricing                         AS star_rating_dd4_drug_safety_and_accuracy_of_drug_pricing,
    --
    bs.drugs_total

    FROM {{ ref('sv_member_plan') }} m

    LEFT JOIN {{ ref('sv_member_drug') }} d ON
        d.MemberID = m.MemberID

    INNER JOIN {{ ref('sv_plan') }} p1 ON
        p1.PlanCode = m.PlanCode
        AND p1.PlanYear = 2024 -- TODO: UNHARDCODE

    LEFT JOIN {{ ref('sv_plan') }} p2 ON
        p2.PlanCode = p1.PlanCode
        AND p2.PlanYear = p1.PlanYear + 1

    LEFT JOIN {{ ref('sv_formulary_drug') }} f1
        ON f1.FormularyId = p1.FormularyId
        AND f1.DrugId = d.drug_dsg_id

    LEFT JOIN {{ ref('sv_formulary_drug') }} f2 ON
        f2.FormularyId = p2.FormularyId
        AND f2.DrugId = d.drug_dsg_id

    LEFT JOIN {{ ref('bz_drug_plan_benefit') }} b1 ON
        b1.plan_id = p1.PlanId
        AND b1.formulary_id = p1.FormularyId
        AND b1.tier_number = f1.TierNumber

    LEFT JOIN {{ ref('bz_drug_plan_benefit') }} b2 ON
        b2.plan_id = p2.PlanId
        AND b2.formulary_id = p2.FormularyId
        AND b2.tier_number = f2.TierNumber

    LEFT JOIN member_drug bs
        ON bs.member_id = m.MemberID

    WHERE m.PlanYear IN (2024, 2025) -- TODO: UNHARDCODE ?

), final AS (

    SELECT cnx_member_id

        -- about 'member'
        , member_customer_id
        , member_first_name
        , member_last_name
        , member_phone_number
        , member_primary_email_address
        , member_date_of_birth
        , member_gender
        -- about 'location'
        , state_id
        , zip_code
        , county_fips_code
        , county_name
        , metro_area
        , central_or_outlying
        , "population"
        -- about 'pharmacy'
        , pharmacy_npi
        , pharmacy_is_primary
        -- about 'provider'
        , provider_external_npi
        , provider_is_primary
        , provider_address1
        , provider_address2
        , provider_city
        , provider_state_id
        , provider_zip_code
        -- about 'agent'
        , agent_email
        , agent_npn
        , agent_user_name
        , agent_first_name
        , agent_last_name
        -- about 'drug'
        , drug_name
        , drug_list
        , drug_ndc
        , drug_dsg_id
        , drug_type
        , drug_ahfs_level_2_name
        , drug_ahfs_level_4_name
        , drug_has_therapeutic_alternative
        -- about 'carrier'
        , carrier_id
        , carrier_name
        --
        , plan_type
        , current_plan_code
        , py_2025_plan
        , discontinued_plan
        , plan_id_prior_year
        , plan_id_current_year
        -- about 'formulary'
        , formulary_id_prior_year
        , formulary_id_current_year
        , formulary_tier_number_prior_year
        , formulary_tier_number_current_year
        , formulary_tier_group_prior_year
        , formulary_tier_group_current_year
        -- , _formulary_status_prior_year, -- NO
        , IF(crosswalk_status_py_2025 = 'New Plan', NULL,
            _formulary_status_prior_year) AS formulary_status_prior_year
        -- , _formulary_status_current_year, -- CHECK -- NO
        , IF(crosswalk_status_py_2025 = 'Terminated Plan', NULL,
            _formulary_status_current_year) AS formulary_status_current_year
        --
        , cost_type_prior_year
        , cost_type_current_year
        , formulary_rate_prior_year
        , formulary_rate_current_year
        --
        , CASE
            WHEN member_brand_name_drugs_off_formulary_yoy_change > 0 THEN 'High Impact'
            WHEN (
                member_brand_name_drugs_off_formulary_yoy_change = 0
                AND member_total_drugs_off_formulary_yoy_change > 0
            ) THEN 'Low Impact'
            WHEN (
                member_brand_name_drugs_off_formulary_yoy_change = 0
                AND member_total_drugs_off_formulary_yoy_change = 0
            ) THEN 'No Impact'

            ELSE NULL END AS drug_formulary_impact
        , drugs_total
        --
        , plan_premium_monthly_prior_year
        , plan_premium_monthly_current_year
        , plan_premium_annualized_prior_year
        , plan_premium_annualized_current_year
        , plan_premium_annualized_yoy_change
        -- , _member_total_drugs_on_formulary_prior_year, -- NO
        , IF(crosswalk_status_py_2025 = 'New Plan', NULL,
            _member_total_drugs_on_formulary_prior_year) AS member_total_drugs_on_formulary_prior_year
        -- , _member_total_drugs_on_formulary_current_year, -- NO
        , IF(crosswalk_status_py_2025 = 'Terminated Plan', NULL,
            _member_total_drugs_on_formulary_current_year) AS member_total_drugs_on_formulary_current_year
        , member_total_drugs_on_formulary_yoy_change
        -- , _member_total_drugs_off_formulary_prior_year, -- NO
        , IF(crosswalk_status_py_2025 = 'New Plan', NULL,
            _member_total_drugs_off_formulary_prior_year) AS member_total_drugs_off_formulary_prior_year
        -- , _member_total_drugs_off_formulary_current_year, -- NO
        , IF(crosswalk_status_py_2025 = 'Terminated Plan', NULL,
            _member_total_drugs_off_formulary_current_year) AS member_total_drugs_off_formulary_current_year
        , member_total_drugs_off_formulary_yoy_change
        -- , _member_brand_name_drugs_off_formulary_prior_year, -- NO
        , IF(crosswalk_status_py_2025 = 'New Plan', NULL,
            _member_brand_name_drugs_off_formulary_prior_year) AS member_brand_name_drugs_off_formulary_prior_year
        -- , _member_brand_name_drugs_off_formulary_current_year, -- NO
        , IF(crosswalk_status_py_2025 = 'Terminated Plan', NULL,
            _member_brand_name_drugs_off_formulary_current_year) AS member_brand_name_drugs_off_formulary_current_year
        , member_brand_name_drugs_off_formulary_yoy_change
        , CASE
            WHEN plan_premium_annualized_yoy_change > 0 THEN 'Unfavorable'
            WHEN plan_premium_annualized_yoy_change < 0 THEN 'Favorable'
            ELSE 'No Impact' END
            AS plan_premium_impact
        , CONCAT(
            crosswalk_contract_id_plan_id_crosswalk,
            '-',
            substr(current_plan_code, 11, 3)
        )  AS current_plan_code_crosswalked
        , crosswalk_status_py_2025
        , crosswalk_status_sub_type_py_2025
        , crosswalk_contract_id_plan_id_py_2024
        , crosswalk_contract_id_plan_id_py_2025
        , crosswalk_contract_id_plan_id_crosswalk
        , crosswalk_contract_category_type
        , crosswalk_parent_organization_name
        , crosswalk_organization_marketing_name
        , crosswalk_organization_type
        , crosswalk_plan_name
        , crosswalk_plan_type
        , crosswalk_special_needs_plan_indicator
        , crosswalk_snp_type
        , crosswalk_part_d_coverage_indicator
        , crosswalk_drug_benefit_category
        , crosswalk_drug_benefit_type
        , star_rating_2025_part_c_summary
        , star_rating_2025_part_d_summary
        , star_rating_2025_overall
        , star_rating_hd1_staying_healthy_screenings_tests_and_vaccines
        , star_rating_hd2_managing_chronic_long_term_conditions
        , star_rating_hd3_member_experience_with_health_plan
        , star_rating_hd4_member_complaints_and_changes_in_the_health_plans_performance
        , star_rating_hd5_health_plan_customer_service
        , star_rating_dd1_drug_plan_customer_service
        , star_rating_dd2_member_complaints_and_changes_in_the_drug_plans_performance
        , star_rating_dd3_member_experience_with_the_drug_plan
        , star_rating_dd4_drug_safety_and_accuracy_of_drug_pricing

    FROM plan_drug

)

SELECT * FROM final
