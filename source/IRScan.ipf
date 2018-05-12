#pragma rtGlobals=1		// Use modern global access method.

// IR Scan v.1.0
// Suhas Somnath 
// UIUC 2010

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
	
	/////////////////////////////////////////////////////////////////////////////////////////////////
	//Stage Movement variables and set up
	////////////////////////////////////////////////////////////////////////////////////////////////
	
	variable/G X_PGain, X_IGain, X_SGain, Y_PGain, Y_IGain, Y_SGain

	X_PGain = td_RV("PGain%PISLoop0")
	X_IGain = td_RV("IGain%PISLoop0")
	X_SGain = td_RV("SGain%PISLoop0")
	
	Y_PGain = td_RV("PGain%PISLoop1")
	Y_IGain = td_RV("IGain%PISLoop1")
	Y_SGain = td_RV("SGain%PISLoop1")
	
	Variable/G gscansize, gscanpoints, gScanAbort, gScanPercent
	gscansize = 20// in microns - default
	gScanPoints = 2// default
	gScanAbort = 0
	gScanPercent = 0
	
	// Rest of the initialization can occur each time the scan is started.	
	Variable/G gIsMovingRight, gXindex, gYindex, gDeltaX, gDeltaY, gOriginX, gOriginY
	
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
	NewPanel /K=1 /W=(485,145, 700,562) as "IR Scan v.1.0"
	SetDrawLayer UserBack
	
	SetDrawEnv fstyle= 1
	DrawText 16,25, "Scan Controls:"
	
	SetVariable sv_scansize,pos={16,31},size={151,18},title="Scan Size (um)", limits={0,90,1}	
	SetVariable sv_scansize,value= root:packages:IRScan:gScanSize,live= 1
	SetVariable sv_scanpoints,pos={16,57},size={139,18},title="Scan Points", limits={1,inf,1}	
	SetVariable sv_scanpoints,value= root:packages:IRScan:gScanPoints,live= 1
	
	SetDrawEnv fstyle= 1
	DrawText 16,108, "Thermal Controls:"
	
	Popupmenu pm_resolution,pos={16,115},size={135,18},title="Resolution"
	Popupmenu pm_resolution,value="1, best;2;3;4;5, default;6;7;8;9, fastest;" ,live= 1, proc=ResolPopup
	
	SetVariable sv_itertime,pos={16,143},size={184,18},title="Number of Samples", limits={0,inf,1}	
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
	
	ValDisplay vd_ScanProgress,pos={16,318},size={183,20},title="Scan", mode=0
	ValDisplay vd_ScanProgress,limits={0,100,0},barmisc={0,35},highColor= (0,43520,65280)
	ValDisplay vd_ScanProgress,value= root:packages:IRScan:gScanPercent
		
	Button but_start,pos={16,353},size={80,20},title="Start Scan", proc=startScan
	Button but_stop,pos={106,353},size={101,20},title="Stop Scan", disable=2, proc=abortScan
	
	SetDrawEnv fstyle= 1 
	SetDrawEnv textrgb= (0,0,65280)
	DrawText 49,397, "Suhas Somnath, UIUC 2010"
	
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
////////////////////////////////////////////////////////// ABORT SCAN ///////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// This is the function that is called when you click on the Stop Scan button
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Function abortScan (ctrlname) : ButtonControl
	String ctrlname
	
	String dfSave = GetDataFolder(1)
	SetDataFolder root:packages:IRScan
	
	NVAR gScanAbort
	gScanAbort = 1
	
	ModifyControl but_stop, disable=2, title="Stopping...."
	
	SetDataFolder dfSave
End

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////// WRAP UP SCAN ///////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// This is the function stops further thermals and the PIS loops for the X and Y stage
// It also resets the buttons and shows the result of the scan
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Function wrapUpScan()

	//Make sure that no more Thermals are done
	ARCheckFunc("ARUserCallbackMasterCheck_1",0)
	
	//Stopping the PIS Loops
	// could use td_stop
	td_StopPISLoop(0)
	td_StopPISLoop(1)
	
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
Function startScan (ctrlname) : ButtonControl
	String ctrlname
	
	String dfSave = GetDataFolder(1)
	SetDataFolder root:packages:IRScan
	
	ModifyControl but_stop, disable=0
	ModifyControl but_start, disable=2, title="Scanning..."
	
	NVAR gscansize, gscanpoints, gScanAbort
	NVAR gIsMovingRight, gXindex, gYindex, gDeltaX, gDeltaY, gOriginX, gOriginY, gScanPercent
	
	gScanAbort = 0
	
	//Before anything is done set scansize right (to microns):
	gScanPercent = 0
	Variable scansize = gScanSize * 1e-6
	
	//Preparing the wave in which the final area values are to be stored:
	//Changing the number of area-under-curve values to be stored can 
	//easily be changed by increasing the number of layers 
	//Best to redimension the wave because remaking the wave doesn't
	//erase all the old data
	Redimension/N=0 finalThermal
	Make/O/N=(gscanpoints,gscanpoints,2) finalThermal
	
	// Just index based variables
	gIsMovingRight = 1// 1 = right and (-1) = left
	gXindex = 0
	gYIndex = 0
	
	//Input Sensor based variables:
	gDeltaX = scansize/(gscanpoints*GV("XLVDTSens"))
	gDeltaY = scansize/(gscanpoints*GV("YLVDTSens"))
	gOriginX = 0
	gOriginY = 0
	
	// Initializing all the thermal based variables here:
	
	NVAR gThermalsamples, gThermalstart1,gThermalend1,gThermalstart2,gThermalend2	
		
	PV("ThermalSamples",gThermalsamples)
	PV("ThermalSamplesLimit",gThermalsamples)
	
	if(gThermalstart1 > gThermalend1)
		gThermalend1=gThermalstart1
	endif
	if(gThermalstart2 > gThermalend2)
		gThermalend2=gThermalstart2
	endif
	
	
	// Moving to first coordinate
	MoveStage(gOriginX, gOriginY,gOriginX, gOriginY)
	
	SetDataFolder dfSave
