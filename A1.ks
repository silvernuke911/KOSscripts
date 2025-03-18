//Mercury - Atlas Launch Script
lock throttle to 1.
declare runmode is 1.
declare stagepitch is 0.
function SafeStage {
    //do a staging safely
    wait until stage:ready.
    stage.
    wait 0.25.
}
wait 1.
gear on.

wait 3.
safestage().
wait 1.
safestage().
until runmode=0 {
        if runmode=1{
            sas off.
            lock throttle to 1.
            if altitude > 100 {
                lock steering to heading (0,90).
             }
            if verticalSpeed>100 {
            set runmode to 2.
            }
        }
        if runmode=2 {
            lock steering to heading (90,82,-90).
            wait 10.
            set runmode to 3.
        }
        if runmode=3 {
            lock steering to heading (90,progradepitch,-90).
            if ship:altitude>15000 {
                print "stage lmao".
                safestage.
                set stagepitch to (90-vectorAngle(ship:up:forevector,ship:facing:forevector)).
                print "stagepitch "+ stagepitch at (5,30).
                SafeStage().
                lock steering to  heading (90,stagepitch,-90).
                set runmode to 4.
            }
        }
        if runmode=4 {
            lock steering to  heading (90,stagepitch,-90).
            wait 25.
            safestage().
            set runmode to 5.
        }
        if runmode=5{
            lock steering to srfprograde.
            if ship:apoapsis>75000 {
                set steering to heading (90,0).
                lock throttle to 0.5.
            }
            if availableThrust<1 {
                lock throttle to 0.
                unlock throttle.
                wait 10.
                safestage().
                unlock steering.
                sas on.
                set runmode to 0.
            }
        }   
    lock progradepitch to (arctan(verticalSpeed/groundspeed)).
}