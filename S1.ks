//Soyuz/R7 Launch Script

if ship:altitude < 70000 {
    set S to 1.
} else if ship:altitude > 70000 {
    set S to 3.
}

until S=0 {
    if S=1 {
        set runmode to 1.
        gear on.
        safestage().
        lock throttle to 1.
        set stagepitch to 0.
        set ThrustInitial to 0.
        set fairings to 1.
        wait 20.
        safestage().
        wait 2.
        SafeStage().
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
                lock steering to heading (90,80,-90).
                wait 10.
                set ThrustInitial to availableThrust.
                set runmode to 3.
            }
            if runmode=3 {
                lock steering to heading (90,arctan(verticalSpeed/groundspeed),-90).
                if altitude>8000 {
                    SafeStage().
                    set runmode to 4.
                }
            }
            if runmode=4 {
                lock steering to heading (90,arctan(verticalSpeed/groundspeed),-90).
                    if availablethrust < ThrustInitial {
                        SafeStage().
                        set stagepitch to (90-vectorAngle(ship:up:forevector,ship:facing:forevector)).
                        print "stagepitch "+ stagepitch at (5,30).
                        lock steering to  heading (90,stagepitch).
                        set runmode to 5.
                }
            }
            if runmode=5 {
                lock steering to  heading (90,stagepitch,-90).
                wait 10.
                set runmode to 6.
            }
            if runmode=6 {
                lock steering to heading (90,arctan(verticalSpeed/groundspeed),-90).
                if altitude > 38000 {
                    lock warp to 0.
                }
                if fairings = 1 and altitude>40000{
                    safestage().
                    set fairings to 0.
                }
                if availableThrust<5 {
                    safestage().
                    safestage().
                    wait 3.
                    safestage().
                    set runmode to 7.
                }
            }
            if runmode=7 {
                lock steering to heading (90,arctan(verticalSpeed/groundspeed),-90).
                if ship:apoapsis > 150000 {
                    print "we in space yey".
                    lock throttle to 0.
                    set runmode to 0.
                }
            }     
        }
        Set S to 2.
    }
    if S=2 {
        //Orbit Insertion
        clearscreen.
        circularization_math().
        debug().
        mnvr_node().
        set runmode to 1.
        set dv0 to circnode:deltav.
        set accel1 to 6.
        sas off.
        until runmode = 0 {
            if runmode = 1 {
                rcs on.
                lock steering to mnvdir.
                if  vang(mnvdir,ship:facing:vector) < 0.25 {
                    set warp to 3.
                }
                if circnode:eta < (t_half + 30) {
                    set warp to 0.
                    set runmode to 2.
                }
            }
            if runmode =2 {
                lock steering to mnvdir.
                if circnode:eta < t_half {
                    lock throttle to 1.
                    if circnode:deltav:mag < accel {
                        set accel1 to accel.
                        set runmode to 3.
                    }
                }
            }
            if runmode = 3 {
                lock throttle to thrust2.
                if thrust2 < 0.2 {
                    lock throttle to 0.2.
                }
                if circnode:deltav:mag < 0.1{
                    lock throttle to 0.
                    set runmode to 4.
                } 
                if vdot(dV0,circnode:deltav)<0 {
                    lock throttle to 0.
                    set runmode to 4.
                }

            }
            if runmode = 4 {
                lock steering to prograde.
                unlock throttle.
                wait until  (vang(ship:prograde:vector,ship:facing:vector) < (0.25)).
                unlock steering.
                sas on.  
                remove circnode.
                wait 3.
                safestage().
                ag1 on.
                ag3 on.
                set runmode to 0.
            }
            if hasnode {
                print "accel " + accel at (5,10).
                print "thrust2 " + thrust2 at (5,9).
                lock accel to ((throttle)*ship:availableThrust)/(ship:mass).
                lock thrust2 to ((ship:mass*1000)*(circnode:deltav:mag)/thrust1).
            }
        }
        Set S to 0.
    }
    if S=3 {
        //Deorbit Program
        //ToBeAdded
    }
}

function SafeStage {
    //do a staging safely
    wait until stage:ready.
    stage.
    wait 0.1.
}
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
        if thrust1=0 {
            set thrust1 to 0.01.
        }
        set g_0 to 9.80665.
        set isp to 303.7325039.
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
function DeorbitMnvr {
    set longitude_target to -150.
    set longitude_burn to 180+longitude_target.
    if longitude_burn > 180 {
        set longitude_burn to 360-longitude_burn.
    }
}