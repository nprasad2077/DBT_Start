
select * from coreconfig..framework_siteurls where siteurl like '%jsa7.destinationrx.com/PC/Agent%'
-- appID = 499049201

select * from CoreMember2..AppPortabilityWhitelist where appID = 499049201
select * from CoreMember2..AppPortabilityWhitelist where appPortableID = 4920

--select up.Username, count(distinct u.userid)
drop table if exists #userid
select		distinct u.userid, ud.domainname, u.username, u.FName, u.LName
into		#userid
from		corePermissions..users (nolock) u
join		coreAgent..agentMaster (nolock) am
			on am.userAgentGUID = u.userid
join		coreAgent..agentAppPermissions (nolock) aap
			on aap.agentID = am.agentID
			and aap.isActive = 1
			and (aap.appID like '424%' or aap.appID like '499%' or aap.appID like '17[0-9][0-9]%' or aap.appID like '9[0-9][0-9][0-9][0-9]%')
left join	CorePermissions..UserDomains (nolock) ud
			on ud.DomainId = u.domainid
where		ud.DomainName not like '%delete%'
			and u.Username not like 'cnx%'
			and aap.appID in (select appID from CoreMember2..AppPortabilityWhitelist where appPortableID = 4920)

select		* from #userid

select * into #planmaster from master.coreplan.dbo.planmaster where PlanYear = 2024

drop table if exists #affected_MemberID
select		distinct  
			mpr.memberID
into		#affected_MemberID
from		CoreMember2..MasterPersonRecord (nolock) mpr
join		CoreMember2..Profile (nolock) p
			on p.memberID = mpr.memberID
join		CorePermissions..Users (nolock) u
			on u.UserId = mpr.agentGUID
