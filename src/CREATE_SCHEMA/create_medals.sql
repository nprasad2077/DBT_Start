BEGIN TRANSACTION;

USE [CoreMember2];
GO

DECLARE @SchemaCreated BIT = 0; -- Flag to track if a schema was created

-- Create schemas if they don't exist
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'bronze')
BEGIN
    EXEC('CREATE SCHEMA bronze');
    PRINT 'Schema [bronze] created successfully.';
    SET @SchemaCreated = 1;
END
ELSE
    PRINT 'Schema [bronze] already exists.';

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'silver')
BEGIN
    EXEC('CREATE SCHEMA silver');
    PRINT 'Schema [silver] created successfully.';
    SET @SchemaCreated = 1;
END
ELSE
    PRINT 'Schema [silver] already exists.';

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'gold')
BEGIN
    EXEC('CREATE SCHEMA gold');
    PRINT 'Schema [gold] created successfully.';
    SET @SchemaCreated = 1;
END
ELSE
    PRINT 'Schema [gold] already exists.';

-- Verify Schema Creation
PRINT 'Verifying schema existence...';
SELECT name AS SchemaName, schema_id FROM sys.schemas WHERE name IN ('bronze', 'silver', 'gold');

-- Decision: Commit or Rollback
IF @SchemaCreated = 1
BEGIN
    PRINT 'Schemas have been created/updated. You can COMMIT or ROLLBACK.';
END
ELSE
    PRINT 'No new schemas were created. You can COMMIT or ROLLBACK safely.';

-- COMMIT TRANSACTION; -- Uncomment to apply changes
-- ROLLBACK TRANSACTION; -- Uncomment to discard changes

