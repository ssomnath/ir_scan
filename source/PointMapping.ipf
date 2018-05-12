#pragma rtGlobals=1		// Use modern global access method.
#pragma ModuleName = PointMapping
	
Function InitPointMapping()

	String DataFolder = GetDF("Variables")
	
	
	Wave GVW = $DataFolder+"GeneralVariablesWave"
	Wave/T GVD = $DataFolder+"GeneralVariablesDescription"
	String LabelList = "PointMapInitFunc;PointMapFunc;PointMapRampFunc;PointMapStopFunc;"
	String ValueList = ";;;;"
	Variable A, nop = ItemsInList(LabelList,";")
	String LabelName, Value
	Variable Index
	for (A = 0;A < nop;A += 1)
		LabelName = StringFromList(A,LabelList,";")
		Value = StringFromList(A,ValueList,";")
		Index = FindDimLabel(GVD,0,LabelName)
		if (Index >= 0)
			continue
		endif
		Index = DimSize(GVD,0)
		InsertPoints/M=0 Index,1,GVD,GVW
		SetDimLabel 0,Index,$LabelName,GVW,GVD
		GVD[Index][0] = Value
	endfor
	
	
	String VarName = GWNS("FMapStatus") 
	
	Wave VarWave = $VarName
	
	Wave/T VarDescript = $(VarName[0,Strlen(VarName)-5]+"Description")
	Index = FindDimLabel(VarWave,0,"PMapStatus")
	if (Index < 0)
		Index = DimSize(VarWave,0)
		InsertPoints/M=0 Index,1,VarWave,VarDescript
		SetDimLabel 0,Index,PMapStatus,VarWave,VarDescript
		
	endif
		
	DataFolder = GetDF("Windows")
	
	Wave/Z PanelParms = $DataFolder+"PointMapPanelParms"
	if (!WaveExists(PanelParms))
		Wave PanelParms = $DataFolder+"ForceMapPanelParms"
		Wave/T PanelDescript = $DataFolder+"ForceMapPanelDescription"
		Duplicate PanelParms,$DataFolder+"PointMapPanelParms"
		Duplicate/O PanelDescript,$DataFolder+"PointMapPanelDescription"
	endif
	
End //InitPointMapping


Window PointMapping()


	MakePanel("PointMap")
	
	
End //PointMapping	
	

Function MakePointMapPanel(var)		//put the controls on the main panel(1) or the master panel(0)
	variable var
	
	String WindowsFolder = GetDF("Windows")
	String GraphStr = GetFuncName()
	GraphStr = GraphStr[4,Strlen(GraphStr)-1]
	Wave PanelParms = $WindowsFolder+GraphStr+"Parms"
	
	if (GV("Is1DPLus"))
//		if (!Var)
//			GraphStr = ARPanelMasterLookup(GraphStr)
//		endif
		DoWindow/K $GraphStr
		return(0)
	endif


	Variable HelpPos = PanelParms[%HelpPos][0]			//is hijacked later.
	Variable SetUpLeft = PanelParms[%SetupLeft][0]		//is hijacked later
	Variable ControlBit = PanelParms[%Control1Bit][0]
	Variable OldControlBit = PanelParms[%oldControl1Bit][0]
	Variable Margin = PanelParms[%Margin][0]
	Variable ButtonWidth = PanelParms[%ButtonWidth][0]
	Variable ButtonHeight = PanelParms[%ButtonHeight][0]
	Variable Red = PanelParms[%HighLightRedColor][0]
	Variable Green = PanelParms[%HighLightGreenColor][0]
	Variable Blue = PanelParms[%HighLightBlueColor][0]
	Variable BorderRed = PanelParms[%RedColor][0]
	Variable BorderBlue = PanelParms[%BlueColor][0]
	Variable BorderGreen = PanelParms[%GreenColor][0]
	Variable StepSize = 25
	Variable BodyWidth = PanelParms[%BodyWidth][0]
	Variable SetVarWidth = NaN
	Variable SetVarLeft = PanelParms[%FirstSetVar][0]

	
	Variable SecondMargin = PanelParms[%SecondMargin][0]
	
	Variable Bit = 0
	String HelpFunc = "ARHelpFunc"
	String SetupFunc = "ARSetupPanel"
	Variable Enab = 0
	Variable DisableHelp = 0
	Variable LeftPos = PanelParms[%FirstSetVar][0]
	Variable FontSize = ARGetFontSize(10)
	String ControlName, ControlName0, ControlName1, ControlName2, ControlName3
	String HelpName
	Variable WhichBit = 1
	String HighName
	Variable TabSpace = 10		//space beneath the sub tab.
		
	Variable TabNum = ARPanelTabNumLookup(GraphStr)
	String TabStr = "_"+num2str(TabNum)
	String SetupTabStr = TabStr+"9"
	String SetUpBaseName = GraphStr[0,strlen(GraphStr)-6]
	
	String MakeTitle = "", MakeName = "", SetupName = "", OtherMakeName = "", OtherGraphStr = ""
	Variable CurrentTop = 10
	if (Var == 0)		//MasterPanel
		CurrentTop = 40
		MakeTitle = "PMap Panel"
		MakeName = GraphStr+"Button"+TabStr
		OtherMakeName = ARPanelMasterLookup(GraphStr)+Tabstr
		Enab = 1		//hide the controls, tabfunc will clear us up.
		OtherGraphStr = GraphStr
		GraphStr = ARPanelMasterLookup(GraphStr)
	elseif (Var == 1)	
		CurrentTop = 10
		MakeTitle = "Master Panel"
		OtherGraphStr = ARPanelMasterLookup(GraphStr)
		MakeName = OtherGraphStr+Tabstr
		OtherMakeName = GraphStr+"Button"+TabStr
		Enab = 0
	endif



	String ParmName, ParmName0, ParmName1, ParmName2, ParmName3, ControlList, TitleList
	Variable Mode, GroupBoxTop
	
