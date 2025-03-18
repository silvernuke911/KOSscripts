//a program that executes maneuver nodes.


set tval to 0.
declare dv is 0.
set nd to nextNode.
set np to nd:deltav.
lock throttle to tval.
declare runmode is 1.
set dv to nd:deltaV.
declare t_total is 0.
function debug {
    print "debug" at (5,2).
    print "-----------------------".
    print "throttle " + round(tval,2) + "     " at (5,3).
    print "dV" + round(nd:deltav:mag,2).
    print "burn tume".

}
until runmode = 0 {
    lock steering to np.
}