@lazyGlobal off.
runpath("0:/lib/maneuver_functions.ks").
runpath("0:/lib/borders.ks").
set config:ipu to 1500.

// global slew_angle is 10.
global target_altitude is 80000.
// global current_mode is "".
// global cycles is 0.
// global shift_alt is 0.

function initialization {
    clearScreen.
    sas off.
    rcs off.
    lock throttle to 1.
    wait 2.
    return.
}
function throttle_2g {
    if ship:availablethrust < 1 {
        return 0.
    } else {
    return (2 * (ship:mass * constant:g0) / ship:availableThrust).
    }
}
function safestage {
    if stage:ready {
        stage.
    }
    return.
}
function open_loop_guidance {
    local runmode to "ignition".
    local slew_angle is 20.
    local shift_alt to 0.
    local cycles to 0.
    // If else ladder
    until runmode = "done" {
        if runmode = "ignition" {
            stage.
            lock steering to heading(90,90,-90).
            set runmode to "clearing tower".
        }
       if runmode = "clearing tower" {
            if ship:verticalSpeed > 100 or alt:radar > 1000 {
                set shift_alt to ship:altitude.
                lock steering to heading(90,90-0.4 * sqrt(max(ship:altitude-shift_alt,0)),-90).
                set runmode to "turn init".
            }
        }
        if runmode = "turn init" {
            if vang(ship:facing:vector,ship:up:vector) > slew_angle {
                lock steering to heading(90,90-slew_angle,-90).
                set runmode to "turn wait".
            }
        }
        if runmode = "turn wait" {
            if vang(ship:facing:vector,ship:srfPrograde:vector) < 0.25 {
                set runmode to "gravity turn init".
            }
        }
        if runmode = "gravity turn init" {
            lock steering to heading(90,90-vang(ship:up:vector,ship:srfprograde:vector),-90).
            set runmode to "2g wait".
        }
        if runmode = "2g wait" {
            if ship:availableThrust / (ship:mass * constant:g0) > 2 {
                lock throttle to throttle_2g().
                set runmode to "gravity turn".
            }
        }
        if runmode = "gravity turn" {
            if ship:availableThrust < 2 {
                lock throttle to 0.
                safestage().
                wait 1.
                safestage().
                lock throttle to throttle_2g().
                set runmode to "done".
            }
        }
        set cycles to cycles + 1.
        screen_data(runmode, cycles).
        wait 0.
    }
    clearScreen.
    return.
}

function closed_loop_guidance {
    local runmode is "fixing apoapsis".
    local cycles is 0.
    until runmode = "done" {
        if runmode = "fixing apoapsis" {
            if ship:apoapsis > target_altitude {
                lock throttle to 0.
                set runmode to "coasting atmosphere".
            }
        }
        if runmode = "coasting atmosphere" {
            if ship:altitude > 70000 {
                safestage().
                rcs on.
                set runmode to "coasting to apoapsis".
            }
        }
        if runmode = "coasting to apoapsis" {
            if ship:altitude > target_altitude - 5000 {
                set runmode to "done".
            }
        }
        set cycles to cycles + 1.
        screen_data(runmode, cycles).
        wait 0.
    }
    clearScreen.
    return.
}

function orbit_insertion {
    create_node(circularize("at apoapsis")).
    execute_node().
    return.
}

function screen_data {
    parameter runmode.
    parameter cycles.

    print cycles at (5,4).
    print runmode + "           " at (5,5).
}
function main {
    initialization().
    open_loop_guidance().
    closed_loop_guidance().
    orbit_insertion().
}
main().