@lazyGlobal off.
set config:ipu to 1500.

// run math.ks.

global slew_angle is 10.
global target_altitude is 100000.
global current_mode is "".
global cycles is 0.
global shift_alt is 0.

function startup {
    clearScreen.
    set current_mode to "Starting Launch".
    screen_data(1).
    print "Starting Launch".
    sas off.
    rcs off.
    lock throttle to 1.
    wait 1.
    clearScreen.
    return.
}

function open_loop_guidance {
    // Zero aoa ascent
    local runmode to 1.
    
    // Runmodes
    set current_mode to "Open Loop Guidance".

    until runmode = 0 {
        if runmode = 1 {
            stage.
            lock steering to heading(90,90,-90).
            set runmode to 2.
        }
        if runmode = 2 {
            if ship:verticalSpeed > 100 or alt:radar > 1000 {
                set shift_alt to ship:altitude.
                lock steering to heading(90,90-0.4 * sqrt(max(ship:altitude-shift_alt,0)),-90).
                set runmode to 3.
            }
        }
        if runmode = 3 {
            if vang(ship:facing:vector,ship:up:vector) > slew_angle {
                lock steering to heading(90,90-slew_angle,-90).
                set runmode to 4.
            }
        }
        if runmode = 4 {
            if vang(ship:facing:vector,ship:srfPrograde:vector) < 0.25 {
                set runmode to 5.
            }
        }
        if runmode = 5 {
            lock steering to heading(90,90-vang(ship:up:vector,ship:srfprograde:vector),-90).
            set runmode to 6.
        }
        if runmode = 6 {
            if ship:availableThrust / (ship:mass * constant:g0) > 2 {
                lock throttle to throttle_2g().
                set runmode to 7.
            }
        }
        if runmode = 7 {
            if ship:availableThrust < 2 {
                lock throttle to 0.
                safestage().
                wait 1.
                safestage().
                lock throttle to throttle_2g().
                set runmode to 0.
            }
        }
        set cycles to cycles +1.
        screen_data(runmode).
    }
    clearScreen.
    return.
}

function closed_loop_guidance {
    //Powered explicit guidance here
    local runmode to 1.
    set current_mode to "Closed Loop Guidance".
    until runmode = 0 {
        if runmode = 1 {
            if ship:apoapsis > target_altitude {
                lock throttle to 0.
                set runmode to 2.
            }
        }
        if runmode = 2 {
            if ship:altitude > 70000 {
                safestage().
                rcs on.
                set runmode to 3.
            }
        }
        if runmode = 3 {
            if ship:altitude > target_altitude {
                set runmode to 0.
            }
        }
        set cycles to cycles + 1.
        screen_data(runmode).
    }
    clearScreen.
    return.
}

function orbit_tasks {
    sas on.
    ag1 on.
    safestage().
    return.
}

function safestage {
    if stage:ready {
        stage.
    }
    return.
}

function throttle_2g {
    if ship:availablethrust < 1 {
        return 0.
    } else {
    return (2 * (ship:mass * constant:g0) / ship:availableThrust).
    }
}

function screen_data {
    parameter runmode.

    print "Current mode : " + current_mode + " RM : " + runmode at (5,4).
    print "Vessel name      : " + ship:name at (5,5).
    print "Vertical speed   : " + round(ship:verticalSpeed,3) + "   " at (5,7).
    print "Horizontal speed : " + round(ship:groundspeed,3) + "   " at (5,8).
    print "Acceleration     : " + round(ship:availablethrust * throttle / ship: mass,3) + "   " at (5,9).
    print "Apoapsis         : " + round(ship:apoapsis,3) + "   " at (5,10).
    print "Periapsis        : " + round(ship:periapsis,3) + "   " at (5,11).
    print "Altitude         : " + round(ship:altitude,3) + "   " at (5,12).
    print "Time to apoapsis : " + round(eta:apoapsis,3) + "   " at (5,13).
    print "HDG              : " + round(ship:heading,3) + "   " at (5,14).
    print "CPU Cycles       : " + cycles at (5,30).
    print shift_alt at (5,31).
}

function main {
    startup().
    open_loop_guidance().
    closed_loop_guidance().
    orbit_tasks().
}

main().



// ORBITAL RENDEZVOUS CODE
    // Find that good paper, but it is probably in your computer anw
    // BOOTUP
    // START SEQUENCE
    // OPEN LOOP GUIDANCE
    // CLOSED LOOP GUIDANCE
    // ORBIT STABILIZATION
    // TARGET ACQUIRING
    // ORBITAL RENDEZVOUS
        // LAMBERT SOLVING
        // PHASING MANEUVERS
            // CIRCULARIZATION
            // PLANE MATCHING
            // WAITING FOR PHASING ANGLE MATCH
            // HOHMAN TRANSFER
            // MATCH VELOCITIES AT CLOSEST POINT
    // DOCKING

// AIRCRAFT AUTOPILOT
    // BOOTUP
    // START SEQUENCE
    // TAKE OFF
    // TARGETING
        // LOCATION
        // HEADING
        // WAYPOINTING
    // CRUISE
        // COOKED CONTROL
            // ALTITUDE
            // ROLL
            // YAW
        // RAW CONTROL
            // MAINTAIN ALTITUDE
            // MAINTAIN ROLL
            // MAINTAIN YAW
            // MAINTAIN HEADING
    // LANDING
        // LANDING ALIGNMENT
        // APPROACH
        // FLARE
        // BRAKE
    // END

// LANDER SIMULATOR
    // BOOTUP
    // START SEQUENCE
    // LIFT OFF
    // HOVER
        // PID LOOPS
    // TEST CONTROL
    // HOVER TO TARGET
        // PID LOOPS
    // SOFT LANDING

// ICBM CODE
    // BOOTUP
    // START SEQUENCE
        // TARGET ACQUISITION
        // TRAJECTORY PRECALCULATION
    // LAUNCH
    // OPEN LOOP SEQUENCE
        // ROLL
        // PITCH
        // GRAVITY TURN
    // CLOSED LOOP SEQUENCE
        // TRAJECTORY TUNING
    // CRUISE
        // FINE CONTROL
    // DESCENT

// PORKCHOP PLOTTING AND TRANSFER
//     OBTAIN BODY1 ORBITAL PARAMETERS
//     OBTAIN BODY2 ORBITAL PARAMETERS
//     LIMIT TIME NOW SEARCH SPACE
//         0 TO BODY2 ORBITAL PERIOD
//     LIMIT TOF SEARCH SPACE
//         BODY1 PERIOD / 2 TO BODY2 PERIOD
//     FOR TIME IN NOW SEARCH SPACE
//         FOR TIME IN TOF SEARCH SPACE
//             OBTAIN BODY1 NOW POSITION
//             OBTAIN BODY2 TOF POSITION
//             OBTAIN BODY1 NOW VELOCITY
//             OBTAIN BODY2 TOF VELOCITY
//             OBTAIN V1 AND V2
//             OBTAIN DV1 AND DV2
//             RECORD NOW, TOF, DV1, DV2
//     TIME CONSTRAINT
//         ANY TIME NOW
//             FIND THE LOWEST DV WITHIN ONE ORBITAL PERIOD
//         LOWEST DV
//             FIND THE LOWEST DV IN THE ENTIRE SEARCH SPACE
//         RETURN DV1, TIME
//     CREATE TRANSFER VECTOR
//     TRANSFORM TRANSFER VECTOR TO POLAR
//     EXECUTE NODE