//launch program for the gemini space craft replica
//declare everything for some reason, removes warnings. investigate "did not use variable locally"
declare runmode is 0.
declare n_run is 0.
declare targetApoapsis is 85000.
declare targetPeriapsis is 85000.
declare alt_time is 0.
declare th_initial is 0.1.
declare stage_time is 0.
declare flight_time is 0.
declare base_time is 0.
declare dV is 0.
declare flight_program is "IDLE".
declare flight_status is "IDLE".
declare cycle is 0..
declare time_diff is 0.
declare stage_delta_t is 0.
declare time_space is 0.
declare targetPitch is 0.
declare th_ratio is 0.

//defining all functions
function Definevariables {
    //defines all the variables beforehand
    //define status
    set flight_status to "ON LAUNCH PAD".
    set flight_program  to "AWAITING LIFT-OFF".
    //define target parameters
    set targetApoapsis to 85000.
    set targetPeriapsis to 85000.
    set targetDirection to 0.
    set targetPitch to 0.
    // time setting
    lock flight_time to missionTime.
    set base_time to missiontime.
    set alt_time to 0.
    set stage_time to 0.
    //thust setting
    set th_initial to 1.
    set th_ratio to 0.
    set availableThrust to 0.
    lock throttle to 0.
    //isp that is only relevant to gemini until we find code that can do that
    set isp to 0.
    //number of node runs. must reset everytime a node is needed
    set n_run to 0.
    //setting cycle (how many times the computer has cycled through the program)
    set cycle to 0.
    // dV setting
    set dV to 0.
}
function Startup {
    //set the vehicle to a known state
    SAS off.
    RCS off.
    lights off.
    Lock throttle to 0.
    Gear off.
    clearScreen.
}
function Time_Elapsed {
    //measure the elapsed time
    lock flight_time to missionTime.
    set base_time to missiontime.
    set alt_time to 0.
}
function SafeStage {
    //do a staging safely
    wait until stage:ready.
    stage.
    set stage_time to missionTime.
    wait 0.25.
}
function Countdown {
    //primitive countdown
    PRINT "Counting down:".
    Print "...10".
    Wait 1.
    Print "...9".
    Wait 1.
    Print "...8".
    Wait 1.
    Print "...7".
    Wait 1.
    Print "...6".
    Wait 1.
    Print "...5".
    Wait 1.
    Print "...4".
    Wait 1.
    Print "...3".
    Wait 1.
    Print "...2".
    Wait 1.
    Print "...1".
    Wait 1.
    Print "...0".
    Print "IGNITION".
}
function HeadBoard {
    //main display board
        print "ASCENT FLIGHT DATA" at (11,2).
        print "--------------------------------------------------" at (0,3).
        print "RUNMODE:    " + runmode + "      " at (5,4).
        print "PROGRAM:    " + flight_program + "      " at (5,5).
        print "ALTITUDE:   " + round(SHIP:ALTITUDE,1) + " m      " at (5,6).
        print "APOAPSIS:   " + round(SHIP:APOAPSIS,1) + " m      " at (5,7).
        print "PERIAPSIS:  " + round(SHIP:PERIAPSIS,1) + " m      " at (5,8).
        print "ETA to AP:  " + round(ETA:APOAPSIS,1) + " s      " at (5,9).
        print "HEADING:    " + round(ship:bearing,1)+" °     " at (5,10).
        print "PITCH:      " + round(90-vectorAngle(ship:up:forevector,ship:facing:forevector),1)+" °     " at (5,11).
        print "RADAR ALT:  " + round(alt:radar,1) + " m     " at (5,12).
        print "VERT. SPEED:" + round(verticalSpeed,1)+" m/s      " at (5,13).
        print "TIME:       " + round(missionTime,1) + " s       " at (5,14).
        print "--------------------------------------------------" at (0,15).
        print "STATUS:     " + flight_status + "      " at (5,16).
    }
