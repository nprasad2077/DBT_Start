WITH raw_data AS (

    SELECT

        -- # keys
        CNXMemberID AS MemberID,
        PharmacyNABP,
        NPI AS PharmacyNPI,

        CAST(CASE
            WHEN STARTS_WITH(isPrimaryPharmacy, 'N\A') THEN NULL
            WHEN isPrimaryPharmacy = '' THEN NULL
            ELSE isPrimaryPharmacy END AS BOOLEAN) AS PharmacyIsPrimary

    FROM {{
        source(
            'landing',
            'member_pharmacy'
        )
    }}

    WHERE CNXMemberID <> ''
        AND PharmacyNABP <> ''
        AND NPI <> ''
        AND IngestionDate = '2024-11-18'

), deduped_data AS (

    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY
                MemberID
            ORDER BY
                PharmacyNPI
        ) AS row_index
    FROM raw_data
)

SELECT *
FROM deduped_data
WHERE row_index = 1
