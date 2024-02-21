/*----------------------------------------------------------------------------------------------------
 Program: 		_104-pull-mat.sql
 Title: 		OPIOID-CIPHER: Pull MAT-related (methadone, buprenorphine, naltrexone) records
				from VA and CC files
 Author: 		Vilija Joyce (vilija.joyce@va.gov)
 Last modified: 20240221
----------------------------------------------------------------------------------------------------*/
/*Select database*/
USE --ORD_XXXX_XXXXXXXXXX; --***Edit***
GO

/*----------------------------------------------------------------------------------------------------
  1) Create temporary code list tables
	 - HCPCS
	 - NDC 
	 - National DrugNameWithDose + sta3n (sites w/ OTP only - contact OMHSP for latest list)
	 - VUIDs
	 - LocalDrugSIDs created from NDC, DrugNameWithDose + sta3n, and VUID tables (for BCMA pull)
  
  Note that NDC, DrugNameWithDose+sta3n, and VUID lists will use NationalDrugSID.
----------------------------------------------------------------------------------------------------*/
/*Methadone, buprenorphine, and naltrexone-related HCPCS codes*/
DROP TABLE IF EXISTS #mat_hcpcs;
CREATE TABLE #mat_hcpcs
(
	HCPCS char(5), ind_met_hcpcs nvarchar(1), ind_bup_hcpcs nvarchar(1), ind_nal_hcpcs nvarchar(1)
)
INSERT INTO #mat_hcpcs (HCPCS,ind_met_hcpcs,ind_bup_hcpcs,ind_nal_hcpcs) 
VALUES 	
--Methadone
('G2067','1','0','0'),('G2078','1','0','0'),('H0020','1','0','0'),('J1230','1','0','0'),('S0109','1','0','0'),
--Buprenorphine
('G2068','0','1','0'),('G2069','0','1','0'),('G2070','0','1','0'),('G2071','0','1','0'),('G2072','0','1','0'),
('G2079','0','1','0'),('J0571','0','1','0'),('J0572','0','1','0'),('J0573','0','1','0'),('J0574','0','1','0'),
('J0575','0','1','0'),('J0592','0','1','0'),
--Naltrexone
('G2073','0','0','1'),('J2315','0','0','1')
		
--Ck
--SELECT * FROM #mat_hcpcs 
--20221006 n=

/*Buprenorphine and naltrexone-related NDC codes*/
DROP TABLE IF EXISTS #mat_ndc_bup_nal1;
CREATE TABLE #mat_ndc_bup_nal1
(
	NDC varchar(11), ind_bup_ndc nvarchar(1), ind_nal_ndc nvarchar(1)
)
INSERT INTO #mat_ndc_bup_nal1 (NDC,ind_bup_ndc,ind_nal_ndc)
VALUES 	
--Buprenorphine
('00054017613','1','0'), ('00054017713','1','0'), ('00054018813','1','0'), ('00054018913','1','0'), ('00093537856','1','0'), ('00093537956','1','0'), 
('00093572056','1','0'), ('00093572156','1','0'), ('00228315303','1','0'), ('00228315403','1','0'), ('00228315473','1','0'), ('00228315503','1','0'), 
('00228315567','1','0'), ('00228315573','1','0'), ('00228315603','1','0'), ('00378092393','1','0'), ('00378092493','1','0'), ('00378876716','1','0'), 
('00378876793','1','0'), ('00378876816','1','0'), ('00378876893','1','0'), ('00406192303','1','0'), ('00406192403','1','0'), ('00406800503','1','0'), 
('00406802003','1','0'), ('00490005100','1','0'), ('00490005130','1','0'), ('00490005160','1','0'), ('00490005190','1','0'), ('00781721606','1','0'), 
('00781721664','1','0'), ('00781722706','1','0'), ('00781722764','1','0'), ('00781723806','1','0'), ('00781723864','1','0'), ('00781724906','1','0'), 
('00781724964','1','0'), ('12496010001','1','0'), ('12496010002','1','0'), ('12496010005','1','0'), ('12496030001','1','0'), ('12496030002','1','0'), 
('12496030005','1','0'), ('12496120201','1','0'), ('12496120203','1','0'), ('12496120401','1','0'), ('12496120403','1','0'), ('12496120801','1','0'), 
('12496120803','1','0'), ('12496121201','1','0'), ('12496121203','1','0'), ('12496127802','1','0'), ('12496128302','1','0'), ('12496130602','1','0'), 
('12496131002','1','0'), ('16590066605','1','0'), ('16590066630','1','0'), ('16590066705','1','0'), ('16590066730','1','0'), ('16590066790','1','0'), 
('23490927003','1','0'), ('23490927006','1','0'), ('23490927009','1','0'), ('35356000407','1','0'), ('35356000430','1','0'), ('35356055530','1','0'), 
('35356055630','1','0'), ('42291017430','1','0'), ('42291017530','1','0'), ('42858050103','1','0'), ('42858050203','1','0'), ('43063018407','1','0'), 
('43063018430','1','0'), ('43063066706','1','0'), ('43063075306','1','0'), ('43598057901','1','0'), ('43598057930','1','0'), ('43598058001','1','0'), 
('43598058030','1','0'), ('43598058101','1','0'), ('43598058130','1','0'), ('43598058201','1','0'), ('43598058230','1','0'), ('47781035503','1','0'), 
('47781035511','1','0'), ('47781035603','1','0'), ('47781035611','1','0'), ('47781035703','1','0'), ('47781035711','1','0'), ('47781035803','1','0'), 
('47781035811','1','0'), ('49999039507','1','0'), ('49999039515','1','0'), ('49999039530','1','0'), ('49999063830','1','0'), ('49999063930','1','0'), 
('50090292400','1','0'), ('50268014411','1','0'), ('50268014415','1','0'), ('50268014511','1','0'), ('50268014515','1','0'), ('50383028793','1','0'), 
('50383029493','1','0'), ('50383092493','1','0'), ('50383093093','1','0'), ('52427069203','1','0'), ('52427069211','1','0'), ('52427069403','1','0'), 
('52427069411','1','0'), ('52427069803','1','0'), ('52427069811','1','0'), ('52427071203','1','0'), ('52427071211','1','0'), ('52440010014','1','0'), 
('52959030430','1','0'), ('52959074930','1','0'), ('53217013830','1','0'), ('53217024630','1','0'), ('54123011430','1','0'), ('54123090730','1','0'), 
('54123091430','1','0'), ('54123092930','1','0'), ('54123095730','1','0'), ('54123098630','1','0'), ('54569549600','1','0'), ('54569573900','1','0'), 
('54569573901','1','0'), ('54569573902','1','0'), ('54569639900','1','0'), ('54569640800','1','0'), ('54569657800','1','0'), ('54868570700','1','0'), 
('54868570701','1','0'), ('54868570702','1','0'), ('54868570703','1','0'), ('54868570704','1','0'), ('54868575000','1','0'), ('55045378403','1','0'), 
('55700014730','1','0'), ('55700018430','1','0'), ('55700030230','1','0'), ('55700030330','1','0'), ('58284010014','1','0'), ('59385001201','1','0'), 
('59385001230','1','0'), ('59385001401','1','0'), ('59385001430','1','0'), ('59385001601','1','0'), ('59385001630','1','0'), ('60429058611','1','0'), 
('60429058630','1','0'), ('60429058633','1','0'), ('60429058711','1','0'), ('60429058730','1','0'), ('60429058733','1','0'), ('60687048111','1','0'), 
('60687048121','1','0'), ('60687049211','1','0'), ('60687049221','1','0'), ('62175045232','1','0'), ('62175045832','1','0'), ('62756045983','1','0'), 
('62756046083','1','0'), ('62756096983','1','0'), ('62756097083','1','0'), ('63629402801','1','0'), ('63629403401','1','0'), ('63629403402','1','0'), 
('63629403403','1','0'), ('63629409201','1','0'), ('63874108403','1','0'), ('63874108503','1','0'), ('63874117303','1','0'), ('65162041503','1','0'), 
('65162041603','1','0'), ('66336001630','1','0'), ('68071138003','1','0'), ('68071151003','1','0'), ('68258299103','1','0'), ('68258299903','1','0'), 
('68308020230','1','0'), ('68308020830','1','0'), ('71335115403','1','0'), 
--Naltrexone
('00056001122','0','1'), ('00056001130','0','1'), ('00056001170','0','1'), ('00056007950','0','1'), ('00056008050','0','1'), ('00185003901','0','1'), 
('00185003930','0','1'), ('00406009201','0','1'), ('00406009203','0','1'), ('00406117001','0','1'), ('00406117003','0','1'), ('00555090201','0','1'), 
('00555090202','0','1'), ('00904703604','0','1'), ('16729008101','0','1'), ('16729008110','0','1'), ('42291063230','0','1'), ('43063059115','0','1'), 
('47335032683','0','1'), ('47335032688','0','1'), ('50090286600','0','1'), ('50436010501','0','1'), ('51224020630','0','1'), ('51224020650','0','1'), 
 ('51285027501','0','1'), ('51285027502','0','1'), ('52152010502','0','1'), ('52152010504','0','1'), ('52152010530','0','1'), ('54868557400','0','1'), 
 ('63459030042','0','1'), ('63629104601','0','1'), ('63629104701','0','1'), ('65694010003','0','1'), ('65694010010','0','1'), ('65757030001','0','1'), 
 ('65757030202','0','1'), ('68084029111','0','1'), ('68084029121','0','1'), ('68094085362','0','1'),  ('68115068030','0','1')
