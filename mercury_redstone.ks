
runpath("0:/lib/maneuver_functions.ks").
runpath("0:/lib/borders.ks").
set config:ipu to 2000.
clearScreen.

global time0 is time:seconds + 10.
lock met to time:seconds - time0.
local function ascent_sequence {
    rcs off.
    sas off. 
    local timer is time:seconds + 8.
    
    local engine_ignition is false.
    local booster_jettison is false.
    local booster_jettison_alt is 80_000.
    local les_jettison is False.
    local les_jettison_alt is 30_000.
    local end_program_alt is 100_000.
    local abort_enable is False.

    local handlers is lexicon().
    handlers:add (
        "pre-ignition",
        {
            if (time:seconds > timer and not engine_ignition) {
                lock throttle to 1.
                stage.
                lock steering to heading(90,90,-90).
                print(steering).
                set engine_ignition to true.
            }
            if (time:seconds > time0) {
                return "ignition".
            }
            return "pre-ignition".
        }
    ).
    handlers:add ( 
        "ignition",
        {
            stage.
            return "vertical ascent".
        }
    ).
    handlers:add(
        "vertical ascent",
        {
            if ship:altitude > les_jettison_alt and not les_jettison {
                stage.
                set les_jettison to true.
                set abort_enable to false.
            }

            if ship:altitude > booster_jettison_alt and not booster_jettison {
                stage.
                lock throttle to 0.
                set booster_jettison to true.
                return "coasting to apoapsis".
            } 

            return "vertical ascent".
        }
    ).
    handlers:add(
        "coasting to apoapsis",
        {
            if ship:altitude > end_program_alt {
                rcs on.
                sas on.
                unlock steering.
                return "in space".
            }
            return "coasting to apoapsis".
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

    // handlers:add(,{}).
    global current_state is "pre-ignition".
    until current_state = "in space" {
        local handler is handlers[current_state].
        set current_state to handler().
        display().
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

local function reentry_sequence {
    local chutes_deployed is false.
    local retro_pack_jettisoned is false.
    local timer is time:seconds + 15.
    local handlers is lexicon().
    rcs on.

    handlers:add(
        "aiming for ocean",
        {
            local east_vec is vcrs(ship:up:vector,ship:north:vector).
            lock throttle to 1.
            lock steering to east_vec.
            return "aiming for ocean2".
        }
    ).

    handlers:add(
        "aiming for ocean2",
        {
            if time:seconds > timer {
                set timer to time:seconds + 5.
                lock steering to ship:srfretrograde:vector.
                lock throttle to 0.
                return "slowing down1".
            }
        }
    ).

    handlers:add(
        "slowing down1",
        {
            if time:seconds > timer {
                lock throttle to 1.
                set timer to time:seconds + 30.
                return "slowing down2".
            }
            return "slowing down1".
        }
    ).

    handlers:add(
        "slowing down2",
        {
            if time:seconds > timer {
                lock throttle to 0.
                stage.
                set retro_pack_jettisoned to True.
                return "reentry coast".
            }
            return "slowing down2".
        }
    ).

    handlers:add(
        "reentry coast",
        {
            if ship:altitude < 5000 {
                stage.
                set chutes_deployed to True.
                return "chute_coast".
            }
            return "reentry coast".
        }
    ).

    handlers:add(
        "chute_coast",
        {
            if ship:altitude < 3 {
                return "splashdown".
            }
            return "chute_coast".
        }
    ).
    set current_state to "aiming for ocean".
    until current_state = "splashdown" {
        local handler is handlers[current_state].
        set current_state to handler().
        display().
        wait 0.
    }
}

local function display {
    print "MET   : " + round(met, 2) at (5,5).
    print "ALT   : " + round(ship:altitude) at (5,7).
    print "APO   : " + round(obt:apoapsis) at (5,9).
}

ascent_sequence().
until verticalSpeed < -10 {
    display().
}
reentry_sequence().