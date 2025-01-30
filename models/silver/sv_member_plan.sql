
SELECT
        -- # keys
        m.MemberID,
        m.PlanCode,
        m.PlanYear,

        m.CustomerID,
        m.PatientID,
        m.FirstName,
        m.MiddleName,
        m.LastName,
        -- DATEDIFF('DAY',
        --     CURRENT_DATE(),
        --     DATE_ADD(m.DateOfBirth,
        --         INTERVAL (YEAR(CURRENT_DATE()) - YEAR(m.DateOfBirth) +
        --             (CASE WHEN MONTH(CURRENT_DATE()) > MONTH(m.DateOfBirth)
        --              OR (MONTH(CURRENT_DATE()) = MONTH(m.DateOfBirth) AND DAY(CURRENT_DATE()) >= DAY(m.DateOfBirth))
        --                 THEN 1 ELSE 0
        --             END)
        --         ) YEAR
        --     )
        -- ) AS days_to_next_birthday,
        -- DATE_ADD(m.DateOfBirth,
        --     INTERVAL (YEAR(CURRENT_DATE()) - YEAR(m.DateOfBirth) +
        --         (CASE WHEN MONTH(CURRENT_DATE()) > MONTH(m.DateOfBirth)
        --             OR (MONTH(CURRENT_DATE()) = MONTH(m.DateOfBirth) AND DAY(CURRENT_DATE()) >= DAY(m.DateOfBirth))
        --             THEN 1 ELSE 0
        --         END)
        --     ) YEAR
        -- ) AS next_birthday,
        m.DateOfBirth,
        m.Gender,
        m.Address1,
        m.Address2,
        m.City,
        m.StateId,
        m.Zipcode,
        m.CountyFIPSCode,
        -- new
        cp.county_name,
        cp.metro_area,
        cp.central_or_outlying,
        cp.population,
        -- new
        m.PhoneNumber,
        m.PrimaryEmailAddress,
        m.AgentUsername,
        a.agent_npn,
        a.agent_first_name,
        a.agent_last_name,
        a.agent_email,
        ph.PharmacyNABP,
        ph.PharmacyIsPrimary,
        ph.PharmacyNPI,
        pr.ProviderExternalNPI,
        pr.ProviderIsPrimary,
        pr.ProviderAddress1,
        pr.ProviderAddress2,
        pr.ProviderCity,
        pr.ProviderStateId,
        pr.ProviderZipCode

FROM {{
    ref('bz_member_profile')
}} AS m
LEFT JOIN {{
    ref('bz_agent')
}} AS a ON a.agent_user_name = m.AgentUsername
LEFT JOIN {{
    ref('bz_member_pharmacy')
}} AS ph ON m.MemberID = ph.MemberID
LEFT JOIN {{
    ref('bz_member_provider')
}} AS pr ON m.MemberID = pr.MemberID
LEFT JOIN {{
    ref('bz_us_country_mapping')
}} AS cp ON m.StateId = cp.state_id AND m.CountyFIPSCode = cp.county_fips
