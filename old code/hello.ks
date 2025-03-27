function StartUp {
        lock throttle to 0.
        SAS off.
        RCS off.
}

function Countdown {
    PRINT "Counting down:".
    Print "...10".
    Wait 1.
    Print "...9".
    Wait 1.
    Print "...8".
    Wait 1.
    Print "...7".
    Wait 1.
    Print "...6".
    Wait 1.
    Print "...5".
    Wait 1.
    Print "...4".
    Wait 1.
    Print "...3".
    Wait 1.
    Print "...2".
    Wait 1.
    Print "...1".
    Wait 1.
    Print "...0".
    Print "IGNITION".
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
    wait 3.
    lock steering to heading(90,90).
    wait 3.
}

function GravityTurn{
    lock targetPitch to 86.963-1.03287*alt:radar^0.409511.
    set targetDirection to 90.
    lock steering to heading(targetDirection,targetPitch).
}
function AutoStage {
    if not(defined Oldthrust) {
        declare global Oldthrust to ship:availablethrust.
    }
    if ship:availableThrust < (oldthrust-10) {
        Print "Staging".
        SafeStage(). wait 1.
        //hehe
        lock thrust to 1.
        if ship:availableThrust = 0 {
            Autostage().
        }
        //hehe
        declare global oldthrust to ship:availablethrust.
        lock thrust to 1.
    }
}
function thrust_off {
    lock throttle to 0.
    lock steering to prograde.
    wait until false.
}
StartUp ().
Print "Running Countdown".
CountDown().
Print "Running Ignition".
Ignition().
Print "Running Towerclear".
Towerclear().
Print "Waiting for 1000 m".
wait 1.
until verticalSpeed > 100 {
    Print alt:radar.
   Print verticalSpeed.
}
if verticalSpeed > 100. {
    Print "Alt 1000".
    Print "Running GravityTurn".
    GravityTurn().
}
//wait until alt > 1000. 
until apoapsis > 100000 {
    AutoStage().
}
Print "Waiting for Apoapse 100 km".
If apoapsis > 100000 {
    Print "Apoapse 100 km".
    lock throttle to 0.
    lock steering to prograde.
}
If verticalSpeed < 10 {
    Print "Near 0!".
}
until periapsis > 100000 {
     lock throttle to 1.
}
wait until false.
