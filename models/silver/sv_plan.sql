
SELECT
        -- # keys
        PlanCode,
        PlanYear,

        FormularyId,
        PlanId,
        CarrierId,
        CarrierName,
        IsSBPlan,
        PlanPremium,
        PlanType,
        -- new bronze_plan_landscape
        pl.crosswalk_status_py_2025,
        pl.crosswalk_status_sub_type_py_2025,
        pl.contract_id_plan_id_py_2024,
        pl.contract_id_plan_id_py_2025,
        pl.contract_id_plan_id_crosswalk,
        pl.contract_category_type,
        pl.parent_organization_name,
        pl.organization_marketing_name,
        pl.organization_type,
        pl.plan_name,
        pl.plan_type,
        pl.special_needs_plan_indicator,
        pl.snp_type,
        pl.part_d_coverage_indicator,
        pl.drug_benefit_category,
        pl.drug_benefit_type,
        -- new bronze_star_rating_summary_rating
        sr."2025_part_c_summary",
        sr."2025_part_d_summary",
        sr."2025_overall",
        -- -- new bronze_star_rating_domain_stars
        ds.hd1_staying_healthy_screenings_tests_and_vaccines,
        ds.hd2_managing_chronic_long_term_conditions,
        ds.hd3_member_experience_with_health_plan,
        ds.hd4_member_complaints_and_changes_in_the_health_plans_performance,
        ds.hd5_health_plan_customer_service,
        ds.dd1_drug_plan_customer_service,
        ds.dd2_member_complaints_and_changes_in_the_drug_plans_performance,
        ds.dd3_member_experience_with_the_drug_plan,
        ds.dd4_drug_safety_and_accuracy_of_drug_pricing
        -- new
FROM {{
    ref('bz_medicare_plan_premium')
}} AS p
LEFT JOIN {{
    ref('bz_plan_landscape')
}} AS pl ON substr(p.PlanCode, 1, 9) = pl.contract_id_plan_id_py_2024
LEFT JOIN {{
    ref('bz_star_rating_summary_rating')
}} AS sr ON substr(p.PlanCode, 1, 5) = sr.contract_number
LEFT JOIN {{
    ref('bz_star_rating_domain_stars')
}} AS ds ON substr(p.PlanCode, 1, 5) = rtrim(ds.contract_number)
