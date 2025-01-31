BEGIN TRANSACTION

USE [CoreMember2];
GO

WITH CurrentAddress AS (
    -- Get the most recent primary address for each profile
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
        SELECT profileID, MAX(ModifiedWhen) as LastModified
        FROM [CoreMember2].[dbo].[ProfileAddress]
        WHERE isPrimary = 1
        GROUP BY profileID
    ) latest ON pa.profileID = latest.profileID 
    AND pa.ModifiedWhen = latest.LastModified
),
CurrentEnrollment AS (
    -- Get the most recent enrollment for each member
    SELECT 
        me.memberID,
        me.planID,
        me.agentGUID,
        pym.planyear
    FROM [CoreMember2].[dbo].[MemberEnrollments] me
    INNER JOIN [CoreMember2].[bronze].[plan_year_mapping] pym 
        ON me.planID = pym.plan_id
    INNER JOIN (
        SELECT memberID, MAX(ModifiedWhen) as LastModified
        FROM [CoreMember2].[dbo].[MemberEnrollments]
        WHERE isActive = 1
        GROUP BY memberID
    ) latest ON me.memberID = latest.memberID 
    AND me.ModifiedWhen = latest.LastModified
),
LatestMemberData AS (
    -- Get the most recent record for each memberID
    SELECT 
        mpr.memberID,
        CAST(ce.planID AS VARCHAR(50)) AS PlanCode,
        ce.planyear AS PlanYear,
        p.CRMID AS CustomerID,
        p.externalMemberID AS PatientID,
        p.FirstName,
        p.MiddleInitial AS MiddleName,
        p.LastName,
        CASE 
            WHEN p.birthyear IS NULL OR p.birthmonth IS NULL OR p.birthday IS NULL THEN NULL
            WHEN p.birthyear < 1900 OR p.birthyear > YEAR(GETDATE()) THEN NULL
            WHEN p.birthmonth < 1 OR p.birthmonth > 12 THEN NULL
            WHEN p.birthday < 1 OR p.birthday > 31 THEN NULL
            ELSE TRY_CONVERT(date, DATEFROMPARTS(p.birthyear, p.birthmonth, p.birthday))
        END AS DateOfBirth,
        g.genderDesc AS Gender,
        ca.street1 AS Address1,
        ca.street2 AS Address2,
        ca.city AS City,
        ca.state AS State,
        ca.zipCode AS Zip,
        ca.countyFips AS CountyFIPSCode,
        COALESCE(p.homePhone, p.cellPhone, p.workPhone) AS PhoneNumber,
        ce.agentGUID AS AgentUsername,
        p.PrimaryEmailAddress,
        ROW_NUMBER() OVER (PARTITION BY mpr.memberID ORDER BY p.ModifiedWhen DESC) as rn
    FROM [CoreMember2].[dbo].[MasterPersonRecord] mpr
    INNER JOIN [CoreMember2].[dbo].[Profile] p 
        ON mpr.memberID = p.memberID
    LEFT JOIN [CoreMember2].[dbo].[GenderType] g 
        ON p.genderID = g.genderID
    LEFT JOIN CurrentAddress ca 
        ON p.profileID = ca.profileID
    LEFT JOIN CurrentEnrollment ce 
        ON mpr.memberID = ce.memberID
    WHERE mpr.isActive = 1
        AND p.ModifiedWhen >= '2024-11-18'
)

INSERT INTO [CoreMember2].[bronze].[bz_member_profile] (
    MemberID,
    PlanCode,
    PlanYear,
    CustomerID,
    PatientID,
    FirstName,
    MiddleName,
    LastName,
    DateOfBirth,
    Gender,
    Address1,
    Address2,
    City,
    State,
    Zip,
    CountyFIPSCode,
    PhoneNumber,
    AgentUsername,
    PrimaryEmailAddress
)
SELECT 
    memberID,
    PlanCode,
    PlanYear,
    CustomerID,
    PatientID,
    FirstName,
    MiddleName,
    LastName,
    DateOfBirth,
    Gender,
    Address1,
    Address2,
    City,
    State,
    Zip,
    CountyFIPSCode,
    PhoneNumber,
    AgentUsername,
    PrimaryEmailAddress
FROM LatestMemberData
WHERE rn = 1;
GO

/* Verify Insertion
select top 1000 * from [CoreMember2].[bronze].[bz_member_profile]
*/

-- COMMIT TRANSACTION
-- ROLLBACK TRANSACTION