--Ck
--SELECT * FROM #mat_ndc_bup_nal1 
--20221006 n=

--Pull NatDrugSID and LocalDrugSID codes
DROP TABLE IF EXISTS #mat_ndc_bup_nal2;
SELECT d1.NationalDrugSID, d1.NationalDrugIEN, d1.Sta3n, d1.DrugNameWithoutDoseSID, d2.DrugNameWithoutDose, d1.DrugNameWithDose, d3.LocalDrugSID, d3.LocalDrugNameWithDose, d1.NationalFormularyName, d1.VADrugPrintName, d1.Strength, d1.StrengthNumeric, d1.VUID, d.NDC, d.ind_bup_ndc, d.ind_nal_ndc
INTO #mat_ndc_bup_nal2  
FROM #mat_ndc_bup_nal1 d
INNER JOIN CDWWork.Dim.LocalDrug d3
ON d.NDC=REPLACE(d3.NDC,'-','')
INNER JOIN CDWWork.Dim.NationalDrug d1
ON d1.NationalDrugSID=d3.NationalDrugSID
INNER JOIN CDWWork.Dim.DrugNameWithoutDose d2
ON d1.DrugNameWithoutDoseSID=d2.DrugNameWithoutDoseSID
WHERE d2.DrugNameWithoutDose LIKE '%BUP%' OR d2.DrugNameWithoutDose LIKE '%NALT%'

--Ck
--SELECT * FROM #mat_ndc_bup_nal2
--20221006 n=

--Create unique list of buprenorphine and naltrexone-related NationalDrugSIDs
DROP TABLE IF EXISTS #mat_ndc_bup_nal3;
SELECT DISTINCT NationalDrugSID, DrugNameWithoutDoseSID, DrugNameWithoutDose, DrugNameWithDose, StrengthNumeric, VUID, ind_bup_ndc, ind_nal_ndc 
INTO #mat_ndc_bup_nal3
FROM #mat_ndc_bup_nal2

--Ck
--SELECT * FROM #mat_ndc_bup_nal3 ORDER BY DrugNameWithoutDose
--20221006 n=

/*Methadone-related national DrugNameWithDose and sta3n v/ VA OTPs (as per OMHSP 20220427*/
DROP TABLE IF EXISTS #mat_drugname_sta3n_met1;
SELECT d1.NationalDrugSID, d1.NationalDrugIEN, d1.Sta3n, d1.DrugNameWithoutDoseSID, d2.DrugNameWithoutDose, d1.DrugNameWithDose, d3.LocalDrugSID, d3.LocalDrugNameWithDose, d1.NationalFormularyName
      , d1.VADrugPrintName, d1.Strength, d1.StrengthNumeric, d1.VUID, '1' AS ind_met_drugnamesta3n
INTO #mat_drugname_sta3n_met1  
FROM CDWWork.Dim.NationalDrug d1
INNER JOIN CDWWork.Dim.DrugNameWithoutDose d2
ON d1.DrugNameWithoutDoseSID=d2.DrugNameWithoutDoseSID
INNER JOIN CDWWork.Dim.LocalDrug d3
ON d1.NationalDrugSID=d3.NationalDrugSID
WHERE (d1.DrugNameWithDose LIKE 'METHADONE CONCENTRATED 10MG/ML SOLN,ORAL' 
		AND d1.sta3n IN ('508','512','523','526','537','539','541','553','561','578','583','618','630','635','642','646','648','650','652','657','662','678','688','689','691'))
		OR 
		(d1.DrugNameWithDose LIKE 'METHADONE HCL 1MG/ML SOLN,ORAL' 
		AND d1.sta3n IN ('596','663'))
		OR
		(d1.DrugNameWithDose LIKE 'METHADONE HCL 10MG/5ML SOLN,ORAL' 
		AND d1.sta3n IN ('621'))		

--Ck
--SELECT * FROM #mat_drugname_sta3n_met1
--20221006 n=

--Create unique list of methadone-related NationalDrugSIDs
DROP TABLE IF EXISTS #mat_drugname_sta3n_met2;
SELECT DISTINCT NationalDrugSID, DrugNameWithoutDoseSID, DrugNameWithoutDose, DrugNameWithDose, StrengthNumeric, VUID, ind_met_drugnamesta3n 
INTO #mat_drugname_sta3n_met2
FROM #mat_drugname_sta3n_met1

--Ck
--SELECT * FROM #mat_drugname_sta3n_met2
-- 2x check that methadone records exist only at sites with OTP (OK)
--20221006 n=

/*Buprenorphine and naltrexone-related VUID codes (as per OMHSP vhapalappalex.v21.med.va.gov:8080/published)*/
DROP TABLE IF EXISTS #mat_vuid_bup_nal1;
CREATE TABLE #mat_vuid_bup_nal1
(
	VUID varchar(7), ind_bup_vuid nvarchar(1), ind_nal_vuid nvarchar(1)
)
INSERT INTO #mat_vuid_bup_nal1 (VUID,ind_bup_vuid,ind_nal_vuid)
VALUES 	--Buprenorphine
('4036322','1','0'),('4032592','1','0'),('4037190','1','0'),('4034817','1','0'),('4032014','1','0'),('4033610','1','0'),('4034820','1','0'),
('4030144','1','0'),('4016378','1','0'),('4037191','1','0'),('4033611','1','0'),('4032013','1','0'),('4032591','1','0'),('4033612','1','0'),
('4035796','1','0'),('4034159','1','0'),('4030145','1','0'),('4016379','1','0'),('4016376','1','0'),('4016377','1','0'),
--Naltrexone
('4034566','0','1'),('4025730','0','1')

--Ck
--SELECT * FROM #mat_vuid_bup_nal1
--20221006 n=

--Pull NatDrugSID codes
DROP TABLE IF EXISTS #mat_vuid_bup_nal2;
SELECT d1.NationalDrugSID, d1.NationalDrugIEN, d1.Sta3n, d1.DrugNameWithoutDoseSID, d2.DrugNameWithoutDose, d1.DrugNameWithDose, d3.LocalDrugSID, d3.LocalDrugNameWithDose, d1.NationalFormularyName, d1.VADrugPrintName, d1.Strength, d1.StrengthNumeric, d1.VUID, d.ind_bup_vuid, d.ind_nal_vuid
INTO #mat_vuid_bup_nal2  
FROM #mat_vuid_bup_nal1 d
INNER JOIN CDWWork.Dim.NationalDrug d1
ON d.vuid=d1.vuid
INNER JOIN CDWWork.Dim.DrugNameWithoutDose d2
ON d1.DrugNameWithoutDoseSID=d2.DrugNameWithoutDoseSID
INNER JOIN CDWWork.Dim.LocalDrug d3
ON d1.NationalDrugSID=d3.NationalDrugSID

--Ck
--SELECT * FROM #mat_vuid_bup_nal2
--20221006 n=

--Create unique list of buprenorphine and naltrexone-related NationalDrugSIDs
DROP TABLE IF EXISTS #mat_vuid_bup_nal3;
SELECT DISTINCT NationalDrugSID, DrugNameWithoutDoseSID, DrugNameWithoutDose, DrugNameWithDose, StrengthNumeric, VUID, ind_bup_vuid, ind_nal_vuid 
INTO #mat_vuid_bup_nal3
FROM #mat_vuid_bup_nal2

--Ck
--SELECT * FROM #mat_vuid_bup_nal3
--20221006 n=

/*Methadone, buprenorphine, and naltrexone-related LocalDrugSIDs and sta3ns using NDC, drugnamewithdose+sta3n, and VUID codes*/
DROP TABLE IF EXISTS #mat_locdrugsid_met_bup_nal1;
SELECT * 
	INTO #mat_locdrugsid_met_bup_nal1 
	FROM 
	(
		SELECT DISTINCT sta3n, LocalDrugSID, LocalDrugNameWithDose, NationalDrugSID, DrugNameWithDose, DrugNameWithoutDose, StrengthNumeric, VUID, ind_bup_ndc, ind_nal_ndc, '0' AS ind_met_drugnamesta3n, '0' AS ind_bup_vuid, '0' AS ind_nal_vuid FROM #mat_ndc_bup_nal2
		UNION
		SELECT DISTINCT sta3n, LocalDrugSID, LocalDrugNameWithDose, NationalDrugSID, DrugNameWithDose, DrugNameWithoutDose, StrengthNumeric, VUID, '0' AS ind_bup_ndc, '0' AS ind_nal_ndc, ind_met_drugnamesta3n, '0' AS ind_bup_vuid, '0' AS ind_nal_vuid FROM #mat_drugname_sta3n_met1
		UNION
		SELECT DISTINCT sta3n, LocalDrugSID, LocalDrugNameWithDose,  NationalDrugSID, DrugNameWithDose, DrugNameWithoutDose, StrengthNumeric, VUID, '0' AS ind_bup_ndc, '0' AS ind_nal_ndc, '0' AS ind_met_drugnamesta3n, ind_bup_vuid, ind_nal_vuid FROM #mat_vuid_bup_nal2 
	) 
	AS FINAL

