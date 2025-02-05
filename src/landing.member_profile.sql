WITH affected_members AS (
    SELECT DISTINCT mpr.memberID
    FROM CoreMember2..MasterPersonRecord mpr (nolock)
    JOIN CoreMember2..Profile p (nolock) ON p.memberID = mpr.memberID
    JOIN CoreMember2..MemberAppJoin maj (nolock) ON maj.memberID = mpr.memberID
    WHERE maj.appID IN (
        SELECT appID 
        FROM CoreMember2..AppPortabilityWhitelist 
        WHERE appPortableID = 4920
    )
),
member_enrollments AS (
    SELECT *
    FROM (
        SELECT 
            me.memberID,
            pm.External_ID,
            pm.External_PlanID,
            pm.External_SegmentID,
            pm.PlanYear,
            ft.modifiedwhen,
            ROW_NUMBER() OVER (
                PARTITION BY me.memberID 
                ORDER BY ft.modifiedwhen DESC
            ) AS row_num
        FROM CMS_Session_Control..FOAM_Transactions ft (nolock)
        JOIN CoreMember2..MemberEnrollments me (nolock) 
            ON me.NativeTransactionID = ft.TransactionGUID
        JOIN master.coreplan.dbo.planmaster pm (nolock)
            ON pm.PLAN_ID = ft.PlanID
        WHERE ft.ConfirmationNumber IS NOT NULL
            AND ft.IsActive = 1
            AND pm.PlanName NOT IN ('Dummy Plan','SOA Generic Plan')
    ) ranked
    WHERE row_num = 1
),
latest_address AS (
    SELECT 
        pa.profileID, 
        pa.street1, 
        pa.street2, 
        pa.City, 
        pa.[State]
    FROM CoreMember2..ProfileAddress pa (nolock)
    WHERE pa.createdwhen = (
        SELECT MAX(createdwhen)
        FROM CoreMember2..ProfileAddress pa2
        WHERE pa2.profileID = pa.profileID
    )
)

SELECT
    mpr.memberID AS cnxmemberid,
    '' AS customerid,
    '' AS carrier,
    en.External_ID + '-' + en.External_PlanID + '-' + en.External_SegmentID + '-' + CAST(en.PlanYear AS VARCHAR) AS [plan],
    '' AS [group],
    '' AS pin,
    sa.ssoValue AS patientid,
    '1' AS personcode,
    '' AS relationshipcode,
    p.FirstName AS firstname,
    p.LastName AS lastname,
    '' AS middlename,
    RIGHT('00' + CONVERT(VARCHAR, p.birthmonth), 2) + '/' + 
    RIGHT('00' + CONVERT(VARCHAR, p.birthday), 2) + '/' + 
    RIGHT('0000' + CONVERT(VARCHAR, p.birthyear), 4) AS dateofbirth,
    CASE 
        WHEN p.genderID = '0' THEN NULL
        WHEN p.genderID = '1' THEN 'M'
        WHEN p.genderID = '2' THEN 'F'
        ELSE CONVERT(VARCHAR, p.genderID)
    END AS gender,
    REPLACE(pa.street1, '"', '') AS address1,
    REPLACE(pa.street2, '"', '') AS address2,
    pa.City AS city,
    pa.[State] AS state,
    d.zip AS zip,
    d.county_fips AS countyfipscode,
    LEFT(p.homePhone, 3) + '0000000' AS phonenumber,
    '' AS effectivedate,
    '' AS termdate,
    CASE 
        WHEN ISNULL(d.healthStatusID, 0) = 0 THEN 'Not Provided'
        WHEN ISNULL(d.healthStatusID, 0) = 1 THEN 'Excellent'
        WHEN ISNULL(d.healthStatusID, 0) = 2 THEN 'Very Good'
        WHEN ISNULL(d.healthStatusID, 0) = 3 THEN 'Good'
        WHEN ISNULL(d.healthStatusID, 0) = 4 THEN 'Fair'
        WHEN ISNULL(d.healthStatusID, 0) = 5 THEN 'Poor'
        ELSE 'Not Provided'
    END AS healthstatus,
    p.CRMID AS crmid,
    p.CustomField1 AS customfield1,
    p.CustomField2 AS customfield2,
    p.CustomField3 AS customfield3,
    p.CustomField4 AS customfield4,
    p.CustomField5 AS customfield5,
    '' AS message,
    u.Username AS agentusername,
    p.PrimaryEmailAddress AS primaryemailaddress,
    am.NPN AS agentnpn,
    u.email AS agent_email,
    u.fname AS agentfirstname,
    u.lname AS agentlastname
FROM CoreMember2..MasterPersonRecord mpr (nolock)
JOIN CoreMember2..Profile p (nolock)
    ON p.memberID = mpr.memberID
LEFT JOIN CorePermissions..Users u (nolock)
    ON u.UserId = mpr.agentGUID
LEFT JOIN coreagent..agentmaster am (nolock)
    ON am.useragentguid = u.userid
LEFT JOIN latest_address pa 
    ON pa.profileID = p.profileID
LEFT JOIN CoreMember2..Demographics d (nolock)
    ON d.memberID = mpr.memberID
LEFT JOIN CoreMember2..SSOAccount sa (nolock)
    ON sa.memberID = mpr.memberID
JOIN member_enrollments en
    ON en.memberID = mpr.memberID
WHERE EXISTS (
    SELECT 1 
    FROM affected_members am 
    WHERE am.memberID = mpr.memberID
)
and en.PlanYear >= 2025
ORDER BY mpr.memberID
OFFSET 100 ROWS
FETCH NEXT 100 ROWS ONLY;