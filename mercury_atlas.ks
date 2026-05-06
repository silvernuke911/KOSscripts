
runpath("0:/lib/maneuver_functions.ks").
runpath("0:/lib/borders.ks").
set config:ipu to 2000.

local function ascent_guidance {
    local parameter target_altitude is 85_000.
    local parameter pitchover_angle is 10.


    // BEGIN STARTUP SEQUENCE 
    local timer is time:seconds + 5.
    local time0 is time:seconds + 6.
    lock met to time:seconds - time0.
    local handlers is lexicon().
    local les_jettison is False.
    local staged is False.
    local abort_enable is False.
    local pitch_start_time is 0.
    local les_jettison_alt is 17_000.
    local booster_staging_alt is 15_000.
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
            gear on.
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
                gear off.
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
           if abs(vang(ship:up:vector, ship:srfPrograde:vector) - pitchover_angle) < 0.25 {
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
            if (ship:altitude > les_jettison_alt) and not les_jettison {
                stage.
                set les_jettison to True.
                set abort_enable to false.
            } 

            if (ship:altitude > booster_staging_alt) and not staged {
                lock throttle to 0.5.
                set timer to time:seconds + 2.
                rcs on.
                return "booster staging".
            } 

            else if ship:apoapsis > (target_altitude + 100) {
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
            return "coasting to apoapsis".
        }
    ).
    handlers:add (
        "coasting to apoapsis",
        {
            set timer to time:seconds + 10.
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
    handlers:add (
        "abort mode",
        {
            stage.
            wait 1.
            stage.
            lock steering to ship:srfRetrograde:vector.
            chutes on.
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
    global current_state is "retracting umbilicals".
    until current_state = "in orbit" {
        local handler is handlers[current_state].
        set current_state to handler().
        screen_output().
        if abort_enable {
            abort_check().
        }
        wait 0.
    }
}

local function abort_check {
    if vang(ship:facing:vector,ship:srfPrograde) > 60 {
        abort on.
        set current_state to "abort mode".
    }
}

ascent_guidance().