//code custom to the Force Map Panel
	Variable ImagingMode = GV("ImagingMode")		//are we doing contact or AC mode
	Variable HamsterRow = LeftPos+BodyWidth+7
	HelpPos = HamsterRow+20
	SetupLeft = HelpPos + 100
	Variable HamsterNumber = PanelParms[%HamsterNumber0][0]
	Variable hamsterCount = 1
	Variable HighLightbit = PanelParms[%HighLight1Bit][0]
	Variable TitleRed, TitleBlue, TitleGreen
	Variable FMapVar
	String FMapStr, SrcStr



	
	//Time for the sub tab!
	
	WhichBit = 2
	String WhichBitStr = num2str(WhichBit)
	ControlBit = PanelParms[%$"Control"+WhichBitStr+"Bit"][0]
	OldControlBit = PanelParms[%$"OldControl"+WhichBitStr+"Bit"][0]
	HighLightBit = Panelparms[%$"HighLight"+WhichBitStr+"Bit"][0]
	Variable SubTabNum = PanelParms[%SubTabNum][0]
	
	String UserData = ""
	String SetupData = ""
	Variable TabHeight = 265
	
	
	String TabCtrlName = "PointMapTab"+TabStr
	
	
	
	TabControl $TabCtrlName,win=$GraphStr,pos={8,CurrentTop},size={5,TabHeight},proc=ForceTabFunc,font=Arial,FSize=13,Disable=Enab
	TabControl $TabCtrlName,Win=$GraphStr,TabLabel(0)="Scan",Tablabel(1)="Adv.",Value=min(SubTabNum,1),UserData="0"
	CurrentTop += 30
	TabHeight -= 30
	Variable ControlTopMem = CurrentTop
	Variable BitMem = Bit
	Bit = 0
	



	controlList = "ScanSize;FMapScanTime;FMapXYVelocity;XOffset;YOffset;ScanAngle;FMapScanPoints;FMapScanLines;ScanRatio;"
	String HamControlList = "ScanSize;FMapScanLineTime;FMapXYVelocity;XOffset;YOffset;"
	String HighLightName = ""
	Variable stop = ItemsInList(controlList)
	Variable Start
	Variable HamIndex
	String Title = ""
	for (Bit = 0;Bit < stop;Bit += 1)
		
		ParmName = StringFromList(Bit,controlList)
		HamIndex = WhichListItem(LowerStr(ParmName),LowerStr(HamControlList),";",0)
		//this controls whether this control is added or not
		if (!(2^bit & ControlBit))
			if (HamIndex >= 0)
				hamsterCount += 1
			endif
			Continue
		endif
		FMapStr = StringFromList(StringMatch(ParmName,"FMap*"),"Main;FMap;",";")
		ControlName = ReplaceString(" ",StudlyCapsToSpaces(ParmName),"_",1)+tabStr
		HighLightName = ""		//this is the name of the control that will be highlighted if selected.
		MakeButton(GraphStr,ControlName,"?",15,15,HelpPos,CurrentTop+1,"ARHelpFunc",DisableHelp)
		UserData += ControlName+";"
		if (HamIndex >= 0)
			ControlName = ParmName+"Box"+TabStr
			if (!StringMatch(ControlName,"FMap*"))
				ControlName = "FMap"+ControlName
			endif
			MakeCheckbox(GraphStr,ControlName," ",HamsterRow,CurrentTop+2,"FMapBoxFunc",(hamsterCount == HamsterNumber),1,Enab)
			UserData += ControlName+";"
			hamsterCount += 1
		endif
		if (stringmatch(ParmName,"ScanRatio"))
			//Switched it so that FastRatio is made first.
			//This way tabing through setvars flows better.
			ControlName = MakeSetVar(GraphStr,"","FastRatio","","FMapSetVarFunc","",LeftPos,currentTop,setVarWidth/2-10,bodyWidth/2-5,tabNum,fontSize,Enab)
			UserData += ControlName+";"
			HighLightName = ControlName
			UserData += MakeSetVar(GraphStr,"","SlowRatio","","FMapSetVarFunc","",LeftPos+BodyWidth/2+5,currentTop,setVarWidth/2-10,bodyWidth/2-5,tabNum,fontSize,Enab)+";"
		elseif (stringmatch(ParmName,"*DelayUpdate"))
			ControlName = ParmName+"Box"+TabStr
			MakeCheckbox(GraphStr,ControlName,"Delay Update",LeftPos-75,CurrentTop,FMapStr+"BoxFunc",GV(ParmName),0,Enab)
			UserData += ControlName+";"
			HighLightBit = HighLightBit & ~2^Bit		//force it off.
		else
			Title = ""
			if (stringmatch(ParmName,"Setpoint"))
				controlName = "SetpointSetVar"+TabStr
				ParmName = StringFromList(ImagingMode,"Deflection;Amplitude;Frequency;Deflection",";")+"SetpointVolts"