--Ck
--SELECT * FROM #mat_locdrugsid_met_bup_nal1	
--20221006 n=

--Collapse by localdrugsid and select max value for indicators
DROP TABLE IF EXISTS #mat_locdrugsid_met_bup_nal2; 
SELECT 	sta3n, LocalDrugSID, LocalDrugNameWithDose, NationalDrugSID, DrugNameWithDose, DrugNameWithoutDose,	StrengthNumeric, VUID,	
		max(ind_bup_ndc) AS ind_bup_ndc,
		max(ind_nal_ndc) AS ind_nal_ndc, 
		max(ind_met_drugnamesta3n) AS ind_met_drugnamesta3n, 
		max(ind_bup_vuid) AS ind_bup_vuid, 
		max(ind_nal_vuid) AS ind_nal_vuid
INTO #mat_locdrugsid_met_bup_nal2 
FROM #mat_locdrugsid_met_bup_nal1 
GROUP BY sta3n, LocalDrugSID, LocalDrugNameWithDose, NationalDrugSID, DrugNameWithDose, DrugNameWithoutDose, StrengthNumeric, VUID

--Ck
--SELECT * FROM #mat_locdrugsid_met_bup_nal2 ORDER BY localdrugsid
--20221006 n=

/*----------------------------------------------------------------------------------------------------
  2) Pull methadone, buprenorphine, and naltrexone-related records
	 - HCPCS
		- Outpat.WorkloadVProcedure
		- Fee.FeeServiceProvided
		- PIT.PITProfessionalClaimDetails
	 - NDC (buprenorphine and naltrexone only)
		- RxOut.RxOutpatFill
	 - National DrugNameWithDose + sta3n 
	  (sites w/ OTP only - contact OMHSP for latest list) (methadone only)
		- RxOut.RxOutpatFill
	 - VUIDs (buprenorphine and naltrexone only)
		- RxOut.RxOutpatFill
	 - LocalDrugSIDs created from NDC, DrugNameWithDose + sta3n, and VUID tables (for BCMA pull)
		- BCMA.MedicationLog
		- BCMA.BCMADispensedDrug
----------------------------------------------------------------------------------------------------*/
/*HCPCS*/
/*How many patients have at least 1 MAT-related HCPS code?*/
--VA 
DROP TABLE IF EXISTS #_104_hcpcs_va; 
SELECT 
	COH.scrssn
	,COH.PatientSID
	,COH.sta3n
	,WVP.VisitDateTime
	,WVP.VProcedureDateTime
	,DIM1.CPTCode
	,LIST.ind_met_hcpcs AS ind_met_hcpcs_va
	,LIST.ind_bup_hcpcs AS ind_bup_hcpcs_va
	,LIST.ind_nal_hcpcs AS ind_nal_hcpcs_va
	,'Outpat.WorkloadVProcedure' AS source
INTO #_104_hcpcs_va 
FROM DFLT.XXXXXX AS COH --***Edit***
INNER JOIN Src.Outpat_WorkloadVProcedure AS WVP 
	ON WVP.PatientSID = COH.PatientSID AND WVP.Sta3n = COH.sta3n
INNER JOIN CDWWork.Dim.CPT AS DIM1 
	ON DIM1.CPTSID=WVP.CPTSID 
INNER JOIN #mat_hcpcs AS LIST 
	ON LIST.HCPCS LIKE DIM1.CPTCode
WHERE 
	(
	WVP.CohortName='Primary' --***Edit***
	AND WVP.VisitDateTime>=CONVERT(datetime2(0),DATEADD(dd,0,COH.cohstart))
	AND WVP.VisitDateTime< CONVERT(datetime2(0),DATEADD(dd,365,COH.cohstart))	)

--Ck
--SELECT * from #_104_hcpcs_va ORDER BY scrssn, VisitDateTime  

--Ck
SELECT 
	COUNT(DISTINCT scrssn) AS patient_count
	,COUNT(CPTCode) AS cptcode_count
FROM #_104_hcpcs_va 
--20221006 scrssn n=
--		   hcpcs  n=

--Fee 
DROP TABLE IF EXISTS #_104_hcpcs_fee; 
SELECT 
	COH.scrssn
	,COH.PatientSID
	,COH.sta3n
	,FEE_IT.InitialTreatmentDateTime
	,DIM1.CPTCode
	,LIST.ind_met_hcpcs AS ind_met_hcpcs_fee
	,LIST.ind_bup_hcpcs AS ind_bup_hcpcs_fee
	,LIST.ind_nal_hcpcs AS ind_nal_hcpcs_fee
	,FEE_SP.AmountPaid
	,'Fee.FeeServiceProvided' AS source
INTO #_104_hcpcs_fee 
FROM DFLT.XXXXXX AS COH --***Edit***
INNER JOIN Src.Fee_FeeInitialTreatment AS FEE_IT
	ON FEE_IT.PatientSID = COH.PatientSID AND FEE_IT.Sta3n = COH.sta3n
INNER JOIN Src.Fee_FeeServiceProvided AS FEE_SP 
	ON FEE_SP.FeeInitialTreatmentSID=FEE_IT.FeeInitialTreatmentSID	
INNER JOIN CDWWork.Dim.CPT AS DIM1 
	ON DIM1.CPTSID=FEE_SP.ServiceProvidedCPTSID AND DIM1.sta3n=FEE_SP.sta3n
INNER JOIN Src.Fee_FeeAuthorization FEE_A
	ON FEE_SP.FeeAuthorizationSID = FEE_A.FeeAuthorizationSID
INNER JOIN #mat_hcpcs AS LIST 
	ON LIST.HCPCS LIKE DIM1.CPTCode
WHERE 
	(
	FEE_IT.CohortName='Primary' --***Edit***
	AND FEE_SP.CohortName='Primary' --***Edit***
	AND FEE_A.CohortName='Primary' --***Edit***
	AND FEE_IT.InitialTreatmentDateTime>=CONVERT(datetime2(0),DATEADD(dd,0,COH.cohstart))
	AND FEE_IT.InitialTreatmentDateTime< CONVERT(datetime2(0),DATEADD(dd,365,COH.cohstart))
	)

--Ck
--SELECT * from #_104_hcpcs_fee ORDER BY scrssn, InitialTreatmentDateTime 
/*
Note that some rows represent single days and others represent a month's worth of treatment. 
For those records that represent a month's worth of treatment, date will occur in the beginning 
of the month, while AmountPaid will be substantially more (e.g $200+ versus $12-$30)  
*/

SELECT 
	COUNT(DISTINCT scrssn) AS patient_count
	,COUNT(CPTCode) AS cptcode_count
FROM #_104_hcpcs_fee 
--20221006 scrssn n=
--		   hcpcs  n=

--PIT 
--Create PIT-specific cohort
DROP TABLE IF EXISTS #_104_pit_cohort; 
SELECT DISTINCT COH.scrssn
	,COH.cohstart
	,PIT.PITPatientSID
INTO #_104_pit_cohort 
FROM DFLT.XXXXXX AS COH --***Edit***
INNER JOIN Src.CohortCrosswalk AS COH2 --***Edit***
	ON COH2.scrssn=COH.scrssn
INNER JOIN Src.SVeteran_PITPatient AS PIT 
	ON PIT.MemberID=COH2.PatientSSN
WHERE 
	(
	PIT.CohortName='Primary' --***Edit***
	)

--Pull HCPCS records from PITProfessionalClaimDetails
DROP TABLE IF EXISTS #_104_hcpcs_pit; 
SELECT COH.scrssn
	,COH.cohstart
	,PITPROFC.PITClaimSID
	,PITPROFCD.PITProfessionalClaimDetailsSID
	,PITPROFCD.ServiceFromDate
	,PITPROFCD.ServiceToDate
	,DIM1.PITProcedureCode
	,DIM1.PITProcedureCodeDescription
	,LIST.ind_met_hcpcs AS ind_met_hcpcs_pit
	,LIST.ind_bup_hcpcs AS ind_bup_hcpcs_pit
	,LIST.ind_nal_hcpcs AS ind_nal_hcpcs_pit
	,ISNULL(CAST(NULLIF(PITPROFCD.PaidAmount,'NULL') AS numeric(12,2)),0) AS PaidAmount
	,PITPROFCD.PayFlag
	,PITCLAIM.CurrentFlag
	,PITCLAIM.ClaimStatus
	,DIM2.PitVAProgram
	,'PIT.PITProfessionalClaimDetails' AS source
INTO #_104_hcpcs_pit 
FROM  #_104_pit_cohort AS COH 
INNER JOIN Src.PIT_PITProfessionalClaimDetails AS PITPROFCD
	ON PITPROFCD.PITPatientSID = COH.PITPatientSID 
LEFT JOIN CDWWork.NDim.PITProcedureCode AS DIM1 
	ON DIM1.PITProcedureCodeSID=PITPROFCD.PITProcedureCodeSID
LEFT JOIN Src.PIT_PITProfessionalClaim AS PITPROFC
	ON PITPROFC.PITClaimSID=PITPROFCD.PITClaimSID 
LEFT JOIN Src.PIT_PITClaim AS PITCLAIM 
	ON PITCLAIM.PITClaimSID=PITPROFCD.PITClaimSID
LEFT JOIN CDWWork.NDim.PITVAProgram AS DIM2
	ON DIM2.PITVAProgramSID=PITCLAIM.PITVAProgramSID
