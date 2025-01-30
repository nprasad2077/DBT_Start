WITH raw_data AS (

    SELECT

        -- # keys
        CNXMemberID AS MemberID,

        ExternalNPI AS ProviderExternalNPI,
        CAST(CASE WHEN STARTS_WITH(IsPrimary,'N\A') THEN NULL
            WHEN STARTS_WITH(IsPrimary,'Y') THEN 'TRUE'
            WHEN STARTS_WITH(IsPrimary,'N') THEN 'FALSE'
            ELSE IsPrimary END AS BOOLEAN) AS ProviderIsPrimary,
        AddressLine1 AS ProviderAddress1,
        AddressLine2 AS ProviderAddress2,
        City AS ProviderCity,
        State AS ProviderStateId,
        ZipCode AS ProviderZipCode

    FROM {{
        source(
            'landing',
            'member_provider'
        )
    }}

    WHERE CNXMemberID <> ''
        AND ExternalNPI <> ''
        AND IngestionDate = '2024-11-18'

), deduped_data AS (

    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY
                MemberID
            ORDER BY
                ProviderExternalNPI
        ) AS row_index
    FROM raw_data
)

SELECT *
FROM deduped_data
WHERE row_index = 1
