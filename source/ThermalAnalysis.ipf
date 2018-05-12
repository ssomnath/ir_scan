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
	
	// Samples within a Thermal
	Variable/G gsamples=10
	
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
	NewPanel /K=1 /W=(485,145, 700,450) as "Thermal Iterator v.1.2"
	SetDrawLayer UserBack
	
	SetVariable sv_samples,pos={16,16},size={184,18},title="Number of Samples", limits={0,inf,1}	
	SetVariable sv_samples,value= root:packages:ThermalAnalysis:gsamples,live= 1
	SetVariable sv_samples,help={"Number of samples taken per Thermal"} 
	
	Popupmenu pm_resolution,pos={16,43},size={135,18},title="Resolution"
	Popupmenu pm_resolution,value="1, best;2;3;4;5, default;6;7;8;9, fastest;" ,live= 1, proc=ResolPopup
		
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
	
	ValDisplay vd_ThermalProgress,pos={16,218},size={183,20},title="Progress", mode=0
	ValDisplay vd_ThermalProgress,limits={0,100,0},barmisc={0,35},highColor= (0,43520,65280)
	ValDisplay vd_ThermalProgress,value=100*root:Packages:MFP3D:Main:Variables:ThermalVariablesWave[%ThermalCounter]/root:packages:ThermalAnalysis:gsamples
		
	Button but_start,pos={16,250},size={187,20},title="Start Thermal", proc=startIterator
	
	DrawText 45,298, "Suhas Somnath, UIUC 2009"
End

Function ResolPopup(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa
		
	switch( pa.eventCode )
		case 2: // mouse up
			ThermalResolutionPopupFunc("ThermalResolutionPopup_1",pa.popNum,pa.popStr)
			break
	endswitch
	
End

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Function startIterator (ctrlname) : ButtonControl
	String ctrlname
	
	String dfSave = GetDataFolder(1)
	SetDataFolder root:packages:ThermalAnalysis
	
	NVAR gsamples, gArea1,gArea2
	
	gArea1 = 0
	gArea2 = 0
	
	NVAR gstart1,gend1,gstart2,gend2
	
	if(gstart1 > gend1)
		gend1=gstart1
	endif
	if(gstart2 > gend2)
		gend2=gstart2
	endif
		
	PV("ThermalSamples",gsamples)
	PV("ThermalSamplesLimit",gsamples)
	
	ARCheckFunc("ARUserCallbackMasterCheck_1",1)
	
	SetDataFolder dfSave
	
	//Call The iterator:
	DoThermalFunc("DoThermal")

End

Function Thermaliterator()

	areaUnderCurve()
	
	DoWindow/K ThermalGraph
		
	ARCheckFunc("ARUserCallbackMasterCheck_1",0)
	
End

Function areaUnderCurve()

	String dfSave = GetDataFolder(1)
	SetDataFolder root:packages:ThermalAnalysis
	
	NVAR gstart1,gend1,gstart2,gend2, gArea1, gArea2
	Wave thermwave = root:packages:MFP3D:Tune:TotalPSD
	
	Variable i
	if(gend1 <= numpnts(thermwave))
		for (i=gstart1 ; i <= gend1 ; i+=1)
			gArea1 += thermwave[i]
		endfor
	endif
	if(gend2 <= numpnts(thermwave))
		for (i=gstart2 ; i <= gend2 ; i+=1)
			gArea2 += thermwave[i]
		endfor
	endif
			
	SetDataFolder dfSave	
End