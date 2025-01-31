BEGIN TRANSACTION

USE [CoreMember2];
GO

-- Verify data before inserting
PRINT 'Verifying data in coreplan..planmaster...';
IF EXISTS (SELECT 1 FROM coreplan..planmaster WITH (NOLOCK))
BEGIN
    -- Populate table from coreplan database
    INSERT INTO CoreMember2.bronze.plan_year_mapping (plan_id, planyear)
    SELECT DISTINCT pm.plan_id, pm.planyear
    FROM coreplan..planmaster pm WITH (NOLOCK);

    PRINT 'Data inserted successfully into [CoreMember2].[bronze].[plan_year_mapping].';
END
ELSE
    PRINT 'No data found in [coreplan] database. Skipping insertion.';
GO

/* ** Verify inserted data **

SELECT TOP 1000 * FROM CoreMember2.bronze.plan_year_mapping;

*/


-- COMMIT TRANSACTION

-- ROLLBACK TRANSACTION
