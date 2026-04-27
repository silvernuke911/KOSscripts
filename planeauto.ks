clearScreen.

// throttle control
sas off.
set ship:control:neutralize to true.
local target_velocity is 300.
local target_alt is 1000.
local target_upv is 0.
local tset is pidLoop(0.05,0.01,0.005,0,1).
local vlim to 10.
local altpid is pidloop(0.1,0.005,0,-vlim,vlim).
local pitchpid is pidLoop(0.05,0.1,0.00,-1,1).
local rollpid is pidLoop(0.005,0.001,0.0,-1,1).
local yawpid is pidLoop(0.05, 0.1, 0.0, -1,1).
lock throttle to tset:update(time:seconds,ship:groundspeed)..
set tset:setpoint to target_velocity.
set pitchpid:setpoint to target_upv.
set rollpid:setpoint to 0.
set yawpid:setpoint to 0.
set altpid:setpoint to target_alt.

function roll_angle {
    local rang is vang(ship:up:vector,ship:facing:topvector).
    local str is ship:facing:starvector.
    if vdot(ship:up:vector, str) < 0 {
        return rang.
    } else {
        return - rang.
    }
}
until false {
    set pitchpid:setpoint to altpid:update(time:seconds, ship:altitude).
    set ship:control:pitch to pitchpid:update(time:seconds,ship:verticalspeed).
    set ship:control:roll to rollpid:update(time:seconds,roll_angle()).
    set ship:control:yaw to yawpid:update(time:seconds,ship:heading).
    print round(ship:groundspeed,1) at (5,2).
    print round(ship:altitude,1) at (5,4).
    print round(ship:control:pitch) at (5,5).
    print ship:control:neutral at (5,6).
    wait 0.
}

set ship:control:neutralize to true.