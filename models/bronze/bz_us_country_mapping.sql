{{
    config(
        unique_key = ['state_id', 'county_fips']
    )
}}

WITH raw_data AS (

    SELECT
        "stateId"           AS "state_id",
        "countyName"        AS "county_name",
        "countyFips"        AS "county_fips",
        "stateName"         AS "state_name",
        "stateCounty"       AS "state_county",
        "metroArea"         AS "metro_area",
        "centralOrOutlying" AS "central_or_outlying",
        "population"        AS "population"
    FROM {{ source( 'landing', 'us_country_mapping' ) }}

), deduped_data AS (

    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY
                state_id, county_fips
            ORDER BY
                "population" desc
        ) AS row_index
    FROM raw_data

), final AS (

    SELECT
        state_id,
        county_name,
        county_fips,
        state_name,
        state_county,
        metro_area,
        central_or_outlying,
        "population"
    FROM deduped_data
    WHERE row_index = 1

)

SELECT * FROM final
