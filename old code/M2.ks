//M2
//CODE FOR CIRUCLARUSATION OF SATURN

function circularization_math {
    //calculates needed delta v
        set ap to (ship:apoapsis+600000).
        set pe to (ship:periapsis+600000).
        set mu_k to 3.5316000*(10^12).
        set mu_m to 6.5138398*(10^10).
        set mu_mnm to 1.7658000*(10^9).
        set v_c to sqrt((mu_k)/(ap)).
        set v_ap to sqrt((((2*mu_k)/(ap+pe)))*(pe/ap)).
        set dV to (v_c)-(v_ap).
        set dV_half to dV/2.
        set mass1 to ship:mass*1000.
        set thrust1 to ship:maxThrust*1000.
        set g_0 to 9.80665.
        set isp to 330.
        set mf to (mass1/(constant():e^(dV/(isp*g_0)))).
        set mf_half to (mass1/(constant():e^(dV_half/(isp*g_0)))).
        set m_dot to thrust1/(isp*g_0).
        set t_total to (mass1-mf)/m_dot.
        set t_half to (mass1-mf_half)/m_dot.
        set thrust2 to 0.
        set accel to 0.
}
function debug {
    //lets you see if the values are correct
    print "apoapsis " + ap at (5,12).
    print "periapsis " + pe at (5,13).
    print "v_c " + v_c at (5,14).
    print "v_ap " + v_ap at (5,15).
    print "dV " + dV at (5,16).
    print "mass_i " + mass1 at (5,17).
    print "thrust " + thrust1 at (5,18).
    print "m_f " + mf at (5,19).
    print "mf/2 " + mf_half at (5,20).
    print "m_dot " + m_dot at (5,21).
    print "t_total " + t_total at (5,22).
    print "t_half " + t_half at (5,23).
    print "dV_half " + dV_half at (5,24).
}
function mnvr_node {
    set circnode to node(time:seconds+eta:apoapsis,0,0,dV).
    add circnode.
    lock mnvdir to circnode:deltav.
}
clearscreen.
circularization_math().
debug().
mnvr_node().
set runmode to 1.
set dv0 to circnode:deltav.
sas off.
until runmode = 0 {
    if runmode = 1 {
        rcs on.
        lock steering to mnvdir.
        if  vang(mnvdir,ship:facing:vector) < 0.25 {
            set warp to 3.
            set runmode to 2.
        }
    }
    if runmode =2 {
        lock steering to mnvdir.
        if circnode:eta < (t_half + 30) {
            set warp to 0.
        }
        if circnode:eta < t_half {
            set runmode to 3.
        }
    }
    if runmode = 3 {
        if circnode:deltav:mag > accel {
            lock throttle to 1.
        }
        if circnode:deltav:mag < accel {
            lock throttle to thrust2.
        }
        if vdot(dV0,circnode:deltav)<0 {
            lock throttle to 0.
            set runmode to 4.
        }
        if circnode:deltav:mag < 0.1{
            lock throttle to 0.
            set runmode to 4.
        } 
    }
    if runmode = 4 {
        unlock throttle.
        unlock steering.
        sas on.
        remove circnode.
        set runmode to 0.
    }
    if hasnode {
        print "mass" + ship:mass at (5,7).
        print "thrust" + ship:availablethrust at (5,8).
        print "accel " + accel at (5,10).
        print "thrust2 " + thrust2 at (5,9).
        lock accel to ((throttle)*ship:availableThrust)/(ship:mass).
        lock thrust2 to ((ship:mass*1000)*(circnode:deltav:mag)/(thrust1)).
    }
}