//			elseif (StringMatch(ParmName,"FMapXYVelocity"))
//				ControlName = "FMapTimePrefsButton"+TabStr
//				MakeButton(GraphStr,ControlName,"Prefs",40,20,15,CurrentTop,"PmapButtonFunc",Enab)
//				UserData += ControlName+";"
//				ControlName = ""
//					
			else
				ControlName = ""
			endif
			if (StringMatch(ParmName,"FMapScanLines") || StringMatch(ParmName,"FMapScanPoints"))
				Title = ParmName[8,Strlen(ParmName)-1]
			endif
			controlName = MakeSetVar(GraphStr,controlName,ParmName,Title,"FMapSetVarFunc","",LeftPos,currentTop,setVarWidth,bodyWidth,tabNum,fontSize,Enab)
			UserData += ControlName+";"
			HighLightName = ControlName
		endif
		
		if ((HighLightBit & 2^Bit) && (Strlen(highLightName)))
			SetVariable $HighLightName,win=$GraphStr,labelback=(Red,Green,Blue)
		endif
		ControlName = SetupBaseName+"Bit_"+num2str(bit+(WhichBit-1)*32)+SetupTabStr
		UpdateCheckBox(GraphStr,ControlName,"Show?",SetupLeft,CurrentTop,"NoShowFunc",(2^bit & oldControlBit),0,1)
		CheckBox $ControlName,Win=$GraphStr,UserData=WhichBitStr
		SetupData += ControlName+";"
		if (!StringMatch(ParmName,"*DelayUpdate"))
			ControlName = SetupBaseName+"Color_"+num2str(bit+(WhichBit-1)*32)+SetupTabStr
			UpdateCheckBox(GraphStr,ControlName,"Color?",HelpPos+30,CurrentTop,"HighLightControlFunc",(2^bit & HighLightBit),0,1)
			CheckBox $ControlName,Win=$GraphStr,UserData=WhichBitStr
			SetupData += ControlName+";"
		endif
		CurrentTop += StepSize		//increment the vertical position
	
	endfor
	
	//done with the scan tab
	TabControl $TabCtrlName,Win=$GraphStr,UserData(X0)=UserData,UserData(S0)=SetupData,UserData(B0)=num2str(CurrentTop+TabSpace)
	
	
	
	//reset for Calc Tab.
	UserData = ""
	SetupData = ""
	CurrentTop = ControlTopMem
	
	WhichBit = 3
	WhichBitStr = num2str(WhichBit)
	ControlBit = PanelParms[%$"Control"+WhichBitStr+"Bit"][0]
	OldControlBit = PanelParms[%$"OldControl"+WhichBitStr+"Bit"][0]
	HighLightBit = Panelparms[%$"HighLight"+WhichBitStr+"Bit"][0]
	Bit = 0
	HamsterNumber = PanelParms[%HamsterNumber1][0]
	HamsterCount = 1

	
	
	
	//Channels Title Box
	ParmName = "PMapFuncs"
	ControlName = ParmName+"Title"+TabStr
	HelpName = "PMap_Funcs"+TabStr
	SetupName = SetupBaseName+"Bit_"+num2str(bit+(WhichBit-1)*32)+SetupTabStr
	SetupData += SetupName+";"
	UserData += ControlName+";"+HelpName+";"


	if (2^bit & ControlBit)
		MakeTitleBox(GraphStr,ControlName,"User Functions",LeftPos,CurrentTop,BorderRed,BorderGreen,BorderBlue,Enab,Frame=1,FontSize=FontSize)
		
		MakeButton(GraphStr,HelpName,"?",15,15,HelpPos,CurrentTop+1,"ARHelpFunc",DisableHelp)
		UpdateCheckBox(GraphStr,SetupName,"Show?",SetupLeft,CurrentTop,"NoShowFunc",(2^bit & oldControlBit),0,1)
		CheckBox $SetupName,win=$GraphStr,UserData=WHichBitStr
		CurrentTop += StepSize
	endif
	bit += 1



	ControlList = "PointMapInitFunc;PointMapFunc;PointMapRampFunc;PointMapStopFunc;"
	TitleList = "Init Function;Point Function;Ramp Function;Stop Function;"
	Stop = Bit+ItemsInList(ControlList,";")
	Start = Bit
	for (Bit = Start;Bit < Stop;Bit += 1)
		ParmName = StringFromList(Bit-Start,ControlList,";")
		ControlName0 = ParmName+"SetVar"+TabStr
		ControlName1 = ParmName+"Button"+TabStr
		
		HelpName = ReplaceString(" ",StudlyCapsToSpaces(ParmName)+TabStr,"_")
		UserData += ControlName0+";"+ControlName1+";"+HelpName+";"
		SetupName = SetupBaseName+"Bit_"+num2str(bit+(WhichBit-1)*32)+SetupTabStr
		SetupData += SetupName+";"
	
		
		
		if (!(2^bit & ControlBit))
			continue
		endif
		LeftPos = SetVarLeft
		Title = StringFromList(Bit-Start,TitleList,";")
		SrcStr = GWDS(ParmName)
		MakeSetVar(GraphStr,ControlName0,"BogusVar",Title,"PointMapFuncFunc","value="+SrcStr+"[%"+ParmName+"][0]",LeftPos,CurrentTop,NaN,BodyWidth,TabNum,fontSize,Enab)
		CurrentTop += StepSize
		LeftPos += BodyWidth-ButtonWidth
		MakeButton(GraphStr,ControlName1,"Edit",ButtonWidth,ButtonHeight,LeftPos,CurrentTop,"ARCallbackButtonFunc",Enab)
		
		CurrentTop -= StepSize/2
		
		MakeButton(GraphStr,HelpName,"?",15,15,HelpPos,CurrentTop+1,"ARHelpFunc",DisableHelp)
		UpdateCheckBox(GraphStr,SetupName,"Show?",SetupLeft,CurrentTop,"NoShowFunc",(2^bit & oldControlBit),0,1)
		CheckBox $SetupName,win=$GraphStr,UserData=WHichBitStr
		CurrentTop += StepSize*2
		//CurrentTop += StepSize/2
		
	endfor
	
	LeftPos = SetVarLeft





	
	//Output Image Name
//
//
//	ParmName = "FMapAutoName"
//	ControlName = ParmName+"Box"+TabStr
//	HelpName = "FMap_Auto_Name"+TabStr
//	SetupName = SetupBaseName+"Bit_"+num2str(bit+(WhichBit-1)*32)+SetupTabStr
//	SetupData += SetupName+";"
//	UserData += ControlName+";"+HelpName+";"
//
//	if (2^bit & ControlBit)
//	
//		MakeCheckbox(GraphStr,ControlName,"Auto Name",LeftPos,CurrentTop,"FMapBoxFunc",GV(ParmName),0,Enab)
//	
//		MakeButton(GraphStr,HelpName,"?",15,15,HelpPos,CurrentTop+1,"ARHelpFunc",DisableHelp)
//		UpdateCheckBox(GraphStr,SetupName,"Show?",SetupLeft,CurrentTop,"NoShowFunc",(2^bit & oldControlBit),0,1)
//		CheckBox $SetupName,win=$GraphStr,UserData=WHichBitStr
//		CurrentTop += StepSize
//	endif
//	bit += 1	
//	
//
//
//	
//	ParmName = "FMapOutputImage"
//	ControlName = ParmName+"SetVar"+TabStr
//	ControlName0 = ParmName+"SetVar_"+TabStr
//	HelpName = "FMap_output_Image"+TabStr
//	SetupName = SetupBaseName+"Bit_"+num2str(bit+(WhichBit-1)*32)+SetupTabStr
//	HighName = SetupBaseName+"Color_"+num2str(bit+(WhichBit-1)*32)+SetupTabStr
//	SetupData += SetupName+";"+HighName+";"
//	UserData += ControlName+";"+HelpName+";"+ControlName0+";"
//
//	if (2^bit & ControlBit)
//	
//		MakeSetVar(GraphStr,ControlName,"BogusVar","Image Name","FMapStringSetVarFunc","value="+GWDS(ParmName)+"[%"+ParmName+"][%Description]",LeftPos,CurrentTop,NaN,BodyWidth,TabNum,fontSize,Enab)
//		if (HighLightBit & 2^Bit)
//			SetVariable $controlName,win=$GraphStr,labelback=(Red,Green,Blue)
//		endif
//		
//		MakeSetVar(GraphStr,ControlName0,ParmName," ","FMapStringSetVarFunc","",LeftPos+BodyWidth,CurrentTop,NaN,17,TabNum,fontSize,Enab)
//
//		MakeButton(GraphStr,HelpName,"?",15,15,HelpPos,CurrentTop+1,"ARHelpFunc",DisableHelp)
//		UpdateCheckBox(GraphStr,SetupName,"Show?",SetupLeft,CurrentTop,"NoShowFunc",(2^bit & oldControlBit),0,1)
//		CheckBox $SetupName,win=$GraphStr,UserData=WHichBitStr
//		UpdateCheckBox(GraphStr,HighName,"Color?",HelpPos+30,CurrentTop,"HighLightControlFunc",(2^bit & HighLightBit),0,1)
//		CheckBox $HighName,win=$GraphStr,UserData=WHichBitStr
//		CurrentTop += StepSize
//	endif
//	bit += 1	
	
	
	
	//done with the Calc tab
	TabControl $TabCtrlName,Win=$GraphStr,UserData(X1)=UserData,UserData(S1)=SetupData,UserData(B1)=num2str(CurrentTop+TabSpace)
	
	
	//Bottom of the panel controls (Under the tab)
