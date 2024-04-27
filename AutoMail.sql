
/*

	EXEC BGM.#BGM_SP_Vendor_BG_Expiry_List @intCompanyCode = 1,
	@intCECode = 1, @strCEDCode = '1535'

	SELECT * FROM EIP40GLM.MDM.GEN_M_Cluster_Element_Details 
	WHERE MCLED_Company_Code = 1 AND MCLED_CE_Code = 1
*/

CREATE OR ALTER PROCEDURE BGM.#BGM_SP_Vendor_BG_Expiry_List
(  
	@intCompanyCode				INT				= NULL,	
	@intDTCode					INT				= NULL,
	@Accounting_centre			Varchar(1000)	= NULL,
	@Region_Code				Varchar(15)		= Null,
	@intCECode					INT				= NULL,
	@strCEDCode					Varchar(15)     = NULL,
	@intExpiryReportDays		INT				= 20
	--@SuppLier_Subcontractor		varchar(15) = 'Both',---'Supplier'
)  
AS  
BEGIN               
Set NoCount On          
  
  /*
		Modified	By	:Ganesan K
		Modified	On	:03-Apr-2018.
		Purpose			:New columns included based on SSC Enchancements;

		Modified	By	:Ganesan K
		Modified	On	:29-May-2018.
		Purpose			:CE & CED Code column parameter input parameters included;
  */
       
	DECLARE @dtFromDate DATE, @dtToDate DATE, @intCEDCode INT

	DECLARE @tblAccountingCentres TABLE(Temp_AC_Code CHAR(8))
	DECLARE @strMailTo VARCHAR(500)
		
	SET @dtFromDate = GETDATE();
	SET @dtToDate = DATEADD(DAY, @intExpiryReportDays, @dtFromDate);
	
	CREATE TABLE #Temp_BGM_BG_Expiry_Status
	(
		Temp_VBGR_Number VARCHAR(30), Temp_AC_Code VARCHAR(8), Temp_Company_Code INT, 
		Temp_BA_Code VARCHAR(15), Temp_Currency_Code INT, Temp_BA_Name VARCHAR(120), 
		Temp_Job_Code VARCHAR(8), Temp_BG_Value MONEY, Temp_BG_Type_Code INT,
		Temp_BG_Valid_Upto DATE, Temp_BG_Claim_Upto DATE, Temp_BG_Valid_Claim_Upto DATE, 
		Temp_BG_Number VARCHAR(100), Temp_BG_Type VARCHAR(200), Temp_Document_Number VARCHAR(30), 
		Temp_Payment_Term VARCHAR(150)
	);
	
	CREATE TABLE #Temp_BGM_Expiry_Document_List
	(
		Temp_Ex_VBGR_Number			VARCHAR(30), 
		Temp_Ex_PO_Number			VARCHAR(30), 
		Temp_Ex_WO_Number			VARCHAR(30), 
		Temp_Ex_Invoice_Regn_Number VARCHAR(30),
		Temp_Ex_DT_Code				INT
	);

	CREATE TABLE #Temp_BGM_Expiry_Job_List(Temp_Ex_Job_Code CHAR(8))

	SET @intCEDCode = @strCEDCode;

	IF @intDTCode = 0 
		SET @intDTCode = NULL;

	IF (@intCECode = 1 OR @intCECode IS NULL) 
	BEGIN
		INSERT INTO #Temp_BGM_Expiry_Job_List(Temp_Ex_Job_Code)
		SELECT LJCE_Job_Code 
		FROM EIP40GLM.MDM.GEM_L_Job_Cluster_Elements
		WHERE LJCE_Company_Code = @intCompanyCode
	END
	ELSE IF @intCECode = 2
	BEGIN
		INSERT INTO #Temp_BGM_Expiry_Job_List(Temp_Ex_Job_Code)
		SELECT LJCE_Job_Code 
		FROM EIP40GLM.MDM.GEM_L_Job_Cluster_Elements
		WHERE LJCE_IC_Code = @intCEDCode; 
	END
	ELSE IF @intCECode = 3
	BEGIN
		INSERT INTO #Temp_BGM_Expiry_Job_List(Temp_Ex_Job_Code)
		SELECT LJCE_Job_Code 
		FROM EIP40GLM.MDM.GEM_L_Job_Cluster_Elements
		WHERE LJCE_SBG_Code = @intCEDCode; 
	END
	ELSE IF @intCECode = 4
	BEGIN
		INSERT INTO #Temp_BGM_Expiry_Job_List(Temp_Ex_Job_Code)
		SELECT LJCE_Job_Code 
		FROM EIP40GLM.MDM.GEM_L_Job_Cluster_Elements
		WHERE LJCE_BU_Code = @intCEDCode; 
	END
	ELSE IF @intCECode = 5
	BEGIN
		INSERT INTO #Temp_BGM_Expiry_Job_List(Temp_Ex_Job_Code)
		SELECT LJCE_Job_Code 
		FROM EIP40GLM.MDM.GEM_L_Job_Cluster_Elements
		WHERE LJCE_Sub_BU_Code = @intCEDCode; 
	END
	ELSE IF @intCECode = 6
	BEGIN
		INSERT INTO #Temp_BGM_Expiry_Job_List(Temp_Ex_Job_Code)
		SELECT LJCE_Job_Code 
		FROM EIP40GLM.MDM.GEM_L_Job_Cluster_Elements
		WHERE LJCE_Cluster_Office_Code = @intCEDCode; 
	END
	ELSE IF @intCECode = 7
	BEGIN
		INSERT INTO #Temp_BGM_Expiry_Job_List(Temp_Ex_Job_Code)
		SELECT LJCE_Job_Code 
		FROM EIP40GLM.MDM.GEM_L_Job_Cluster_Elements
		WHERE LJCE_Region_Code = @intCEDCode; 
	END
	ELSE IF @intCECode = 8
	BEGIN
		INSERT INTO #Temp_BGM_Expiry_Job_List(Temp_Ex_Job_Code)
		SELECT LJCE_Job_Code 
		FROM EIP40GLM.MDM.GEM_L_Job_Cluster_Elements
		WHERE LJCE_Location_Code = @intCEDCode; 
	END
	ELSE IF @intCECode = 9
	BEGIN
		INSERT INTO #Temp_BGM_Expiry_Job_List(Temp_Ex_Job_Code)
		SELECT LJCE_Job_Code 
		FROM EIP40GLM.MDM.GEM_L_Job_Cluster_Elements
		WHERE LJCE_Zone_Code = @intCEDCode; 
	END
	ELSE IF @intCECode = 10
	BEGIN
		INSERT INTO #Temp_BGM_Expiry_Job_List(Temp_Ex_Job_Code)
		SELECT LJCE_Job_Code 
		FROM EIP40GLM.MDM.GEM_L_Job_Cluster_Elements
		WHERE LJCE_Area_Code = @intCEDCode; 
	END;

	INSERT INTO #Temp_BGM_BG_Expiry_Status(Temp_VBGR_Number, Temp_Company_Code, Temp_AC_Code, 
		Temp_Job_Code, Temp_Currency_Code, Temp_BA_Code, Temp_BG_Valid_Upto, 
		Temp_BG_Claim_Upto, Temp_BG_Value, Temp_BG_Number, Temp_BG_Type_Code)
	Select TVBGR_VBGR_Number, TVBGR_Company_Code, TVBGR_AC_Code, 
		LBGLR_Job_Code, TVBGR_Currency_Code, TVBGR_Vendor_Code, 
		TVBGR_Valid_Up_To, TVBGR_Claim_Up_To, TVBGR_BG_Value, TVBGR_BG_Number, VBG.TVBGR_BG_Type_Code
	From EIP40FIN.BGM.VBG_T_Vendor_Bank_Guarantee_Register VBG
		INNER JOIN EIP40FIN.BGM.VBG_L_Vendor_BG_LR LBGLR ON LBGLR_VBGR_Number = VBG.TVBGR_VBGR_Number
		INNER JOIN #Temp_BGM_Expiry_Job_List ON LBGLR_Job_Code = Temp_Ex_Job_Code
	Where VBG.TVBGR_Valid_Up_To BETWEEN @dtFromDate AND @dtToDate
	AND VBG.TVBGR_Company_Code = @intCompanyCode
	AND VBG.TVBGR_DS_Code = 4
	AND ISNULL(TVBGR_BG_Expiry_Mail_Sent, 'N') = 'N'          
	AND LBGLR.LBGLR_DS_Code NOT IN(8);    
	
	UPDATE #Temp_BGM_BG_Expiry_Status SET Temp_BG_Type = MBGT_Description
	FROM EIP40GLM.MDM.GEM_M_BG_Type
	WHERE Temp_BG_Type_Code = MBGT_BG_Type_Code
	AND Temp_Company_Code = MBGT_Company_Code;

	INSERT INTO #Temp_BGM_Expiry_Document_List
	(
		Temp_Ex_VBGR_Number, Temp_Ex_PO_Number, Temp_Ex_WO_Number, 
		Temp_Ex_Invoice_Regn_Number, Temp_Ex_DT_Code
	)
	SELECT LBGLR_VBGR_Number, LBGLR_PO_Number, LBGLR_WO_Number, 
		LBGLR_LR_Number, LBGLR_DT_Code
	FROM EIP40FIN.BGM.VBG_L_Vendor_BG_LR
	INNER JOIN #Temp_BGM_BG_Expiry_Status ON Temp_VBGR_Number = LBGLR_VBGR_Number
	AND LBGLR_DS_Code = 4;
	--GROUP BY LBGLR_VBGR_Number, CASE WHEN LBGLR_PO_Number IS NULL 
	--THEN LBGLR_WO_Number ELSE LBGLR_PO_Number END 

	--UPDATE #Temp_BGM_Expiry_Document_List SET Temp_Ex_Invoice_Regn_Number = LBGLR_LR_Number
	--FROM EIP.SQLBGM.BGM_L_Vendor_BG_LR
	--WHERE Temp_Ex_VBGR_Number = LBGLR_VBGR_Number
	--AND LBGLR_LR_Number IS NOT NULL 

	UPDATE #Temp_BGM_BG_Expiry_Status SET Temp_Payment_Term = MPTE_Description, 
	 Temp_BG_Type = CASE WHEN MPTEC_Is_Advance_Category = 'Y' THEN 'Advance BG' ELSE 'Performance BG' END
	FROM #Temp_BGM_Expiry_Document_List 
	INNER JOIN EIP40FIN.ACP.FAS_H_Ledger_Register_Vendor ON Temp_Ex_Invoice_Regn_Number = HLRV_LR_Number
	INNER JOIN EIP40GLM.MDM.GEM_M_PT_Events ON HLRV_PT_Event_Code = MPTE_Event_Code
	INNER JOIN EIP40GLM.MDM.GEM_M_PT_Event_Category ON MPTE_Event_Category_Code = MPTEC_Event_Category_Code
	WHERE Temp_VBGR_Number = Temp_Ex_VBGR_Number
	AND Temp_Ex_Invoice_Regn_Number IS NOT NULL 
	AND Temp_BG_Type IS NULL;
	
	--SELECT @strMailTo = (SELECT STUFF((SELECT  ',' + Email_Id 
	--FROM finance.dbo.BG_Expiry_Mail_Intimation_List
	--WHERE (BG_Type ='Vendor'
	--AND Sector_Code = @strCEDCode ) FOR XML PATH ('')),1,1,'' ))
	
	SELECT Temp_AC_Code, Temp_VBGR_Number BG_Request_Number, Temp_BG_Number BG_Number, 
	Temp_Job_Code Job_Code, MCUR_Description, 
	CAST(ROUND(Temp_BG_Value, MCUR_Decimal_Places) AS VARCHAR(25)) AS BG_Value, 
	CONVERT(VARCHAR(11), Temp_BG_Valid_Upto, 106) AS Valid_Upto,
	Temp_BG_Type BG_Type, Temp_Payment_Term, Temp_Ex_Po_Number PONumber,
	Temp_Ex_WO_Number WONumber,
	Temp_Ex_Invoice_Regn_Number Invoice_Regn_Number, MBA_BA_Code,	MBA_BA_Name,
	@strMailTo As mail_to
    FROM #Temp_BGM_BG_Expiry_Status
	INNER JOIN #Temp_BGM_Expiry_Document_List ON Temp_VBGR_Number = Temp_Ex_VBGR_Number
	INNER JOIN EIP40GLM.MDM.BAM_M_Business_Associates ON MBA_Company_Code = Temp_Company_Code
		AND MBA_BA_Code = Temp_BA_Code
	INNER JOIN EIP40GLM.MDM.GEM_M_Currencies ON Temp_Currency_Code = MCUR_Currency_Code;
	
     
Return  

END







