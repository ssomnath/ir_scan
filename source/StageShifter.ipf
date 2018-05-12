#pragma rtGlobals=1		// Use modern global access method.

Menu "Macros"
	"Stage Shifter", StageShifterDriver()
End

Function StageShifterDriver()
	
	// If the panel is already created, just bring it to the front.
	DoWindow/F StageShifterPanel
	if (V_Flag != 0)
		return 0
	endif
	
	String dfSave = GetDataFolder(1)
	// Create a data folder in Packages to store globals.
	NewDataFolder/O/S root:packages:StageShifter
	
	Variable/G gXm_out = 0
	Variable/G gXP_delta = 0
	Variable/G gXP_in = 0
	Variable/G gXP_fin = 0
	Variable/G gXS_in = 0
	Variable/G gXS_fin = 0
	Variable/G gXm_act = 0
	Variable/G gErr_m = 0
	Variable/G gErr_per = 0
	
	// Create the control panel.
	Execute "StageShifterPanel()"
	//Reset the datafolder to the root / previous folder
	SetDataFolder dfSave
	
End

Window StageShifterPanel(): Panel
	
	PauseUpdate; Silent 1		// building window...
	NewPanel /K=1 /W=(800,400, 1060,775) as "X Stage Shifter"
	SetDrawLayer UserBack
	
	SetVariable sv_Xm_out_mov,pos={16,16},size={225,18},title="Movement expected (um)"
	SetVariable sv_Xm_out_mov,limits={-10,10,0}, value=root:packages:StageShifter:gXm_out
	
	ValDisplay vd_XV_out_mov,pos={51,43},size={187,18},title="XPiezo change (V)"
	ValDisplay vd_XV_out_mov, value=root:packages:StageShifter:gXP_delta
	
	ValDisplay vd_Pzs,pos={66,73},size={173,18},title="XPiezoSens (V)"
	ValDisplay vd_Pzs,value=GV("XPiezoSens")
	
	ValDisplay vd_xlv,pos={66,101},size={173,18},title="XLVDTSens (V)"
	ValDisplay vd_xlv,value=GV("XLVDTSens")
	
	DrawText 16,148, "X output Piezo Voltages"
		
	ValDisplay vd_XP_in,pos={33,159},size={97,18},title="Initial"
	ValDisplay vd_XP_in,value=root:packages:StageShifter:gXP_in
	
	ValDisplay vd_XP_fin,pos={145,159},size={95,18},title="Final"
	ValDisplay vd_XP_fin,value=root:packages:StageShifter:gXP_fin
	
	DrawText 16,205, "X input sensor Voltages:"
	
	ValDisplay vd_XS_in,pos={33,215},size={97,18},title="Initial"
	ValDisplay vd_XS_in,value=root:packages:StageShifter:gXS_in
	
	ValDisplay vd_XS_fin,pos={145,215},size={95,18},title="Final"
	ValDisplay vd_XS_fin,value=root:packages:StageShifter:gXS_fin
		
	ValDisplay vd_Xm_in,pos={46,250},size={187,18},title="Actual Movement (um)"
	ValDisplay vd_Xm_in,value=root:packages:StageShifter:gXm_act
	
	ValDisplay vd_Err_m,pos={16,280},size={130,18},title="Error (um)"
	ValDisplay vd_Err_m,value=root:packages:StageShifter:gErr_m
	
	ValDisplay vd_Err_per,pos={157,280},size={85,18},title="(%)"
	ValDisplay vd_Err_per,value=root:packages:StageShifter:gErr_per
	
	Button but_move,pos={16,317},size={230,20},title="Move", proc=moveStage
	
	DrawText 91,369, "Suhas Somnath, UIUC 2010"

End

Function moveStage (ctrlname) : ButtonControl
	String ctrlname
	
	String dfSave = GetDataFolder(1)
	SetDataFolder root:packages:StageShifter
	
	NVAR gXm_out, gXP_delta, gXP_in, gXP_fin, gXS_in, gXS_fin, gXm_act, gErr_m, gErr_per
	
	Variable xM_out = 1e-6 * gXm_out
	
	// First calculating how much voltage to apply to the X Piezo	
	// Will be using the XPiezoSens (although not the most accurate method)
	gXP_delta = Xm_out/GV("XPiezoSens")
	
	//Calculating the Xpiezo values:
	gXP_in = td_rv("X%Output")
	gXP_fin = gXP_delta + gXP_in
	
	//Reading initial X sensor value
	gXS_in = td_rv("X%Input")
	
	//Moving
	td_wv("X%Output",gXP_fin)
	
	//Reading final X sensor value
	gXS_fin = td_rv("X%Input")
	
	//Calculating actual movement:
	gXm_act = GV("XLVDTSens") * (gXS_fin - gXS_in)
	
	//Errors:
	gErr_m = abs(gXm_act - Xm_out)
	gErr_per = 100*gErr_m/gXm_act
	
	//Setting in terms of microns:
	gErr_m *= 1e+6
	gXm_act *= 1e+6
		
	SetDataFolder dfSave
End