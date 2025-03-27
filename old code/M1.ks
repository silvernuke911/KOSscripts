sas on.
set throttle to 1.
declare runmode is 1.
declare stagepitch is 0.
set stage to 1.
function SafeStage {
    //do a staging safely
    wait until stage:ready.
    stage.
    wait 0.25.
}
wait 15.
safestage().
wait 2.
safestage().
until runmode=0 {
    if runmode=1{
        sas off.
        lock throttle to 1.
        if altitude > 400 {
            lock steering to heading (90,90).
        }
        if verticalSpeed>100 {
            set runmode to 2.
        }
    }
    if runmode=2 {
        lock steering to heading (90,78).
        wait 10.
        set runmode to 3.
    }
    if runmode=3 {
        lock steering to ship:srfprograde.
        if availablethrust <1 {
            set stagepitch to (90-vectorAngle(ship:up:forevector,ship:facing:forevector)).
            print "stagepitch "+ stagepitch at (5,30).
            SafeStage().
            lock steering to  heading (90,stagepitch).
            wait 4.
            SafeStage().
            wait 1.
            SafeStage().
            set runmode to 4.
        }
    }
    if runmode=4 {
        lock steering to  heading (90,stagepitch).
        wait 25.
        safestage().
        set runmode to 5.
    }
    if runmode=5 {
        lock steering to ship:srfprograde.
        if apoapsis > 100000 {
            lock steering to ship:srfprograde.
            set throttle to 0.
            wait 5.
            safestage().
            set runmode to 6.
        }
    }
    if runmode=6 {
        lock steering to ship:prograde.
        wait 1.
        unlock steering.
        sas on.
        set runmode to 0.
    }
}

