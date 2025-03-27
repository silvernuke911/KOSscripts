// function to hover a certain altitude
// sas on. 
print ("turning engine on").
rcs on.
print ("waiting for engine to warm up").
// wait 7.5.
local targ_alt is 25.
print("setting pid structure").
set hoverpid to pidLoop(0.02,0.05,0.02,0,1).


function terminal_input {
    local value is 0.
    local dim is "UP".
    local decrement is 1.
    if terminal:input:haschar() { 
        set ch to terminal:input:getchar().
        if ch = "." {
            set decrement to decrement*10.
        }
        if ch = "," {
            set decrement to decrement/10.
        }
        if ch = "h" {
            set value to value + decrement.
            set dim to "UP".
        }
        if ch = "n" {
            set value to value - decrement.
            set dim to "UP".
        }
        if ch = terminal:input:downcursorone or ch ="s" {
            set value to  value - decrement.
            set dim to "FORE".
        }
        if ch = terminal:input:upcursorone or ch ="w" {
            set value to  value + decrement.
            set dim to "FORE".
        }
        if ch = terminal:input:rightcursorone or ch ="e" {
            set value to  value + decrement.
            set dim to "SIDE".
        }
        if ch = terminal:input:leftcursorone or ch ="q" {
            set value to  value - decrement.
            set dim to "SIDE".
        }
        if ch = "a" {
            set value to  value - decrement.
            set dim to "HDG".
        }
        if ch = "d" {
            set value to  value + decrement.
            set dim to "HDG".
        }
        if ch = terminal:input:backspace {
            set value to 1.
            set dim to "END".
        }
        terminal:input:clear().
    }
    print list(value, dim)[0]+"  " at (5,4).
    print list(value, dim)[1]+"  " at (5,5).
    return list(value, dim, decrement).
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
set collective to 0.
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


set system_done to false.

// get the components for up, fore, and east
until system_done {


    global input_list to terminal_input().
    print "DECREMENT : " + input_list[2] at (5,10).
    if input_list[1] = "UP" {
        set targ_vertvel to targ_vertvel + input_list[0].
    }
    if input_list[1] = "FORE" {
        set targ_forvel to  targ_forvel + input_list[0].
    }
    if input_list[1] = "SIDE" {
        set targ_sidevel to  targ_sidevel + input_list[0].
    }
    if input_list[1] = "HDG" {
        set targ_hdg to  targ_hdg  + input_list[0].
        if targ_hdg < 0 {
            set targ_hdg to 360 + targ_hdg.
        }
    }

    if input_list[1] = "END" {
        if input_list[0] = 1 {
            set system_done to true.
        }
    }
    print "V : "+targ_vertvel+ "   " at (5,12).
    print "F : "+targ_forvel+ "   " at (15,12).
    print "S : "+targ_sidevel+ "   " at (25,12).

    print round(ship:verticalspeed,2)+ "   " at (5,13).
    print round(alt:radar,2) at (5,11).

    local velocity_vector is ship:velocity:surface:vec.
    local up_vector is ship:up:vector.
    local fore_vector is vxcl(up_vector,ship:facing:forevector).
    local starboard_vector is vcrs(up_vector, fore_vector).

    // Compute the components
    local up_component is vdot(velocity_vector, up_vector).
    local fore_component is vdot(velocity_vector, fore_vector).
    local sb_component is vdot(velocity_vector, starboard_vector).

    print "Up Component: " + round(up_component,2)+ "   " at (5,16).
    print "Forward Component: " + round(fore_component,2)+ "   " at (5,17).
    print "Starboard Component: " + round(sb_component,2)+ "   " at (5,18).

    print "TGT HDG : " + round(targ_hdg)+"  " at (5,20).
    print "TRU HDG : " + round(compass_hdg())+"  " at (5,21).
    
    set vertpid:setpoint to targ_vertvel.
    set collective to vertpid:update(time:seconds, ship:verticalspeed).

    set forepid:setpoint to targ_forvel.
    set pitch_ang  to -forepid:update(time:seconds, fore_component).

    set sidepid:setpoint to targ_sidevel.
    set side_ang to -sidepid:update(time:seconds, sb_component).

    lock steering to heading(targ_hdg, pitch_ang, side_ang).

    print round(pitch_ang, 1) + "  " at (5,23).
    print round(side_ang, 1) + "  " at (15,23).
    wait 0. 
}

set ship:control:neutralize to true.
// forward velocity // pitch

// side velocity // yaw