INNER JOIN #mat_hcpcs AS LIST 
	ON LIST.HCPCS LIKE DIM1.PITProcedureCode	
WHERE 
	(
	PITPROFCD.CohortName='Primary' --***Edit***
	AND PITPROFC.CohortName='Primary' --***Edit***
	AND PITCLAIM.CohortName='Primary' --***Edit***
	AND PITPROFCD.ServiceFromDate>=CONVERT(datetime2(0),DATEADD(dd,0,COH.cohstart))
	AND PITPROFCD.ServiceFromDate< CONVERT(datetime2(0),DATEADD(dd,365,COH.cohstart))
	AND PITCLAIM.CurrentFlag = 'Y'
	AND PITCLAIM.ClaimStatus IN ('ACCEPTED','APPROVED','PAID')
	AND (PITPROFCD.PayFlag = 'Y' OR ISNULL(CAST(NULLIF(PITPROFCD.PaidAmount,'NULL') AS numeric(12,2)),0)>0)
	AND DIM2.PitVAProgram <> ('CHAMPVA')
	)

--Ck
--SELECT * from #_104_hcpcs_pit ORDER BY scrssn, ServiceFromDate 
--Similar to FEE, note that some rows represent single days and others represent a month's worth of treatment.

--Ck
SELECT 
	COUNT(DISTINCT scrssn) AS patient_count
	,COUNT(PITProcedureCode) AS PITProcedureCode_count
FROM #_104_hcpcs_pit 
--20221006 scrssn n=
--         hcpcs  n=

--VA, Fee, or PIT 
----Count distinct scrssn from the VA, Fee, and PIT tables
DROP TABLE IF EXISTS #_104_hcpcs_va_fee_pit; 
SELECT * 
	INTO #_104_hcpcs_va_fee_pit 
	FROM 
	(
		SELECT scrssn FROM #_104_hcpcs_va 
		UNION 
		SELECT scrssn FROM #_104_hcpcs_fee 
		UNION
		SELECT scrssn FROM #_104_hcpcs_pit 
	) 
	AS FINAL

--Ck
--SELECT * FROM #_104_hcpcs_va_fee_pit 
--20221006 n=

/*NDC*/ 
-- VA
-- For bup and nal, use ReleaseDateTime
DROP TABLE IF EXISTS #_104_ndc_va_out; 
SELECT 
	COH.scrssn
	,COH.PatientSID
	,COH.sta3n
	,RX.RxOutpatSID
	,RX.ReleaseDateTime AS DateTimeRX 
	,REPLACE(RX.NDC,'-','') AS NDC
	,RX.NationalDrugSID
	,LIST.DrugNameWithDose
	,LIST.DrugNameWithoutDose
	,LIST.VUID	
	,LIST.ind_bup_ndc AS ind_bup_ndc_va_out
	,LIST.ind_nal_ndc AS ind_nal_ndc_va_out	
	,LIST.StrengthNumeric
	,RX.QtyNumeric
	,RX.DaysSupply
	,'RxOut.RxOutpatFill' AS source
INTO #_104_ndc_va_out 
FROM DFLT.XXXXXX AS COH --***Edit***
INNER JOIN Src.RxOut_RxOutpatFill AS RX 
	ON RX.PatientSID = COH.PatientSID AND RX.Sta3n = COH.sta3n
INNER JOIN #mat_ndc_bup_nal3 AS LIST 
	ON LIST.NationalDrugSID = RX.NationalDrugSID
WHERE 
	(
	RX.CohortName='Primary' --***Edit***
	AND (RX.ReleaseDateTime >= CONVERT(datetime2(0),DATEADD(dd,0,COH.cohstart))
	AND RX.ReleaseDateTime < CONVERT(datetime2(0),DATEADD(dd,365,COH.cohstart)))
	)
;
--Ck
--SELECT * from #_104_ndc_va_out ORDER BY scrssn, DateTimeRX  
;
--Ck
SELECT 
	COUNT(DISTINCT scrssn) AS patient_count
	,COUNT(NDC) AS ndccode_count
FROM #_104_ndc_va_out 
;  
--20221006 scrssn 	n=
--		   ndc 		n=

-- Fee
-- NOTE: Reviewed MAT-related DrugName in Fee.FeePrescription. 
-- 		 For our cohort (FY16-FY18), only 2 records. Ignored for now.

-- PIT 
-- NOTE: Reviewed MAT-related ProductID (aka NDC) in PIT.PITPharmacyClaimDetails. 
-- 		 For our cohort (FY16-FY18), only 1 records. Ignored for now.

/*Methadone using national DrugNameWithDose+Sta3n (OTP) aka NationalDrugSID - per OMHSP criteria 202204*/
-- VA
-- For methadone, use FillDateTime if ReleaseDateTime is NULL (often). 
DROP TABLE IF EXISTS #_104_met_drugnamesta3n_va_out; 
SELECT 
	COH.scrssn
	,COH.PatientSID
	,COH.sta3n
	,RX.sta3n AS sta3n_rx
	,ISNULL(RX.ReleaseDateTime, RX.FillDateTime) AS DateTimeRX 
	,REPLACE(RX.NDC,'-','') AS NDC
	,RX.NationalDrugSID
	,LIST.DrugNameWithDose
	,LIST.DrugNameWithoutDose
	,LIST.VUID	
	,LIST.ind_met_drugnamesta3n AS ind_met_drugnamesta3n_va_out
	,LIST.StrengthNumeric
	,RX.QtyNumeric
	,RX.DaysSupply
	,'RxOut.RxOutpatFill' AS source
INTO #_104_met_drugnamesta3n_va_out 
FROM DFLT.XXXXXX AS COH --***Edit***
INNER JOIN Src.RxOut_RxOutpatFill AS RX 
	ON RX.PatientSID = COH.PatientSID AND RX.Sta3n = COH.sta3n
INNER JOIN #mat_drugname_sta3n_met2 AS LIST 
	ON LIST.NationalDrugSID = RX.NationalDrugSID 
WHERE 
	(
	RX.CohortName='Primary' --***Edit***
	AND (ISNULL(RX.ReleaseDateTime, RX.FillDateTime) >= CONVERT(datetime2(0),DATEADD(dd,0,COH.cohstart))
	AND ISNULL(RX.ReleaseDateTime, RX.FillDateTime) < CONVERT(datetime2(0),DATEADD(dd,365,COH.cohstart)))
	)
;
--Ck
--SELECT * from #_104_met_drugnamesta3n_va_out ORDER BY scrssn, DateTimeRX 
;
--Ck
SELECT 
	COUNT(DISTINCT scrssn) AS patient_count
	,COUNT(NationalDrugSID) AS natdrugsid_count
FROM #_104_met_drugnamesta3n_va_out  
;
--20221006 scrssn 		n=
--		   NatDrugSID 	n=

/*Buprenorphine and naltrexone using VUID*/
-- VA
-- For bup and nal, use ReleaseDateTime

DROP TABLE IF EXISTS #_104_bup_nal_vuid_va_out; 
SELECT 
	COH.scrssn
	,COH.PatientSID
	,COH.sta3n
	,RX.sta3n AS sta3n_rx
	,RX.ReleaseDateTime AS DateTimeRX 
	,REPLACE(RX.NDC,'-','') AS NDC
	,RX.NationalDrugSID
	,LIST.DrugNameWithDose
	,LIST.DrugNameWithoutDose
	,LIST.VUID	
	,LIST.ind_bup_vuid AS ind_bup_vuid_va_out
	,LIST.ind_nal_vuid AS ind_nal_vuid_va_out		
	,LIST.StrengthNumeric
	,RX.QtyNumeric
	,RX.DaysSupply
	,'RxOut.RxOutpatFill' AS source
INTO #_104_bup_nal_vuid_va_out 
FROM DFLT.XXXXXX AS COH --***Edit***
INNER JOIN Src.RxOut_RxOutpatFill AS RX 
	ON RX.PatientSID = COH.PatientSID AND RX.Sta3n = COH.sta3n
INNER JOIN CDWWork.Dim.NationalDrug AS DIM1 
	ON DIM1.NationalDrugSID = RX.NationalDrugSID
INNER JOIN #mat_vuid_bup_nal3 AS LIST 
	ON LIST.NationalDrugSID = DIM1.NationalDrugSID 
WHERE 
	(
	RX.CohortName='Primary' --***Edit***
	AND (RX.ReleaseDateTime >= CONVERT(datetime2(0),DATEADD(dd,0,COH.cohstart))
	AND RX.ReleaseDateTime < CONVERT(datetime2(0),DATEADD(dd,365,COH.cohstart)))
	)

--Ck
--SELECT * from #_104_bup_nal_vuid_va_out ORDER BY scrssn, DateTimeRX  

--Ck
SELECT 
	COUNT(DISTINCT scrssn) AS patient_count
	,COUNT(VUID) AS vuidcode_count
FROM #_104_bup_nal_vuid_va_out  

--20221006 scrssn	n=
--		   VUID 	n=

