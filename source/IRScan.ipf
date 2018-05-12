#pragma rtGlobals=1		// Use modern global access method.

Menu "Macros"
	"IR Scan", IRScanDriver()
End

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////// IRSCAN DRIVER ///////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// This is the function sets up the direcectory and all global variables for future use
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Function IRScanDriver()
	
	// If the panel is already created, just bring it to the front.
	DoWindow/F IRScanPanel
	if (V_Flag != 0)
		return 0
	endif
	
	String dfSave = GetDataFolder(1)
	// Create a data folder in Packages to store globals.
	NewDataFolder/O/S root:packages:IRScan
	
	
	/////////////////////////////////////////////////////////////////////////////////////////////
	//Thermal related Variables and set up
	////////////////////////////////////////////////////////////////////////////////////////////
	
	// Samples per thermal
	Variable/G gThermalsamples=5
	
	//Variables for the indices of Thermal
	Variable start1 = NumVarOrDefault(":gThermalstart1",58)
	Variable/G gThermalstart1= start1
	Variable end1 = NumVarOrDefault(":gThermalend1",63)
	Variable/G gThermalend1= end1
	Variable start2 = NumVarOrDefault(":gThermalstart2",72)
	Variable/G gThermalstart2= start2
	Variable end2 = NumVarOrDefault(":gThermalend2",75)
	Variable/G gThermalend2= end2
	
	Variable/G gThermalStarted = 0
		
	//Set up call back information to enable looping
	//turn on master callbacks
	ARCheckFunc("ARUserCallbackMasterCheck_1",1)
	//turn on the other callbacks we will use
	ARCheckFunc("ARUserCallbackThermDoneCheck_1",1)
	//tell the callbacks what to call
	PDS("ARUserCallbackThermDone","Thermal_callback()") //Does a Thermal
	
	// Create the control panel.
	Execute "IRScanPanel()"
	//Reset the datafolder to the root / previous folder
	SetDataFolder dfSave

End

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////// IRSCAN PANEL ////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// This is the function renders the window and all widgets within for IR Scan Panel
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Window IRScanPanel(): Panel
	
	PauseUpdate; Silent 1		// building window...
	NewPanel /K=1 /W=(485,145, 700,562) as "IR Scan v.1.1"
	SetDrawLayer UserBack
		
	SetDrawEnv fstyle= 1
	DrawText 16,108, "Thermal Controls:"
	
	Popupmenu pm_resolution,pos={16,115},size={135,18},title="Resolution"
	Popupmenu pm_resolution, mode=(GV("ThermalResolution")+1)
	Popupmenu pm_resolution,value="1, best;2;3;4;5, default;6;7;8;9, fastest;" ,live= 1, proc=ResolPopup
	
	SetVariable sv_itertime,pos={16,146},size={184,18},title="Number of Samples", limits={0,inf,1}	
	SetVariable sv_itertime,value= root:packages:IRScan:gThermalsamples,live= 1
	SetVariable sv_itertime,help={"Number of samples taken per Thermal"}
	
	SetDrawEnv fstyle= 4
	DrawText 16,189, "Area under Curve Limits:"
	
	SetVariable sv_start1,pos={16,202},size={84,18},title="Start 1", limits={0,inf,1}
	SetVariable sv_start1,value= root:packages:IRScan:gThermalstart1,live= 1
	SetVariable sv_end1,pos={115,202},size={84,18},title="End 1", limits={0,inf,1}
	SetVariable sv_end1,value= root:packages:IRScan:gThermalend1,live= 1
	
	SetVariable sv_start2,pos={16,232},size={84,18},title="Start 2", limits={0,inf,1}
	SetVariable sv_start2,value= root:packages:IRScan:gThermalstart2,live= 1
	SetVariable sv_end2,pos={115,232},size={84,18},title="End 2", limits={0,inf,1}
	SetVariable sv_end2,value= root:packages:IRScan:gThermalend2,live= 1
		
	SetDrawEnv fstyle= 1
	DrawText 16,278, "Progress:"
	
	ValDisplay vd_ThermalProgress,pos={16,288},size={183,20},title="Thermal", mode=0
	ValDisplay vd_ThermalProgress,limits={0,100,0},barmisc={0,35},highColor= (0,43520,65280)
	ValDisplay vd_ThermalProgress,value=100*root:Packages:MFP3D:Main:Variables:ThermalVariablesWave[%ThermalCounter]/root:packages:IRScan:gThermalSamples
	
	//ValDisplay vd_ScanProgress,pos={16,318},size={183,20},title="Scan", mode=0
	//ValDisplay vd_ScanProgress,limits={0,100,0},barmisc={0,35},highColor= (0,43520,65280)
	//ValDisplay vd_ScanProgress,value= root:packages:IRScan:gScanPercent
		
	Button but_start,pos={16,353},size={180,20},title="Prepare Scan", proc=writeFuncNames
	//Button but_stop,pos={106,353},size={101,20},title="Stop Scan", disable=2, proc=abortScan
	
	SetDrawEnv fstyle= 1 
	SetDrawEnv textrgb= (0,0,65280)
	DrawText 49,397, "Suhas Somnath, UIUC 2010"
	
End

Function dummy()
	print "dummy!!"
end

Function dummy2()
	print "point operation!!"
	PointMapCallBackFunc("Ramp"); 
	td_WriteString("4%Event","Once")
