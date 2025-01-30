{{
    config(
        unique_key = [
            'drug_dsg_id'
        ]
    )
}}

WITH raw_data AS (

    SELECT
        "ndc"                           AS ndc,
        "drug_dsg_id"                   AS drug_dsg_id,
        "label_name"                    AS label_name,
        "unit_cost"                     AS unit_cost,
        "ahfs_level_2_name"             AS ahfs_level_2_name,
        "ahfs_level_4_name"             AS ahfs_level_4_name,
        "hastherapeuticalternative"     AS has_therapeutic_alternative,
        "drugtype"                      AS drug_type,
        'emittedat'                     AS emitted_at
    FROM {{ source( 'landing', 'drug_list' ) }}
    WHERE 
        NDC <> ''
        AND DRUG_DSG_ID <> ''

), normalized_data AS (
    
    SELECT drug_dsg_id
        , ndc
        , TRY_CAST(unit_cost AS DECIMAL(12, 2))     AS unit_cost
        , label_name
        , ahfs_level_2_name
        , ahfs_level_4_name
        , has_therapeutic_alternative
        , UPPER(drug_type)                          AS drug_type
        , ROW_NUMBER() OVER (
            PARTITION BY
                drug_dsg_id
            ORDER BY
                ndc
        ) AS row_index
        , '{{ var("run_started_at") }}' AS normalized_at
    FROM raw_data

), deduped_data AS (

    SELECT *
    FROM normalized_data
    WHERE row_index = 1

), final AS (
    
    SELECT
        drug_dsg_id,
        ndc,
        unit_cost,
        label_name,
        ahfs_level_2_name,
        ahfs_level_4_name,
        has_therapeutic_alternative,
        drug_type,
        normalized_at
    FROM deduped_data

)

SELECT * FROM final
