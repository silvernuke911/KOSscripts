set targetApoapsis to 85000.
set targetPeriapis to 85000.
set flight_status to "null".
set flight_program to "null".
set delta_periapsis to (ship:periapsis - targetPeriapis).
set delta_apoapsis to (ship:apoapsis - targetApoapsis).
sas off.
rcs off.
set runmode to 1.
clearScreen.
function Debugging {
    print "DEBUGGING TOOL" at (2,18).
    print "mission time " + round(missionTime,2)+"  " at (5,19).
    print "status          " + flight_status + "                   "  at (5,22).
    print "program         " + flight_program + "                  " at (5,23).
    print "alt             " + round(altitude,2)+"  "  at (5,24).
    print "radar alt       " + round(alt:radar,2)+"  "  at (5,25).
    print "target hdg      " + round(ship:bearing,2)+"   "  at (5,26).
    print "throttle        " + (throttle*100) + "  " at (5,28).
    print "ship apoapsis   " + round(ship:apoapsis,2)+"   "  at (5,29).
    print "ship periapsis  " + round(ship:periapsis,2)+"   "  at (5,30).
    print "target apoapsis " + round(targetApoapsis,2)+"   "  at (5,31).
    print "target periapsis" + round(targetPeriapis,2)+"   "  at (5,32).
    print "eta apoapsis    " + round(eta:apoapsis,2)+"   "  at (5,33).
    print "eta periapsis   " + round(eta:periapsis,2)+"   "  at (5,34).
    print "delta ap        " + round(delta_apoapsis)+"   "  at (5,16).
    print "delta pe        " + round(delta_periapsis)+"   "  at (5,17).
    print "runmode         " + runmode at (5, 15).
}
until runmode = 0 {
    if eta:apoapsis < eta:periapsis {
        set flight_program to "PERIAPSIS FINE TUNE".
        if ship:periapsis > (targetPeriapis) {
            lock steering to retrograde. 
        } else if ship:periapsis < (targetPeriapis) {
            lock steering to prograde. 
        }
        if (eta:apoapsis > 200) {
            set flight_status to "WARPING TO APOAPSIS 1".
            set warp to 3.
            print "I GOT HERE" at (5,2).
        } else if (eta:apoapsis < 100) and (eta:apoapsis > 30) { 
            print "I GOT HERE TOO" at (5,2).
            set flight_status to "WARPING TO APOAPSIS 2".
            set warp to 2.
        } else if (eta:apoapsis < 30) {
            print "I GOT HERE THREE" at (5,2).
            set flight_status to "WARPING TO APOAPSIS HALT".
            set warp to 0.
            if (eta:apoapsis < 5) {
                if (delta_periapsis > 10000) {
                    set flight_status to "BURNING RETROGRADE".
                    lock throttle to 1.
                } else if (delta_periapsis < 10000) and (delta_periapsis > 0) {
                        rcs off.
                        set flight_status to "BURNING RETROGRADE".
                        lock throttle to 0.1. 
                } else if abs(delta_periapsis) < 50 {
                        rcs off.
                        set flight_status to "PERIAPSIS FINETUNED".
                        lock throttle to 0.
                        unlock steering.
                        set runmode to 1.
                } else if (delta_periapsis < -10000) {
                    set flight_status to "BURNING  PROGRADE".
                    lock throttle to 1.
                } else if  (delta_periapsis > -10000){
                        rcs off.
                        set flight_status to "BURNING PROGRADE".
                        lock throttle to 0.1.
                } 
            }
        } 
    } else if eta:periapsis < eta:apoapsis {
        set flight_program to "APOAPSIS FINE TUNE".
        if ship:apoapsis  > (targetapoapsis) {
            lock steering to retrograde. 
        } 
        if (eta:periapsis > 200) {
            set flight_status to "WARPING TO PERIAPSIS 1".
            set warp to 3.
        } else if (eta:periapsis < 200) and (eta:periapsis > 30) {
            set flight_status to "WARPING TO PERIAPSIS 2".
            set warp to 2.
        } else if (eta:periapsis < 30) {
            set flight_status to "WARPING TO PERIAPSIS HALT".
            set warp to 0.
            if (eta:periapsis < 5) {
                if (delta_apoapsis > 10000) {
                    set flight_status to "BURNING RETROGRADE".
                    lock throttle to 1.
                } else if (delta_apoapsis < 10000) {
                    print "I GOT HERE THREEEEEEEEEEEEE" at (5,2).
                    set runmode to 3.
                }
            }
            
        }
    //needs fixing otherwise its already good. prolly a smarter maneuvernode system will do.
    } else if runmode = 3 {
            if (delta_apoapsis < 10000) {
                rcs off.
                unlock steering.
                sas on.
                set flight_status to "BURNING RETROGRADE".
                lock throttle to 0.1.
            }
            if ((delta_apoapsis) < 50) and ((delta_apoapsis) > 0) {
                set flight_status to "APOAPSIS FINETUNED".
                lock throttle to 0.
                unlock steering.
                sas on.
                set runmode to 0.
            }
    }
set delta_periapsis to (ship:periapsis - targetPeriapis).
set delta_apoapsis to (ship:apoapsis - targetApoapsis).
Debugging().
}