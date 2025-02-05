SELECT
    mpr.memberID as cnxmemberid,
    pc.pharmacyNABP as pharmacynabp,
    ppm.npi as npi,
    CAST(pc.isPrimaryPharmacy AS VARCHAR) as isprimarypharmacy,
    '2024-11-18' as ingestiondate
FROM CoreMember2..MasterPersonRecord mpr (nolock)
JOIN CoreMember2..Profile p (nolock)
    ON p.memberID = mpr.memberID
JOIN CoreMember2..CabinetControl cc (nolock)
    ON cc.CreationMemberID = mpr.memberID
JOIN CoreMember2..PharmacyCabinet pc (nolock)
    ON pc.cabinetID = cc.cabinetID
LEFT JOIN master.corePharmacy.dbo.PHM_PHARMACY_MASTER ppm (nolock)
    ON ppm.PHARMACY_NABP = pc.pharmacyNABP
WHERE pc.isActive = 1
    AND mpr.memberID IN (
        SELECT memberID 
        FROM CoreMember2..MemberAppJoin maj (nolock)
        WHERE maj.appID IN (
            SELECT appID 
            FROM CoreMember2..AppPortabilityWhitelist 
            WHERE appPortableID = 4920
        )
    )
    AND mpr.memberID NOT IN (358695863,361417623)  -- Exclusion from original script
ORDER BY mpr.memberID;