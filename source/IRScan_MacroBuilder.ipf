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
	
	// array size
	Variable scanpts = NumVarOrDefault(":gscanpts",16)
	Variable/G gscanpts= scanpts
	Variable scanlines = NumVarOrDefault(":gscanlines",16)
	Variable/G gscanlines= scanlines
	//Variables for the indices of Thermal
	Variable start1 = NumVarOrDefault(":gThermalstart1",58)
	Variable/G gThermalstart1= start1
	Variable end1 = NumVarOrDefault(":gThermalend1",63)
	Variable/G gThermalend1= end1
	Variable start2 = NumVarOrDefault(":gThermalstart2",72)
	Variable/G gThermalstart2= start2
	Variable end2 = NumVarOrDefault(":gThermalend2",75)
	Variable/G gThermalend2= end2
	
	Variable xindex = NumVarOrDefault(":gxindex",0)
	Variable/G gxindex= xindex
	Variable yindex = NumVarOrDefault(":gyindex",0)
	Variable/G gyindex= yindex
	
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
	NewPanel /K=1 /W=(485,145, 700,400) as "IR Scan v.3.1"
	SetDrawLayer UserBack
	
	SetDrawEnv fstyle= 1
	DrawText 16,25, "Point Scan Parameters:"
	
	SetVariable sv_scanlines,pos={16,34},size={150,18},title="IR Scan Lines", limits={1,inf,1}	
	SetVariable sv_scanlines,value= root:packages:IRScan:gscanlines,live= 1
	SetVariable sv_scanlines,help={"This is NOT related to the scan lines in Master Panel"}
	SetVariable sv_scanpoints,pos={16,62},size={150,18},title="IR Scan Points", limits={1,inf,1}	
	SetVariable sv_scanpoints,value= root:packages:IRScan:gscanpts,live= 1
	SetVariable sv_scanpoints,help={"This is NOT related to the scan points in Master Panel"}
	
	SetDrawEnv fstyle=1
	DrawText 16,110, "Area under Curve Indices:"
	
	SetVariable sv_start1,pos={16,125},size={84,18},title="Start 1", limits={0,inf,1}
	SetVariable sv_start1,value= root:packages:IRScan:gThermalstart1,live= 1
	SetVariable sv_end1,pos={115,125},size={84,18},title="End 1", limits={0,inf,1}
	SetVariable sv_end1,value= root:packages:IRScan:gThermalend1,live= 1
	
	SetVariable sv_start2,pos={16,155},size={84,18},title="Start 2", limits={0,inf,1}
	SetVariable sv_start2,value= root:packages:IRScan:gThermalstart2,live= 1
	SetVariable sv_end2,pos={115,155},size={84,18},title="End 2", limits={0,inf,1}
	SetVariable sv_end2,value= root:packages:IRScan:gThermalend2,live= 1
		
	Button but_start,pos={15,182},size={184,24},title="Set Variables", proc=startProc
	
	SetDrawEnv fstyle= 1 
	SetDrawEnv textrgb= (0,0,65280)
	DrawText 49,237, "Suhas Somnath, UIUC 2010"
	
End

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////// WRAP UP SCAN ///////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Display Results
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Function DisplayScanResults()

	//Displaying results:
	String dfSave = GetDataFolder(1)
	SetDataFolder root:packages:IRScan
	Edit/K=0 'finalThermal';DelayUpdate
	SetDataFolder dfSave
	DoAlert 0, "There are two 'pages' in this table, one for each area under the curve\nUse the arrows in the top right corner to see them\nTo export this table go to: \nFile>>Save Table Copy >> Select txt or csv as type"

End

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////// START SCAN ////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Function startProc (ctrlname) : ButtonControl
	String ctrlname
	
	String dfSave = GetDataFolder(1)
	SetDataFolder root:packages:IRScan
	
	NVAR gscanlines, gscanpts
	
	//Preparing the wave in which the final area values are to be stored:
	//Changing the number of area-under-curve values to be stored can 
	//easily be changed by increasing the number of layers 
	//Best to redimension the wave because remaking the wave doesn't
	//erase all the old data
	Redimension/N=0 finalThermal
	Make/O/N=(gscanpts,gscanlines,2) finalThermal
	
	SetDataFolder dfSave
End


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////// AREA UNDER CURVE //////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// This is the function calculates the area(s) under the curve (thermal) and stores them 
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Function areaUnderCurve()

	String dfSave = GetDataFolder(1)
	SetDataFolder root:packages:IRScan
	
	NVAR gThermalStart1,gThermalEnd1,gThermalStart2,gThermalEnd2, gScanLines, gScanPts
	Wave thermwave = root:packages:MFP3D:Tune:TotalPSD
	NVAR gXindex, gYindex
	Wave finalThermal
	
	if(gYindex == gScanlines)
		//reached end of scan. should not be here
		DoAlert 0, "Error!\nAlready finished saving all data points!"
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
	
	finalThermal[gXindex][gYindex][0] = total1
	finalThermal[gXindex][gYindex][1] = total2
	
	// setting the X and Y index to the next values:
	if(gXindex == gScanLines - 1)
		gXindex = 0
		gYindex += 1
	else
		gXindex += 1
	endif
		
	SetDataFolder dfSave	
End