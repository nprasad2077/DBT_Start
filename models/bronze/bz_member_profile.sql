WITH raw_data AS (

    SELECT

        -- # keys
        m.CNXMemberID AS MemberID,
        SUBSTR(CASE WHEN Plan = '' THEN Null ELSE Plan END, 1, 13) AS PlanCode,
        CAST(SUBSTR(CASE WHEN Plan = '' THEN Null ELSE Plan END, -4, 4) AS INT) AS PlanYear,

        CustomerID,
        PatientID,
        FirstName,
        MiddleName,
        LastName,
        CAST(date_parse(CASE WHEN (DateOfBirth <> '' AND DateOfBirth <> '00/00/0000') THEN dateofbirth ELSE NULL END, '%m/%d/%Y') AS DATE) AS DateOfBirth,
        CASE WHEN Gender = '' THEN NULL ELSE Gender END AS Gender,
        Address1,
        Address2,
        City,
        State AS StateId,
        Zip AS Zipcode,
        CountyFIPSCode,
        PhoneNumber,
        AgentUsername,
        PrimaryEmailAddress AS PrimaryEmailAddress

    FROM {{
        source(
            'landing',
            'member_profile'
        )
    }} m
    LEFT JOIN {{
        source(
            'landing',
            'cno_whitelist'
        )
    }} w ON w.CNXMemberID = m.CNXMemberID

    WHERE m.CNXMemberID <> ''
        AND CustomerID <> ''
        AND ( CustomerID <> 'CNO'
            OR w.CNXMemberID IS NOT NULL
        )
        AND IngestionDate = '2024-11-18'
), deduped_data AS (

    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY
                MemberID -- KEEP ONE PLAN PER MEMBER PER YEAR? HOW TO PICK THE LATTEST?
            ORDER BY
                PlanYear DESC
        ) AS row_index
    FROM raw_data
)

SELECT *
FROM deduped_data
WHERE row_index = 1
