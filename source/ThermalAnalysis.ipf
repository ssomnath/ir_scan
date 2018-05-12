#pragma rtGlobals=1		// Use modern global access method.

//Thermal Analysis 
//Suhas Somnath, UIUC 2009

Menu "Macros"
	"Thermal Analysis", ThermalAnalDriver()
End


Function ThermalAnalDriver()
	
	// If the panel is already created, just bring it to the front.
	DoWindow/F ThermalAnalysisPanel
	if (V_Flag != 0)
		return 0
	endif
	
	String dfSave = GetDataFolder(1)
	// Create a data folder in Packages to store globals.
	NewDataFolder/O/S root:packages:ThermalAnalysis
	
	//Total number of times this should run
	Variable/G giter=3
	// Samples per iteration
	Variable/G gsamples=10
	// How many times it has already run
	Variable/G gcurrent=1
	
	//Variables for the indices of Thermal
	Variable/G gstart1=NumVarOrDefault(":gstart1",58)
	Variable/G gend1=NumVarOrDefault(":gend1",63)
	Variable/G gstart2=NumVarOrDefault(":gstart2",58)
	Variable/G gend2=NumVarOrDefault(":gend2",63)
	
	//Variables for displaying total Area under curve
	Variable/G gArea1=0
	Variable/G gArea2=0
	
	//Variable for displaying Progress
	Variable/G gPercent=0
		
	//Set up call back information to enable looping
	//turn on master callbacks
	ARCheckFunc("ARUserCallbackMasterCheck_1",1)
	//turn on the other callbacks we will use
	ARCheckFunc("ARUserCallbackThermDoneCheck_1",1)
	//tell the callbacks what to call
	PDS("ARUserCallbackThermDone","Thermaliterator()") //Does a Thermal	
	
	// Create the control panel.
	Execute "ThermalAnalysisPanel()"
	//Reset the datafolder to the root / previous folder
	SetDataFolder dfSave

End

Window ThermalAnalysisPanel(): Panel
	
	PauseUpdate; Silent 1		// building window...
	NewPanel /K=1 /W=(485,145, 700,450) as "Thermal Iterator v.1.1"
	SetDrawLayer UserBack
	
	SetVariable sv_maxiter,pos={16,14},size={184,18},title="Number of Iterations"
	SetVariable sv_maxiter,value= root:packages:ThermalAnalysis:giter,live= 1
	SetVariable sv_maxiter,help={"Number of times the Thermal must run"}
	SetVariable sv_itertime,pos={16,43},size={184,18},title="Number of Samples", limits={0,inf,1}	
	SetVariable sv_itertime,value= root:packages:ThermalAnalysis:gsamples,live= 1
	SetVariable sv_itertime,help={"Number of samples taken per Thermal"}
	
	DrawText 16,89, "Area under Curve Section:"
	
	SetVariable sv_start1,pos={16,102},size={84,18},title="Start 1", limits={0,inf,1}
	SetVariable sv_start1,value= root:packages:ThermalAnalysis:gstart1,live= 1
	SetVariable sv_end1,pos={115,102},size={84,18},title="End 1", limits={0,inf,1}
	SetVariable sv_end1,value= root:packages:ThermalAnalysis:gend1,live= 1
	
	SetVariable sv_start2,pos={16,132},size={84,18},title="Start 2", limits={0,inf,1}
	SetVariable sv_start2,value= root:packages:ThermalAnalysis:gstart2,live= 1
	SetVariable sv_end2,pos={115,132},size={84,18},title="End 2", limits={0,inf,1}
	SetVariable sv_end2,value= root:packages:ThermalAnalysis:gend2,live= 1
	
	ValDisplay vd_Area1,pos={16,163},size={180,18},title="Area 1"
	ValDisplay vd_Area1,value= root:packages:ThermalAnalysis:gArea1,live= 1
	
	ValDisplay vd_Area2,pos={16,188},size={180,18},title="Area 2"
	ValDisplay vd_Area2,value= root:packages:ThermalAnalysis:gArea2,live= 1
	
	ValDisplay vd_Progress,pos={14,222},size={183,20},title="Progress", mode=0
	ValDisplay vd_Progress,limits={0,100,0},barmisc={0,35},highColor= (0,43520,65280)
	ValDisplay vd_Progress,value= root:packages:ThermalAnalysis:gPercent
		
	Button but_start,pos={16,250},size={187,20},title="Start", proc=startIterator
	
	DrawText 45,298, "Suhas Somnath, UIUC 2009"
End

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Function startIterator (ctrlname) : ButtonControl
	String ctrlname
	
	String dfSave = GetDataFolder(1)
	SetDataFolder root:packages:ThermalAnalysis
	
	NVAR gsamples, gcurrent, giter, gPercent,gArea1,gArea2
	
	gcurrent = 1
	gPercent = 0
	gArea1 = 0
	gArea2 = 0
	
	Make/O/N=(giter,2) thermalareas
	
	PV("ThermalSamples",gsamples)
	PV("ThermalSamplesLimit",gsamples)
	
	ARCheckFunc("ARUserCallbackMasterCheck_1",1)
	
	SetDataFolder dfSave
	
	//Call The iterator:
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
		SetDataFolder root:packages:ThermalAnalysis
	
		NVAR gcurrent, giter,gPercent
		
		print "Completed iteration #" + num2str(gcurrent) + " of " + num2str(giter)
		gPercent = gcurrent*100/gIter
		
		// Calculating area(s) under the curve
		areaUnderCurve(gcurrent-1)
		
		gcurrent +=1
		
		if(gcurrent <= giter)
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
			gcurrent=1
			SetDataFolder root:
			ARCheckFunc("ARUserCallbackMasterCheck_1",0)
			
			// Displaying the results:			
			displayAreas()
			// Killing the thermal window
			KillWindow ThermalGraph
		endif
		
	endif

End

Function areaUnderCurve(index)
	Variable index

	String dfSave = GetDataFolder(1)
	SetDataFolder root:packages:ThermalAnalysis
	
	NVAR gstart1,gend1,gstart2,gend2	
	Wave thermwave = root:packages:MFP3D:Tune:TotalPSD
	Wave thermalAreas
	
	if(gstart1 > gend1)
		gend1=gstart1
	endif
	if(gstart2 > gend2)
		gend2=gstart2
	endif
	
	Variable i
	Variable total1 = 0
	Variable total2 = 0
	if(gend1 <= numpnts(thermwave))
		for (i=gstart1 ; i <= gend1 ; i+=1)
			total1 += thermwave[i]
		endfor
	endif
	if(gend2 <= numpnts(thermwave))
		for (i=gstart2 ; i <= gend2 ; i+=1)
			total2 += thermwave[i]
		endfor
	endif
	
	thermalAreas[index][0] = total1
	thermalAreas[index][1] = total2
		
	SetDataFolder dfSave	
End

Function displayAreas()

	String dfSave = GetDataFolder(1)
	SetDataFolder root:packages:ThermalAnalysis

	Wave thermalAreas
	NVAR gArea1,gArea2
	
	Variable i,total1,total2
	total1 = 0
	total2 = 0
	
	for(i=0; i<numpnts(thermalAreas); i+=1)
		total1 += thermalAreas[i][0]
		total2 += thermalAreas[i][1]
	endfor
	
	gArea1 = total1/numpnts(thermalAreas)
	gArea2 = total2/numpnts(thermalAreas)

	SetDataFolder dfSave	

End