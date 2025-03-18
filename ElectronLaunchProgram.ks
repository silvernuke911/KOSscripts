//Launch Script Experiment

function mainlaunch {
    StartUp().
    //CountDown().
    //Ignition().
    //GravityTurn().
   // until apoapsis > 100000 {
    //    AutoStage().
   // }
    //Orbit().
    //ShutDown().
}.

function StartUp {
        lock throttle to 0.
        SAS off.
        RCS off.
}

function CountDown {
    PRINT "Counting down:".
    FROM {local countdown is 10.} UNTIL countdown = 0 STEP {SET countdown to countdown - 1.} DO {
        PRINT "..." + countdown.
        WAIT 1. // pauses the script here for 1 second.
    }
}

function Ignition {
    lock throttle to 1.
    SafeStage().
}

function SafeStage {
    wait until stage:ready.
    stage.
}

function Towerclear{
    lock steering to up.
}

function GravityTurn{
    lock targetPitch to 86.963-1.03287+alt:radar^0.409511.
    set targetDirection to 90.
    lock steering to heading(targetDirection,targetPitch).
}
function AutoStage {
    if not defined (Oldthrust) {
        declare global Oldthrust to ship:availablethrust.
    }
    if ship:availableThrust < (oldthrust-10) {
        SafeStage(). wait 1.
        set Oldthrust to ship:availablethrust.
    }
}

function Shut_Down {
    lock throttle to 0.
    lock steering to prograde.
    wait until false.
}
function Orbit {
    print "it ran".
}

main().