end

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////// WRITE FUNC NAMES ///////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// This function prepares the Point Map Panel's functions
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Function writeFuncNames (ctrlname) : ButtonControl
	String ctrlname
	PointMapFuncFunc("PointMapInitFuncSetVar_5",  NaN, "startScan()", "GeneralVariablesDescription[%PointMapInitFunc]")
	PointMapFuncFunc("PointMapInitFuncSetVar_5",  NaN, "startThermal()", "GeneralVariablesDescription[%PointMapFunc]")
	//PointMapFuncFunc("PointMapInitFuncSetVar_5",  NaN, "startScan()", "GeneralVariablesDescription[%PointMapRampFunc]")
	PointMapFuncFunc("PointMapInitFuncSetVar_5",  NaN, "wrapUpScan()", "GeneralVariablesDescription[%PointMapStopFunc]")
End

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////// RESOL POPUP ///////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// This function simply allows the user to access the resolution control for the thermal
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Function ResolPopup(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa
		
	switch( pa.eventCode )
		case 2: // mouse up
			ThermalResolutionPopupFunc("ThermalResolutionPopup_1",pa.popNum,pa.popStr)
			break
	endswitch
	
End

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////// WRAP UP SCAN ///////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// It also resets the buttons and shows the result of the scan
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Function wrapUpScan()

	//Make sure that no more Thermals are done
	ARCheckFunc("ARUserCallbackMasterCheck_1",0)
		
	//Displaying results:
	String dfSave = GetDataFolder(1)
	SetDataFolder root:packages:IRScan
	Edit/K=0 'finalThermal';DelayUpdate
	SetDataFolder dfSave
	DoAlert 0, "There are two 'pages' in this table, one for each area under the curve\nUse the arrows in the top right corner to see them\nTo export this table go to: \nFile>>Save Table Copy >> Select txt or csv as type"
		
	ModifyControl but_start, disable=0, title="Start Scan"
	ModifyControl but_stop, disable=0, title="Stop Scan"

End

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////// START SCAN ////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// This is the function that is called when you click on the start scan button
// It initializes all the global scan related variables using the scan size and scan points etc
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Function startScan()
	
	String dfSave = GetDataFolder(1)
	SetDataFolder root:packages:IRScan
	
	//ModifyControl but_stop, disable=0
	//ModifyControl but_start, disable=2, title="Scanning..."
			
	//Preparing the wave in which the final area values are to be stored:
	//Changing the number of area-under-curve values to be stored can 
	//easily be changed by increasing the number of layers 
	//Best to redimension the wave because remaking the wave doesn't
	//erase all the old data
	Redimension/N=0 finalThermal
	Make/O/N=(GV("FMapScanPoints"),GV("FMapScanLines"),2) finalThermal
		
	NVAR gThermalsamples, gThermalstart1,gThermalend1,gThermalstart2,gThermalend2	
		
	PV("ThermalSamples",gThermalsamples)
	PV("ThermalSamplesLimit",gThermalsamples)
	
	if(gThermalstart1 > gThermalend1)
		gThermalend1=gThermalstart1
	endif
	if(gThermalstart2 > gThermalend2)
		gThermalend2=gThermalstart2
	endif
		
	SetDataFolder dfSave
End

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////// START THERMAL /////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// This is the function starts a thermal
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Function startThermal()
	
	String dfSave = GetDataFolder(1)
	SetDataFolder root:packages:IRScan	
	
	NVAR gScanAbort
		
	NVAR gThermalStarted
	gThermalStarted = 1	
	
	ARCheckFunc("ARUserCallbackMasterCheck_1",1)
	
	SetDataFolder dfSave
	
	//Doing the thermal
	Variable t0 = ticks
	do
	while ((ticks - t0)/60 < 1)
	
	DoThermalFunc("DoThermal")
	
End

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////// THERMAL CALLBACK //////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// This is the function that is called once a thermal is completed - hence a 'Callback' function
// It calls for the calculation of the area under the curve and asks the stage to be moved to the next
// coordinate
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Function Thermal_callback()
		
	String dfSave = GetDataFolder(1)
	SetDataFolder root:packages:IRScan
	
	NVAR gThermalStarted
	
	print "coming here!"
		
	if(gThermalStarted)
		//Legitimate call to this function
		//print "@ThermalCallback - Legal call"
		
		gThermalStarted = 0
		
		areaUnderCurve()
	
		DoWindow/K ThermalGraph
	
		PV("ThermalCounter",0)
		
		ARCheckFunc("ARUserCallbackMasterCheck_1",0)
			
		SetDataFolder dfSave
		
		print "legal here!!"
										
		PointMapCallBackFunc("Ramp"); 
		td_WriteString("4%Event","Once")
	else
		print "going here!"
		SetDataFolder dfSave
		
		//print "%%% Ignoring illegal ThermalCallback"
	endif

End

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////// AREA UNDER CURVE //////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// This is the function calculates the area(s) under the curve (thermal) and stores them 
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Function areaUnderCurve()

	String dfSave = GetDataFolder(1)
	SetDataFolder root:packages:IRScan
	
	NVAR gThermalStart1,gThermalEnd1,gThermalStart2,gThermalEnd2	
	Wave thermwave = root:packages:MFP3D:Tune:TotalPSD
	NVAR gXindex, gYindex
	Wave finalThermal
	
	Variable i
	Variable total1 = 0
	Variable total2 = 0
	if(gThermalEnd1 <= numpnts(thermwave))
		for (i=gThermalStart1 ; i <= gThermalEnd1 ; i+=1)
			total1 += thermwave[i]
		endfor
	endif
	if(gThermalEnd2 <= numpnts(thermwave))
		for (i=gThermalStart2 ; i <= gThermalEnd2 ; i+=1)
			total2 += thermwave[i]
		endfor
	endif
	
	finalThermal[gXindex][gYindex][0] = total1
	finalThermal[gXindex][gYindex][1] = total2
		
	SetDataFolder dfSave	
End