
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

function log_flight_data {
    local parameter targ_alt_.
    set file_name to "hu1pidtuning0.csv".
    if not exists(file_name) {
        // Create the file and write the header if it doesn't exist
        log "Time,Altitude,Setpoint" to file_name.
    }
    set ship_alt to round(alt:radar, 2).
    set time_now to round(time:seconds, 2).
    set targ_alt_ to round(targ_alt_,2).
    log time_now + "," + ship_alt+ ","+ targ_alt_ to file_name.
}

set collective to 0.
local targ_alt is 50.
lock throttle to collective.

clearScreen.
local targ_vertvel to 0.
set vertpid to pidLoop(0.4,0.6,0.025,0,1). // this is good

local targ_forvel to 0.
// set forepid to pidLoop(5,0.6,0.25,-30,30).
set forepid to pidLoop(4,0.6,0.25,-30,30).

set targ_sidevel to 0.
set sidepid to pidLoop(4,0.6,0.25,-15,15).

set targ_hdg to compass_hdg().

set hoverpid to pidLoop(0.02,0.002,0.02,0,1).

set system_done to false.
set runmode to 1.
set time_start to time:seconds.
set time_limit to 30.

sas on.
rcs on.
until system_done {
    if runmode = 1 {
        // initial ascent
        set hoverpid:setpoint to targ_alt.
        set collective to hoverpid:update(time:seconds, alt:radar).
        log_flight_data(targ_alt).
    }
    if (time:seconds - time_start) > time_limit {
        set targ_sidevel to 0.
        set targ_forvel to 0.
        set targ_vertvel to -5.
        set runmode to 8.
    }
    if runmode = 8 {
        set vertpid:setpoint to targ_vertvel.
        set collective to vertpid:update(time:seconds, ship:verticalspeed).
        if alt:radar < 15 {
            set targ_vertvel to -1.
            set runmode to 9.
        }
    }
    if runmode = 9 {
        set vertpid:setpoint to targ_vertvel.
        set collective to vertpid:update(time:seconds, ship:verticalspeed).
        if alt:radar < 0.75 {
            set runmode to 10.
        }
    }
    if runmode = 10 {
        rcs off.
        set system_done to true.
    }
    print "TIME : " + round((time:seconds - time_start),1) at (5,8).
    print "V : "+targ_vertvel+ "   " at (5,12).
    print "F : "+targ_forvel+ "   " at (15,12).
    print "S : "+targ_sidevel+ "   " at (25,12).

    print "ALT RDR : "+round(alt:radar,2) at (5,10).

    local velocity_vector is ship:velocity:surface:vec.
    local up_vector is ship:up:vector.
    local fore_vector is vxcl(up_vector,ship:facing:forevector).
    local starboard_vector is vcrs(up_vector, fore_vector).

    // Compute the components
    local up_component is vdot(velocity_vector, up_vector).
    local fore_component is vdot(velocity_vector, fore_vector).
    local sb_component is vdot(velocity_vector, starboard_vector).

    print "UP     : " + round(up_component,2)+ "   " at (5,16).
    print "FORE   : " + round(fore_component,2)+ "   " at (5,17).
    print "STRBRD : " + round(sb_component,2)+ "   " at (5,18).

    print "TGT HDG : " + round(targ_hdg)+"  " at (5,20).
    print "TRU HDG : " + round(compass_hdg())+"  " at (5,21).
}