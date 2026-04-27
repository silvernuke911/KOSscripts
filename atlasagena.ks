@lazyGlobal off.
runpath("0:/lib/maneuver_functions.ks").
runpath("0:/lib/borders.ks").
set config:ipu to 2000.

local function ascent_guidance {
    local parameter target_altitude is 100_000.
    local parameter pitchover_angle is 30.


    // BEGIN STARTUP SEQUENCE 
    local timer is time:seconds + 5.
    local time0 is time:seconds + 6.
    lock met to time:seconds - time0.
    local handlers is lexicon().
    local staged is False.
    local apoapsis_fine_tuned is false.
    local pitch_start_time is 0.
    local booster_staging_alt is 12_000.
    local pitch_rate is 1. // deg /sec
    local tset is pidLoop(1,0.1,0,0.25,1).
    sas off.
    rcs off.
    clearScreen.
    // END STARTUP SEQUENCE'

    handlers:add (
        "retracting umbilicals",
        {
            stage.
            return "pre-ignition".
        }
    ).
    handlers:add (
        "pre-ignition",
        {
            if time:seconds > timer {
                lock throttle to 1.
                return "ignition".
            }
            return "pre-ignition".
        }
    ).
    handlers:add (
        "ignition",
        {
            stage.
            lock steering to heading(90,90,-90).
            set timer to time:seconds + 1.
            return "liftoff".
        }
    ).
    handlers:add (
        "liftoff",
        {
            if time:seconds > timer {
                stage.
                set time0 to time:seconds.
                return "vertical ascent".
            }
            return "liftoff".
        }
    ).
    handlers:add (
        "vertical ascent",
        {
            if ship:verticalSpeed > 100 or ship:altitude > 1000 {
                set pitch_start_time to time:seconds.
                lock steering to heading(90,90-min(pitchover_angle , pitch_rate * (time:seconds - pitch_start_time)),-90).
                return "pitching".
            }
            return "vertical ascent".
        }
    ).
    handlers:add (
        "pitching",
        {
            if abs(vang(ship:facing:vector, ship:up:vector) - pitchover_angle) < 0.25 {
                lock steering to heading(90,90-pitchover_angle,-90).
                return "holding pitch".
            }
        return "pitching".
        }
    ).
    handlers:add (
        "holding pitch",
        {
            if vang(ship:facing:vector, ship:srfPrograde:vector) < 0.25 {
                lock steering to heading (
                    90,
                    90 - vang(ship:up:vector,ship:srfPrograde:vector),
                    -90
                ).
                return "gravity turn".
            }
            return "holding pitch".
        }
    ).
    handlers:add (
        "gravity turn",
        {
            if (ship:altitude > booster_staging_alt) and not staged {
                lock throttle to 0.5.
                set timer to time:seconds + 2.
                rcs on.
                return "booster staging".
            } 
            else if ship:apoapsis > (target_altitude - 300) {
                return "main engine cuttoff".
            }
            return "gravity turn".
        }
    ).
    handlers:add (
        "booster staging",
        {
            if time:seconds > timer {
                stage.
                set staged to True.
                set timer to time:seconds + 3.
                return "restoring throttle".
            }
            return "booster staging".
        }
    ).
    handlers:add (
        "restoring throttle",
        {
            if time:seconds > timer {
                set tset:setpoint to 90.
                lock throttle to tset:update(time:seconds,eta:apoapsis).
                rcs off.
                return "gravity turn".
            }
            return "restoring throttle".
        }
    ).
    handlers:add (
        "main engine cuttoff",
        {
            lock throttle to 0.
            set timer to time:seconds + 5.
            return "agena staging".
        }
    ).
    handlers:add (
        "agena staging",
        {
            if time:seconds > timer {
                stage.
                rcs on.
                set timer to time:seconds + 5.
                return "fine tune apoapsis 1".
            }
            return "agena staging".
        }
    ).
    handlers:add (
        "fine tune apoapsis 1",
        {   
            if apoapsis_fine_tuned and (ship:altitude > body:atm:height) {
                rcs off.
                return "coasting to apoapsis".
            }
            if time:seconds > timer {
                if obt:apoapsis > target_altitude {
                    set ship:control:fore to -1.
                } else {
                    set ship:control:fore to +1.
                }
                return "fine tune apoapsis 2".
            }
            return "fine tune apoapsis 1".
        }
    ).
    handlers:add (
        "fine tune apoapsis 2",
        {
            if abs(obt:apoapsis - target_altitude) < 10 {
                set ship:control:fore to 0.
                set apoapsis_fine_tuned to true.
                return "fine tune apoapsis 1".
            }
            return "fine tune apoapsis 2".
        }
    ).
    handlers:add (
        "coasting to apoapsis",
        {
            stage.
            set timer to time:seconds + 5.
            return "plotting circularization".
        }
    ).
    handlers:add (
        "plotting circularization",
        {
            if time:seconds > timer {
                create_node(
                    circularize("at apoapsis")
                ).
                return "execute burn".
            }
            return "plotting circularization".
        }
    ).
    handlers:add (
        "execute burn",
        {
            execute_node(False).
            return "in orbit".
        }
    ).
    // TELEMETRY
    local function screen_output {
        print "MET   : " + round(met, 2) at (5,5).
        print "ALT   : " + round(ship:altitude) at (5,7).
        print "APO   : " + round(obt:apoapsis) at (5,9).
    }
    //============================================
    // GUIDANCE LOOP
    //============================================
    local current_state is "retracting umbilicals".
    until current_state = "in orbit" {
        local handler is handlers[current_state].
        set current_state to handler().
        screen_output().
        wait 0.
    }
}

ascent_guidance().
ag1 on.