//reset all tab parms.
	Bit = BitMem
	CurrentTop = ControlTopMem+TabHeight+TabSpace
	WhichBit = 1
	WhichBitStr = num2str(WhichBit)
	ControlBit = PanelParms[%$"Control"+WhichBitStr+"Bit"][0]
	OldControlBit = PanelParms[%$"OldControl"+WhichBitStr+"Bit"][0]
	HighLightBit = Panelparms[%$"HighLight"+WhichBitStr+"Bit"][0]
	UserData = ""
	SetupData = ""
	



	ParmName = "FMapSlowScanDisabled"
	ControlName = ParmName+"Title"+TabStr
	ControlName0 = ParmName+"Box"+TabStr
	HelpName = "Slow_Scan_Disabled"+TabStr
	SetupName = SetupBaseName+"Bit_"+num2str(bit)+SetupTabStr
	HighName = SetupBaseName+"Color_"+num2str(bit)+SetupTabStr
	ControlName1 = "ClearImage"+TabStr
	SetupData += SetupName+";"+HighName+";"
	UserData += ControlName+";"+HelpName+";"
	UserData += ControlName0+";"+ControlName1+";"

	

	if (2^bit & ControlBit)
		if (HighLightBit & 2^Bit)
			TitleRed = Red
			TitleGreen = Green
			TitleBlue = Blue
		else
			TitleRed = Nan
			TitleGreen = Nan
			TitleBlue = Nan
		endif
		MakeTitleBox(GraphStr,ControlName,"Slow Scan Disabled",22,CurrentTop+1,TitleRed,TitleGreen,TitleBlue,Enab,Frame=0,FontSize=FontSize)
		
		MakeCheckbox(GraphStr,ControlName0," ",LeftPos+27,CurrentTop,"FMapBoxFunc",GV(ParmName),0,Enab)
		
		MakeButton(GraphStr,ControlName1,"Clear Image",ButtonWidth,ButtonHeight,LeftPos+BodyWidth-ButtonWidth,CurrentTop-2,"PMapButtonFunc",Enab)
		
		MakeButton(GraphStr,HelpName,"?",15,15,HelpPos,CurrentTop+1,"ARHelpFunc",DisableHelp)
		UpdateCheckBox(GraphStr,SetupName,"Show?",SetupLeft,CurrentTop,"NoShowFunc",(2^bit & oldControlBit),0,1)
		UpdateCheckBox(GraphStr,HighName,"Color?",HelpPos+30,CurrentTop,"HighLightControlFunc",(2^bit & HighLightBit),0,1)
		CurrentTop += StepSize
	endif
	bit += 1



	ParmName = "FMapDisplayLVDTTraces"
	ControlName = ParmName+"Title"+TabStr
	ControlName0 = ParmName+"Box"+TabStr
	HelpName = "Display_LVDT_Traces"+TabStr
	SetupName = SetupBaseName+"Bit_"+num2str(bit)+SetupTabStr
	HighName = SetupBaseName+"Color_"+num2str(bit)+SetupTabStr
	SetupData += SetupName+";"+HighName+";"
	UserData += ControlName+";"+HelpName+";"
	UserData += ControlName0+";"


	if (2^bit & ControlBit)
		
		if (HighLightBit & 2^Bit)
			TitleRed = Red
			TitleGreen = Green
			TitleBlue = Blue
		else
			TitleRed = Nan
			TitleGreen = Nan
			TitleBlue = Nan
		endif
		MakeTitleBox(GraphStr,ControlName,"Display LVDT",Margin+30,CurrentTop+1,TitleRed,TitleGreen,TitleBlue,Enab,Frame=0,FontSize=FontSize)

		MakeCheckbox(GraphStr,ControlName0," ",LeftPos+27,CurrentTop,"FMapBoxFunc",GV(ParmName),0,Enab)

		MakeButton(GraphStr,HelpName,"?",15,15,HelpPos,CurrentTop+1,"ARHelpFunc",DisableHelp)
		UpdateCheckBox(GraphStr,SetupName,"Show?",SetupLeft,CurrentTop,"NoShowFunc",(2^bit & oldControlBit),0,1)
		UpdateCheckBox(GraphStr,HighName,"Color?",HelpPos+30,CurrentTop,"HighLightControlFunc",(2^bit & HighLightBit),0,1)
		CurrentTop += StepSize
	endif
	bit += 1



	ParmName = "ScanMode"
	ControlName = ParmName+"Title"+TabStr
	ControlName0 = ParmName+"Popup"+TabStr
	HelpName = "Scan_Mode"+TabStr
	SetupName = SetupBaseName+"Bit_"+num2str(bit)+SetupTabStr
	HighName = SetupBaseName+"Color_"+num2str(bit)+SetupTabStr
	SetupData += SetupName+";"+HighName+";"
	UserData += ControlName+";"+HelpName+";"
	UserData += ControlName0+";"


	if (2^bit & ControlBit)
		if (HighLightBit & 2^Bit)
			TitleRed = Red
			TitleGreen = Green
			TitleBlue = Blue
		else
			TitleRed = Nan
			TitleGreen = Nan
			TitleBlue = Nan
		endif
		MakeTitleBox(GraphStr,ControlName,"Scan Mode",Margin+27,CurrentTop+1,TitleRed,TitleGreen,TitleBlue,Enab,Frame=0,FontSize=FontSize)

		MakePopup(GraphStr,ControlName0," ",LeftPos,CurrentTop-1,"MainPopupFunc","\"Closed Loop;Hybrid;Open Loop;\"",GV("ScanMode")+1,Enab,FontSize=FontSize)

		MakeButton(GraphStr,HelpName,"?",15,15,HelpPos,CurrentTop+1,"ARHelpFunc",DisableHelp)
		UpdateCheckBox(GraphStr,SetupName,"Show?",SetupLeft,CurrentTop,"NoShowFunc",(2^bit & oldControlBit),0,1)
		UpdateCheckBox(GraphStr,HighName,"Color?",HelpPos+30,CurrentTop,"HighLightControlFunc",(2^bit & HighLightBit),0,1)
		CurrentTop += StepSize
	endif
	bit += 1

	ControlName = "DoPMap"+TabStr
	ControlName0 = "LastPMap"+TabStr
	MakeButton(GraphStr,ControlName,"Do Scan",ButtonWidth,ButtonHeight,Margin,CurrentTop,"PMapButtonFunc",Enab)
	MakeButton(GraphStr,ControlName0,StringFromList(GV("LastScan"),"Last Scan;Waiting...;",";"),ButtonWidth,ButtonHeight,Margin,CurrentTop,"PMapButtonFunc",Enab)
	UserData += ControlName+";"+ControlName0+";"
	
	ControlName = "StopScan"+TabStr
	MakeButton(GraphStr,ControlName,"Stop!!!",ButtonWidth,ButtonHeight,LeftPos+20,CurrentTop,"PMapButtonFunc",Enab)
	UserData += ControlName+";"

	ControlName = "Do_Scan"+TabStr
	MakeButton(GraphStr,ControlName,"?",15,15,HelpPos,CurrentTop+1,"ARHelpFunc",DisableHelp)
	UserData += ControlName+";"
	CurrentTop += StepSize
	


	ControlName = "UpScan"+TabStr
	ControlName0 = "DownScan"+TabStr
	HelpName = "Frame_Up"+TabStr
	SetupName = SetupBaseName+"Bit_"+num2str(bit)+SetupTabStr
	SetupData += SetupName+";"
	UserData += ControlName+";"+HelpName+";"
	UserData += ControlName0+";"

	if (2^bit & ControlBit)
		MakeButton(GraphStr,ControlName,"Frame Up",ButtonWidth,ButtonHeight,Margin,CurrentTop,"PMapButtonFunc",Enab)

		MakeButton(GraphStr,ControlName0,"Frame Down",ButtonWidth,ButtonHeight,LeftPos+20,CurrentTop,"PMapButtonFunc",Enab)

		MakeButton(GraphStr,HelpName,"?",15,15,HelpPos,CurrentTop+1,"ARHelpFunc",DisableHelp)
		UpdateCheckBox(GraphStr,SetupName,"Show?",SetupLeft,CurrentTop,"NoShowFunc",(2^bit & oldControlBit),0,1)
		CurrentTop += StepSize
	endif
	bit += 1




	ParmName = "BaseName"
	ControlName = ParmName+"SetVar"+TabStr
	HelpName = "Base_Name"+TabStr
	SetupName = SetupBaseName+"Bit_"+num2str(bit)+SetupTabStr
	HighName = SetupBaseName+"Color_"+num2str(bit)+SetupTabStr
	SetupData += SetupName+";"+HighName+";"
	UserData += ControlName+";"+HelpName+";"


	if (2^bit & ControlBit)
		MakeSetVar(GraphStr,ControlName,"BogusVar","Base Name","BaseNameSetVarFunc","Value="+GetDF("Variables")+ParmName,LeftPos-5,CurrentTop,NaN,BodyWidth+30,TabNum,fontSize,Enab)
		if (HighLightBit & 2^Bit)
			SetVariable $ControlName,win=$GraphStr,labelback=(Red,Green,Blue)
		endif

		MakeButton(GraphStr,HelpName,"?",15,15,HelpPos,CurrentTop+1,"ARHelpFunc",DisableHelp)
		UpdateCheckBox(GraphStr,SetupName,"Show?",SetupLeft,CurrentTop,"NoShowFunc",(2^bit & oldControlBit),0,1)
		UpdateCheckBox(GraphStr,HighName,"Color?",HelpPos+30,CurrentTop,"HighLightControlFunc",(2^bit & HighLightBit),0,1)
		CurrentTop += StepSize-3
	endif
	bit += 1


	ParmName = "BaseSuffix"
	ControlName = ParmName+"SetVar"+TabStr
	HelpName = "Base_Suffix"+TabStr
	SetupName = SetupBaseName+"Bit_"+num2str(bit)+SetupTabStr
	HighName = SetupBaseName+"Color_"+num2str(bit)+SetupTabStr
	SetupData += SetupName+";"+HighName+";"
	UserData += ControlName+";"+HelpName+";"


	if (2^bit & ControlBit)
		MakeSetVar(GraphStr,ControlName,ParmName,"Base Suffix","BaseNameSetVarFunc","",LeftPos-5,CurrentTop,NaN,BodyWidth+20,TabNum,fontSize,Enab)

		if (HighLightBit & 2^Bit)
			SetVariable $ControlName,win=$GraphStr,labelback=(Red,Green,Blue)
		endif

		MakeButton(GraphStr,HelpName,"?",15,15,HelpPos,CurrentTop+1,"ARHelpFunc",DisableHelp)
		UpdateCheckBox(GraphStr,SetupName,"Show?",SetupLeft,CurrentTop,"NoShowFunc",(2^bit & oldControlBit),0,1)
		UpdateCheckBox(GraphStr,HighName,"Color?",HelpPos+30,CurrentTop,"HighLightControlFunc",(2^bit & HighLightBit),0,1)
		CurrentTop += StepSize-3
	endif
	bit += 1
	

