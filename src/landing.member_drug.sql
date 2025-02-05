WITH drug_ndc AS (
    SELECT DISTINCT 
        mc.drugRecordID, 
        mc.drug_dsg_id, 
        dcp.NDC
    FROM CoreMember2..MasterPersonRecord mpr (nolock)
    JOIN CoreMember2..CabinetControl cc (nolock)
        ON cc.CreationMemberID = mpr.memberID
    JOIN CoreMember2..MedicineCabinet mc (nolock)
        ON mc.cabinetID = cc.cabinetID
        AND mc.isActive = 1
    LEFT JOIN (
        SELECT DISTINCT n.drug_dsg_id, n.NDC
        FROM drugdb..drg_cms_proxycui c
        JOIN drugdb..drg_ndc_lookup n 
            ON c.related_ndc = n.ndc
        WHERE NDC_EXEMPLAR = 1
    ) dcp ON dcp.DRUG_DSG_ID = mc.drug_dsg_id
),
drug_details AS (
    SELECT DISTINCT 
        mpr.memberID AS CNXMemberID,
        ddl.LABEL_NAME,
        mc.metricQuantity,
        mc.daysOfSupply,
        mc.package_id,
        mc.drug_dsg_id,
        dn.NDC,
        CASE 
            WHEN mc.daysOfSupply = 30 THEN CONVERT(VARCHAR, mc.metricQuantity) + ' per month'
            WHEN mc.daysOfSupply = 60 THEN CONVERT(VARCHAR, mc.metricQuantity) + ' per 2 months'
            WHEN mc.daysOfSupply = 90 THEN CONVERT(VARCHAR, mc.metricQuantity) + ' per 3 months'
            WHEN mc.daysOfSupply = 365 THEN CONVERT(VARCHAR, mc.metricQuantity) + ' per 12 months'
        END AS MonthlyQuantity
    FROM CoreMember2..MasterPersonRecord mpr (nolock)
    JOIN CoreMember2..CabinetControl cc (nolock)
        ON cc.CreationMemberID = mpr.memberID
    JOIN CoreMember2..MedicineCabinet mc (nolock)
        ON mc.cabinetID = cc.cabinetID
        AND mc.isActive = 1
    JOIN drugdb.dbo.DRG_DOSAGE_LOOKUP ddl (nolock)
        ON ddl.DRUG_DSG_ID = mc.drug_dsg_id
        AND ddl.DOSE_CMS_VISIBLE = 1
    LEFT JOIN drug_ndc dn
        ON dn.drugRecordID = mc.drugRecordID
)
SELECT top 100
    d.CNXMemberID as cnxmemberid,
    d.LABEL_NAME as drugname,
    d.LABEL_NAME + ', ' + 
    ISNULL(CASE 
        WHEN pkg.total_pkg_qty/pkg.package_size = 1 AND pkg.package_size_uom <> 'ML' THEN NULL
        WHEN pkg.total_pkg_qty/pkg.package_size = 1 AND pkg.package_size_uom = 'ML' 
            THEN CONVERT(VARCHAR,pkg.package_size) + ' ' + pkg.package_size_uom + ' ' + LOWER(pkg.package_desc)
        ELSE CONVERT(VARCHAR,pkg.package_size) + ' ' + pkg.package_size_uom + ' ' + LOWER(pkg.package_desc)
    END,'') + ' ' +
    ISNULL(CASE 
        WHEN pkg.total_pkg_qty/pkg.package_size = 1 AND pkg.package_size_uom = 'EA' 
            THEN pkg.package_desc + ' of ' + CONVERT(VARCHAR,pkg.package_size) + ' ' + pkg.dose_form_PackageText
        WHEN pkg.total_pkg_qty/pkg.package_size = 1 AND pkg.package_desc = 'BOTTLE' 
            THEN CONVERT(VARCHAR,pkg.package_size) + ' ' + pkg.package_size_uom + ' ' + LOWER(pkg.package_desc)
        WHEN pkg.total_pkg_qty/pkg.package_size = 1 AND pkg.package_desc IN ('inhaler', 'tube')
            THEN CONVERT(VARCHAR,pkg.package_size) + ' ' + pkg.package_size_uom + ' ' + LOWER(pkg.package_desc)
        WHEN pkg.total_pkg_qty/pkg.package_size = 1 AND pkg.package_size_uom = 'ML' 
            THEN '(sold in a package of ' + CONVERT(VARCHAR,pkg.package_qty) + ' ' + LOWER(pkg.package_desc) + '(s))'
        ELSE '(sold in a package of ' + CONVERT(VARCHAR,CONVERT(INT,pkg.total_pkg_qty/pkg.package_size)) + ' ' + LOWER(pkg.package_desc) + '(s))'
    END,'') + ' ' +
    ISNULL(d.MonthlyQuantity, '') as druglist,
    d.NDC as ndc,
    CAST(d.metricQuantity AS VARCHAR) as metricquantity,
    CAST(d.daysOfSupply AS VARCHAR) as daysofsupply,
    '2024-11-18' as ingestiondate -- manually set from DBT
FROM drug_details d
OUTER APPLY drugdb.dbo.dose_fn_GetPackageInfo(d.package_id, d.drug_dsg_id) pkg
WHERE EXISTS (
    SELECT 1 
    FROM CoreMember2..MemberAppJoin maj (nolock)
    WHERE maj.memberID = d.CNXMemberID
    AND maj.appID IN (
        SELECT appID 
        FROM CoreMember2..AppPortabilityWhitelist 
        WHERE appPortableID = 4920
    )
)
ORDER BY d.CNXMemberID;