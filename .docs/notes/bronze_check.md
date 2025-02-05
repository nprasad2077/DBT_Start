# Bronze Data Check

## Overall Checklist

- [x] bz_drug_plan_benefit
- [x] bz_formulary_drug
- [x] bz_drug_list
- [x] bz_member_drug
- [x] bz_agent
- [x] bz_member_pharmacy
- [x] bz_member_profile
- [x] bz_member_provider
- [ ] bz_us_country_mapping
- [x] bz_medicare_plan_premium
- [ ] bz_plan_landscape -- Andrew will explain
- [x] bz_star_rating_domain_stars -- obtained from cms website
- [x] bz_star_rating_summary_rating -- obtained from cms website

## bz_drug_list

- [x] ndc
- [x] drug_dsg_id
- [x] label_name
- [x] unit_cost
- [x] ahfs_level_2_name
- [x] ahfs_level_4_name
- [x] has_therapeutic_alternative
- [x] drug_type

## bz_drug_plan_benefit

- [x] Formulary_ID
- [x] TierNumber
- [x] Plan_ID
- [x] days_supply_id
- [x] subsidy_id
- [x] pharmacy_status
- [x] is_mail_order
- [x] COST_TYPE
- [x] COST_AMOUNT
- [x] MIN_AMOUNT
- [x] MAX_AMOUNT
- [x] THRESHOLD
- [x] THRESHOLD_OVERAGE_SHARE
- [x] gap_cost_type
- [x] gap_cost_amount
- [x] gap_min_amount
- [x] gap_max_amount
- [x] gap_threshold
- [x] gap_threshold_overage_share
- [x] cat_cost_type
- [x] cat_cost_amount
- [x] cat_min_amount
- [x] cat_max_amount
- [x] cat_threshold
- [x] cat_threshold_overage_share
- [x] pre_cost_type
- [x] pre_cost_amount
- [x] pre_min_amount
- [x] pre_max_amount
- [x] pre_threshold
- [x] pre_threshold_overage_share
- [x] copay_floor
- [x] cost_type_label
- [x] is_mail_order_label
- [ ] tier_number_grouped -- not sure how to obtain value

## bz_formulary_drug

- [x] DrugId 
- [x] FormularyId 
- [ ] PlanYear 
- [x] isAvailableByMail
- [x] isCappedBenefit 
- [x] isExcludedFormulary 
- [x] isFreeFirstFill 
- [x] isFRFExcludedCombo 
- [x] isHomeInfusionDrug 
- [x] isPartialGapCoverage 
- [x] isPriorAuthorization 
- [x] isQuantityLimit 
- [x] isSpecialtyDrug 
- [x] isStepTherapy 
- [x] isSupplementalFormulary (CAST CASE WHEN STARTS_WITH(isSupplementalFormulary, 'N\A') OR STARTS_WITH(isSupplementalFormulary, 'NA') THEN NULL ELSE isSupplementalFormulary END AS BOOLEAN)
- [x] QuantityLimitAmount 
- [x] QuantityLimitDays
- [x] TierNumber
- [ ] TierNumberGrouped  -- not sure how to obtain value

## bz_medicare_plan_premium

- [x] PlanCode
- [x] CarrierId
- [x] PlanYear
- [ ] PlanId
- [ ] FormularyId
- [x] CarrierName
- [x] ExternalId
- [x] ExternalPlanID
- [x] ExternalSegmentID
- [x] IsSBPlan
- [x] PlanPremium
- [x] PlanType

## bz_star_rating_summary_rating

- [x] contract_number
- [x] organization_type
- [x] contract_name
- [x] organization_marketing_name
- [x] parent_organization
- [x] snp
- [x] 2022_disaster_%
- [x] 2023_disaster_%
- [x] 2025_part_c_summary
- [x] 2025_part_d_summary
- [x] 2025_overall
- [ ] ingestion_date -- manually set?
