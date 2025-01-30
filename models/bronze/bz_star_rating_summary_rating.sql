{{
    config(
        unique_key = 'contract_number'
    )
}}

WITH raw_data AS (

    SELECT
        "contract number"               AS contract_number,
        "organization type"             AS organization_type,
        "contract name"                 AS "contract_name",
        "organization marketing name"   AS organization_marketing_name,
        "parent organization"           AS parent_organization,
        "snp"                           AS snp,
        "2022 disaster %"               AS "2022_disaster_%",
        "2023 disaster %"               AS "2023_disaster_%",
        "2025 part c summary"           AS "2025_part_c_summary",
        "2025 part d summary"           AS "2025_part_d_summary",
        "2025 overall"                  AS "2025_overall",
        'dummy'                         AS ingestion_date
    FROM {{ source( 'landing', 'star_rating_summary_rating' ) }}

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
        organization_type,
        "contract_name",
        organization_marketing_name,
        parent_organization,
        snp,
        "2022_disaster_%",
        "2023_disaster_%",
        "2025_part_c_summary",
        "2025_part_d_summary",
        "2025_overall",
        ingestion_date
    FROM deduped_data
    WHERE row_index = 1

)

SELECT * FROM final
