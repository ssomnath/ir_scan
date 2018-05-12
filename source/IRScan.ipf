#pragma rtGlobals=1		// Use modern global access method.

// IR Scan v.1.0
// Suhas Somnath 
// UIUC 2010

Menu "Macros"
	"IR Scan", IRScanDriver()
End

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
	
	//Total number of times this should run
	Variable/G gThermaliter=2
	// Samples per iteration
	Variable/G gThermalsamples=5
	// How many times it has already run
	Variable/G gThermalcurrent=1
	
	//Variables for the indices of Thermal
	Variable start1 = NumVarOrDefault(":gThermalstart1",58)
	Variable/G gThermalstart1= start1
	Variable end1 = NumVarOrDefault(":gThermalend1",63)
	Variable/G gThermalend1= end1
	Variable start2 = NumVarOrDefault(":gThermalstart2",72)
	Variable/G gThermalstart2= start2
	Variable end2 = NumVarOrDefault(":gThermalend2",75)
	Variable/G gThermalend2= end2
		
	//Variable for displaying Thermal Progress for that coordinate
	Variable/G gThermalPercent=0
		
	//Set up call back information to enable looping
	//turn on master callbacks
	ARCheckFunc("ARUserCallbackMasterCheck_1",1)
	//turn on the other callbacks we will use
	ARCheckFunc("ARUserCallbackThermDoneCheck_1",1)
	//tell the callbacks what to call
	PDS("ARUserCallbackThermDone","Thermaliterator()") //Does a Thermal
	
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
	gScanPoints = 4// default
	gScanAbort = 0
	gScanPercent = 0
	
	// Rest of the initialization can occur each time the scan is started.	
	Variable/G gIsMovingRight, gXindex, gYindex, gDeltaX, gDeltaY, gOriginX, gOriginY
	
	// Create the control panel.
	Execute "IRScanPanel()"
	//Reset the datafolder to the root / previous folder
	SetDataFolder dfSave

End

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
	
	SetVariable sv_maxiter,pos={16,117},size={184,18},title="Number of Iterations"
	SetVariable sv_maxiter,value= root:packages:IRScan:gThermaliter,live= 1
	SetVariable sv_maxiter,help={"Number of times the Thermal must run"}
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
	
	//ValDisplay vd_Area1,pos={16,163},size={180,18},title="Area 1"
	//ValDisplay vd_Area1,value= root:packages:IRScan:gThermalArea1,live= 1
	
	//ValDisplay vd_Area2,pos={16,188},size={180,18},title="Area 2"
	//ValDisplay vd_Area2,value= root:packages:IRScan:gArea2,live= 1
	
	SetDrawEnv fstyle= 1
	DrawText 16,278, "Progress:"
	
	ValDisplay vd_ThermalProgress,pos={16,288},size={183,20},title="Thermal", mode=0
	ValDisplay vd_ThermalProgress,limits={0,100,0},barmisc={0,35},highColor= (0,43520,65280)
	ValDisplay vd_ThermalProgress,value= root:packages:IRScan:gThermalPercent
	
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
////////////////////////////////////////////////////////// ABORT SCAN ///////////////////////////////////////////////////////////
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

Function abortCurrentScan()
		
	ModifyControl but_start, disable=0, title="Start Scan"
	ModifyControl but_stop, disable=0, title="Stop Scan"

End

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////// START SCAN ////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Function startScan (ctrlname) : ButtonControl
	String ctrlname
	
	String dfSave = GetDataFolder(1)
	SetDataFolder root:packages:IRScan
	
	ModifyControl but_stop, disable=0
	ModifyControl but_start, disable=2, title="Scanning..."
	
	NVAR gscansize, gscanpoints
	NVAR gIsMovingRight, gXindex, gYindex, gDeltaX, gDeltaY, gOriginX, gOriginY, gScanPercent
	
	//Before anything is done set scansize right (to microns):
	gScanPercent = 0
	Variable scansize = gScanSize * 1e-6
	
	//Preparing the wave in which the final area values are to be stored:
	//Changing the number of area-under-curve values to be stored can 
	//easily be changed by increasing the number of layers 
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
	
	DoAlert 0, "If the 'Stop Scan' button does not work\nTry the 'Abort' button at the bottom left of the IGOR screen"
		
	// Moving to first coordinate
	MoveStage(gOriginX, gOriginY,gOriginX, gOriginY)
	
	SetDataFolder dfSave
End

Function MoveStage(Xstart, Ystart, Xend, Yend)
	Variable Xstart, Ystart, Xend, Yend
		
	print "Dummy moving to (" + num2str(Xend) + " , " + num2str(Yend) + ")"
	
	Variable t0 = ticks
	do
	while ((ticks - t0)/60 < 1)
	
	//startThermals()
	moveToNext()
	
