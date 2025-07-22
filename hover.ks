@lazyGlobal off.          //                        ||
set config:ipu to 2000.   //   

stage.

// wait 7.5.
local targ_alt is 25.
print("setting pid structure").

local kp to 0.02.
local ki to 0.05.
local kd to 0.02.
local min_set to 0.
local max_set to 1.
declare hoverpid to pidLoop(kp,ki,kd,min_set,max_set).

local tset is 0.
lock throttle to tset.

local start_time to time:seconds.
set hoverpid:setpoint to targ_alt.
print("launch").
until (time:seconds - start_time) > 60 {
    print ( "alt : " + alt:radar) at (5,10).
    set tset to hoverpid:update(time:seconds, alt:radar).
}
set start_time to time:seconds.
set hoverpid:setpoint to 1.
until (time:seconds - start_time) > 10 {
    set tset to hoverpid:update(time:seconds, alt:radar).
}


// target altitude

// target vertical velocity

// target horizontal velocity