//
//	ParmName = "ImageNote"
//	ControlName = ParmName+"SetVar"+TabStr
//	HelpName = "Image_Note"
//	SetupName = SetupBaseName+"Bit_"+num2str(bit)+SetupTabStr
//	HighName = SetupBaseName+"Color_"+num2str(bit)+SetupTabStr
//	SetupData += SetupName+";"+HighName+";"
//	UserData += ControlName+";"+HelpName+";"
//
//	//FMapNote
//	if (2^bit & ControlBit)
//		
//		MakeSetVar(GraphStr,ControlName,"BogusVar","Note","SaveTSNData","Value="+GetDF("Variables")+"ImageNote",45,CurrentTop,NaN,220,TabNum,NaN,Enab)
//		if (HighLightBit & 2^Bit)
//			SetVariable $ControlName,win=$GraphStr,labelback=(Red,Green,Blue)
//		endif
//
//
//		MakeButton(GraphStr,HelpName,"?",15,15,HelpPos,CurrentTop+1,"ARHelpFunc",DisableHelp)
//		UpdateCheckBox(GraphStr,SetupName,"Show?",SetupLeft,CurrentTop,"NoShowFunc",(2^bit & oldControlBit),0,1)
//		UpdateCheckBox(GraphStr,HighName,"Color?",HelpPos+30,CurrentTop,"HighLightControlFunc",(2^bit & HighLightBit),0,1)
//
//		CurrentTop += StepSize-3
//	endif
//	Bit += 1


