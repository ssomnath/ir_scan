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
	Make/N=3 Xval, Yval
	Xval[0] = 1
	Yval[0] = 0
	Xval[1] = 1
	Yval[1] = 1
	Xval[2] = 2
	Yval[2] = 1
	
	// Starting off with first movement:
	ClosedLoopXShifter(0, 0, Xval[0], Yval[0])
end

function ClosedLoopXShifter(X_start, Y_start, X_delta, Y_delta)
	variable X_start, Y_start, X_delta, Y_delta
	//The size of the Radius of the circle in volts. These are low voltage sensor volts
	//The min is -10 volts and the max is +10 volts, but the sensors don't use the full range
	//Try using 3 volts for a radius
	
	//Note that this function will make new copies of the graphs everytime. To keep things simpler I didn't 
	//address that. If this annoys you (and it should) take a look at the help for DoWindow.

	variable Error = 0
	//We will accumulate all the outputs from the td_ commands to see if we made any mistakes
	//If all went well, Error will be 0 at the end
	
	Make/N=(1024)/O XVoltage YVoltage XSensor YSensor XCommand YCommand
	Display/K=1 /W=(5.25,41.75,399.75,250.25) XVoltage
	Appendtograph/R YVoltage
	Display/K=1 /W=(7.5,275.75,402,484.25) XSensor
	Appendtograph/R YSensor
	Display/K=1 /W=(409.5,41.75,662.25,250.25) YSensor vs XSensor
	ModifyGraph width={Plan,1,bottom,left} 
	
	GetGains()
	NVAR X_PGain, X_IGain, X_SGain, Y_PGain, Y_IGain, Y_SGain

	//Since we haven't set up the waves yet, they will still have p scaling so we will do the sign and cosine
	//based on p scaling rather than x scaling (time) like we did in the OpenLoopCircle function.
	
	//Since we will be doing this closed loop, inputs and outputs are reversed from the open loop situation.
	//We will pass the feedback loop XSensor and YSensor voltages we would like (a command signal) and
	//it will vary the XVoltage and YVoltage to try to achieve this.
	//We will use the trick of looking at outputs (X%Output) as input waves to see what these voltages were.
	
	if (X_delta < 0)
		X_delta = abs(X_delta)
		XCommand = X_delta*(1-(p/1024)) // moves X leftwards i guess
	else
		XCommand = X_delta*((p/1024)) // moves X rightwards
	endif
	
	if (Y_delta < 0)
		Y_delta = abs(Y_delta)
		YCommand = Y_delta*(1-(p/1024)) // moves Y downward i guess
	else
		YCommand = Y_delta*((p/1024)) // moves Y upward
	endif
	
	//XCommand = X_delta*(1-(p/1024)) // moves X leftwards i guess
	//YCommand =0*pi*p/1024// No Y movement
	//YCommand = Y_delta*((p/1024)) // moves Y upwards
	//YCommand =Radius*sin(2*pi*p/1024)
	
	Error += td_stop()
	//print Error
	Error += td_xSetPISLoop(0,"always", "X%Input@Controller", X_delta, X_PGain, X_IGain, X_SGain, "X%Output@Controller")
	//print Error
	Error += td_xSetPISLoop(1,"always", "Y%Input@Controller", 0, Y_PGain, Y_IGain, Y_SGain, "Y%Output@Controller")
	//print Error
	Error += td_xSetOutWavePair(0, "0,0", "Setpoint%PISLoop0", XCommand, "SetPoint%PISLoop1",YCommand,100)
	//print Error
	Error += td_xSetInWavePair(0, "0,0", "X%Output@Controller", XVoltage, "Y%Output@Controller", YVoltage, "", 100)
	//print Error
	Error += td_xSetInWavePair(1, "0,0", "X%Input@Controller", XSensor, "Y%Input@Controller", YSensor, "print \"Finished moving. Can start themal now.\"", 100)
	//print Error

	Error +=td_WriteString("0%Event", "once")

	if (Error)
		print "Error in one of the td_ functions in ClosedLoopCircle: ", Error
	endif
	
end