where		u.UserId in (select userid from #userid)
-- (324728 rows affected)

--select		count(distinct memberID) from #affected_MemberID

create index IX_affected_MemberID on #affected_MemberID(MemberID)

select		distinct mpr.memberID
into		#temp
from		CoreMember2..MasterPersonRecord (nolock) mpr
join		CoreMember2..Profile (nolock) p
			on p.memberID = mpr.memberID
join		CoreMember2..MemberAppJoin (nolock) maj
			on maj.memberID = mpr.memberID
where		maj.appID in (select appID from CoreMember2..AppPortabilityWhitelist where appPortableID = 4920)
--(349795 rows affected)

insert		#affected_MemberID(memberID)
select		*
from		(
				select * from #temp
				except 
				select * from #affected_MemberID
			) t
-- (25218 rows affected)

select count(distinct memberid) from #affected_MemberID
-- 349946

drop table if exists #MemberEnrollment
select	distinct ft.ConfirmationNumber, me.memberID, pm.PlanName, pm.External_ID, pm.External_PlanID, pm.External_SegmentID, pm.PlanYear, ft.modifiedwhen, ptl.PlanType
into	#MemberEnrollment
from	CMS_Session_Control..FOAM_Transactions (nolock) ft
join	CoreMember2..MemberEnrollments (nolock) me
		on me.NativeTransactionID = ft.TransactionGUID
join	#affected_MemberID t
		on t.memberID = me.memberID
join	#planmaster pm (nolock)
		on pm.PLAN_ID = ft.PlanID
join	CorePlan..PlanTypeLookup ptl (nolock)
		on ptl.PlanTypeID = pm.PlanTypeID
		and ptl.PlanType in ('PDP','MA','MAPD')
		--and pm.PlanYear in (2021,2022,2023,2024)
where	ft.ConfirmationNumber is not null
		and ft.IsActive = 1
		and pm.PlanName not in ('Dummy Plan','SOA Generic Plan')
-- (43728 rows affected)

--SELECT	*
--FROM	(
--		  SELECT	*, 
--					ROW_NUMBER = ROW_NUMBER() OVER (PARTITION BY memberID ORDER BY modifiedwhen DESC)
--		  FROM		#MemberEnrollment
--		) d
--WHERE	[ROW_NUMBER] = 1
														
drop table if exists #temp_memberprofile
select	*
into	#temp_memberprofile
from	(
			select		distinct  
						CNXMemberID			= mpr.memberID,
						CustomerID			= '',
						Carrier				= '',
						[Plan]				= en.External_ID+'-'+en.External_PlanID+'-'+en.External_SegmentID+'-'+en.PlanYear,
						[Group]				= '',
						PIN					= '',
						PatientID			= sa.ssoValue,
						PersonCode			= '1',
						RelationshipCode	= '',
						FirstName			= p.FirstName,
						LastName			= p.LastName,
						MiddleName			= '',
						DateOfBirth			= right('00'+convert(varchar,p.birthmonth),2)+'/'+right('00'+convert(varchar,p.birthday),2)+'/'+right('0000'+convert(varchar,p.birthyear),4),
						Gender				= case when p.genderID = '0' then null when p.genderID = '1' then 'M' when p.genderID = '2' then 'F' else convert(varchar, p.genderID) end,
						Address1			= replace(pa.street1,'"',''),
						Address2			= replace(pa.street2,'"',''),
						pa.City,
						pa.[State],
						Zip					= d.zip,
						CountyFIPSCode		= d.county_fips,
						PhoneNumber			= left(p.homePhone,3) + '0000000',--p.homePhone,
						EffectiveDate		= '',
						TermDate			= '',
						HealthStatus		= case when isnull(d.healthStatusID,0) = 0 then 'Not Provided' when isnull(d.healthStatusID,0) = 1 then 'Excellent' when isnull(d.healthStatusID,0) = 2 then 'Very Good' when isnull(d.healthStatusID,0) = 3 then 'Good' when isnull(d.healthStatusID,0) = 4 then 'Fair' when isnull(d.healthStatusID,0) = 5 then 'Poor' else 'Not Provided' end,
						CRMID				= p.CRMID,
						CustomField1		= p.CustomField1,
						CustomField2		= p.CustomField2,
						CustomField3		= p.CustomField3,
						CustomField4		= p.CustomField4,
						CustomField5		= p.CustomField5,
						[Message]			= '',
						u.Username,
						PrimaryEmailAddress	= p.PrimaryEmailAddress,
						sa.ssoValue,
						en.PlanName,
						ContractID			= en.External_ID,
						PlanID				= en.External_PlanID,
						SegmentID			= en.External_SegmentID,
						en.PlanYear,
						en.PlanType,
						en.ConfirmationNumber,
						am.NPN as AgentNPN,
						u.email as Agent_Email,
						u.fname as AgentFirstName,
						u.lname as AgentLastName
			from		CoreMember2..MasterPersonRecord (nolock) mpr
			join		CoreMember2..Profile (nolock) p
						on p.memberID = mpr.memberID
			left join	CorePermissions..Users (nolock) u
						on u.UserId = mpr.agentGUID
			left join	coreagent..agentmaster (nolock) am
						on am.useragentguid = u.userid
			left join	(
							 SELECT	*
							 FROM	(
										  SELECT	*, 
													[ROW_NUMBER] = ROW_NUMBER() OVER (PARTITION BY profileid ORDER BY createdwhen DESC)
										  FROM		CoreMember2..ProfileAddress (nolock) 
									) t
							 WHERE	[ROW_NUMBER] = 1
						) pa
						on pa.profileID = p.profileID
			left join	CoreMember2..Demographics d (nolock)
						on d.memberID = mpr.memberID
			left join	CoreMember2..SSOAccount sa (nolock)
						on sa.memberID = mpr.memberID
			join	(
							SELECT	*
							FROM	(
									  SELECT	*, 
												ROW_NUMBER = ROW_NUMBER() OVER (PARTITION BY memberID ORDER BY modifiedwhen DESC)
									  FROM		#MemberEnrollment
									) d
							WHERE	[ROW_NUMBER] = 1
						) en
						on en.memberID = mpr.memberID
			where		mpr.memberID in (select distinct memberid from #affected_MemberID)
		) t
-- (42222 rows affected)

select		CNXMemberID, count(*)
from		#temp_memberprofile
group by	CNXMemberID
having		count(*) > 1

select		PlanType, count(*)
from		#temp_memberprofile
group by	PlanType
--- This portion is for plan smart
--drop table if exists CommercialDW.dbo.[Plansmart-SMS-Sample_09052024]
--select ssovalue, planname, contractid, planid, segmentid,zip as zipcode, countyfipscode as countyfips, cnxmemberid as memberid, username, confirmationnumber, plantype
--into CommercialDW.dbo.[Plansmart-SMS-Sample_09052024]
--from #temp_memberprofile order by CNXMemberID

-- profile tab
select	CNXMemberID,
		CustomerID,
		Carrier,
		[Plan],
		[Group],
		PIN,
		PatientID,
		PersonCode,
		RelationshipCode,
		FirstName,
		LastName,
		MiddleName,
		DateOfBirth,
		Gender,
		Address1,
		Address2,
		City,
		State,
		Zip,
		CountyFIPSCode,
		PhoneNumber,
		EffectiveDate,
		TermDate,
		HealthStatus,
		CRMID,
		CustomField1,
		CustomField2,
		CustomField3,
		CustomField4,
		CustomField5,
		Message,
		Username as AgentUsername,
		PrimaryEmailAddress,
		AgentNPN,
		Agent_Email,
		AgentFirstName,
		AgentLastName
from	#temp_memberprofile 
order by cnxmemberid 


-- agent tab
select	distinct Username as AgentUsername,
		AgentNPN,
		Agent_Email,
		AgentFirstName,
		AgentLastName
from	#temp_memberprofile 
where	Username is not null
order by	Username

select		distinct mc.drugRecordID, mc.drug_dsg_id, dcp.NDC
into		#drugNDC
from		CoreMember2..MasterPersonRecord (nolock) mpr
left join	CoreMember2..[Profile] (nolock) p
			on p.memberID = mpr.memberID
left join	CoreMember2..ProfileAddress (nolock) pa
			on pa.profileID = p.profileID
join		CoreMember2..CabinetControl (nolock) cc
			on cc.CreationMemberID = mpr.memberID
join		CoreMember2..MedicineCabinet (nolock) mc
			on mc.cabinetID = cc.cabinetID
			and mc.isActive = 1
left join	(
				select	distinct n.drug_dsg_id, n.NDC
				from	drugdb..drg_cms_proxycui c
				join	drugdb..drg_ndc_lookup n on c.related_ndc = n.ndc
				where	NDC_EXEMPLAR = 1
			)dcp
			on dcp.DRUG_DSG_ID = mc.drug_dsg_id
where	exists (select 1 from #temp_memberprofile t where t.CNXMemberID = mpr.memberID)
-- (118352 rows affected)

--select drug_dsg_id, drugRecordID, count(*) from #drugNDC group by drug_dsg_id, drugRecordID having count(*) > 1
--select drug_dsg_id, drugRecordID, count(*) from #drugNDC group by drug_dsg_id, drugRecordID

--drop table #DRG_DOSAGE_LOOKUP
select * into #DRG_DOSAGE_LOOKUP from coredb.DrugDB.dbo.DRG_DOSAGE_LOOKUP

-- drop table #temp1
select	distinct p.FirstName,p.LastName, p.birthmonth, p.birthday, p.birthyear,pa.zipCode, ddl.LABEL_NAME, 
		MonthlyQuantity = case when mc.daysOfSupply = 30 then convert(varchar, mc.metricQuantity) + ' per month'
								when mc.daysOfSupply = 60 then convert(varchar, mc.metricQuantity) + ' per 2 months'
								when mc.daysOfSupply = 90 then convert(varchar, mc.metricQuantity) + ' per 3 months'
								when mc.daysOfSupply = 365 then convert(varchar, mc.metricQuantity) + ' per 12 months'
							end,
		mc.daysOfSupply, mc.metricQuantity, mc.package_id,mc.drug_dsg_id, CNXMemberID = mpr.memberID, dn.NDC
into	#temp1
from	CoreMember2..MasterPersonRecord (nolock) mpr
left join	CoreMember2..[Profile] (nolock) p
			on p.memberID = mpr.memberID
left join	CoreMember2..ProfileAddress (nolock) pa
		on pa.profileID = p.profileID
join	CoreMember2..CabinetControl (nolock) cc
		on cc.CreationMemberID = mpr.memberID
join	CoreMember2..MedicineCabinet (nolock) mc
		on mc.cabinetID = cc.cabinetID
join	#DRG_DOSAGE_LOOKUP ddl
		on ddl.DRUG_DSG_ID = mc.drug_dsg_id
left join	#drugNDC dn
			on dn.drugRecordID = mc.drugRecordID
where	--maj.appID in (4226502 )
		mc.isActive = 1
		and ddl.DOSE_CMS_VISIBLE = 1
		and exists (select 1 from #temp_memberprofile t where t.CNXMemberID = mpr.memberID)
-- (118171 row(s) affected)

-- drop table #temp2
select	CNXMemberID,FirstName,LastName,birthmonth,birthday,birthyear,zipCode= min(zipCode),LABEL_NAME,MonthlyQuantity, metricQuantity, daysOfSupply ,package_id, drug_dsg_id, NDC
into	#temp2
from	#temp1
group by CNXMemberID,FirstName,LastName,birthmonth,birthday,birthyear,LABEL_NAME,MonthlyQuantity, metricQuantity, daysOfSupply ,package_id, drug_dsg_id, NDC
-- (118093 row(s) affected)

drop table if exists #temp_druglist
select	t.CNXMemberID, t.FirstName,t.LastName,birthmonth,birthday,birthyear,zipCode, metricQuantity, daysOfSupply,t.LABEL_NAME,
		DrugList = t.LABEL_NAME + ', ' +
		isnull(case when pkg.total_pkg_qty/pkg.package_size = 1 and pkg.package_size_uom <> 'ML' then null
			when pkg.total_pkg_qty/pkg.package_size = 1 and pkg.package_size_uom = 'ML' then convert(varchar,pkg.package_size) + ' ' + pkg.package_size_uom + ' ' + lower(pkg.package_desc)
			else convert(varchar,pkg.package_size) + ' ' + pkg.package_size_uom + ' ' + lower(pkg.package_desc)
		end,'') + ' ' +
		isnull(case when pkg.total_pkg_qty/pkg.package_size = 1 and pkg.package_size_uom = 'EA' then pkg.package_desc + ' of ' + convert(varchar,pkg.package_size) + ' ' + pkg.dose_form_PackageText
			when pkg.total_pkg_qty/pkg.package_size = 1 and pkg.package_desc = 'BOTTLE' then convert(varchar,pkg.package_size) + ' ' + pkg.package_size_uom + ' ' + lower(pkg.package_desc)
			when pkg.total_pkg_qty/pkg.package_size = 1 and pkg.package_desc = 'inhaler' then convert(varchar,pkg.package_size) + ' ' + pkg.package_size_uom + ' ' + lower(pkg.package_desc)
			when pkg.total_pkg_qty/pkg.package_size = 1 and pkg.package_desc = 'tube' then convert(varchar,pkg.package_size) + ' ' + pkg.package_size_uom + ' ' + lower(pkg.package_desc)
			when pkg.total_pkg_qty/pkg.package_size = 1 and pkg.package_size_uom = 'ML' then '(sold in a package of ' + convert(varchar,pkg.package_qty) + ' ' + lower(pkg.package_desc) + '(s))'
			else '(sold in a package of ' + convert(varchar,convert(int,pkg.total_pkg_qty/pkg.package_size)) + ' ' + lower(pkg.package_desc) + '(s))'
		end,'') + ' ' +
		isnull(case when convert(varchar,metricQuantity/pkg.total_pkg_qty) + ' per month' is not null and MonthlyQuantity not like '%months' then convert(varchar,metricQuantity/pkg.total_pkg_qty) + ' per month'
					when convert(varchar,metricQuantity/pkg.total_pkg_qty) + ' per month' is not null and MonthlyQuantity like '%12 months' then convert(varchar,metricQuantity/pkg.total_pkg_qty) + ' per 12 months'
					when convert(varchar,metricQuantity/pkg.total_pkg_qty) + ' per month' is not null and MonthlyQuantity like '%2 months' then convert(varchar,metricQuantity/pkg.total_pkg_qty) + ' per 2 months'
					when convert(varchar,metricQuantity/pkg.total_pkg_qty) + ' per month' is not null and MonthlyQuantity like '%3 months' then convert(varchar,metricQuantity/pkg.total_pkg_qty) + ' per 3 months'
			else MonthlyQuantity
		end,''),  
		t.drug_dsg_id, t.package_id, t.NDC
into	#temp_druglist
from	#temp2 t
OUTER APPLY drugdb.dbo.dose_fn_GetPackageInfo(t.package_id,t.drug_dsg_id) pkg
order by t.CNXMemberID
-- (118093 row(s) affected)

-- Drug tab
select CNXMemberID,LABEL_NAME as DrugName, DrugList, NDC, metricQuantity, daysOfSupply from #temp_druglist order by CNXMemberID

select * into #PHM_PHARMACY_MASTER from master.corePharmacy.dbo.PHM_PHARMACY_MASTER

--drop table #temp_pharmacy
select	*
into	#temp_pharmacy
from	(
			select	mp.CNXMemberID, pc.pharmacyNABP, ppm.npi, pc.isPrimaryPharmacy
			from	#temp_memberprofile mp
			join	CoreMember2..CabinetControl (nolock) cc
					on cc.CreationMemberID = mp.CNXMemberID
			join	CoreMember2..PharmacyCabinet (nolock) pc
					on pc.cabinetID = cc.cabinetID
			left join	#PHM_PHARMACY_MASTER ppm
						on ppm.PHARMACY_NABP = pc.pharmacyNABP
			where	pc.isActive = 1
					and mp.CNXMemberID not in (358695863,361417623)
		) t
-- (38049 rows affected)

-- Pharmacy tab
select	distinct CNXMemberID, p.pharmacyNABP, p.NPI, isPrimaryPharmacy
from	#temp_pharmacy p
order by CNXMemberID

------------ The following are not provided ---------------------

--select * 
--into	#MemberAgentNotes 
--from	CoreMember2.dbo.MemberAgentNotes 
--where	memberid in (select CNXMemberID from #temp_memberprofile_withoutplan)

--select	*
--into	#AgentNoteActionItemType
--from	Coremember2.dbo.AgentNoteActionItemType

---- 3rd tab
--select	distinct t.CNXMemberID, anat.agentNoteActionItemTypeDesc, man.[description],man.createdWhen, u.Username
--from	#temp_memberprofile_withoutplan t
--join	#MemberAgentNotes man
--		on man.memberID = t.CNXMemberID
--left join	#AgentNoteActionItemType anat
--			on anat.agentNoteActionItemTypeID = man.agentNoteActionItemTypeID
--left join	CorePermissions..Users (nolock) u
--			on u.UserId = man.userAgentGUID
--order by t.CNXMemberID,man.createdWhen

-- provider
select	distinct t.CNXMemberID, pm.ExternalNPI, pc.isPrimary
from	#temp_memberprofile t
join	CoreMember2..CabinetControl (nolock) cc
		on cc.CreationMemberID = t.CNXMemberID
join	CoreMember2..ProviderCabinet (nolock)pc
		on pc.cabinetID = cc.cabinetID
		and isactive = 1
join	Coremember2..ProviderMaster (nolock) pm
		on pm.providerID = pc.providerID
order by t.CNXMemberID,pm.ExternalNPI, pc.isPrimary

--select top 100 * from CoreMember2..ProviderCabinet (nolock)
--select top 100 * from CoreMember2..MemberAgentNotes where	memberID = 407130555
--select * from CoreMember2..Profile where FirstName = 'Test' and LastName = 'Broker' and zipCode = '44839'

---- claims

--select distinct source_id from CoreClaims..ClaimMember where memberid in (select cnxmemberid from #temp_memberprofile_withoutplan)
--select * from ClaimSourceCustomerIDLookup where SourceID = '6281'
--select * from ClaimSourceCustomerIDLookup where SourceID = '6295'

--use CoreClaims

--select top 100 * from claimmember
--select top 100 * from ClaimDrug


--OPEN MASTER KEY DECRYPTION BY PASSWORD = 'PRODClaims12345678910!' ;

--OPEN SYMMETRIC KEY PWKey
--DECRYPTION BY CERTIFICATE PWCertificate;

--select	distinct
--		cm.claimMember_ID,
--		CustomerID			= '',
--		Carrier				= '',
--		[Plan]				= pm.External_ID+'-'+pm.External_PlanID+'-'+pm.External_SegmentID+'-'+pm.PlanYear,
--		[Group]				= '',
--		PIN					= '',
--		PatientID			= externalMemberID,
--		PersonCode			= personID,
--		RelationshipCode	= '1',
--		FirstName			= CONVERT(varchar, DecryptByKey(firstname)),
--		LastName			= CONVERT(varchar, DecryptByKey(LastName)),
--		MiddleName,
--		DateOfBirth			= right('00'+CONVERT(varchar, DecryptByKey(birthmonth)),2)+'/'+right('00'+CONVERT(varchar, DecryptByKey(birthday)),2)+'/'+right('0000'+CONVERT(varchar, DecryptByKey(birthyear)),4),
--		Gender				= gender,
--		Address1			= replace(CONVERT(varchar, DecryptByKey(ca.address1)),'"',''),
--		Address2			= replace(CONVERT(varchar, DecryptByKey(ca.address2)),'"',''),
--		City				= CONVERT(varchar, DecryptByKey(ca.city)),
--		ca.[State],
--		ca.Zip,
--		CountyFIPSCode		= '',
--		PhoneNumber			= CONVERT(varchar, DecryptByKey(homePhone)),
--		EffectiveDate		= '',
--		TermDate			= '',
--		healthstatusID,
--		CRMID				= CRMID,
--		CustomField1		= CustomField1,
--		CustomField2		= CustomField2,
--		CustomField3		= CustomField3,
--		CustomField4		= CustomField4,
--		CustomField5		= CustomField5,
--		[Message]			= '',
--		Username			= cat.AgentKey,
--		PrimaryEmailAddress	= CONVERT(varchar, DecryptByKey(PrimaryEmailAddress))
--from	claimmember (nolock) cm
--left join	ClaimAddress (nolock) ca
--			on ca.claimMember_ID = cm.claimMember_ID
--left join	ClaimAgent (nolock) cat
--			on cat.ClaimAgentId = cm.ClaimAgentId
--left join	ClaimPlan (nolock) cp
--			on cp.claimMember_ID = cm.claimMember_ID
--left join	#planmaster pm
--			on pm.plan_id = cp.plan_ID
--where	source_id in (6281,6295)
--		and cm.MemberID is null

--CLOSE SYMMETRIC KEY PWKey

--select	*
--from	claimmember (nolock) cm
--left join	ClaimAddress (nolock) ca
--			on ca.claimMember_ID = cm.claimMember_ID
--left join	ClaimDrug cd
--			on cd.claimMember_ID = cm.claimMember_ID
--where	source_id in (6281,6295)
--		and cm.MemberID is null



----select	distinct ddl.LABEL_NAME, MonthlyQuantity = convert(varchar, cd.quantity) + ' per month', cd.quantity, cd.package_id,cd.drug_dsg_id, CNXMemberID = cm.claimMember_ID
------into	#temp1ClaimDrug
----from	claimmember (nolock) cm
----left join	ClaimAddress (nolock) ca
----			on ca.claimMember_ID = cm.claimMember_ID
----left join	ClaimDrug cd
----			on cd.claimMember_ID = cm.claimMember_ID
----join	DrugDB..DRG_DOSAGE_LOOKUP (nolock) ddl
----		on ddl.DRUG_DSG_ID = cd.drug_dsg_id
----where	source_id in (6281,6295)
----		and ddl.DOSE_CMS_VISIBLE = 1
---- (27198 row(s) affected)

--		--		CustomerID			= '',
----		PatientID			= convert(varchar,maj.memberID)+'_'+isnull(p.externalMemberID,''),	
----		NABP				= '',
----		DEA					= '',
----		RxNumber			= '',
----		FillNumber			= '',
----		NDC					= nc.ndc,
----		mc.drug_dsg_id,
----		Quantity			= mc.metricQuantity,
----		DaysSupply			= mc.daysOfSupply,
----		DateFilled			= isnull(mc.dateLastFill, mc.dateFirstFill),
----		RefillsAuthorized	= mc.refillsAuthorized,
----		CardholderNumber	= '',
----		NPI					= ''