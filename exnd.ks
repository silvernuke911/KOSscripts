@lazyGlobal off.
set config:ipu to 1500.
// Launching the fucker
function create_node {
    
}
function circularize {
    local parameter mode.
    if mode = "at periapsis" {

    }
    if mode = "at apoapsis" {

    }
    if mode = "at altitude" {

    }
    if mode = "after fixed time" {

    }
}

function change_apoapsis {
    local parameter target_apoapsis.
    local parameter mode.
    if mode = "at next periapsis" {

    }
    if mode = "at next apoapsis" {

    }
    if mode = "after a fixed time" {

    }
    if mode = "at equatorial DN" {

    }
    if mode = "at equatorial AN" {

    }
}
function change_periapsis {
    local parameter target_periapsis.
    local parameter mode.
    if mode = "at next periapsis" {

    }
    if mode = "at next apoapsis" {

    }
    if mode = "after a fixed time" {

    }
    if mode = "at equatorial DN" {

    }
    if mode = "at equatorial AN" {
        
    }
}

function change_inclination {
    local parameter target_inclination.
    local parameter mode.
    if mode = "at cheapeast node" {

    }
    if mode = "at nearest node" {

    }
    if mode = "at AN" {
         
    }
    if mode = "at DN" {

    }
    if mode = "after fixed time" {

    }
}

function change_longitude_of_ascending_node {

}

function change_pe_and_ap {

}

function return_from_a_moon {
    local parameter target_periapsis.
} 

function change_semi_major_axis {

}

function change_resonant_orbit {
    local parameter target_resonance.
    local parameter mode.
    if mode = "at periapsis" {

    }
    if mode = "at apoasis" {

    }
    if mode = "after fixed time" {

    }
    if mode = "at altitude" {

    }
}

function rcs_orbit_corrector {

}
function execute_node {
    parameter next_node.
}

function compass_hdg {
    local up_vector is ship:up:vector.
    local north_vector is ship:north:vector. // Horizontal North direction
    local east_vector is vcrs(up_vector, north_vector).       // Horizontal East direction
    local facing_vector is ship:facing:forevector.
    local projV is vxcl(up_vector, facing_vector). // Project forward vector onto the horizontal plane
    local angle is vang(north_vector, projV). // Angle from North

    // Use dot product with east to determine left/right deviation
    if vdot(projV, east_vector) < 0 {
        set angle to 360 - angle.
    }
    return angle.
}

// run math.ks.

global slew_angle is 12.5.
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
    // Runmodes
    set current_mode to "Open Loop Guidance".
    local runmode to "ignition".

    until runmode = "ascent done" {
        if runmode = "ignition" {
            stage.
            lock steering to heading(90,90,-90).
            set runmode to "clearing tower".
        }
        if runmode = "clearing tower" {
            if ship:verticalSpeed > 100 or alt:radar > 1000 {
                set shift_alt to ship:altitude.
                lock steering to heading(90,90-0.4 * sqrt(max(ship:altitude-shift_alt,0)),-90).
                set runmode to "pitch program".
            }
        }
        if runmode = "pitch program"{
            if vang(ship:facing:vector,ship:up:vector) > slew_angle {
                lock steering to heading(90,90-slew_angle,-90).
                set runmode to "pitch holding".
            }
        }
        if runmode = "pitch holding" {
            if vang(ship:facing:vector,ship:srfPrograde:vector) < 0.25 {
                set runmode to "setting aoa".
            }
        }
        if runmode = "setting aoa" {
            lock steering to heading(90,90-vang(ship:up:vector,ship:srfprograde:vector),-90).
            set runmode to "gravity turn1".
        }
        if runmode = "gravity turn1" {
            if ship:availableThrust / (ship:mass * constant:g0) > 2 {
                lock throttle to throttle_2g().
                set runmode to "gravity turn2".
            }
        }
        if runmode = "gravity turn2" {
            if ship:availableThrust < 2 {
                lock throttle to 0.
                safestage().
                wait 1.
                safestage().
                lock throttle to throttle_2g().
                set runmode to "ascent done".
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
    local runmode to "reaching apoapsis".
    set current_mode to "Closed Loop Guidance".
    until runmode = "done" {
        if runmode = "reaching apoapsis" {
            if ship:apoapsis > target_altitude {
                lock throttle to 0.
                set runmode to "coast1".
            }
        }
        if runmode = "coast1" {
            if ship:apoapsis < target_altitude {        
                lock throttle to 0.05.
                set runmode to "coast2".
            }
            if ship:altitude > 70000 {
                set runmode to "vaccuum".
            }
        }
        if runmode = "coast2"{
            if ship:apoapsis > target_altitude {
                lock throttle to 0.
                set runmode to "coast1".
            }
            if ship:altitude > 70000 {
                set runmode to "vaccuum".
            }
        }
        if runmode = "vaccuum" {
            safestage().
            rcs on.
            set runmode to "v coast".
        }
        if runmode = "v coast" {
            if ship:altitude > target_altitude {
                set runmode to "done".
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

    print "Current mode : " + current_mode + "  " at (5,3).
    print "Runmode      : "+ runmode + "  " at (5, 4).
    print "Vessel name      : " + ship:name at (5,5).
    print "Vertical speed   : " + round(ship:verticalSpeed,3) + "   " at (5,7).
    print "Horizontal speed : " + round(ship:groundspeed,3) + "   " at (5,8).
    print "Acceleration     : " + round(ship:availablethrust * throttle / ship: mass,3) + "   " at (5,9).
    print "Apoapsis         : " + round(ship:apoapsis,3) + "   " at (5,10).
    print "Periapsis        : " + round(ship:periapsis,3) + "   " at (5,11).
    print "Altitude         : " + round(ship:altitude,3) + "   " at (5,12).
    print "Time to apoapsis : " + round(eta:apoapsis,3) + "   " at (5,13).
    print "HDG              : " + round(compass_hdg(),3) + "   " at (5,14).
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