End

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////// MOVE STAGE ////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// This is the main function that moves the stage from and to the specified coordinates
// It does so using a closed loop feedback system - PIS Loops
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Function MoveStage(X_start, Y_start, X_end, Y_end)
	Variable X_start, Y_start, X_end, Y_end
	
	String dfSave = GetDataFolder(1)
	SetDataFolder root:packages:IRScan
	
	NVAR gScanAbort
	
	if(gScanAbort)
		SetDataFolder dfSave
		wrapUpScan()
		return -1
	endif
		
	Make/N=(1024)/O XVoltage YVoltage XSensor YSensor XCommand YCommand
	
	//print "moving stage"
	
	//Display/K=1 /W=(5.25,41.75,399.75,250.25) XVoltage
	//ModifyGraph rgb(XVoltage)=(0,0,65535 )
	//Appendtograph/R YVoltage; Legend
	//Display/K=1 /W=(7.5,275.75,402,484.25) XSensor
	//ModifyGraph rgb(XSensor)=(0,0,65535 )
	//Appendtograph/R YSensor; Legend
	//Display/K=1 /W=(409.5,41.75,662.25,250.25) YSensor vs XSensor
	//ModifyGraph width={Plan,1,bottom,left} 
	
	NVAR X_PGain, X_IGain, X_SGain, Y_PGain, Y_IGain, Y_SGain
	
	// Giving movement directions to the X and Y Piezos:
	XCommand = X_start + (X_end - X_start)*(p/1024) 
	YCommand = Y_start + (Y_end - Y_start)*(p/1024) 
		
	// To make it least painful for the sensors / piezo: X and Y start must be the starting values
	// Or else they'll have to jump from their hardcoded set point to the first setpoint in the arrays
	// given by the PIS loops
	
	//Unfortunately, as consequence, the piezos move back to their initial setpoint as given during
	// their initialization although the set out wave pair is actually resetting the setpoint of the PIS
	// Must use a callback to reset the PIS to the final position.
	
	variable Error = 0
	
	Error += td_stop()
	
	Error += td_xSetPISLoop(0,"always", "X%Input@Controller", XCommand[0], X_PGain, X_IGain, X_SGain, "X%Output@Controller")
	
	Error += td_xSetPISLoop(1,"always", "Y%Input@Controller", YCommand[0], Y_PGain, Y_IGain, Y_SGain, "Y%Output@Controller")
	
	Error += td_xSetOutWavePair(0, "0,0", "Setpoint%PISLoop0", XCommand, "SetPoint%PISLoop1",YCommand,100)
	
	Error += td_xSetInWavePair(0, "0,0", "X%Output@Controller", XVoltage, "Y%Output@Controller", YVoltage, "", 100)
	
	Error += td_xSetInWavePair(1, "0,0", "X%Input@Controller", XSensor, "Y%Input@Controller", YSensor, "holdStationary()", 100)
	

	Error +=td_WriteString("0%Event", "once")
	
	if (Error)
		//print "Error in one of the td_ functions in ClosedLoopStageShifter: ", Error
	endif
	
	SetDataFolder dfSave
	
