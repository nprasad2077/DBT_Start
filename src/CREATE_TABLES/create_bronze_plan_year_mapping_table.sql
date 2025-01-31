BEGIN TRANSACTION

USE [CoreMember2];
GO

-- Create table if it does not exist
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'bronze' AND TABLE_NAME = 'plan_year_mapping')
BEGIN
    CREATE TABLE bronze.plan_year_mapping (
        plan_id INT PRIMARY KEY,
        planyear INT
    );
    PRINT 'Table [bronze.plan_year_mapping] created successfully.';
END
ELSE
    PRINT 'Table [bronze.plan_year_mapping] already exists.';
GO

-- COMMIT TRANSACTION

-- ROLLBACK TRANSACTION