/*Methadone, buprenorphine, or naltrexone using LocalDrugSID and sta3n (as derived from NDC, drugname+sta3n, and VUID lists)*/
--VA (BCMA Medication Log)
DROP TABLE IF EXISTS #_104_met_bup_nal_va_inp;
SELECT 
	DISTINCT
	COH.scrssn
	,COH.PatientSID
	,COH.sta3n	
	,BCMA.ActionDateTime AS DateTimeRX
	,LIST.NationalDrugSID
	,LIST.DrugNameWithDose
	,LIST.DrugNameWithoutDose
	,LIST.VUID	
	,LIST.ind_met_drugnamesta3n AS ind_met_drugnamesta3n_va_inp
	,LIST.ind_bup_ndc AS ind_bup_ndc_va_inp
	,LIST.ind_bup_vuid AS ind_bup_vuid_va_inp
	,LIST.ind_nal_ndc AS ind_nal_ndc_va_inp
	,LIST.ind_nal_vuid AS ind_nal_vuid_va_inp
	,BCMA.PatientLocation
	,BCMA.OrderDosage
	,'BCMA.BCMAMedicationLog' AS source
INTO #_104_met_bup_nal_va_inp 
FROM DFLT.XXXXXX AS COH --***Edit***
INNER JOIN Src.BCMA_BCMAMedicationLog AS BCMA 
	ON BCMA.PatientSID = COH.PatientSID AND BCMA.Sta3n = COH.sta3n
INNER JOIN CDWWork.Dim.LocalDrug AS DIM1
	ON BCMA.PharmacyOrderableItemSID=DIM1.PharmacyOrderableItemSID
INNER JOIN #mat_locdrugsid_met_bup_nal2 AS LIST
	ON LIST.LocalDrugSID = DIM1.LocalDrugSID AND LIST.sta3n=DIM1.sta3n 
WHERE 
	(
	BCMA.CohortName='Primary' --***Edit***
	AND (BCMA.ActionDateTime >= CONVERT(datetime2(0),DATEADD(dd,0,COH.cohstart))
	AND BCMA.ActionDateTime < CONVERT(datetime2(0),DATEADD(dd,365,COH.cohstart)))
	AND BCMA.ActionStatus='G'
	)

-- Ck
--SELECT * FROM #_104_met_bup_nal_va_inp ORDER BY scrssn, DateTimeRX

-- Ck
SELECT 
	COUNT(DISTINCT scrssn) AS patient_count
	,COUNT(NationalDrugSID) AS natdrugsidcode_count
FROM #_104_met_bup_nal_va_inp

--20221006 scrssn			n=
--		   NationalDrugSID 	n=

--VA (BCMA Dispensed Drug)
DROP TABLE IF EXISTS #_104_met_bup_nal_va_inp2;
SELECT 
	DISTINCT
	COH.scrssn
	,COH.PatientSID
	,COH.sta3n	
	,BCMA.ActionDateTime AS DateTimeRX
	,LIST.NationalDrugSID
	,LIST.DrugNameWithDose
	,LIST.DrugNameWithoutDose
	,LIST.VUID	
	,LIST.ind_met_drugnamesta3n AS ind_met_drugnamesta3n_va_inp
	,LIST.ind_bup_ndc AS ind_bup_ndc_va_inp
	,LIST.ind_bup_vuid AS ind_bup_vuid_va_inp
	,LIST.ind_nal_ndc AS ind_nal_ndc_va_inp
	,LIST.ind_nal_vuid AS ind_nal_vuid_va_inp
	,BCMA.DosesOrdered
	,BCMA.DosesGiven
	,BCMA.UnitOfAdministration
	,'BCMA.BCMADispensedDrug' AS source
INTO #_104_met_bup_nal_va_inp2 
FROM DFLT.XXXXXX AS COH --***Edit***
INNER JOIN Src.BCMA_BCMADispensedDrug AS BCMA 
	ON BCMA.PatientSID = COH.PatientSID AND BCMA.Sta3n = COH.sta3n
INNER JOIN CDWWork.Dim.LocalDrug AS DIM1
	ON BCMA.LocalDrugSID=DIM1.LocalDrugSID and BCMA.Sta3n=DIM1.Sta3n
INNER JOIN #mat_locdrugsid_met_bup_nal2 AS LIST
	ON LIST.LocalDrugSID = DIM1.LocalDrugSID AND LIST.sta3n=DIM1.sta3n 
WHERE 
	(
	BCMA.CohortName='Primary' --***Edit***
	AND (BCMA.ActionDateTime >= CONVERT(datetime2(0),DATEADD(dd,0,COH.cohstart))
	AND BCMA.ActionDateTime < CONVERT(datetime2(0),DATEADD(dd,365,COH.cohstart)))
	)

-- Ck
--SELECT * FROM #_104_met_bup_nal_va_inp2 ORDER BY scrssn, DateTimeRX

-- Ck
SELECT 
	COUNT(DISTINCT scrssn) AS patient_count
	,COUNT(NationalDrugSID) AS natdrugsidcode_count
FROM #_104_met_bup_nal_va_inp2

--20240221 scrssn			n=
--		   NationalDrugSID 	n=
	
/*Stop code 523 - Opioid Treatment Program (OTP) in either primary or secondary position*/
/*Assume methadone*/
--VA
DROP TABLE IF EXISTS #_104_stop_va; 
SELECT 
	COH.scrssn
	,COH.PatientSID
	,COH.sta3n
	,OUTW.VisitSID
	,OUTW.VisitDateTime
	,OUTW.sta3n AS sta3n_visit
	,DIM1.StopCode
	,DIM1.StopCodeName
	,'1' AS ind_met_stop_va
	,'Outpat.Workload' AS source
INTO #_104_stop_va 
FROM DFLT.XXXXXX AS COH --***Edit***
INNER JOIN Src.Outpat_Workload AS OUTW 
	ON OUTW.PatientSID = COH.PatientSID AND OUTW.Sta3n = COH.sta3n
INNER JOIN CDWWork.Dim.StopCode AS DIM1 
	ON DIM1.StopCodeSID = OUTW.PrimaryStopCodeSID --Primary Stop Code 
		OR DIM1.StopCodeSID = OUTW.SecondaryStopCodeSID --Secondary Stop Code
INNER JOIN (
	SELECT '523' AS FILTER2
) AS FILTER1
	ON DIM1.StopCode LIKE FILTER1.[FILTER2]
WHERE 
	(
	OUTW.CohortName='Primary' --***Edit***
	AND (OUTW.VisitDateTime>=CONVERT(datetime2(0),DATEADD(dd,0,COH.cohstart))
	AND OUTW.VisitDateTime< CONVERT(datetime2(0),DATEADD(dd,365,COH.cohstart)))	
	)

--Ck
--SELECT * FROM #_104_stop_va ORDER BY scrssn, VisitDateTime 

--Ck
SELECT 
	COUNT(DISTINCT scrssn) AS patient_count
	,COUNT(StopCode) AS stopcode_count
FROM #_104_stop_va  
--20221006 scrssn 	  n= 
--		   stop + otp n=

