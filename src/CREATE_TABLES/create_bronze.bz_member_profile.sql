BEGIN TRANSACTION

USE [CoreMember2];
GO
-- Check if table exists before creating it
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'bronze' AND TABLE_NAME = 'bz_member_profile')
BEGIN
    CREATE TABLE bronze.bz_member_profile (
        MemberID BIGINT NOT NULL,
        PlanCode VARCHAR(50),           -- From MemberEnrollments.planID
        PlanYear INT,                   -- From plan_year_mapping
        CustomerID NVARCHAR(100),       -- From Profile.CRMID
        PatientID NVARCHAR(510),        -- From Profile.externalMemberID
        FirstName NVARCHAR(200),
        MiddleName NVARCHAR(1),
        LastName NVARCHAR(200),
        DateOfBirth DATE,
        Gender NVARCHAR(10),
        Address1 VARCHAR(255),          -- From ProfileAddress
        Address2 VARCHAR(255),          -- From ProfileAddress
        City VARCHAR(255),              -- From ProfileAddress
        State CHAR(2),                  -- From ProfileAddress
        Zip VARCHAR(10),                -- From ProfileAddress
        CountyFIPSCode VARCHAR(5),      -- From ProfileAddress.countyFips
        PhoneNumber NVARCHAR(24),
        AgentUsername UNIQUEIDENTIFIER, -- From MemberEnrollments.agentGUID
        PrimaryEmailAddress NVARCHAR(510),
        normalized_at DATETIME DEFAULT GETDATE(),
        PRIMARY KEY (MemberID)
    );
    PRINT 'Table [bronze.bz_member_profile] created successfully.';
END
ELSE
    PRINT 'Table [bronze.bz_member_profile] already exists.';
GO

/*
-- Verify Table Creation

select * from CoreMember2.bronze.bz_member_profile

*/

-- COMMIT TRANSACTION

-- ROLLBACK TRANSACTION