function BootUp {
    //bootup display program
        clearScreen.
        print "SYSTEM BOOT UP STARTING" at (11,2).
        print "--------------------------------------------------" at (0,3).
        print "TITAN II ROCKET LAUNCH PROGRAM FILES" at (5,5).
        print "FILES ACCESSED. AWAITING LOADING PROCEDURES" at (5,6).
        print "      ".
        wait 2.
        print "LOADING" at (5,8).
        wait 0.5.
        print "LOADING." at (5,8).
        wait 0.5.
        print "LOADING.." at (5,8).
        wait 0.5.
        print "LOADING..." at (5,8).
        wait 0.5.
        print "LOADING" at (5,8).
        wait 0.5.
        print "LOADING." + "      " at (5,8).
        wait 0.5.
        print "LOADING.." + "      "  at (5,8).
        wait 0.5.
        print "LOADING..." + "      " at (5,8).
        wait 0.5.
        print "LOADING COMPLETE" at (5,8).
        print "--------------------------------------------------" at (0,9).
        wait 0.5.
        print "EXECUTING ELECTRON PROGRAM" at (5,10).
        wait 1.
        print "...10" + "      " at (10,12).
        wait 1.
        print "...9" + "      " at (10,12).
        wait 1.
        print "...8" + "      " at (10,12).
        wait 1.
        print "...7" + "      " at (10,12).
        wait 1.
        print "...6" + "      " at (10,12).
        wait 1.
        print "...5" + "      " at (10,12).
        wait 1.
        print "...4" + "      " at (10,12).
        wait 1.
        print "...3" + "      " at (10,12).
        wait 1.
        print "...2" + "      " at (10,12).
        wait 1.
        print "...1" + "      " at (10,12).
        wait 1.
         print "IGNITION" at (10,12).
    }
function circularization_math {
    //calculates needed delta v
        set ap to (ship:apoapsis+600000).
        set pe to (ship:periapsis+600000).
        set mu_k to 3.5316000*(10^12).
        set mu_m to 6.5138398*(10^10).
        set mu_mnm to 1.7658000*(10^9).
        set v_c to sqrt((mu_k)/(ap)).
        set v_ap to sqrt((((2*mu_k)/(ap+pe)))*(pe/ap)).
        set dV to (v_c)-(v_ap).
        set mass1 to ship:mass*1000.
        set thrust1 to ship:maxThrust*1000.
        set g_0 to 9.80665.
        local mf is (mass1/constant():e^(dV/(isp*g_0))).
        local m_dot is thrust1/(isp*g_0).
        local t_total is (mass1-mf)/m_dot.
        set t_half to (t_total/2).
        set flight_status to "HALF BURN TIME:  " + round(t_half,1) + " s    ".
}
function ISP_calc {
    //calculates engine isp
    list engines in myEngines.
        for en in myengines {
                if en:ignition and not en:flameout  {
                        set isp to isp + (en:isp*(en:maxthrust/ship:maxthrust)).
                }
        }
}
function orbit_insertion  {
    //does orbit insetion burn
        if (eta:apoapsis < t_half) {
            //temporary fix
            unlock steering.
            sas on.
            //
            set flight_status to "BURNING               ".
            lock throttle to 1.
        }
        if ship:periapsis > (targetPeriapsis-10000) {
            set flight_status to "EASING BURN".
            //temporary fix
            unlock steering.
            sas on.
            //
            lock throttle to (1-ship:periapsis/((2*targetPeriapsis))).
        }
        if (ship:periapsis > targetPeriapsis) or (ship:periapsis > targetPeriapsis*0.9999) {
            lock throttle to 0.
            sas on.
        }
}
function ClampStage {
    // to be added
}
function flight_stage {
    //measures where the fuck in the flight you are
    if alt:radar < 50 {
    set runmode to 1.
    } else if (alt:radar < 2500) and (alt:radar > 50) {
        set runmode to 2.
    } else if (alt:radar < 70000) and (alt:radar > 2500) {
        set runmode to 3.
    } else if (alt:radar > 70000) and (alt:radar < (targetApoapsis*0.95)){
        set runmode to 4.
    } else if (alt:radar <(targetApoapsis*0.95)){
        if (periapsis < targetPeriapsis){
            set runmode to 5.
        } else set runmode to 10.
    } else set runmode to 0.
}
function Debugging {
    //a tool to see the variable values and whether they align to expectations
    print "DEBUGGING TOOL" at (2,18).
    print "mission time " + round(missionTime,2)+"  " at (5,19).
    print "time diff    " + round(time_diff,2)+"  "  at (5,20).
    print "flight time  " + round(flight_time,2)+"  "  at (5,21).
    print "status       " + flight_status + "  "  at (5,22).
    print "program      " + flight_program + "       " at (5,23).
    print "alt          " + round(altitude,2)+"  "  at (5,24).
    print "radar alt    " + round(alt:radar,2)+"  "  at (5,25).
    print "target hdg   " + round(ship:bearing,2)+"   "  at (5,26).
    print "target pitch " + round(targetPitch,2)+"  "  at (5,27).
    print "throttle     " + (throttle*100) + "  " at (5,28).
    print "th available " + round(availableThrust,2)+"  "  at (5,32).
    print "th max       " + round(maxThrust,2)+"  "  at (5,33).
    print "th initial   " + round(th_initial,2)+"  "  at (5,34).
    print "th_ratio     " + round(th_ratio,2)+"  "  at (5,35).
    print "alt time     " + round(alt_time,2)+"   "  at (28,19).
    print "time space   " + round(time_space,2)+"   "  at (28,20).
    print "isp          " + isp at (28,25).
    print "stage time   " + round(stage_time,2) at (28,26).
    print "cycle        " + cycle at (28,27).
    print "deltaV       " + round (dV,2) at (28,28).
    print "stage deta t " + round (stage_delta_t,2) at (26,29).
}

