// // VERTICAL ASCENT DIRECT, SMALL PITCH TO TARGET VECTOR (1 DEGREE)
//     // point to (targ vec - pos_vec) srf hdg

// // WAIT UNTIL 40 KM ISH FOR FIRST STAGE.
// // LAMBERT SOLVE, INITIAL POINT IS BURNOUT POINT, AROUND 40 TO 60 SECOND ISH, 20 MINUTE TOF
// // LAST POINT IS THE TARGET LOCATION (20 MINUTES FROM INITIAL POINT)
// // DO ANOTHER (CORRECTION) AT 80 KM
// // WAIT AND SEE IG GNG

// @lazyGlobal off.
// runpath("0:/lib/maneuver_functions.ks").
// runpath("0:/lib/borders.ks").
// set config:ipu to 2000.

// local function ascent_guidance {
//     local parameter target_altitude is 100_000.
//     local parameter pitchover_angle is 7.5.


//     // BEGIN STARTUP SEQUENCE 
//     local timer is time:seconds + 1.
//     local time0 is time:seconds + 1.
//     lock met to time:seconds - time0.
//     local handlers is lexicon().
//     local staged is False.
//     local apoapsis_fine_tuned is false.
//     local pitch_start_time is 0.
//     local pitch_rate is 1. // deg /sec
//     local tset is pidLoop(1,0.1,0,0.25,1).
//     sas off.
//     rcs off.
//     local ignition is false.
//     clearScreen.
//     // END STARTUP SEQUENCE'
    
//     handlers:add (
//         "ignition",
//         {
//             if not ignition {
//                 lock throttle to 1.
//                 stage.
//                 lock steering to heading(90,90,-90).
//                 set ignition to true.
//             }
//             if time:seconds > timer {
//                 return "liftoff".
//             }
//             return "ignition".
//         }
//     ).
//      handlers:add (
//         "liftoff",
//         {
//             stage.
//             set time0 to time:seconds.
//             return "vertical ascent".
//         }
//     ).
//     handlers:add (
//         "vertical ascent",
//         {
//             if ship:verticalSpeed > 100 {
//                 set pitch_start_time to time:seconds.
//                 lock steering to heading(90,90-min(pitchover_angle , pitch_rate * (time:seconds - pitch_start_time)),-90).
//                 return "pitching".
//             }
//             return "vertical ascent".
//         }
//     ).
//     handlers:add (
//         "pitching",
//         {
//             if abs(vang(ship:facing:vector, ship:up:vector) - pitchover_angle) < 0.25 {
//                 lock steering to heading(90,90-pitchover_angle,-90).
//                 return "holding pitch".
//             }
//         return "pitching".
//         }
//     ).
//     handlers:add (
//         "holding pitch",
//         {
//             if vang(ship:facing:vector, ship:srfPrograde:vector) < 0.25 {
//                 lock steering to heading (
//                     90,
//                     90 - vang(ship:up:vector,ship:srfPrograde:vector),
//                     -90
//                 ).
//                 return "gravity turn".
//             }
//             return "holding pitch".
//         } 
//     ).
//     handlers:add (
//         "gravity turn",
//         {
//             if (ship:availablethrust = 0) and not staged {
//                 return "booster staging".
//             } 
//             else if ship:apoapsis > (target_altitude - 50) {
//                 return "ascent engine cutoff".
//             }
//             return "gravity turn".
//         }
//     ).
//     handlers:add (
//         "booster staging",
//         {
//             stage.
//             set staged to True.
//             set tset:setpoint to 90.
//             lock throttle to tset:update(time:seconds,eta:apoapsis).
//             return "gravity turn".
//         }
//     ).
//     handlers:add (
//         "ascent engine cutoff",
//         {
//             lock throttle to 0.
//             rcs on.
//             return "fine tune apoapsis 1".
//         }
//     ).
//     handlers:add (
//         "fine tune apoapsis 1",
//         {   
//             if apoapsis_fine_tuned and (ship:altitude > body:atm:height) {
//                 rcs off.
//                 return "coasting to apoapsis".
//             }
//             if time:seconds > timer {
//                 if obt:apoapsis > target_altitude {
//                     set ship:control:fore to -1.
//                 } else {
//                     set ship:control:fore to +1.
//                 }
//                 return "fine tune apoapsis 2".
//             }
//             return "fine tune apoapsis 1".
//         }
//     ).
//     handlers:add (
//         "fine tune apoapsis 2",
//         {
//             if abs(obt:apoapsis - target_altitude) < 10 {
//                 set ship:control:fore to 0.
//                 set apoapsis_fine_tuned to true.
//                 return "fine tune apoapsis 1".
//             }
//             return "fine tune apoapsis 2".
//         }
//     ).
//     handlers:add (
//         "coasting to apoapsis",
//         {
//             set timer to time:seconds + 2.
//             return "plotting circularization".
//         }
//     ).
//     handlers:add (
//         "plotting circularization",
//         {
//             if time:seconds > timer {
//                 create_node(
//                     circularize("at apoapsis")
//                 ).
//                 return "execute burn".
//             }
//             return "plotting circularization".
//         }
//     ).
//     handlers:add (
//         "execute burn",
//         {
//             execute_node(False).
//             return "in orbit".
//         }
//     ).
//     // TELEMETRY
//     local function screen_output {
//         print "MET   : " + round(met, 2) at (5,5).
//         print "ALT   : " + round(ship:altitude) at (5,7).
//         print "APO   : " + round(obt:apoapsis) at (5,9).
//     }
//     //============================================
//     // GUIDANCE LOOP
//     //============================================
//     local current_state is "ignition".
//     until current_state = "in orbit" {
//         local handler is handlers[current_state].
//         set current_state to handler().
//         screen_output().
//         wait 0.
//     }
// }

// ascent_guidance().
// ag1 on.
local runmode is "ignition".
local stage1 is false.
local stage2 is false.
local pitch_start_time is 0.
local pitchover_angle is 45.
local pitch_rate is 1.

// MAINTAIN 45 DEGREE PROGRADE VECTOR
until runmode = "done" {
    if runmode = "ignition" {
        sas off.
        rcs off.
        lock throttle to 1.
        stage.
        wait 1.
        stage.
        lock steering to heading(90,90).
        set runmode to "vertical ascent".
    }
    if runmode = "vertical ascent" {
        if ship:verticalSpeed > 100 {
            set pitch_start_time to time:seconds.
            lock steering to heading(90,90-min(pitchover_angle, pitch_rate * (time:seconds - pitch_start_time))).
            set runmode to "pitching".
        }
    }
    if runmode = "pitching" {
        if abs(vang(ship:facing:vector, ship:up:vector) - pitchover_angle) < 0.25 {
            lock steering to heading(90,90-pitchover_angle).
            set runmode to "maintaining pitch".
        }
    }
    if runmode = "maintaining pitch"{
        if (availableThrust = 0) and (not stage1) {
            set stage1 to True.
            stage.
        }
        if (availableThrust = 0) and (stage1) and (not stage2) {
            set stage2 to True.
            stage.
            ag2 on.
            set runmode to "done".
        }
    }
}