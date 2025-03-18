wait 1.
print "hello".
clearScreen.
set runmode to 1.
set flight_program to 1.
set flight_status to 1.

until runmode < 0 {
    HeadBoard().
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
wait 30.