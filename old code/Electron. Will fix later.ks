//Electron Launch Program
Print "Executing Electron Launch Program".

function Startup {
    SAS off.
    RCS off.
    lights off.
    Lock throttle to 0.
    Gear off.
    clearScreen.
}

function SafeStage {
    wait until stage:ready.
    stage.
}

function Countdown {
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
        print "ASCENT FLIGHT DATA" at (11,2).
        print "--------------------------------------------------" at (0,3).
        print "RUNMODE:    " + runmode + "      " at (5,4).
        print "PROGRAM:    " + flight_program + "      " at (5,5).
        print "ALTITUDE:   " + round(SHIP:ALTITUDE) + " m      " at (5,6).
        print "APOAPSIS:   " + round(SHIP:APOAPSIS) + " m      " at (5,7).
        print "PERIAPSIS:  " + round(SHIP:PERIAPSIS) + " m      " at (5,8).
        print "ETA to AP:  " + round(ETA:APOAPSIS) + " s      " at (5,9).
        print "HEADING:    " + round(ship:bearing)+" °     " at (5,10).
        print "PITCH:      " + round(90-vectorAngle(ship:up:forevector,ship:facing:forevector))+" °     " at (5,11).
        print "RADAR ALT:  " + round(alt:radar) + " m     " at (5,12).
        print "VERT. SPEED:" + round(verticalSpeed)+" m/s      " at (5,13).
        print "--------------------------------------------------" at (0,14).
        print "STATUS:     " + flight_status + "      " at (5,15).
    }

