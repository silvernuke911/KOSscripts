@lazyGlobal off.
set config:ipu to 1500.

// Launching the fucker
function create_node {
    local parameter mnv_node.
    local eta____ is mnv_node[0]+time:seconds.
    local radial_ is mnv_node[1].
    local normal_ is mnv_node[2].
    local prograd is mnv_node[3].
    local maneuver_node to node(
        eta____,
        radial_,
        normal_,
        prograd
    ).
    add maneuver_node.
}

function raw_node {
    local parameter eta____.
    local parameter radial_.
    local parameter normal_.
    local parameter prograd.
    local mnv_nd is list(
        eta____,
        radial_,
        normal_,
        prograd
    ).
    return mnv_nd.
}
// warp functions
function orbital_velocity_circular {
    local parameter altitude_.
    local r__ is body:radius + altitude_.
    return sqrt(body:mu/r__).
}
function vis_viva_equation {
    local parameter altitude_.
    local r_ is body:radius + altitude_.
    local a is ship:orbit:semimajoraxis.
    return sqrt (body:mu * (2/r_ - 1/a)).
}

function circularize {
    local parameter mode.
    if mode = "at periapsis" {
        local periapsis_dV is 
            orbital_velocity_circular(ship:periapsis) - 
            vis_viva_equation(ship:periapsis).
        return list(eta:periapsis,0,0,periapsis_dV).
    }
    if mode = "at apoapsis" {
        local apoapsis_dv is
            orbital_velocity_circular(ship:apoapsis) - 
            vis_viva_equation(ship:apoapsis).
        return list(eta:apoapsis,0,0,apoapsis_dV).
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
    local parameter warp_to_node is true.
    local mnv_node to nextNode.

    unlock steering.
    sas on.
    set sasMode to "MANEUVER".
    if ship:availableThrust = 0 {
        stage.
    }
    wait until vang(ship:facing:vector, mnv_node:deltav:vec) < 0.5.
    //warp here to about 10 s before node 
    wait until mnv_node:eta <= half_burn_time(mnv_node). 
    local init_dv to mnv_node:deltav.
    local tset to 0.
    lock throttle to tset.
    local burn_done to false.
    until burn_done {
        local max_acc to ship:maxthrust/ship:mass.
        set tset to min(mnv_node:deltav:mag/max_acc,1).
        if vDot(init_dv,mnv_node:deltav) <0 {
            lock throttle to 0.
            break.
        }
        if mnv_node:deltav:mag < 0.1 {
            wait until vDot(init_dv, mnv_node:deltav)<0.5.
            lock throttle to 0.
            set burn_done to true.
        }
    }
    wait 1.
    remove mnv_node.
    return.
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

function ship_isp {
    local engineList to list().
    list engines in engineList.
    local total_thrust to 0.
    local weighted_isp to 0.
    for engine in engineList {
        if engine:availablethrust > 0 and engine:isp > 0 {
            set total_thrust to total_thrust + engine:availablethrust.
            set weighted_isp to weighted_isp + (engine:availablethrust * engine:isp).
        }
    }
    
    if total_thrust > 0 {
        set weighted_isp to weighted_isp/total_thrust.
    } else {
        return 0.
    }
    return weighted_isp.
}

function total_burn_time {
    local parameter mnv.
    local deltav is  mnv:deltav:mag.
    local Isp is ship_isp().
    if isp = 0 {
        return 0.
    }
    local ve is Isp *constant:g0.
    local mdot is ship:maxThrust/ve.
    local m0 is ship:mass.
    local mf is m0*constant:e^(-deltav/ ve).
    local dm is m0 - mf.
    local t is dm / mdot.
    return t.

}

function half_burn_time {
    local parameter mnv.
    local deltav is  mnv:deltav:mag.
    local deltav_2 is deltav/2.
    local Isp is ship_isp().
    if isp = 0 {
        return 0.
    }
    local ve is Isp * constant:g0.
    local mdot is ship:maxThrust/ve.
    local m0 is ship:mass.
    local mf is m0*constant:e^(-deltav_2/ ve).
    local dm is m0 - mf.
    local t is dm / mdot.
    return t.    
}
// run math.ks.

global slew_angle is 15.
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
                lock steering to 
                    heading(
                        90,
                        90-0.4 * sqrt(max(ship:altitude-shift_alt,0)),
                        -90
                    ).
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
            lock steering to heading(
                90,
                90-vang(ship:up:vector,ship:srfprograde:vector),
                -90
            ).
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
            if ship:apoapsis > (target_altitude - 10000) {
                lock throttle to min(1,max(0.1,(target_altitude-ship:apoapsis)/7500)).
                set runmode to "Closing in on apoapsis".
            }
        }
        if runmode = "Closing in on apoapsis" {
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
            if ship:altitude > 80000 {
                set runmode to "creating node".
            }
        }
        if runmode = "creating node" {
            create_node(circularize("at apoapsis")).
            unlock steering.
            set runmode to "circularizing burn".
        }
        if runmode = "circularizing burn" {
            print ("IT GOT HERE") at (5,25).
            execute_node().
            set runmode to "done".
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
    ag2 on.
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
