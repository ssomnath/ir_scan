#pragma rtGlobals=1		// Use modern global access method.

function GetGains()
//This function grabs the gains that the X, Y, and Z feedback loops are using. It prints them to the history and also
//copies them into some global variables. The microscope should be engaged and scanning when this is run.

	variable/G X_PGain, X_IGain, X_SGain, Y_PGain, Y_IGain, Y_SGain, Z_PGain, Z_IGain, Z_SGain

	//Loop 0 is a bit strange in that it should have been named PISLoop0 but for historical reasons is named PISLoop
	X_PGain = td_RV("PGain%PISLoop0")
	X_IGain = td_RV("IGain%PISLoop0")
	X_SGain = td_RV("SGain%PISLoop0")
	
	Y_PGain = td_RV("PGain%PISLoop1")
	Y_IGain = td_RV("IGain%PISLoop1")
	Y_SGain = td_RV("SGain%PISLoop1")

	//printf "X Gains:  P:%.4g I:%.4g S:%.4g\r", X_PGain, X_IGain, X_SGain
	//printf "Y Gains:  P:%.4g I:%.4g S:%.4g\r", Y_PGain, Y_IGain, Y_SGain
	//printf "Z Gains:  P:%.4g I:%.4g S:%.4g\r", Z_PGain, Z_IGain, Z_SGain

end

function masterRaster()
	Make/N=3 /O Xval, Yval
	Xval[0] = 1
	Yval[0] = 0
	Xval[1] = 1
	Yval[1] = 1
	Xval[2] = 2
	Yval[2] = 1
	
	Variable/G giter = 0
	
	// Starting off with first movement:
	ClosedLoopXShifter(0, 0, Xval[0], Yval[0])
end

function ClosedLoopXShifter(X_start, Y_start, X_end, Y_end)
	variable X_start, Y_start, X_end, Y_end
	//These are low voltage sensor volts
	//The min is -10 volts and the max is +10 volts, but the sensors don't use the full range
	//Try using 3 volts for a radius

	Make/N=(1024)/O XVoltage YVoltage XSensor YSensor XCommand YCommand
	
	//Display/K=1 /W=(5.25,41.75,399.75,250.25) XVoltage
	//ModifyGraph rgb(XVoltage)=(0,0,65535 )
	//Appendtograph/R YVoltage; Legend
	//Display/K=1 /W=(7.5,275.75,402,484.25) XSensor
	//ModifyGraph rgb(XSensor)=(0,0,65535 )
	//Appendtograph/R YSensor; Legend
	//Display/K=1 /W=(409.5,41.75,662.25,250.25) YSensor vs XSensor
	//ModifyGraph width={Plan,1,bottom,left} 
	
	GetGains()
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
		//print "Error in one of the td_ functions in ClosedLoopXShifter: ", Error
	endif
	
end

Function holdStationary()

	td_stop()
	
	NVAR X_PGain, X_IGain, X_SGain, Y_PGain, Y_IGain, Y_SGain
	
	Wave XCommand, YCommand
	
	Variable Error = 0
	Variable xvalue = XCommand[numpnts(XCommand)-1]
	Variable yvalue = YCommand[numpnts(YCommand)-1]
	
	print "requesting to hold at (" + num2str(xvalue) + " , " + num2str(yvalue) + ")"
	
	Error += td_xSetPISLoop(0,"always", "X%Input@Controller", xvalue, X_PGain, X_IGain, X_SGain, "X%Output@Controller")
	
	Error += td_xSetPISLoop(1,"always", "Y%Input@Controller", yvalue, Y_PGain, Y_IGain, Y_SGain, "Y%Output@Controller")

	if (Error)
		//print "Error in one of the td_ functions in holdStationary: ", Error
	endif
	
	//Start calling thermal here!
	// actually once thermal is over
	// thermal's callback will actually call nextPos
	
	
	//Temporarily placed a wait here. 
	// Assuming thermal doesn't wipe out my PIS / stop them......
	// This should simulate the the position kept constant for some time
	// Moreover. Noticed that the position is more stable this way
	// Piezos dont look like they want to be rushed into darting to the coordinate
	Variable t0 = ticks
	do
	while ((ticks - t0)/60 < 3)	
	
	
	nextPos()
	
	
End

Function nextPos()

	NVAR giter
	Wave Xval, Yval
	
	giter +=1
	
	print "Finished Iteration #" + num2str(giter)
	print "Current position = (" + num2str(td_rv("X%input@Controller")) + " , " + num2str(td_rv("Y%input@Controller")) + ")"
	
	if(giter < numpnts(Xval))
		print "Calling move again!"
		ClosedLoopXShifter(Xval[giter-1], Yval[giter-1], Xval[giter], Yval[giter])
	else
		print "Finished raster scanning!"
	endif
End