//Saturn Circularization Burn
function P2_variables {
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
    declare isp is 330.
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
        //rewrite this one
        set t_total to (mass1-mf)/m_dot.
        set t_half to (t_total/2).
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
P2_variables().
circularization_math().

print dV.