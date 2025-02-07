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
        "formulary_id"                  AS formulary_id,
        "cat_cost_amount"               AS cat_cost_amount,
        "cat_cost_type"                 AS cat_cost_type,
        "cat_max_amount"                AS cat_max_amount,
        "cat_min_amount"                AS cat_min_amount,
        "cat_threshold"                 AS cat_threshold,
        "cat_threshold_overage_share"   AS cat_threshold_overage_share,
        "copay_floor"                   AS copay_floor,
        "cost_amount"                   AS cost_amount,
        "cost_type"                     AS cost_type,
        "cost_type_label"               AS cost_type_label,
        "days_supply_id"                AS days_supply_id,
        "days_supply_label"             AS days_supply_label,
        "gap_cost_amount"               AS gap_cost_amount,
        "gap_cost_type"                 AS gap_cost_type,
        "gap_max_amount"                AS gap_max_amount,
        "gap_min_amount"                AS gap_min_amount,
        "gap_threshold"                 AS gap_threshold,
        "gap_threshold_overage_share"   AS gap_threshold_overage_share,
        "is_mail_order"                 AS is_mail_order,
        "is_mail_order_label"           AS is_mail_order_label,
        "max_amount"                    AS max_amount,
        "min_amount"                    AS min_amount,
        "pharmacy_status"               AS pharmacy_status,
        "plan_id"                       AS plan_id,
        "pre_cost_amount"               AS pre_cost_amount,
        "pre_cost_type"                 AS pre_cost_type,
        "pre_max_amount"                AS pre_max_amount,
        "pre_min_amount"                AS pre_min_amount,
        "pre_threshold"                 AS pre_threshold,
        "pre_threshold_overage_share"   AS pre_threshold_overage_share,
        "subsidy_id"                    AS subsidy_id,
        "threshold"                     AS threshold,
        "threshold_overage_share"       AS threshold_overage_share,
        "tiernumber"                    AS tier_number,
        "tiernumber_grouped"            AS tier_number_grouped
    FROM {{ source('landing', 'drug_plan_benefit') }}
    WHERE 
        formulary_id <> ''
        AND plan_id <> ''
        AND tiernumber <> ''

), normalized_data AS (

    SELECT formulary_id
        , CAST(cat_cost_amount AS DECIMAL(12, 2))               AS cat_cost_amount
        , CAST(cat_cost_type AS INT)                            AS cat_cost_type
        , CAST(cat_max_amount AS DECIMAL(12, 2))                 AS cat_max_amount
        , CAST(cat_min_amount AS DECIMAL(12, 2))                AS cat_min_amount
        , CAST(cat_threshold AS DECIMAL(12, 2))                 AS cat_threshold
        , CAST(cat_threshold_overage_share AS DECIMAL(12, 2))   AS cat_threshold_overage_share
        , CAST(cost_amount AS DECIMAL(12, 2))                   AS cost_amount
        , CAST(cost_type AS INT)                                AS cost_type
        , CAST(days_supply_id AS INT)                           AS days_supply_id
        , days_supply_label                                     AS days_supply_label
        , TRY_CAST(gap_cost_amount AS DECIMAL(12, 2))           AS gap_cost_amount
        , TRY_CAST(gap_cost_type AS INT)                        AS gap_cost_type
        , CAST(is_mail_order AS BOOLEAN)                        AS is_mail_order
        , is_mail_order_label                                   AS is_mail_order_label
        , TRY_CAST(max_amount AS DECIMAL(12, 2))                AS max_amount
        , TRY_CAST(min_amount AS DECIMAL(12, 2))                AS min_amount
        , CAST(pharmacy_status AS BOOLEAN)                      AS pharmacy_status
        , plan_id                                               AS plan_id
        , TRY_CAST(pre_cost_amount AS DECIMAL(12, 2))           AS pre_cost_amount
        , TRY_CAST(pre_cost_type AS INT)                        AS pre_cost_type
        , CAST(tier_number AS INT)                              AS tier_number
        , CAST(tier_number_Grouped AS INT)                      AS tier_number_grouped
        , CASE 
            WHEN starts_with(cost_type_label, 'unknown')
            THEN NULL ELSE cost_type_label
          END                                                   AS cost_type_label
        , TRY_CAST(subsidy_id AS INT)                           AS subsidy_id
        , ROW_NUMBER() OVER (
            PARTITION BY
                formulary_id,
                plan_id,
                tier_number
            ORDER BY
                cat_cost_amount
        )                                                       AS row_index
        , '{{ var("run_started_at") }}'                         AS normalized_at
    FROM raw_data

), deduped_data AS (

    SELECT *
    FROM normalized_data
    WHERE row_index = 1

), final AS (

    SELECT
        formulary_id,
        cat_cost_amount,
        cat_cost_type,
        cat_max_amount,
        cat_min_amount,
        cat_threshold,
        cat_threshold_overage_share,
        cost_amount,
        cost_type,
        days_supply_id,
        days_supply_label,
        gap_cost_amount,
        gap_cost_type,
        is_mail_order,
        is_mail_order_label,
        max_amount,
        min_amount,
        pharmacy_status,
        plan_id,
        pre_cost_amount,
        pre_cost_type,
        tier_number,
        tier_number_grouped,
        cost_type_label,
        subsidy_id,
        row_index,
        normalized_at
    FROM deduped_data

)

SELECT * FROM final
