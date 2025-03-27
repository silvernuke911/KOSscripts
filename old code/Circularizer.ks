//circularizer (only at apoapsis, we can include periapsis later.

declare ap is ship:apoapsis.
declare pe is ship:periapsis.
declare mu_k is 3.5316000*(10^12).
declare runmode is 1.
declare n_run is 0.
declare targetapoapsis is ship:apoapsis.
declare targetperiapsis is ship:apoapsis.
declare burn_time is 0.
declare dV is 0.
declare t_total is 0.
declare t_half is 0.
declare isp is 0.
function circularization_math {
    //calculates needed delta v
        set ap to (ship:apoapsis+600000).
        set pe to (ship:periapsis+600000).
        set mu_k to 3.5316000*(10^12).
        set v_c to sqrt((mu_k)/(ap)).
        set v_ap to sqrt((((2*mu_k)/(ap+pe)))*(pe/ap)).
        set dV to (v_c)-(v_ap).
        set mass1 to ship:mass*1000.
        set thrust1 to ship:maxThrust*1000.
        set g_0 to 9.80665.
        set mf to (mass1/constant():e^(dV/(isp*g_0))).
        set m_dot to thrust1/(isp*g_0).
        set t_total to (mass1-mf)/m_dot.
        set t_half to (t_total/2).
}
function ISP_calc {
    //calculates engine isp
    list engines in myEngines.
        for en in myengines {
                if en:ignition and not en:flameout  {
                        set isp to isp + (en:isp*(en:maxthrust/ship:maxthrust)).
                }
        }
}
function orbit_insertion  {
    //does orbit insetion burn
        if (eta:apoapsis < t_half) {
            //temporary fix
            unlock steering.
            sas on.
            //
            set flight_status to "BURNING               ".
            lock throttle to 1.
        }
        if ship:periapsis > (targetPeriapsis-5000) {
            set flight_status to "EASING BURN".
            //temporary fix
            unlock steering.
            sas on.
            //
            lock throttle to (1-ship:periapsis/((2*targetPeriapsis))).
        }
        if (ship:periapsis > targetPeriapsis) or (ship:periapsis > targetPeriapsis*0.9999) {
            lock throttle to 0.
            sas on.
        }
}
function debugger {
    print "DEBUG TOOL" at (5,2).
    print "---------------------------------------" at (5,3).
    print "periapse       " + round(ship:periapsis,2) + "      " at (5,5).
    print "apoapse        " + round(ship:apoapsis,2) + "      "  at (5,6).
    print "targ ap        " + round(targetapoapsis,2) + "      "  at (5,7). 
    print "targ pe        " + round(targetperiapsis,2) + "      "  at (5,8).
    print "burn time      " + round(t_total,2) + "      "  at (5,9).
    print "dv             " + round(dV,2) + "      "  at (5,10).
    print "half burn time " + round(t_half,2) + "      "  at (5,11).
    print "eta ap         " + round(eta:apoapsis,2) + "      "  at (5,12).
}
clearscreen.

until runmode = 0 {
    if eta:apoapsis > 90 {
        set warp to 4.
    } else if (eta:apoapsis < 90) and (eta:apoapsis > 30) {
        set warp to 2.
    } else if eta:apoapsis < 30 {
        set warp to 0.
        if n_run = 0 {
            sas off.
            ISP_calc().
            circularization_math().
            set mynode to node (time:seconds+eta:apoapsis,0,0,dV).
            add mynode.
            lock mnvdir to mynode:deltav.
            lock steering to mnvdir.
            set n_run to 1.
        }
        orbit_insertion ().
    } else if ship:periapsis > (targetPeriapsis*0.999) {
        remove mynode.
        set runmode to 10.
    }
    debugger().
    //     if n_run = 0 {
    //         ISP_calc().
    //         circularization_math().
    //         set mynode to node (time:seconds+eta:apoapsis,0,0,dV).
    //         add mynode.
    //         lock mnvdir to mynode:deltav.
    //         lock steering to mnvdir.
    //         set n_run to 1.
    //     }
    //     orbit_insertion ().
    // } else if ship:periapsis > (targetPeriapsis*0.999) {
    //         remove mynode.
    //         set runmode to 10.
    // }
}
remove mynode.