function Autostage {
    //does automatic staging
    if (th_ratio < 0.75)  and (runmode < 3.5) and ((maxThrust < 1) or (stage:Liquidfuel < 1) or (stage:solidfuel < 1) ) {
        lock throttle to 0.
        set th_initial to 0.01.
        set stage_time to missionTime.
        if stage_delta_t > 1 {
            SafeStage().
            if stage_delta_t > 1 {
                lock throttle to 1.
            set th_initial to availableThrust.
            print "THE FUCKER HAS STAGED"AT (5,30).
            } 
        }
        lock throttle to 1.
        if (maxThrust < 1) {
            SafeStage().
            wait (0.5).
            lock throttle to 1.
            set th_initial to availableThrust. 
            print "THE FUCKER HAS STAGED" AT (5,30).
        } else {
            lock throttle to 1.
            set th_initial to availableThrust.
            print "THE FUCKER HAS STAGED"AT (5,30).
        }
    }
}

//Main Program

//warping initially because im lazy 
set warpmode to "physics".
set warp to 4.


//actual program start
BootUp().  
Startup().
Definevariables().
flight_stage().
//flight program
until runmode = 0 {
    //timesets
    set cycle to (cycle+1).
    set time_diff to (flight_time-base_time).
    set stage_delta_t to (missionTime-stage_time).
    set th_ratio to ((availableThrust)/(th_initial)).
    set time_space to (missionTime-alt_time).
    if altitude < 70000 {
        if altitude > 69000 {
            set alt_time to missionTime.  
            }
        } else if altitude < 69000 {
            set alt_time to 0.
        }
    //flight plan
    if runmode = 1 {
        // On the launchpad
        clearScreen.
        HeadBoard().
        lock steering to heading (0,90).
        lock throttle to 1.
        set flight_status to "IGNITION".
        set flight_program  to "IGNITION".
            PRINT "IT REACHED IGNITION" AT (5,30). //makes it easier to debug
        SafeStage().
            PRINT "IT REACHED SAFE STAGE HERE     " AT (5,30).
        wait 2.
        set th_initial to availableThrust.
        set th_ratio to ((availableThrust)/(th_initial)).
        if (verticalSpeed < 1) {
            PRINT "IT REACHED CLAMPS            " AT (5,30).
            set flight_status to "CLEARING CLAMPS".
            SafeStage().
            set runmode to 2.
        }
        else if alt:radar > 10 {
            set runmode to 2.
        } else set runmode to 2.
    } 
    else if runmode = 2 {
        //vertical ascent
        set flight_status to "CLEARING TOWER".
        set flight_program to "VERTICAL ASCENT".
        lock steering to heading (0,90).
        lock throttle to 1.
        if ship:altitude > 200 {
            set flight_status to "TOWER CLEARED".
                PRINT "IT CLEARED TOWER                " AT (5,30).
            lock steering to heading (90,90).
        }
        if (verticalSpeed > 100) or (ship:altitude > 2500)  {
            set runmode to 3.
        }
    } else if runmode = 3 {
        //gravity turn
        set flight_status to "STARTING GRAVITY TURN".
        set flight_program to "GRAVITY TURN".
        lock targetPitch to ((-4)*(10^(-13))*((alt:radar)^3) + 5*(10^(-08))*((alt:radar)^2) - (0.0032)*(alt:radar) + (90.311)).
        set targetDirection to 90.
        lock steering to heading(targetDirection,targetPitch).
        if ship:apoapsis > targetApoapsis {
            set flight_status to "TARGET APOAPSIS ACHIEVED".
            lock throttle to 0.
            lock steering to prograde.
            set runmode to (3.6).
        }
        if (ship:altitude > 70000){
            set runmode to 4.
        }
    } else if runmode = 3.6 {
        //coasting to space
        set warp to 4.
        if ship:apoapsis < targetApoapsis {
            lock steering to prograde.
            lock throttle to (0.5).
        } else {
            lock throttle to 0.
            lock steering to prograde.
        }
        if (ship:altitude > 70000){
            set warp to 0.
            print "THE FUCKER IS IN SPACE" AT (5,30).
            set runmode to 4.
        }  
    } else if runmode = 4 {
        //coasting to apoapsis
        set flight_program to "COASTING TO APOAPSIS".
        if (time_space > 10) {
            rcs on.
            lock throttle to 0.
            set targetPitch to 0.
            lock steering to heading(90,0).
        }
        if (time_space > 15) {
            if (eta:apoapsis > 90) {
                set flight_status to "TIME WARP PARAMETERS SATISFIED".
                set warp to 3.
            } else if (eta:apoapsis > 90) {
                set warp to 2.
            }else if (eta:apoapsis < 60) {
                set flight_status to "TIME WARP COMPLETE".
                set warp to 0.
                set runmode to 5.
            } 
        }
    } else if runmode = 5 {
        //circularization burn
        if (eta:apoapsis < 45) {
            if n_run = 0 {
                ISP_calc().
                circularization_math().
                set mynode to node (time:seconds+eta:apoapsis,0,0,dV).
                add mynode.
                lock mnvdir to mynode:deltav.
                lock steering to mnvdir.
                set n_run to 1.
            }
            orbit_insertion().
        }
        if ship:periapsis > (targetPeriapsis*0.999) {
            remove mynode.
            set runmode to 10.
        }
    } else if runmode = 10 {
        //final commands
        lock throttle to 0.
        rcs off.
        unlock steering.
        sas on.
        lights on.
        fuelCells on.
        clearscreen.
        print "THE FUCKER IS IN ORBIT" AT (5,30).
        set runmode to 0.
    }
//checks all of it during flight
Autostage().
HeadBoard().
Debugging().
}

wait 20.
clearScreen.