End

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////// HOLD STATIONARY ///////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// This is the function holds the stage in its new position for less than a second and then
// calls the iteration of thermals
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Function holdStationary()

	String dfSave = GetDataFolder(1)
	SetDataFolder root:packages:IRScan

	td_stop()
	
	NVAR X_PGain, X_IGain, X_SGain, Y_PGain, Y_IGain, Y_SGain
	
	NVAR gScanAbort
	
	if(gScanAbort)
		SetDataFolder dfSave
		wrapUpScan()
		return -1
	endif
	
	Wave XCommand, YCommand
	
	Variable Error = 0
	Variable xvalue = XCommand[numpnts(XCommand)-1]
	Variable yvalue = YCommand[numpnts(YCommand)-1]
	
	//print "holding stage at (" + num2str(xvalue) + " , " + num2str(yvalue) + ")"
	
	Error += td_xSetPISLoop(0,"always", "X%Input@Controller", xvalue, X_PGain, X_IGain, X_SGain, "X%Output@Controller")
	
	Error += td_xSetPISLoop(1,"always", "Y%Input@Controller", yvalue, Y_PGain, Y_IGain, Y_SGain, "Y%Output@Controller")

	if (Error)
		//print "Error in one of the td_ functions in holdStationary: ", Error
	endif
		
	//Temporarily placed a wait here. 
	// Assuming thermal doesn't wipe out my PIS / stop them......
	// This should simulate the the position kept constant for some time
	// Moreover. Noticed that the position is more stable this way
	// Piezos dont look like they want to be rushed into darting to the coordinate
	Variable t0 = ticks
	do
	while ((ticks - t0)/60 < 3)	
	
	SetDataFolder dfSave
	
	//print "calling thermal start"
		
	startThermal()
	
End

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////// MOVE TO NEXT ////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// This is the function tells the stage where to move next.
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function moveToNext()

	String dfSave = GetDataFolder(1)
	SetDataFolder root:packages:IRScan

	NVAR gIsMovingRight, gXindex, gYindex, gDeltaX, gDeltaY, gOriginX, gOriginY, gScanAbort
	
	if(gScanAbort)
		wrapUpScan()
		return -1
	endif
	
	//print "requesting to move to next"
	
	//printf "Right= %.2g, Xindex = %.2g, Yindex = %.2g\r", gIsMovingRight, gXindex, gYindex
	
	//Start coordinate for next move is going to be the same regardless:
	Variable XS = gOriginX + gXindex*gDeltaX
	Variable YS = gOriginY + gYindex*gDeltaY
	
	// Updating Progress(es): should be shifted to the thermal code
	NVAR gScanPercent, gScanPoints
	
	if(gIsMovingRight == 1)
		gScanPercent = ((gScanPoints * gYIndex) + 1 + gXIndex)*100/(gScanPoints^2)
	else
		gScanPercent = ((gScanPoints * gYIndex) + (gScanPoints - gXIndex))*100/(gScanPoints^2)
	endif
	
	//printf "Percent scanned = %.2g\r", gScanPercent
	
	if(((gIsMovingRight==1 && gXindex == gScanPoints-1) || (gIsMovingRight==-1 && gXindex == 0)) && gYindex == gScanPoints-1)
		//print "Finished Scanning!"
		SetDataFolder dfSave
		wrapUpScan()
		return 0
	elseif(((gIsMovingRight==1 && gXindex == gScanPoints-1) || (gIsMovingRight==-1 && gXindex == 0)) && gYindex != gScanPoints-1)
		//Need to Move up one and then start in the opposite direction in X
		gIsMovingRight *= -1
		gYindex +=1
		SetDataFolder dfSave
		MoveStage(XS, YS, XS, YS + gDeltaY)
	else
		//Need to move horizontally one step keeping in mind the direction
		gXindex +=1*gIsMovingRight
		SetDataFolder dfSave
		MoveStage(XS, YS, XS + gIsMovingRight*gDeltaX, YS)	
	endif
	
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
	
	if(gScanAbort)
		SetDataFolder dfSave
		wrapUpScan()
		return -1
	endif
	
	NVAR gThermalStarted
	gThermalStarted = 1	
	
	ARCheckFunc("ARUserCallbackMasterCheck_1",1)
	
	SetDataFolder dfSave
	
	//Doing the thermal
	Variable t0 = ticks
	do
	while ((ticks - t0)/60 < 1)
	
	//print "Input Sensors = (" + num2str(td_rv("X%input@Controller")) + " , " + num2str(td_rv("Y%input@Controller")) + ")"
	//print "Output Sensors = (" + num2str(td_rv("X%output@Controller")) + " , " + num2str(td_rv("Y%output@Controller")) + ")"

	//print "Starting Thermal"
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
	
	NVAR gScanAbort, gThermalStarted
	
	if(gScanAbort)
		SetDataFolder dfSave
		wrapUpScan()
		return -1
	endif
	
	if(gThermalStarted)
		//Legitimate call to this function
		//print "@ThermalCallback - Legal call"
		
		gThermalStarted = 0
		
		areaUnderCurve()
	
		DoWindow/K ThermalGraph
	
		PV("ThermalCounter",0)
		
		ARCheckFunc("ARUserCallbackMasterCheck_1",0)
			
		SetDataFolder dfSave
	
		//Variable t0 = ticks
		//do
			//This is simply to add a pause into the program
		//while ((ticks - t0)/60 < 1)
									
		moveToNext()
	else
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