//	
//	ParmName0 = "SaveMem"
//	ControlName0 = ParmName0+"Title"+TabStr
//	ControlName1 = ParmName0+"Box"+TabStr
//	ParmName1 = "SaveDisk"
//	ControlName2 = ParmName1+"Title"+TabStr
//	ControlName3 = ParmName1+"Box"+TabStr
//	HelpName = "Save_Forces"+TabStr
//	SetupName = SetUpBaseName+"Bit_"+num2str(bit+(WhichBit-1)*32)+SetUpTabStr
//	HighName = SetUpBaseName+"Color_"+num2str(bit+(WhichBit-1)*32)+SetUpTabStr
//	SetupData += SetupName+";"+HighName+";"
//	UserData += ControlName0+";"+HelpName+";"
//	UserData += ControlName1+";"+ControlName2+";"+ControlName3+";"
//
//	//Save Checkboxes
//	if (2^bit & ControlBit)
//		if (HighLightBit & 2^Bit)
//			TitleRed = Red
//			TitleGreen = Green
//			TitleBlue = Blue
//		else
//			TitleRed = Nan
//			TitleGreen = Nan
//			TitleBlue = Nan
//		endif
//		MakeTitleBox(GraphStr,ControlName0,"Save to Mem.",Margin,CurrentTop+1,TitleRed,TitleGreen,TitleBlue,Enab,Frame=0,FontSize=FontSize)
//		
//		
//		
//		MakeCheckbox(GraphStr,ControlName1," ",LeftPos,CurrentTop,"ForceCheckBoxFunc",1 & GV("SaveForce"),0,Enab)
//		
//		TitleRed = Nan
//		TitleGreen = Nan
//		TitleBlue = Nan
//		MakeTitleBox(GraphStr,ControlName2,"Save to Disk",LeftPos+30,CurrentTop+1,TitleRed,TitleGreen,TitleBlue,Enab,Frame=0,FontSize=FontSize)
//
//		MakeCheckbox(GraphStr,ControlName3," ",LeftPos+105,CurrentTop,"ForceCheckBoxFunc",2 & GV("SaveForce"),0,Enab)
//
//		MakeButton(GraphStr,HelpName,"?",15,15,HelpPos,currentTop+1,"ARHelpFunc",DisableHelp)
//		UpdateCheckBox(GraphStr,SetupBaseName+"Bit_"+num2str(bit)+SetupTabStr,"Show?",SetupLeft,CurrentTop,"NoShowFunc",(2^bit & oldControlBit),0,1)
//		UpdateCheckBox(GraphStr,SetupBaseName+"Color_"+num2str(bit)+SetupTabStr,"Color?",HelpPos+30,CurrentTop,"HighLightControlFunc",(2^bit & HighLightBit),0,1)
//		currentTop += StepSize
//	endif
//	bit += 1
//	

	MakeButton(GraphStr,MakeName,MakeTitle,ButtonWidth*1.25,ButtonHeight,Margin-15,CurrentTop,"MakePanelProc",Enab)
	UserData += MakeName+";"+OtherMakeName+";"
	MakeButton(GraphStr,GraphStr+"Setup"+TabStr,"Setup",ButtonWidth,ButtonHeight,LeftPos+20,CurrentTop,"ARSetupPanel",Enab)
	UserData += GraphStr+"SetUp"+TabStr+";"+OtherGraphStr+"Setup"+TabStr+";"
	MakeButton(GraphStr,"Setup"+tabStr,"?",15,15,HelpPos,CurrentTop+1,"ARHelpFunc",DisableHelp)
	UserData += "Setup"+TabStr+";"
	CurrentTop += 25
	
	
	//Then we have to add the controls that the setup can put on there...
	UserData += "ForceMapPanelColor"+SetUpTabStr+";ForceMapPanelHighLight"+SetUpTabStr+";Border_Color"+SetUpTabStr+";ForceMapPanelShow"+SetUpTabStr+";"
	UserData += SetupData
	
	PanelParms[%CurrentBottom][0] = currentTop		//save the bottom position of the controls
	TabControl $TabCtrlName,Win=$GraphStr,UserData(Bottom)=UserData
	
End //MakePointMapPanel


Function GhostPointMapPanel()


	Variable TabNum
	String TabStr
	Variable ScanStatus
	String ShowList, HideList, TitleList0, TitleList1, TitleList
	
	//Point Map, LastScan button	
	TabNum = ARPanelTabNumLookup("PointMapPanel")
	TabStr = "_"+num2str(TabNum)
	ScanStatus = GV("PMapStatus")
	ShowList = "DoPMap"+TabStr+";"
	HideList = "LastPMap"+TabStr+";"
	TitleList0 = "Do Scan;"
	TitleList1 = "Last Scan;"
	TitleList = ""
	if (ScanStatus)
		if (ScanStatus == 2)
			TitleList = "Waiting...;"
		else
			TitleList = TitleList1
		endif
		UpdateAllControls(StringFromList(0,HideList,";"),StringFromList(0,TitleList,";"),"","")
		SwapStrings(ShowList,HideList)
	else
		TitleList = TitleList0
	endif
	TabNum = ARPanelTabNumLookUp("ForceMapPanel")
	TabStr = "_"+num2str(TabNum)
	ButtonSwapper(ShowList,HideList,TitleList)	
	

End //GhostPointMapPanel


Function PointMapFuncFunc(CtrlName,VarNum,VarStr,VarName)
	String CtrlName		//used
	Variable VarNum		//not used, strings
	String VarStr		//used
	String VarName		//used
	
	
	
	String ParmName = ARConvertVarName2ParmName(VarName)
	
	
	StrSwitch (ParmName)
		case "PointMapInitFunc":
			break
			
		case "PointMapFunc":
			break
			
		case "PointMapRampFunc":
			break
			
		case "PointMapStopFunc":
			break
			
	endswitch
	
	
	return(0)
End //PointMapFuncFunc


Function StopPointMap()

	Wave FVW = $GetDF("Variables")+"ForceVariablesWave"
	if (FVW[%ShowXYSpot][0])
		RedSpotBackground()
	endif
	PV("PMapStatus;LowNoise;",0)
	ARManageRunning("PMap",0)
	PointMapCallbackFunc("Stop")
	GhostPointMapPanel()
	PV("FMapScanDown",!GV("FMapScanDown"))
	PV("BaseSuffix",GV("BaseSuffix")+1)

End //StopPointMap


Function PointMapCallbackFunc(When)
	String When
//print When	
	
	SVAR/Z WhatsRunning = root:Packages:MFP3D:Main:WhatsRunning
	Variable PMap = WhichListItem("PMap",WhatsRunning,";",0,0)	
	if (PMap < 0)
		return(0)
	endif
	
	
	
	String Callback = ""
	String DataFolder = GetDF("Variables")
	Wave/T GVD = $DataFolder+"GeneralVariablesDescription"
	

	
	String ParmName = ""
	StrSwitch (When)
		case "Init":
			ParmName = "PointMapInitFunc"
			break
		
		case "Point":
			ParmName = "PointMapFunc"
			break
			
		case "Ramp":
			ParmName = "PointMapRampFunc"
			break
			
		case "Stop":
			ParmName = "PointMapStopFunc"
			break
	
		default:
			return(0)		
			
	endswitch
	
	
	Callback = GVD[%$ParmName][0]
	Execute/Q Callback
	
	
	return(0)
	