End

// This is to be the callback function that will reset the global variables 
function moveToNext()

	String dfSave = GetDataFolder(1)
	SetDataFolder root:packages:IRScan

	NVAR gIsMovingRight, gXindex, gYindex, gDeltaX, gDeltaY, gOriginX, gOriginY, gScanAbort
	
	if(gScanAbort)
		AbortCurrentScan()
	endif
	
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
		ModifyControl but_start, disable=0, title="Start Scan"
		SetDataFolder dfSave
		//Although not a good idea. For now it'll work
		abortCurrentScan()
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

Function startThermals()
	
	String dfSave = GetDataFolder(1)
	SetDataFolder root:packages:IRScan
	
	NVAR gThermalsamples, gThermalcurrent, gThermaliter, gThermalPercent
	
	gThermalcurrent = 1
	gThermalPercent = 0
	
	Make/O/N=(gThermaliter,2) thermalareas
	
	PV("ThermalSamples",gThermalsamples)
	PV("ThermalSamplesLimit",gThermalsamples)
	
	ARCheckFunc("ARUserCallbackMasterCheck_1",1)
	
	SetDataFolder dfSave
	
	//Call The iterator:
	Variable t0 = ticks
	do
	while ((ticks - t0)/60 < 1)
	print "Starting Thermal Iterator!"
	DoThermalFunc("DoThermal")
	
End

Function Thermaliterator()
	
	Variable t0
	
	if(GV("ThermalCounter") < GV("ThermalSamples"))
		//print GV("ThermalCounter")
		//print "Not done this time, will wait and execute again!"
		t0 = ticks
		do
			//This is simply to add a pause into the program
		while ((ticks - t0)/60 < 1)	
		DoThermalFunc("DoThermal")
	else
		///print "done this time"
		
		String dfSave = GetDataFolder(1)
		SetDataFolder root:packages:IRScan
	
		NVAR gThermalCurrent, gThermaliter,gThermalPercent, gScanAbort
		
		if(gScanAbort)
			abortCurrentScan()
		endif
		
		print "Completed iteration #" + num2str(gThermalCurrent) + " of " + num2str(gThermaliter)
		gThermalPercent = gThermalCurrent*100/gThermaliter
		
		// Calculating area(s) under the curve
		areaUnderCurve(gThermalcurrent-1)
		
		gThermalCurrent +=1
		
		if(gThermalCurrent <= gThermaliter)
			// Killing the thermal graph because it wont restart
			KillWindow ThermalGraph
		
			PV("ThermalCounter",0)
			//Waiting:
			t0 = ticks
			do
				//This is simply to add a pause into the program
			while ((ticks - t0)/60 < 1)
		
			// Start a new thermal NOW!!
			//print "Starting another thermal now!"
			SetDataFolder dfSave
			DoThermalFunc("DoThermal")
		
		else
			print "All Iterations finished"
			gThermalCurrent=1
			SetDataFolder dfSave
			ARCheckFunc("ARUserCallbackMasterCheck_1",0)
			
			// Averaging Areas under curves			
			averageAreas()
			// Killing the thermal window
			KillWindow ThermalGraph
			
			moveToNext()
		endif
		
	endif

End

Function areaUnderCurve(index)
	Variable index

	String dfSave = GetDataFolder(1)
	SetDataFolder root:packages:IRScan
	
	NVAR gThermalStart1,gThermalEnd1,gThermalStart2,gThermalEnd2	
	Wave thermwave = root:packages:MFP3D:Tune:TotalPSD
	Wave thermalAreas
	
	if(gThermalStart1 > gThermalEnd1)
		gThermalEnd1=gThermalStart1
	endif
	if(gThermalStart2 > gThermalEnd2)
		gThermalEnd2=gThermalStart2
	endif
	
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
	
	thermalAreas[index][0] = total1
	thermalAreas[index][1] = total2
		
	SetDataFolder dfSave	
End

Function averageAreas()

	String dfSave = GetDataFolder(1)
	SetDataFolder root:packages:IRScan

	Wave thermalAreas, finalThermal
	NVAR gXindex, gYindex
	
	Variable i,total1,total2
	total1 = 0
	total2 = 0
	
	for(i=0; i<numpnts(thermalAreas); i+=1)
		total1 += thermalAreas[i][0]
		total2 += thermalAreas[i][1]
	endfor
	
	finalThermal[gXindex][gYindex][0] = total1/numpnts(thermalAreas)
	finalThermal[gXindex][gYindex][1] = total2/numpnts(thermalAreas)

	SetDataFolder dfSave	

End