/*----------------------------------------------------------------------------------------------------
  3) Create primary table
----------------------------------------------------------------------------------------------------*/
/* Combine records */
DROP TABLE IF EXISTS #_104_primary; 
SELECT *
	INTO #_104_primary 
	FROM
	(
		SELECT 	scrssn, 
				cast(vproceduredatetime AS date) date1, 
				NULL AS date2,
				ind_met_hcpcs_va, 
				ind_bup_hcpcs_va, 
				ind_nal_hcpcs_va, 
				'0' AS ind_met_hcpcs_fee, 
				'0' AS ind_bup_hcpcs_fee,
				'0' AS ind_nal_hcpcs_fee,
				'0' AS ind_met_hcpcs_pit,
				'0' AS ind_bup_hcpcs_pit,
				'0' AS ind_nal_hcpcs_pit,	
				'0' AS ind_bup_ndc_va_out,
				'0' AS ind_nal_ndc_va_out,				
				'0' AS ind_met_drugnamesta3n_va_out,
				'0' AS ind_bup_vuid_va_out,
				'0' AS ind_nal_vuid_va_out,
				'0' AS ind_met_drugnamesta3n_va_inp,
				'0' AS ind_bup_ndc_va_inp,
				'0' AS ind_bup_vuid_va_inp,
				'0' AS ind_nal_ndc_va_inp,
				'0' AS ind_nal_vuid_va_inp,				
				'0' AS ind_met_stop_va				
			FROM #_104_hcpcs_va 
		UNION 
		SELECT 	scrssn, 
				cast(InitialTreatmentDateTime AS date) date1,
				NULL AS date2,
				'0' AS ind_met_hcpcs_va, 
				'0' AS ind_bup_hcpcs_va,
				'0' AS ind_nal_hcpcs_va,
				ind_met_hcpcs_fee, 
				ind_bup_hcpcs_fee, 
				ind_nal_hcpcs_fee, 
				'0' AS ind_met_hcpcs_pit,
				'0' AS ind_bup_hcpcs_pit,
				'0' AS ind_nal_hcpcs_pit,
				'0' AS ind_bup_ndc_va_out,
				'0' AS ind_nal_ndc_va_out,				
				'0' AS ind_met_drugnamesta3n_va_out,
				'0' AS ind_bup_vuid_va_out,
				'0' AS ind_nal_vuid_va_out,
				'0' AS ind_met_drugnamesta3n_va_inp,
				'0' AS ind_bup_ndc_va_inp,
				'0' AS ind_bup_vuid_va_inp,
				'0' AS ind_nal_ndc_va_inp,
				'0' AS ind_nal_vuid_va_inp,				
				'0' AS ind_met_stop_va				
			FROM #_104_hcpcs_fee 
		UNION
		SELECT 	scrssn, 
				cast(ServiceFromDate AS date) date1, 
				cast(ServiceToDate AS date) date2,
				'0' AS ind_met_hcpcs_va, 
				'0' AS ind_bup_hcpcs_va,
				'0' AS ind_nal_hcpcs_va,
				'0' AS ind_met_hcpcs_fee,
				'0' AS ind_bup_hcpcs_fee,
				'0' AS ind_nal_hcpcs_fee,
				ind_met_hcpcs_pit, 
				ind_bup_hcpcs_pit, 
				ind_nal_hcpcs_pit,	
				'0' AS ind_bup_ndc_va_out,
				'0' AS ind_nal_ndc_va_out,
				'0' AS ind_met_drugnamesta3n_va_out,
				'0' AS ind_bup_vuid_va_out,
				'0' AS ind_nal_vuid_va_out,
				'0' AS ind_met_drugnamesta3n_va_inp,
				'0' AS ind_bup_ndc_va_inp,
				'0' AS ind_bup_vuid_va_inp,
				'0' AS ind_nal_ndc_va_inp,
				'0' AS ind_nal_vuid_va_inp,				
				'0' AS ind_met_stop_va
			FROM #_104_hcpcs_pit 
		UNION
		SELECT	scrssn,
				cast(DateTimeRX AS date) date1,
				NULL AS date2,
				'0' AS ind_met_hcpcs_va, 
				'0' AS ind_bup_hcpcs_va,
				'0' AS ind_nal_hcpcs_va,
				'0' AS ind_met_hcpcs_fee,
				'0' AS ind_bup_hcpcs_fee,
				'0' AS ind_nal_hcpcs_fee,
				'0' AS ind_met_hcpcs_pit,
				'0' AS ind_bup_hcpcs_pit,
				'0' AS ind_nal_hcpcs_pit,				
				ind_bup_ndc_va_out,
				ind_nal_ndc_va_out,
				'0' AS ind_met_drugnamesta3n_va_out,
				'0' AS ind_bup_vuid_va_out,
				'0' AS ind_nal_vuid_va_out,
				'0' AS ind_met_drugnamesta3n_va_inp,
				'0' AS ind_bup_ndc_va_inp,
				'0' AS ind_bup_vuid_va_inp,
				'0' AS ind_nal_ndc_va_inp,
				'0' AS ind_nal_vuid_va_inp,				
				'0' AS ind_met_stop_va				
				FROM #_104_ndc_va_out 
		UNION
		SELECT 	scrssn, 
				cast(DateTimeRX AS date) date1, 
				NULL AS date2,
				'0' AS ind_met_hcpcs_va, 
				'0' AS ind_bup_hcpcs_va,
				'0' AS ind_nal_hcpcs_va,
				'0' AS ind_met_hcpcs_fee,
				'0' AS ind_bup_hcpcs_fee,
				'0' AS ind_nal_hcpcs_fee,
				'0' AS ind_met_hcpcs_pit,
				'0' AS ind_bup_hcpcs_pit,
				'0' AS ind_nal_hcpcs_pit,
				'0' AS ind_bup_ndc_va_out,
				'0' AS ind_nal_ndc_va_out,	
				ind_met_drugnamesta3n_va_out,
				'0' AS ind_bup_vuid_va_out,
				'0' AS ind_nal_vuid_va_out,
				'0' AS ind_met_drugnamesta3n_va_inp,
				'0' AS ind_bup_ndc_va_inp,
				'0' AS ind_bup_vuid_va_inp,
				'0' AS ind_nal_ndc_va_inp,
				'0' AS ind_nal_vuid_va_inp,				
				'0' AS ind_met_stop_va				
			FROM #_104_met_drugnamesta3n_va_out 
		UNION
		SELECT 	scrssn, 
				cast(DateTimeRX AS date) date1, 
				NULL AS date2,
				'0' AS ind_met_hcpcs_va, 
				'0' AS ind_bup_hcpcs_va,
				'0' AS ind_nal_hcpcs_va,
				'0' AS ind_met_hcpcs_fee,
				'0' AS ind_bup_hcpcs_fee,
				'0' AS ind_nal_hcpcs_fee,
				'0' AS ind_met_hcpcs_pit,
				'0' AS ind_bup_hcpcs_pit,
				'0' AS ind_nal_hcpcs_pit,
				'0' AS ind_bup_ndc_va_out,
				'0' AS ind_nal_ndc_va_out,					
				'0' AS ind_met_drugnamesta3n_va_out,
				ind_bup_vuid_va_out,
				ind_nal_vuid_va_out,
				'0' AS ind_met_drugnamesta3n_va_inp,
				'0' AS ind_bup_ndc_va_inp,
				'0' AS ind_bup_vuid_va_inp,
				'0' AS ind_nal_ndc_va_inp,
				'0' AS ind_nal_vuid_va_inp,				
				'0' AS ind_met_stop_va					
			FROM #_104_bup_nal_vuid_va_out 	
		UNION
		SELECT 	scrssn, 
				cast(DateTimeRX AS date) date1, 
				NULL AS date2,
				'0' AS ind_met_hcpcs_va, 
				'0' AS ind_bup_hcpcs_va,
				'0' AS ind_nal_hcpcs_va,
				'0' AS ind_met_hcpcs_fee,
				'0' AS ind_bup_hcpcs_fee,
				'0' AS ind_nal_hcpcs_fee,
				'0' AS ind_met_hcpcs_pit,
				'0' AS ind_bup_hcpcs_pit,
				'0' AS ind_nal_hcpcs_pit,
				'0' AS ind_bup_ndc_va_out,
				'0' AS ind_nal_ndc_va_out,	
				'0' AS ind_met_drugnamesta3n_va_out,
				'0' AS ind_bup_vuid_va_out,
				'0' AS ind_nal_vuid_va_out,
				ind_met_drugnamesta3n_va_inp,
				ind_bup_ndc_va_inp,
				ind_bup_vuid_va_inp,
				ind_nal_ndc_va_inp,
				ind_nal_vuid_va_inp,				
				'0' AS ind_met_stop_va					
			FROM #_104_met_bup_nal_va_inp 	
		UNION
		SELECT 	scrssn, 
				cast(DateTimeRX AS date) date1, 
				NULL AS date2,
				'0' AS ind_met_hcpcs_va, 
				'0' AS ind_bup_hcpcs_va,
				'0' AS ind_nal_hcpcs_va,
				'0' AS ind_met_hcpcs_fee,
				'0' AS ind_bup_hcpcs_fee,
				'0' AS ind_nal_hcpcs_fee,
				'0' AS ind_met_hcpcs_pit,
				'0' AS ind_bup_hcpcs_pit,
				'0' AS ind_nal_hcpcs_pit,
				'0' AS ind_bup_ndc_va_out,
				'0' AS ind_nal_ndc_va_out,	
				'0' AS ind_met_drugnamesta3n_va_out,
				'0' AS ind_bup_vuid_va_out,
				'0' AS ind_nal_vuid_va_out,
				ind_met_drugnamesta3n_va_inp,
				ind_bup_ndc_va_inp,
				ind_bup_vuid_va_inp,
				ind_nal_ndc_va_inp,
				ind_nal_vuid_va_inp,				
				'0' AS ind_met_stop_va					
			FROM #_104_met_bup_nal_va_inp2			
		UNION	
		SELECT 	scrssn, 
				cast(VisitDateTime AS date) date1, 
				NULL AS date2,
				'0' AS ind_met_hcpcs_va, 
				'0' AS ind_bup_hcpcs_va,
				'0' AS ind_nal_hcpcs_va,
				'0' AS ind_met_hcpcs_fee,
				'0' AS ind_bup_hcpcs_fee,
				'0' AS ind_nal_hcpcs_fee,
				'0' AS ind_met_hcpcs_pit,
				'0' AS ind_bup_hcpcs_pit,
				'0' AS ind_nal_hcpcs_pit,
				'0' AS ind_bup_ndc_va_out,
				'0' AS ind_nal_ndc_va_out,				
				'0' AS ind_met_drugnamesta3n_va_out,
				'0' AS ind_bup_vuid_va_out,
				'0' AS ind_nal_vuid_va_out,
				'0' AS ind_met_drugnamesta3n_va_inp,
				'0' AS ind_bup_ndc_va_inp,
				'0' AS ind_bup_vuid_va_inp,
				'0' AS ind_nal_ndc_va_inp,
				'0' AS ind_nal_vuid_va_inp,				
				ind_met_stop_va				
			FROM #_104_stop_va 	
	)
	AS FINAL  

--CK
--SELECT * FROM #_104_primary ORDER BY scrssn, date1 
--20240221 n=

--Note: Dupes by scrssn and date1. Records may have more than 1 end date and more than 1 source (e.g. Fee and PIT)