End //PointMapCallbackFunc
	
			
Function PMapButtonFunc(CtrlName)
	String CtrlName
	
	
	String ParmName = ARConvertName2Parm(CtrlName,"Button")
	StrSwitch (ParmName)
		case "UpScan":
		case "DownScan":
			PV("FMapScanDown",StringMatch(ParmName,"Down*"))
			//don't break
		case "DoPMap":
			//Double Check Parms.
			if (!GV("SaveForce"))
				//now lets make sure they are saving something, these things are slow.
				//but this is a soft error, things still work, I just don't see the point
				Print "Point Map Started!\r\tBut Data is NOT being Saved!"
				DoWindow/H
				//so we let things continue
			
			endif
			
			PV("FMapCounter;FMapLineCounter;FMapPointCounter;",0)
			AR_Stop(OKList="FreqFB;PotFB;PMap;")		//stop all other actions.
			PV("PMapStatus;LowNoise;",2)
			SetScanBandWidth()
			Wave MVW = root:Packages:MFP3D:Main:Variables:MasterVariablesWave
			Duplicate/O MVW root:Packages:MFP3D:Main:Variables:OldMVW
			RealScanParmFunc("All","Copy")		//copy the real parms over to the RealVariablesWave
			AdjustScanWaves()
			GhostPointMapPanel()
			DoPointMap()
			
			break
			
		case "LastPMap":
			PV("PMapStatus",2)
			GhostPointMapPanel()
			break
			
		case "StopScan":
			StopPointMap()
			break
		
//		case "FMapTimePrefs":
//			MakeFMapPrefPanel(1)
//			break
//			
//		case "ClearImage":
//			break
//			
	endswitch
	return(0)
	
End //PMapButtonFunc


Function ARPMapRampCallback()


	PointMapCallbackFunc("Point")
	String DataFolder = GetDF("Variables")
	Wave FVW = $DataFolder+"ForceVariablesWave"

	Struct ARFMapParms Parms
	GetARFMapParms(Parms)

	Parms.Counter += 1
	FVW[%FMapCounter][0] = Parms.Counter
	String ErrorStr = ""
	//PV("FMapCounter",Parms.Counter)
	if (Parms.Counter >= Parms.nopX*Parms.nopY)
		//OK, we are on the last run.
		
		//setup a bogus bank, so we can call back in to clear things up.
		
		
		ErrorStr += num2str(td_WriteString("OutWave0StatusCallback","StopPointMap()"))+","
		Wave BogusWave = $LocalWave(2)
		ErrorStr += num2str(td_xSetOutWave(0,"4","Dummy%output",BogusWave,1))+","
		
		//FVW[%FMapScanDown][0] = !FVW[%FMapScanDown][0]
		ARReportError(ErrorStr)
		return(0)
	endif
	Variable TotalTime
	String RampChannelX, RampChannelY
	
	
	if (Parms.XYClosedLoop)
		RampChannelX = "Setpoint%PISloop3"
		RampChannelY = "Setpoint%PISLoop4"
		TotalTime = sqrt(((Parms.XPoints[Parms.Counter]-Parms.XPoints[Parms.Counter-1])*Parms.XLVDTSens)^2+((Parms.YPoints[Parms.Counter]-Parms.YPoints[Parms.Counter-1])*Parms.YLVDTSens)^2)/Parms.ScanSpeed
	else		//open loops
		RampChannelX = "X%output"
		RampChannelY = "Y%output"
		TotalTime = sqrt(((Parms.XPoints[Parms.Counter]-Parms.XPoints[Parms.Counter-1])*Parms.XPiezoSens)^2+((Parms.YPoints[Parms.Counter]-Parms.YPoints[Parms.Counter-1])*Parms.YPiezoSens)^2)/Parms.ScanSpeed
		
	endif



	SineRamp(Parms.XPoints[Parms.Counter],Parms.YPoints[Parms.Counter],RampChannelX,RampChannelY,TotalTime,Parms.RampX,Parms.RampY,0,"4",GetFuncName()+"()")
	//ErrorStr += num2str(td_WriteString("4%Event","Once"))+","
	
	if (FVW[%FMapDisplayLVDTTraces][0])
		//work up our display waves.
		Duplicate/O Parms.RampX,$Parms.DataFolder+"XRampWaveLast"
		Duplicate/O Parms.RampY,$Parms.DataFolder+"YRampWaveLast"
//		Wave XDisplay = $Parms.DataFolder+"XRampWaveLast"
//		Wave YDisplay = $Parms.DataFolder+"YRampWaveLast"
//		FastOp XDisplay = (Parms.XLVDTSens)*XDisplay
//		FastOp YDisplay = (Parms.YLVDTSens)*YDisplay
//		SetScale d,0,0,"m",XDisplay,YDisplay
		//No, timing is going to be a <edit>
		//so we will just waite for the input wave callback to hit
		//the input waves should be longer (always?)
	endif
	

	ARReportError(ErrorStr)
	
	if (FVW[%ShowXYSpot][0])
		RedSpotBackground()
	endif
	
	

End //ARPMapRampCallback


Function DoPointMap()



