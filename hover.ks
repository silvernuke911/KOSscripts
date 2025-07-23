@lazyGlobal off.          //                        ||
set config:ipu to 2000.   //
runpath("0:/lib/maneuver_functions.ks").
clearScreen.

set terminal:width to 50.
set terminal:height to 15.

stage.
lock steering to heading(90,90,-90).
// wait 7.5.

// print("setting pid structure").

// how to set pid
// local kp to 0.2.
// local ki to 0.042. good for vertical
// local kd to 0.3.

// ===========================
// HOVER HOVER HOVER HOVER 
// ===========================
// local targ_alt is 50.
// local kp to 0.25.
// local ki to 0.07.
// local kd to 0.35. //TS GOOD

// local kp to 0.5.
// local ki to 0.15.
// local kd to 0.7.     //TS ALSO GOOD

// local min_set to 0.
// local max_set to 1.
// local hoverpid to pidLoop(kp,ki,kd,min_set,max_set).

// local tset is 0.
// lock throttle to tset.

// local start_time to time:seconds.
// set hoverpid:setpoint to targ_alt.
// print("launch").
// if exists("hoverks.csv") { deletePath("hoverks.csv").}
// log "time,alt,setpoint" to "hoverks.csv".
// lock timer to (time:seconds - start_time).
// until  timer > 30 {
//     print ("T : " + round(timer,1)) at (5,5).
//     print ( "alt : " + alt:radar) at (5,7).
//     if timer > 15 {
//         set targ_alt to 25.
//         set hoverpid:setpoint to targ_alt.
//     }
//     set tset to hoverpid:update(time:seconds, alt:radar).
//     log timer +","+alt:radar+","+targ_alt to "hoverks.csv".
//     wait 0.01.
// }
// // set start_time to time:seconds.
// // set hoverpid:setpoint to 1.
// until alt:radar < 0.7 {
//     set tset to (1/twr() - (ship:verticalSpeed + max(0.5,alt:radar-2)))/(twr()).
// }

// ================================
// VERTICAL SPEED VERTICAL SPEED
// ================================
local kp to 0.4.
local ki to 1.9.    
local kd to 0.0.   

local min_set to 0.
local max_set to 1.
local vertpid to pidLoop(kp,ki,kd,min_set,max_set).

local tset is 0.
local targ_vel to 2.5.
lock throttle to tset.

local start_time to time:seconds.
set vertpid:setpoint to targ_vel.
print("launch").
local filename to "hvertpid.csv".
if exists(filename) { deletePath(filename).}
log "time,alt,setpoint" to filename.
lock timer to (time:seconds - start_time).
until  timer > 20 {
    print ("T : " + round(timer,1)) at (5,5).
    print ( "vspd : " + ship:verticalspeed) at (5,7).
    if timer > 10 {
        set targ_vel to 0.
        set vertpid:setpoint to targ_vel.
    }
    set tset to vertpid:update(time:seconds, ship:verticalspeed).
    log timer +","+ship:verticalSpeed+","+targ_vel to filename.
    wait 0.01.
}
// set start_time to time:seconds.
// set hoverpid:setpoint to 1.

until alt:radar < 0.8 {
    set targ_vel to - alt:radar.
    if alt:radar < 2 {
        set targ_vel to -0.5.
    }
    set vertpid:setpoint to targ_vel.
    set tset to vertpid:update(time:seconds, ship:verticalspeed).
    log timer +","+ship:verticalSpeed+","+targ_vel to filename.
    wait 0.
}


// target vertical velocity

// target horizontal velocity