--Collapse by scrssn and start date and selecting max value for end date and source flags
DROP TABLE IF EXISTS #_104_primaryb; 
SELECT 	scrssn, 
		date1, 
		max(date2) AS date2,
		max(ind_met_hcpcs_va) AS ind_met_hcpcs_va, 
		max(ind_met_hcpcs_fee) AS ind_met_hcpcs_fee, 
		max(ind_met_hcpcs_pit) AS ind_met_hcpcs_pit, 
		max(ind_met_drugnamesta3n_va_out) AS ind_met_drugnamesta3n_va_out,
		max(ind_met_drugnamesta3n_va_inp) AS ind_met_drugnamesta3n_va_inp,
		max(ind_met_stop_va) AS ind_met_stop_va,
		max(ind_bup_hcpcs_va) AS ind_bup_hcpcs_va,
		max(ind_bup_hcpcs_fee) AS ind_bup_hcpcs_fee,
		max(ind_bup_hcpcs_pit) AS ind_bup_hcpcs_pit,
		max(ind_bup_ndc_va_out) AS ind_bup_ndc_va_out,
		max(ind_bup_vuid_va_out) AS ind_bup_vuid_va_out,
		max(ind_bup_ndc_va_inp) AS ind_bup_ndc_va_inp,
		max(ind_bup_vuid_va_inp) AS ind_bup_vuid_va_inp,
		max(ind_nal_hcpcs_va) AS ind_nal_hcpcs_va,
		max(ind_nal_hcpcs_fee) AS ind_nal_hcpcs_fee,
		max(ind_nal_hcpcs_pit) AS ind_nal_hcpcs_pit,
		max(ind_nal_ndc_va_out) AS ind_nal_ndc_va_out,
		max(ind_nal_vuid_va_out) AS ind_nal_vuid_va_out,
		max(ind_nal_ndc_va_inp) AS ind_nal_ndc_va_inp,
		max(ind_nal_vuid_va_inp) AS ind_nal_vuid_va_inp
INTO #_104_primaryb 
FROM #_104_primary 
GROUP BY scrssn, date1

--Ck
--SELECT * FROM #_104_primaryb ORDER BY scrssn, date1 
--20221006 n=

--Ck
SELECT 
	COUNT(DISTINCT scrssn) AS patient_count
FROM #_104_primaryb  
--20221006 scrssn n=
--Note: Records can represent a single day or a range of days. See date1 and date2. 

--Create 3 additional indicators (ind_met, ind_bup, ind_nal)
DROP TABLE IF EXISTS #_104_primaryc; 
SELECT 	scrssn, 
		date1, 
		date2,
		case when ind_met_hcpcs_va=1 or ind_met_hcpcs_fee=1 or ind_met_hcpcs_pit=1 
			or ind_met_drugnamesta3n_va_out=1 or ind_met_drugnamesta3n_va_inp=1 or ind_met_stop_va=1 
			then 1 else 0 end AS ind_met,
		case when ind_bup_hcpcs_va=1 or ind_bup_hcpcs_fee=1 or ind_bup_hcpcs_pit=1 
			or ind_bup_ndc_va_out=1 or ind_bup_vuid_va_out= 1 or ind_bup_ndc_va_inp=1 or ind_bup_vuid_va_inp=1
			then 1 else 0 end AS ind_bup,
		case when ind_nal_hcpcs_va=1 or ind_nal_hcpcs_fee=1 or ind_nal_hcpcs_pit=1 
			or ind_nal_ndc_va_out=1 or ind_nal_vuid_va_out=1 or ind_nal_ndc_va_inp=1 or ind_nal_vuid_va_inp=1
			then 1 else 0 end AS ind_nal,
		ind_met_hcpcs_va, 
		ind_met_hcpcs_fee, 
		ind_met_hcpcs_pit, 
		ind_met_drugnamesta3n_va_out,
		ind_met_drugnamesta3n_va_inp,
		ind_met_stop_va,
		ind_bup_hcpcs_va,
		ind_bup_hcpcs_fee,
		ind_bup_hcpcs_pit,
		ind_bup_ndc_va_out,
		ind_bup_vuid_va_out,
		ind_bup_ndc_va_inp,
		ind_bup_vuid_va_inp,
		ind_nal_hcpcs_va,
		ind_nal_hcpcs_fee,
		ind_nal_hcpcs_pit,
		ind_nal_ndc_va_out,
		ind_nal_vuid_va_out,
		ind_nal_ndc_va_inp,
		ind_nal_vuid_va_inp
INTO #_104_primaryc 
FROM #_104_primaryb 

--Ck
--SELECT * FROM #_104_primaryc ORDER BY scrssn, date1 
--20221006 n=

--Ck
SELECT 
	ind_met, ind_bup, ind_nal, count(ind_met) AS freq 
FROM #_104_primaryc 
GROUP BY ind_met, ind_bup, ind_nal
ORDER BY count(ind_met) DESC

/*
20221005
ind_met	ind_bup	ind_nal	freq

*/

/*Save as final file*/
DROP TABLE IF EXISTS DFLT._104_primary  --***Edit***
SELECT * 
INTO DFLT._104_primary --***Edit***
FROM #_104_primaryc  
--20221006 n=

/*----------------------------------------------------------------------------------------------------
  4) Create supplemental tables 
	 - #1: Drug Details
	 - #2: Proportion Days Covered (PDC)
	 Notes: 
	 Code does NOT include MAT records pulled using HCPCS codes, from VA inpatient, nor from community care data.
	
	 PDC table 
		- Deals with overlapping days supply for same drug versus different drugs
			- Same drug overlap? Assume pt finishes current fill before starting the refill.
			- Different drug overlap? Assume pt will start new medication immediately.
		- Uses end of FY as last date in treatment period. Does NOT account for unenrollment or death.
		- Edit date range of interest prior to using.
----------------------------------------------------------------------------------------------------*/
/*Supplemental Table #1 - Drug details*/
--Merge NDC, drugnamesid+sta3n, and VUID tables
DROP TABLE IF EXISTS #_104_supp1_1; 
SELECT * 
	INTO #_104_supp1_1 
	FROM 
	(
		SELECT scrssn, DateTimeRX, cast(DateTimeRX AS date) date1, 
	row_number() OVER (PARTITION BY scrssn, DATEADD(DAY, DATEDIFF(DAY, 0, DateTimeRX), 0) ORDER BY scrssn, DateTimeRX, DrugNameWithDose, DrugNameWithoutDose) AS _n_,
    NDC, DrugNameWithDose, DrugNameWithoutDose, StrengthNumeric, QtyNumeric, DaysSupply FROM #_104_ndc_va_out 
		UNION
		SELECT scrssn, DateTimeRX, cast(DateTimeRX AS date) date1, 
	row_number() OVER (PARTITION BY scrssn, DATEADD(DAY, DATEDIFF(DAY, 0, DateTimeRX), 0) ORDER BY scrssn, DateTimeRX, DrugNameWithDose, DrugNameWithoutDose) AS _n_,
    NDC, DrugNameWithDose, DrugNameWithoutDose, StrengthNumeric, QtyNumeric, DaysSupply FROM #_104_met_drugnamesta3n_va_out 
		UNION
		SELECT scrssn, DateTimeRX, cast(DateTimeRX AS date) date1, 
	row_number() OVER (PARTITION BY scrssn, DATEADD(DAY, DATEDIFF(DAY, 0, DateTimeRX), 0) ORDER BY scrssn, DateTimeRX, DrugNameWithDose, DrugNameWithoutDose) AS _n_,
    NDC, DrugNameWithDose, DrugNameWithoutDose, StrengthNumeric, QtyNumeric, DaysSupply FROM #_104_bup_nal_vuid_va_out 
	) 
	AS FINAL

SELECT DISTINCT * FROM #_104_supp1_1 ORDER BY scrssn, date1
--20221006 n=

--Ck, incl max drugs on any given day
--SELECT * FROM #_104_supp1_1 ORDER BY scrssn, DateTimeRX 
SELECT MAX(_n_) AS max_n_ FROM #_104_supp1_1  
--20221006 n=

--Summarize to quantify dose for those with missing StrengthNumeric
DROP TABLE IF EXISTS #_104_supp1_1b; 
SELECT 
	DISTINCT DrugNameWithDose AS DrugNameWithDose
INTO #_104_supp1_1b
FROM #_104_supp1_1
WHERE StrengthNumeric IS NULL
--Ck
--SELECT * FROM #_104_supp1_1b ORDER BY DrugNameWithDose

--Assign dose (uses info from 2016-2018 files)
DROP TABLE IF EXISTS #_104_supp1_2; 
SELECT scrssn, DateTimeRX, date1, _n_, NDC, DrugNameWithDose
	,DrugNameWithoutDose
	,StrengthNumeric
	 ,CASE 
		WHEN DrugNameWithDose LIKE 'BUPRENORPHINE 12%' THEN 12
		WHEN DrugNameWithDose LIKE 'BUPRENORPHINE 2.1%' THEN 2.1
		WHEN DrugNameWithDose LIKE 'BUPRENORPHINE 2%' THEN 2
		WHEN DrugNameWithDose LIKE 'BUPRENORPHINE 300%' THEN 300
		WHEN DrugNameWithDose LIKE 'BUPRENORPHINE 4%' THEN 4
		WHEN DrugNameWithDose LIKE 'BUPRENORPHINE 8%' THEN 8
		WHEN DrugNameWithDose LIKE 'BUPRENORPHINE HCL 1.4%' THEN 1.4
		WHEN DrugNameWithDose LIKE 'BUPRENORPHINE HCL 11.4%' THEN 11.4
		WHEN DrugNameWithDose LIKE 'BUPRENORPHINE HCL 2%' THEN 2
		WHEN DrugNameWithDose LIKE 'BUPRENORPHINE HCL 5.7%' THEN 5.7
		WHEN DrugNameWithDose LIKE 'BUPRENORPHINE HCL 8%' THEN 8
		WHEN DrugNameWithDose LIKE 'NALTREXONE (EQV-REVIA) 50%' THEN 50
		WHEN DrugNameWithDose LIKE 'NALTREXONE (EQV-VIVITROL) 380MG%' THEN 380
	ELSE StrengthNumeric
	END AS StrengthNumeric2
	,QtyNumeric 
	,DaysSupply
	INTO #_104_supp1_2 
	FROM #_104_supp1_1 