//	//Update the SaveForce path if needed.
//	String PName = "SaveForce"
//	Variable EndNum = 0
//	if (GV("SaveForce") & 2)
//		if (SafePathInfo(PName))
//			PathInfo $PName
//			String CurrentFolder = LastDir(S_Path)
//			EndNum = GetEndNum(CurrentFolder)
//			if ((!IsNan(EndNum)) && (StringMatch(CurrentFolder,"ForceMap"+num2str(EndNum))))
//				//we have already saved to a SubFolder
//				NewPath/C/O/Q/Z $PName UpDir(S_Path)+":ForceMap"+num2str(EndNum+1)
//			else
//				NewPath/C/O/Q/Z $Pname S_Path+"ForceMap0"
//			endif
//		endif
//	else
//		//we need to store the folder in a global string.
//		String ParmFolder = ARGetForceFolder("Parameters","")
//		Wave/T ForceFolderListWave = $ParmFolder+"ForceFolderListWave"
//		SVAR FMapDestFolder = $InitOrDefaultString(ParmFolder+"FMapDestFolder","")
//		
//		EndNum = 0
//		Variable Index = Find1Twave(ForceFolderListWave,"ForceMap"+num2str(EndNum))
//		
//		if (Index >= 0)
//			do
//				Index = Find1Twave(ForceFolderListWave,"ForceMap"+num2str(EndNum))
//				EndNum += 1
//			while (Index >= 0)
//			EndNum -= 1
//		endif
//		FMapDestFolder = "ForceMap"+num2str(EndNum)
//		
//	endif

	if (GV("ShowXYSpot"))
		PutOnXYSpot(1)
		ARBackground("RedSpotBackground",0,"")		//stop the background from running, it is too slow
	endif
	
	ARManageRunning("PMap",1)		//we are now doing a force map.
	PointMapCallbackFunc("Init")
	ReCalcFMapMatrix()
	Struct ARFMapParms Parms
	GetARFMapParms(Parms)
	Wave XPoints = Parms.XPoints
	Wave YPoints = Parms.YPoints

	String ErrorStr = ""
	Variable XIgain = Parms.XLVDTSens*10^GV("XIGain")
	Variable YIgain = Parms.YLVDTSens*10^GV("YIGain")
	
	
	Variable XStart, YStart, TotalTime
	String RampChannelX, RampChannelY
	
	
	if (Parms.XYClosedLoop)
		RampChannelX = "Setpoint%PISloop3"
		RampChannelY = "Setpoint%PISLoop4"
	
		Xstart = td_ReadValue("XSensor")		//calculate where the XY actually is with the gains and
		Ystart = td_ReadValue("YSensor")		//offset that we will be using
		
		Wave PISLoopWave = root:Packages:MFP3D:Main:PISLoopWave
		if (FindTextMultiWave(PISLoopWave,"X%Output","outChannelString") == 0)
			ir_StopPISLoop(0)
		endif
		if (FindTextMultiWave(PISLoopWave,"Y%Output","outChannelString") == 1)
			ir_StopPISLoop(1)
		endif
		
		//set the X and Y feedback loops
		ErrorStr += num2str(ir_SetPISLoop(3,"1","XSensor",Xstart,0,XIgain,0,"X%Output"))+","
		ErrorStr += num2str(ir_SetPISLoop(4,"1","YSensor",Ystart,0,YIgain,0,"Y%Output"))+","
		
		//this is the X & Y offset
		ErrorStr += num2str(ir_WriteValue("SetpointOffset%PISLoop3",0))+","
		ErrorStr += num2str(ir_WriteValue("SetpointOffset%PISLoop4",0))+","
		//this is the scan size
		ErrorStr += num2str(ir_WriteValue("SetpointGain%PISLoop3",1))+","
		//now turn on the feedback, and we should already be at the right spot
		ErrorStr += num2str(ir_WriteValue("SetpointGain%PISLoop4",1))+","
		ErrorStr += num2str(td_WriteString("1%Event","Once"))+","
	
	
		TotalTime = sqrt(((Parms.XPoints[Parms.Counter]-XStart)*Parms.XLVDTSens)^2+((Parms.YPoints[Parms.Counter]-YStart)*Parms.YLVDTSens)^2)/Parms.ScanSpeed
	else			//open loop
		RampChannelX = "X%output"
		RampChannelY = "Y%output"
	
		Xstart = td_ReadValue("X%output")		//calculate where the XY actually is with the gains and
		Ystart = td_ReadValue("Y%Output")		//offset that we will be using
		
		Wave PISLoopWave = root:Packages:MFP3D:Main:PISLoopWave
		if (FindTextMultiWave(PISLoopWave,"X%Output","outChannelString") == 0)
			ir_StopPISLoop(0)
		endif
		if (FindTextMultiWave(PISLoopWave,"Y%Output","outChannelString") == 1)
			ir_StopPISLoop(1)
		endif
		
		TotalTime = sqrt(((Parms.XPoints[Parms.Counter]-XStart)*Parms.XPiezoSens)^2+((Parms.YPoints[Parms.Counter]-YStart)*Parms.YPiezoSens)^2)/Parms.ScanSpeed
	endif
	
	
	SineRamp(Parms.XPoints[Parms.Counter],Parms.YPoints[Parms.Counter],RampChannelX,RampChannelY,TotalTime,Parms.RampX,Parms.RampY,0,"4","ARPMapRampCallback()")
	ErrorStr += num2str(td_WriteString("4%Event","Once"))+","
	
	
	//time to setup the force plot stuff.
	//DoForceFunc("
	
	ARReportError(ErrorStr)


End //DoPointMap


Function PointMapImageFunc(Action,ParmWave)
	String Action
	Wave ParmWave
	
	
	
	//This function deals with the image created by the point map
	//ParmWave, needs to have N points, 1 for each layer of the created image.
	//it will be used by the anayze function to pass the points into the image.
	
	//The labels on ParmWave will be used for the layer labels on the image
	//Action is 
	//Init, make the wave the correct size, clear it out, set labels
	//Update, put info into the wave based on the current position, from data in ParmWave



	String DataFolder = GetDF("ImageRoot")
	String SuffixStr = num2strLen(GV("BaseSuffix"),4)
	SVAR gBaseName = $GetDF("Variables")+"BaseName"
	String BaseName = gBaseName		//
	SVAR/Z gBaseName = $""		//clear the ref, we are not going to be changing it.
	Wave/Z ImageWave = $DataFolder+BaseName+SuffixStr
	if (!WaveExists(ImageWave))
		Make/N=(0) $DataFolder+BaseName+SuffixStr
		Wave/Z ImageWave = $DataFolder+BaseName+SuffixStr
	endif
	Variable Counter = GV("FMapCounter")
	Variable Lines = GV("FMapScanLines")
	Variable Points = GV("FMapScanPoints")
	Variable ScanDown = GV("FMapScanDown")
//	Variable XIndex = 
	Variable/C MapPos = GetFMapPos(ScanDown,Lines,Points,Counter)
	Variable XIndex = Real(MapPos)
	Variable YIndex = Imag(MapPos)
	String NoteStr = ""
	
	
	
	StrSwitch (Action)
		case "Init":
			Redimension/N=(Points,Lines,DimSize(ParmWave,0)) ImageWave
			SetDimLabels(ImageWave,GetDimLabels(ParmWave,0),2)
			FastOp ImageWave = (NaN)
			SetScale/I x,0,GV("FastScanSize"),"m",ImageWave
			SetScale/I y,0,GV("SlowScanSize"),"m",ImageWave
			SetScale d,0,0,"m",ImageWave
			NoteStr = ReplaceNumberByKey("Display Range 0",NoteStr,2000,":","\r")
			NoteStr = ReplaceNumberByKey("Display Offset 0",NoteStr,GV("BECarrierFreq"),":","\r")
			Note/K ImageWave
			Note ImageWave,NoteStr
			DisplayImage(ImageWave)
			break
			
			
		case "Update":
			ImageWave[XIndex][YIndex][] = ParmWave[R]
//print XIndex,YIndex, Counter,ScanDown
		
			break
			
			
	endswitch



End //PointMapImageFunc	
	
	
	
	