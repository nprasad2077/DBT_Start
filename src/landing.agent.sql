SELECT DISTINCT
    u.Username AS agentusername,
    am.NPN AS agentnpn,
    u.email AS agent_email,
    u.fname AS agentfirstname,
    u.lname AS agentlastname,
    '2024-11-18' AS ingestiondate  -- Using DBT date
FROM CorePermissions..Users u (nolock)
JOIN coreagent..agentmaster am (nolock)
    ON am.useragentguid = u.userid
JOIN CoreMember2..MasterPersonRecord mpr (nolock)
    ON mpr.agentGUID = u.UserId
WHERE u.Username IS NOT NULL
    AND u.Username NOT LIKE 'cnx%'
    AND EXISTS (
        SELECT 1
        FROM CoreMember2..MemberAppJoin maj (nolock)
        WHERE maj.memberID = mpr.memberID
        AND maj.appID IN (
            SELECT appID 
            FROM CoreMember2..AppPortabilityWhitelist 
            WHERE appPortableID = 4920
        )
    )
ORDER BY u.Username;