--Ck
--SELECT * FROM #_104_supp1_2 ORDER BY scrssn, DateTimeRX
--SELECT * FROM #_104_supp1_2 where StrengthNumeric is null ORDER BY scrssn, DateTimeRX 
--20221006 n=

/*Save as final file*/
DROP TABLE IF EXISTS DFLT._104_supp_rx1  --***Edit***
SELECT * 
INTO DFLT._104_supp_rx1 --***Edit***
FROM #_104_supp1_2 
--20221006 n=

/* Supplemental Table #2 - Proportion Days Covered (PDC)*/
-- ***Edit*** Our year of interest is FY17. Trim dataset to include only the rxs that were released/filled in FY17.
DROP TABLE IF EXISTS #_104_supp2_pdc;
SELECT 	scrssn, 
		CONVERT(date, DateTimeRX) AS RelFillDate,
		DrugNameWithoutDose,
		DaysSupply
INTO #_104_supp2_pdc  
FROM #_104_supp1_2
WHERE CONVERT(date, DateTimeRX)>='2016-10-01' AND CONVERT(date, DateTimeRX)<='2017-09-30' --***Edit***
	
--Ck 
--SELECT * FROM #_104_supp2_pdc
--20221006 n= 

-- Create a table with all dates in the FY of interest
DROP TABLE IF EXISTS #_104_dates;
CREATE TABLE #_104_dates (dt DATE);
INSERT INTO #_104_dates
SELECT
  DATEADD(day, n - 1, '2016-10-01') --***Edit***
FROM (
  SELECT
	TOP (DATEDIFF(DAY, '2016-10-01', '2017-09-30') + 1) n = ROW_NUMBER() OVER (ORDER BY [object_id]) FROM sys.all_objects --***Edit***
  ) n;

--Ck 
--SELECT * FROM #_104_dates;
--20221006 n=

-- 1) Determine running days supply and first rx release/fill date
DROP TABLE IF EXISTS #_104_supp2_pdc_final;

WITH _104_days_supply_ytd AS (
SELECT 	*, 
		SUM(DaysSupply) OVER (PARTITION BY scrssn, DrugNameWithoutDose ORDER BY RelFillDate) AS days_supply_ytd,
		MIN(RelFillDate) OVER (PARTITION BY scrssn, DrugNameWithoutDose) AS RelFillDate_first 
FROM #_104_supp2_pdc
),
-- Ck
-- SELECT * FROM _104_days_supply_ytd;

-- 2) Calculate running days supply prior to rx using the LAG() window function.
_104_days_supply_ytd_prior AS (
SELECT 	*, 
		COALESCE(LAG(days_supply_ytd) OVER (PARTITION BY scrssn, DrugNameWithoutDose ORDER BY RelFillDate), 0) AS days_supply_ytd_prior
FROM _104_days_supply_ytd
),
-- Ck
-- SELECT * FROM _104_days_supply_ytd_prior;

-- 3) Calculate any remaining days supply prior to the rx by subtracting the last date with days supply prior to the rx claims 
--    from the release/fill date on the rx claim. Remaining days supply prior to the rx claim cannot be less than 0.
_104_days_supply_remaining AS ( 
SELECT 	*,
		CASE WHEN DATEDIFF(DAY, DATEADD(DAY, days_supply_ytd_prior, RelFillDate_first), RelFillDate) > 0 
		THEN DATEDIFF(DAY, DATEADD(DAY, days_supply_ytd_prior, RelFillDate_first), RelFillDate)
		ELSE 0 END AS days_supply_remaining
FROM _104_days_supply_ytd_prior
),
-- Ck
-- SELECT * FROM _104_days_supply_remaining;

-- 4) Bring forward the remaining days supply from prior rx claims to subsequent rx claims 
_104_days_supply_remaining_ytd AS (
SELECT 	*,
		MAX(days_supply_remaining) OVER(PARTITION BY scrssn, DrugNameWithoutDose ORDER BY RelFillDate) AS days_supply_remaining_ytd
FROM _104_days_supply_remaining
),
-- Ck
-- SELECT * FROM _104_days_supply_remaining_ytd;

-- 5) Calculate the adjusted start date for the rx claim by adding the running days supply prior to the rx claim 
--    to any remaining days supply from prior claims and then adding first release/fill date for the drug.
_104_RelFillDate_adjust AS (
SELECT 	*,
		DATEADD(DAY, days_supply_ytd_prior + days_supply_remaining_ytd, RelFillDate_first) AS RelFillDate_adjust
FROM _104_days_supply_remaining_ytd
),
-- Ck
-- SELECT * FROM _104_RelFillDate_adjust;

-- 6) Calculate the date of the last days supply for the rx claim by adding the days supply to the adjusted start date.
--    Truncate if days supply extends beyond the end of the measurement year(s).
_104_date_last_dose AS (
SELECT	 *, 
		CASE WHEN DATEADD(DAY, DaysSupply + 1, RelFillDate_adjust) > '2017-09-30' THEN DATEDIFF(DAY, RelFillDate_adjust, '2017-09-30') + 1 --***Edit***
			ELSE DaysSupply END AS days_supply_adjust, 
		CASE WHEN DATEADD(DAY, DaysSupply + 1, RelFillDate_adjust) > '2017-09-30' THEN '2017-09-30' --***Edit***
			ELSE DATEADD(DAY, DaysSupply - 1, RelFillDate_adjust) END AS date_last_dose 
FROM _104_RelFillDate_adjust
),
-- Ck
-- SELECT * FROM _104_date_last_dose;

-- 7) Calculate the index rx start date aka the first fill during the measurement period.
--    Use it to calculate the days in the treatment period.
_104_index_rx_start_date AS (
SELECT 	*,
		MIN(RelFillDate) OVER (PARTITION BY scrssn) AS index_rx_start_date
FROM _104_date_last_dose
WHERE days_supply_adjust > 0
),
-- Ck
-- SELECT * FROM _104_index_rx_start_date;

-- 8) Calculate days in treatment period by subtracting the index_rx_start_date from the last day 
--    in the measurement period. Assumes patients are continuously enrolled through end of measurement period.
--    If patient unenrolls or dies during measurement year, the date of unenrollment (or death) should be used 
--    as the end of the treatment period.
_104_days_in_tx_period AS (
SELECT *, 
		DATEDIFF(DAY, index_rx_start_date, '2017-09-30') + 1 AS days_in_tx_period --***Edit***
FROM _104_index_rx_start_date
),
-- Ck
--SELECT * FROM _104_days_in_tx_period;

-- 9) Full join between list of dates in time period of interest and rx claims. 
--    Limit to dates between the adjusted release/fill date and date of last dose.
--    Keep unique dates between patient and drug. Count unique drugs covered on each date for each patient.
_104_drugs_covered AS (
SELECT 	scrssn, 
		days_in_tx_period, 
		dt, 
		COUNT(*) AS drugs_covered 
FROM (	SELECT DISTINCT	scrssn, 
						days_in_tx_period, 
						DrugNameWithoutDose, 
						dt 
		FROM _104_days_in_tx_period, #_104_dates 
	WHERE dt BETWEEN RelFillDate_adjust AND date_last_dose) t1
GROUP BY	scrssn, 
			days_in_tx_period, 
			dt
),
-- Ck
--SELECT * FROM _104_drugs_covered;

-- 10) Calculate if covered by at least 1 drug on each day in the period and sum up days covered.
_104_days_covered AS (
SELECT 	scrssn, 
		days_in_tx_period, 
		SUM(day_covered) AS days_covered 
FROM (SELECT 
	  *, 
	  CASE WHEN drugs_covered > 0 THEN 1 ELSE 0 END AS day_covered
	FROM _104_drugs_covered) t1
GROUP BY 	scrssn, 
			days_in_tx_period
)
-- Ck
-- SELECT * FROM _104_days_covered;

-- 11) Calculate the proportion days covered (PDC) by dividing the days covered by the days in the treatment period.
--     Format as a percent (%).
SELECT 
  *, 
  FORMAT(CAST(days_covered AS FLOAT) / CAST(days_in_tx_period AS FLOAT), 'P') AS pdc 
  INTO #_104_supp2_pdc_final
FROM _104_days_covered
-- Ck
--SELECT * FROM #_104_supp2_pdc_final ORDER BY scrssn;
--20221006 n=

/*Save as final file*/
DROP TABLE IF EXISTS DFLT._104_supp_rx2  --***Edit***
SELECT * 
INTO DFLT._104_supp_rx2 --***Edit***
FROM #_104_supp2_pdc_final 
--20221006 n=
