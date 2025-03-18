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

function Thrust_off {
    lock throttle to 0.
    lock steering to prograde.
    wait until false.
}