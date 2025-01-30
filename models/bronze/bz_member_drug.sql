WITH raw_data AS (
    SELECT

        -- # keys
        CNXMemberID AS MemberID,
        LPAD(NDC, 11, '0') AS NDC,

        DrugName,
        DrugList,
        CAST(CAST(metricQuantity AS DECIMAL(12,2)) AS INT) AS Quantity,
        CAST(CAST(daysOfSupply AS INT) AS INT) AS DaysSupply

    FROM {{
        source(
            'landing',
            'member_drug'
        )
    }}

    WHERE CNXMemberID <> ''
        AND NDC <> ''
        AND NDC <> 'NULL'
        AND IngestionDate = '2024-11-18'

), deduped_data AS (

    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY
                MemberID,
                NDC
            ORDER BY
                DrugList
        ) AS row_index
    FROM raw_data
)

SELECT *
FROM deduped_data
WHERE row_index = 1
