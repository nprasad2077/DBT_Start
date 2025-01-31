BEGIN TRANSACTION

USE [CoreMember2];
GO

WITH BaseMemberData AS (
    SELECT 
        mpr.memberID,
        p.profileID AS CustomerID,
        p.FirstName,
        p.MiddleInitial AS MiddleName,  -- Changed to match target column
        p.LastName,
        p.externalMemberID AS PatientID,
        p.PrimaryEmailAddress,
        CASE 
            WHEN p.birthyear IS NULL 
                 OR p.birthmonth IS NULL 
                 OR p.birthday IS NULL THEN NULL
            WHEN p.birthyear < 1900 
                 OR p.birthyear > YEAR(GETDATE()) THEN NULL
            WHEN p.birthmonth < 1 
                 OR p.birthmonth > 12 THEN NULL
            WHEN p.birthday < 1 
                 OR p.birthday > 31 THEN NULL
            ELSE TRY_CONVERT(date, DATEFROMPARTS(p.birthyear, p.birthmonth, p.birthday))
        END AS DateOfBirth,
        p.genderID,
        COALESCE(p.homePhone, p.cellPhone, p.workPhone) AS PhoneNumber,
        mpr.agentGUID AS AgentUsername,
        ROW_NUMBER() OVER (PARTITION BY mpr.memberID ORDER BY p.ModifiedWhen DESC) AS rn
    FROM [CoreMember2].[dbo].[MasterPersonRecord] mpr
    INNER JOIN [CoreMember2].[dbo].[Profile] p 
        ON mpr.memberID = p.memberID
    WHERE mpr.isActive = 1
      AND p.ModifiedWhen >= '2024-11-18'
),
CurrentAddress AS (
    SELECT 
        pa.profileID,
        pa.street1,
        pa.street2,
        pa.city,
        pa.state,
        pa.zipCode,
        pa.countyFips
    FROM [CoreMember2].[dbo].[ProfileAddress] pa
    INNER JOIN (
        SELECT profileID, MAX(ModifiedWhen) AS LastModified
        FROM [CoreMember2].[dbo].[ProfileAddress]
        WHERE isPrimary = 1
        GROUP BY profileID
    ) latest 
        ON pa.profileID = latest.profileID 
       AND pa.ModifiedWhen = latest.LastModified
),
CurrentEnrollment AS (
    SELECT *
    FROM
    (
        SELECT 
            me.memberID,
            me.planID,
            me.agentGUID,
            pym.planyear,
            ROW_NUMBER() OVER (
                PARTITION BY me.memberID 
                ORDER BY pym.planyear DESC
            ) AS PlanYearRank
        FROM [CoreMember2].[dbo].[MemberEnrollments] me
        INNER JOIN [CoreMember2].[bronze].[plan_year_mapping] pym
            ON me.planID = pym.plan_id
        INNER JOIN (
            SELECT memberID, MAX(ModifiedWhen) AS LastModified
            FROM [CoreMember2].[dbo].[MemberEnrollments]
            WHERE isActive = 1
            GROUP BY memberID
        ) latest 
            ON me.memberID = latest.memberID 
           AND me.ModifiedWhen = latest.LastModified
        WHERE pym.planyear >= 2025
    ) t
    WHERE PlanYearRank = 1
)
MERGE INTO [CoreMember2].[bronze].[bz_member_profile] AS target
USING (
    SELECT *
    FROM (
        SELECT 
            b.memberID,
            CAST(ce.planID AS VARCHAR(50)) AS PlanCode,
            ce.planyear AS PlanYear,
            b.CustomerID,
            b.PatientID,
            b.FirstName,
            b.MiddleName,
            b.LastName,
            b.DateOfBirth,
            g.genderDesc AS Gender,
            ca.street1 AS Address1,
            ca.street2 AS Address2,
            ca.city AS City,
            ca.state AS State,
            ca.zipCode AS Zip,
            ca.countyFips AS CountyFIPSCode,
            b.PhoneNumber,
            b.AgentUsername,
            b.PrimaryEmailAddress,
            ROW_NUMBER() OVER (PARTITION BY b.memberID ORDER BY ce.planyear DESC, b.CustomerID DESC) as final_rn
        FROM BaseMemberData b
        LEFT JOIN [CoreMember2].[dbo].[GenderType] g 
            ON b.genderID = g.genderID
        LEFT JOIN CurrentAddress ca 
            ON b.CustomerID = ca.profileID
        INNER JOIN CurrentEnrollment ce
            ON b.memberID = ce.memberID
        WHERE b.rn = 1
    ) ranked
    WHERE final_rn = 1
) AS source
ON target.memberID = source.memberID
WHEN MATCHED THEN
    UPDATE SET
        PlanCode = source.PlanCode,
        PlanYear = source.PlanYear,
        CustomerID = source.CustomerID,
        PatientID = source.PatientID,
        FirstName = source.FirstName,
        MiddleName = source.MiddleName,
        LastName = source.LastName,
        DateOfBirth = source.DateOfBirth,
        Gender = source.Gender,
        Address1 = source.Address1,
        Address2 = source.Address2,
        City = source.City,
        State = source.State,
        Zip = source.Zip,
        CountyFIPSCode = source.CountyFIPSCode,
        PhoneNumber = source.PhoneNumber,
        AgentUsername = source.AgentUsername,
        PrimaryEmailAddress = source.PrimaryEmailAddress,
        normalized_at = GETDATE()
WHEN NOT MATCHED THEN
    INSERT (
        MemberID, PlanCode, PlanYear, CustomerID, PatientID, 
        FirstName, MiddleName, LastName, DateOfBirth, Gender,
        Address1, Address2, City, State, Zip, CountyFIPSCode,
        PhoneNumber, AgentUsername, PrimaryEmailAddress, normalized_at
    )
    VALUES (
        source.MemberID, source.PlanCode, source.PlanYear, source.CustomerID, source.PatientID,
        source.FirstName, source.MiddleName, source.LastName, source.DateOfBirth, source.Gender,
        source.Address1, source.Address2, source.City, source.State, source.Zip, source.CountyFIPSCode,
        source.PhoneNumber, source.AgentUsername, source.PrimaryEmailAddress, GETDATE()
    );

GO

/* 
-- (Optional) Verify the result:
SELECT memberID, PlanYear, PlanCode, normalized_at
FROM [CoreMember2].[bronze].[bz_member_profile]
WHERE memberID = 85557368;
*/

-- COMMIT TRANSACTION
-- ROLLBACK TRANSACTION
