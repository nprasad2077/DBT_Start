SELECT 
    mpr.memberID as cnxmemberid,
    pm.ExternalNPI as externalnpi,
    CAST(pc.isPrimary AS VARCHAR) as isprimary,
    '' as addressline1,  -- Blank in Landing Tables
    '' as addressline2,  -- Blank in Landing Tables
    '' as city,         -- Blank in Landing Tables
    '' as state,        -- Blank in Landing Tables
    '' as zipcode,      -- Blank in Landing Tables
    '' as ingestiondate
FROM CoreMember2..MasterPersonRecord mpr (nolock)
JOIN CoreMember2..CabinetControl cc (nolock)
    ON cc.CreationMemberID = mpr.memberID
JOIN CoreMember2..ProviderCabinet pc (nolock)
    ON pc.cabinetID = cc.cabinetID
    AND pc.isactive = 1
JOIN Coremember2..ProviderMaster pm (nolock)
    ON pm.providerID = pc.providerID
WHERE mpr.memberID IN (
    SELECT memberID 
    FROM CoreMember2..MemberAppJoin maj (nolock)
    WHERE maj.appID IN (
        SELECT appID 
        FROM CoreMember2..AppPortabilityWhitelist 
        WHERE appPortableID = 4920
    )
)
ORDER BY cnxmemberid, externalnpi, isprimary;