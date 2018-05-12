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
	NewPanel /K=1 /W=(485,145, 700,280) as "Thermal Iterator v.1.0"
	SetDrawLayer UserBack
	
	SetVariable sv_maxiter,pos={16,14},size={184,18},title="Number of Iterations"
	SetVariable sv_maxiter,value= root:packages:ThermalAnalysis:giter,live= 1
	SetVariable sv_itertime,pos={16,43},size={184,18},title="Number of Samples", limits={0,inf,1}	
	SetVariable sv_itertime,value= root:packages:ThermalAnalysis:gsamples,live= 1
	
	Button but_start,pos={16,77},size={74,20},title="Start", proc=startIterator
	Button but_save,pos={102,77},size={98,20},title="Save Results", proc=saveResults
	
	DrawText 45,124, "Suhas Somnath, UIUC 2009"
End

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Function startIterator (ctrlname) : ButtonControl
	String ctrlname
	
	String dfSave = GetDataFolder(1)
	SetDataFolder root:packages:ThermalAnalysis
	
	NVAR gsamples, gcurrent, giter
	
	gcurrent = 1
	
	Make/O/N=(giter) thermalpeakwave
	
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
	
		NVAR gcurrent, giter
		
		print "Completed iteration #" + num2str(gcurrent) + " of " + num2str(giter)
		
		// Storing / taking value from the themal??
		Wave thermalpeakwave
		thermalpeakwave[gcurrent-1] = peakThermalValue()
		
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
			Edit/K=0 'thermalpeakwave';DelayUpdate
			display thermalpeakwave
		endif
		
	endif

End

Function peakThermalValue()
	
	Wave thermwave = root:packages:MFP3D:Tune:TotalPSD
	
	Variable i
	for (i=2 ; i < numpnts(thermwave) ; i+=1)
		//print "i = " + num2str(i)
		//print "comparing indices i and i-1 as : " + num2str(thermwave[i]) + " vs " + num2str(thermwave[i-1])
		if(thermwave[i] > thermwave[i-1])
			//print "starting ascent at index " +  num2str(i-1)
			break
		endif
	endfor
	
	// reached the starting part of the ascent to the peak
	
	for (i=i ; i < numpnts(thermwave) ; i+=1)
		if(thermwave[i] < thermwave[i-1])
			//print "peak at index " + num2str(i-1)
			return thermwave[i-1]
		endif
	endfor	
	
	return -1
End

Function saveResults (ctrlname) : ButtonControl
	String ctrlname
	
	String dfSave = GetDataFolder(1)
	// Grabbing the current Lithos that are being displayed to the user
	setdatafolder root:packages:ThermalAnalysis
	
	if( exists("thermalpeakwave") != 1)
		DoAlert 0, "\t\tNo results found!\nPerform Iterations before saving!"
		return -1
	endif
	// O - overwrite ok, J - tab limted, W - save wave name, I - provides dialog
	Save /O/J/W/I thermalpeakwave
	
	setdatafolder dfsave
	
End