function BootUp {
        print "SYSTEM BOOT UP STARTING" at (11,2).
        print "--------------------------------------------------" at (0,3).
        print "ELECTRON ROCKET LAUNCH PROGRAM FILES" at (5,5).
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
//primitive maneuver node
function circularization_math {
        wait 1.
        // clearscreen.
        set ap to (ship:apoapsis+600000).
        set pe to (ship:periapsis+600000).
        set mu_k to 3.5316000*(10^12).
        set mu_m to 6.5138398*(10^10).
        set mu_mnm to 1.7658000*(10^9).
        set v_c to sqrt((mu_k)/(700000)).
        set v_ap to sqrt((((2*mu_k)/(ap+pe)))*(pe/ap)).
        set dV to (v_c)-(v_ap).
        set flight_status to "DELTA V:  " + round(dV,1) + " m/s    ".
            // print "vc:" + v_c. 
            // print "vap:" + v_ap.
            // print "dV:" + dV.
        set mass1 to ship:mass*1000.
        set thrust1 to ship:maxThrust*1000.
        set g_0 to 9.80665.
            // print g_0.
        //specific to electron.
        local isp is 355.
        //    
            // print "isp:" + isp.
            // print "mass:" + mass1.
            // print "thrust:"+ thrust1.
        local mf is (mass1/constant():e^(dV/(isp*g_0))).
        local m_dot is thrust1/(isp*g_0).
        local t_total is (mass1-mf)/m_dot.
            // print "mf:" + mf.
            // print "mdot:" + m_dot.
            // print "t_total:" + t_total.
        wait 3.
        set flight_status to "BURN TIME:  " + round(t_total,1) + " s    ".
        set t_half to (t_total/2).
            // print "t/2:" + t_half.
        wait 3.
        set flight_status to "HALF BURN TIME:  " + round(t_half,1) + " s    ".
        wait 1.
}
// function ThrottleCheck {
//     if not(defined Oldthrust) {
//         declare global Oldthrust to ship:availablethrust.
//     }
//     if ship:availableThrust < (oldthrust-10) {
//         set throttlecheck to true.
//         declare global Oldthrust to ship:availablethrust.
//     } else {
//         set throttlecheck to false.
//     }
// }
set targetApoapsis to 100000.
set targetPeriapsis to 100000.
set runmode to 2.
if alt:radar < 50 {
    set runmode to 1.
}

// print "LIFT-OFF".
// print "CLEARING TOWER".
// Print "Starting Gravity Turn".
// Print "Coasting to Apoapsis".
// Print "Orbit Insertion".
// print "Now in orbit".
//curve line
//86.963-1.03287*(alt:radar)^0.409511
//
clearScreen.
BootUp().
clearScreen.
    // set flight_status to "IGNITION".
    // Set flight_program  to "IGNITION".
// until runmode < 0 {
//     HeadBoard().
// }
until runmode = 0 {
    if runmode = 1 {
        lock steering to heading (0,90).
        set TVAL to 1.
        clearScreen.
        set flight_status to "IGNITION".
        set flight_program  to "IGNITION".
        HeadBoard().
        set flight_status to "IGNITION".
        SafeStage().
        set throttle to 1.
        set flight_status to "LIFT-OFF".
        wait 3.
        if verticalSpeed <1 {// launch clamp security
            set flight_status to "CLEARING CLAMPS".
            SafeStage().
            wait 1.
            set runmode to 2.
        } else set runmode to 2.
    }
    else if runmode = 2 {
        set flight_status to "CLEARING TOWER".
        lock steering to heading (0,90).
        set tval to 1.
        if ship:altitude > 200 {
            set flight_status to "TOWER CLEARED".
            lock steering to heading (90,90).
        }
        if verticalSpeed > 100 {
            set runmode to 3.
        }
        else if ship:altitude > 2500 {
            set runmode to 3.
        }
    }
    else if runmode = 3 { 
        set flight_status to "STARTING GRAVITY TURN".
        lock targetPitch to (258.17-(22.16*ln(alt:radar))).
        set targetDirection to 90.
        lock steering to heading(targetDirection,targetPitch).
        set TVAL to 1.
        if ship:apoapsis > targetApoapsis {
            set flight_status to "TARGET APOAPSIS ACHIEVED".
            set tval to 0.
            lock steering to prograde.
        }
        if (ship:altitude > 70000){
            set runmode to 4.
        }
    } else if runmode = 4 {
        if (ship:altitude > 75000){
            SafeStage().
            set flight_status to "FAIRING DEPLOY".
            rcs on.
        } else if (ship:altitude > 82000){
            lock steering to heading (90,0).
            set tval to 0.
        } else if (ship:altitude > 85000) {
            // wait 1.
            // set flight_status to "TIME WARP PARAMETERS SATISFIED".
            // wait 2.
            // set flight_status to "STARTING TIME WARP               ".
            // wait 1.
            set warp to 3.
        } else if eta:apoapsis < 60. {
            circularization_math().
            set runmode to 5.
        }     
        } 
    // else if runmode = 4 {
    //     wait 10.
    //     SafeStage().
    //     set flight_status to "FAIRING DEPLOY".
    //     rcs on.
    //     wait 3.
    //     lock steering to heading (90,0).
    //     circularization_math.
    //     set runmode to 5.
        // set tval to 0.
        // // //specific to electron
        // wait 10.
        // SafeStage().
        // set flight_status to "FAIRING DEPLOY".
        // //yeye
        // rcs on.
        // wait 3.
        // lock steering to heading (90,0).
        // set throttle to 0.
        // //and (eta:apoapsis > 60) and (verticalSpeed > 0) 
        // if (ship:altitude > 80000) {
        //     wait 1.
        //     set flight_status to "TIME WARP PARAMETERS SATISFIED".
        //     wait 2.
        //     set flight_status to "STARTING TIME WARP               ".
        //     wait 1.
        //     set warp to 3.
        //     wait until eta:apoapsis < 60.
        // } 
        // wait until eta:apoapsis < 45. {
        //     set flight_status to "STARTING BURN                  ".
        //     circularization_math().
        //     set runmode to 5.
        // }
    //}
    else if runmode = 5 {
        set warp to 0.
        circularization_math().
        if eta:apoapsis < t_half {
            set flight_status to "BURNING               ".
            set tval to 1.
        }
        if ship:periapsis > 30000 {
            set flight_status to "EASING BURN".
            set tval to (1-ship:periapsis/((1.5*targetPeriapsis))).
        }
        if (ship:periapsis > targetPeriapsis) or (ship:periapsis > targetPeriapsis*0.99) {
            set tval to 0.
            set runmode to 10.
        }
    }
    else if runmode = 10 {
        set flight_status to "ORBIT ACHIEVED".
        set tval to 0.
        panels on.
        lights on.
        unlock steering.
        sas on.
        //specific to electron
        wait 5.
        SafeStage().
        //ends here
        set runmode to 0.
    }

    //maintenance
    //or (throttlecheck = true)
    //stage:Liquidfuel < 1
    if (maxThrust < 1) {
        lock throttle to 0.
        set flight_status to "STAGING".
        //wait 2.
        //lock throttle to 1.
        SafeStage().
        //wait 2.
        set flight_status to "STAGING COMPLETE".
        set flight_status to "RESUMING FLIGHT".
        lock throttle to 1.
    }

    if runmode = 0 {
        set flight_program  to "LAUNCH PROGRAM COMPLETE".
    } else if runmode = 1 {
        set flight_program  to "IGNITION".
    } else if runmode = 2 {
        set flight_program  to "LIFT-OFF".
    } else if runmode = 3 {
        set flight_program  to "GRAVITY TURN".
    } else if runmode = 4 {
        set flight_program  to "COASTING TO APOAPSIS".
    } else if runmode = 5{
        set flight_program  to "ORBIT INSERTION BURN".
    } else if runmode = 10 {
        set flight_program  to "LAUNCH PROGRAM COMPLETE".
    }
    set finalTVAL to TVAL. 
    lock throttle to finalTVAL.

    if runmode > -1 {
        HeadBoard().
    }
}
    
//ag1 - ag9 on. activates action groups so you dont fucking have to
// solved for rocket equation
// ∆v=v_e*ln⁡(m_0/m_f )
// ∆v=I_sp*g*ln⁡(m_0/(m_0-m ̇t))
// (I_sp*gm_0*(e)^((-∆v)/(I_sp∙g))-1))/F_th =t
HeadBoard().
wait 20.
clearScreen.