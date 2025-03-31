@lazyGlobal off.
set config:ipu to 1500.
runpath("0:/lib/maneuver_functions.ks").
runpath("0:/lib/borders.ks").
global targ_inclination is 30.
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
    title_borders().
    return.
}
lock tgt_heading to inclination_heading(targ_inclination,"northbound").
function open_loop_guidance {
    // Zero aoa ascent
    // Runmodes
    set current_mode to "Open Loop Guidance".
    local runmode to "ignition".

    until runmode = "ascent done" {
        if runmode = "ignition" {
            stage.
            lock steering to heading(90,90,-90).
            set runmode to "roll program".
        }
        if runmode = "roll program" {
            if alt:radar > 150 {
                lock steering to heading(tgt_heading,90,-90).
                set runmode to "clearing tower".
            }
        }
        if runmode = "clearing tower" {
            if ship:verticalSpeed > 100 or alt:radar > 1000 {
                set shift_alt to ship:altitude.
                lock steering to 
                    heading(
                        tgt_heading,
                        90-0.4 * sqrt(max(ship:altitude-shift_alt,0)),
                        -90
                    ).
                set runmode to "pitch program".
            }
        }
        if runmode = "pitch program"{
            if vang(ship:facing:vector,ship:up:vector) > slew_angle {
                lock steering to heading(
                    tgt_heading,
                    90-slew_angle,
                    -90).
                set runmode to "pitch holding".
            }
        }
        if runmode = "pitch holding" {
            print vang(ship:facing:vector,ship:srfprograde:vector) at (5,29). //DEELTEE
            if vang(ship:facing:vector,ship:srfprograde:vector) < 0.5 {
                set runmode to "setting aoa".
            }
        }
        if runmode = "setting aoa" {
            lock steering to heading(
                tgt_heading,
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
    title_borders().
    return.
}

function closed_loop_guidance {
    //Powered explicit guidance here
    local runmode to "reaching apoapsis".
    set current_mode to "Closed Loop Guidance".
    until runmode = "done" {
        if runmode = "reaching apoapsis" {
            if ship:apoapsis > (target_altitude - 10000) {
                lock throttle to min(
                    1,
                    max(
                        0.1,
                        (target_altitude-ship:apoapsis)/7500
                    )
                ).
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
            execute_node(false,false).
            set runmode to "done".
        }
        set cycles to cycles + 1.
        screen_data(runmode).
    }
    unlock steering.
    clearScreen.
    title_borders().
    return.
}
function title_borders{
    horizontal_line(0, terminal:width,1,"=").
    horizontal_line(0, terminal:width,5,"=").
    horizontal_line(0, terminal:width,20,"-").
    horizontal_line(0, terminal:width,terminal:height,"=").
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
    if ship:availablethrust = 0 {
        return 0.
    } else {
        return (2 * (ship:mass * constant:g0) / ship:availableThrust).
    }
}

function screen_data {
    parameter runmode.
    
    print "Current mode : " + current_mode + "  " at (5,2).
    print "Runmode      : "+ runmode + "  " at (5, 3).
    
    print "Vessel name      : " + ship:name at (5,5).
    print "Vertical speed   : " + round(ship:verticalSpeed,3) + "   " at (5,7).
    print "Horizontal speed : " + round(ship:groundspeed,3) + "   " at (5,8).
    print "Acceleration     : " + round(ship:availablethrust * throttle / ship: mass,3) + "   " at (5,9).
    print "Apoapsis         : " + round(ship:apoapsis,3) + "   " at (5,10).
    print "Periapsis        : " + round(ship:periapsis,3) + "   " at (5,11).
    print "Altitude         : " + round(ship:altitude,3) + "   " at (5,12).
    print "Time to apoapsis : " + round(eta:apoapsis,3) + "   " at (5,13).
    print "HDG              : " + round(compass_hdg(),3) + "   " at (5,14).
    print "TWR              : " + round(twr(), 2) + "   " at (5,15).
    
    print "CPU Cycles       : " + cycles at (5,30).
    
    print shift_alt at (5,31).
}

function main {
    startup().
    open_loop_guidance().
    closed_loop_guidance().
    orbit_tasks().
    global done to false.
    until done {
        screen_data("ORBIT").
    }
}
main().
