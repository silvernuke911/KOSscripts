//==================================================||
//==================================================||
//            MANEUVER FUNCTIONS LIBRARY            ||
//==================================================||
//==================================================||
// cc. Vercil Juan KOS.                             ||
//--------------------------------------------------||
// Collection of functions and other implements for ||
// orbital mechanics and navigation purposes.       ||
//==================================================||
//                                                  ||
//--------------------------------------------------||
@lazyGlobal off.          //                        ||
set config:ipu to 1500.   //                        ||               
//--------------------------------------------------||
//               BURN TIME FUNCTIONS                ||
//--------------------------------------------------||
function ship_isp {
    local engineList to list().
    list engines in engineList.
    local total_thrust to 0.
    local weighted_isp to 0.
    for engine in engineList {
        if engine:availablethrust > 0 and engine:isp > 0 {
            set total_thrust to 
                total_thrust + 
                engine:availablethrust.
            set weighted_isp to 
                weighted_isp + (
                    engine:availablethrust * 
                    engine:isp
                ).
        }
    }
    
    if total_thrust > 0 {
        set weighted_isp to weighted_isp/total_thrust.
    } else {
        return 0.
    }
    return weighted_isp.
}

function total_burn_time {
    local parameter mnv.
    local deltav is  mnv:deltav:mag.
    local Isp is ship_isp().
    if isp = 0 {
        return 0.
    }
    local ve is Isp *constant:g0.
    local mdot is ship:maxThrust/ve.
    local m0 is ship:mass.
    local mf is m0*constant:e^(-deltav/ ve).
    local dm is m0 - mf.
    local t is dm / mdot.
    return t.
}

function half_burn_time {
    local parameter mnv.
    local deltav is  mnv:deltav:mag.
    local deltav_2 is deltav/2.
    local Isp is ship_isp().
    if isp = 0 {
        return 0.
    }
    local ve is Isp * constant:g0.
    local mdot is ship:maxThrust/ve.
    local m0 is ship:mass.
    local mf is m0*constant:e^(-deltav_2/ ve).
    local dm is m0 - mf.
    local t is dm / mdot.
    return t.    
}
//--------------------------------------------------||
//                   SHIP SYSTEMS                   ||
//--------------------------------------------------||
function twr {
    if ship:availablethrust = 0 {
        return 0.
    }
    local g0 is body:mu / (body:radius + ship:altitude).
    local ship_weight is ship:mass * g0.
    local twr_val is ship:availablethrust / ship_weight.
    return twr_val.
}

//--------------------------------------------------||
//               ORBITAL CALCULATION                ||
//--------------------------------------------------||
function orbital_velocity_circular {
    local parameter altitude_.
    local r__ is body:radius + altitude_.
    return sqrt(body:mu/r__).
}
function vis_viva_equation {
    local parameter altitude_.
    local parameter a_.
    local r_ is body:radius + altitude_.
    return sqrt (body:mu * (2/r_ - 1/a_)).
}
function calculate_semimajor_axis {
    local parameter periapsis__.
    local parameter apoapsis___.
    return body:radius + (periapsis__+apoapsis___)/2.
}
//--------------------------------------------------||
//                  MANEUVER NODES                  ||
//--------------------------------------------------||
function create_node {
    local parameter mnv_node.
    local eta____ is mnv_node[0]+time:seconds.
    local radial_ is mnv_node[1].
    local normal_ is mnv_node[2].
    local prograd is mnv_node[3].
    if eta____ < 0 {
        if radial_=0 and normal_ = 0 and prograd = 0 {
            print ( "WRONG MNV NODE").
        }
    }
    local maneuver_node to node(
        eta____,
        radial_,
        normal_,
        prograd
    ).
    add maneuver_node.
}

function raw_node {
    local parameter eta____.
    local parameter radial_.
    local parameter normal_.
    local parameter prograd.
    local mnv_nd is list(
        eta____,
        radial_,
        normal_,
        prograd
    ).
    return mnv_nd.
}

function null_mnv {
    return list(-1,0,0,0).
}
function circularize {
    local parameter mode.
    if mode = "at periapsis" {
        local periapsis_dV is 
            orbital_velocity_circular(ship:periapsis) - 
            vis_viva_equation(
                ship:periapsis, 
                ship:orbit:semimajoraxis
            ).
        return list(eta:periapsis,0,0,periapsis_dV).
    }
    if mode = "at apoapsis" {
        local apoapsis_dv is
            orbital_velocity_circular(ship:apoapsis) - 
            vis_viva_equation(
                ship:apoapsis, 
                ship:orbit:semimajoraxis
            ).
        return list(eta:apoapsis,0,0,apoapsis_dV).
    }
    if mode = "at altitude" {

    }
    if mode = "after fixed time" {

    }
    else {
        return null_mnv().
    }
}

function change_eccentricity {
    local parameter mode.
    if mode = "at periapsis"{

    }
    if mode = "at apoapsis" {

    }
    if mode = "after fixed time"{

    }
    if mode = "at an altitude" {

    }
    else {
        return null_mnv().
    }
}
function change_apoapsis {
    local parameter target_apoapsis.
    local parameter mode.
    if mode = "at next periapsis" {
        local periapsis_dV is ( 
            vis_viva_equation(
                target_apoapsis, 
                calculate_semimajor_axis(
                    target_apoapsis, 
                    ship:periapsis)) - 
            vis_viva_equation(
                ship:apoapsis,
                ship:orbit:semimajoraxis
            )
        ).
        return list(
            eta:periapsis, 
            0,
            0, 
            periapsis_dV
        ).
    }
    if mode = "at next apoapsis" {

    }
    if mode = "after a fixed time" {

    }
    if mode = "at equatorial DN" {

    }
    if mode = "at equatorial AN" {

    }
    else {
        return null_mnv().
    }
}

function change_periapsis {
    local parameter target_periapsis.
    local parameter mode.

    if mode = "at next periapsis" {

    }
    if mode = "at next apoapsis" {
        local apoapsis_dV is ( 
            vis_viva_equation(
                target_periapsis, 
                calculate_semimajor_axis(
                    target_periapsis, 
                    ship:apoapsis)) - 
            vis_viva_equation(
                ship:periapsis,
                ship:orbit:semimajoraxis
            )
        ).
        return list(
            eta:periapsis,
            0,
            0, 
            apoapsis_dV
        ).
    }
    if mode = "after a fixed time" {

    }
    if mode = "at equatorial DN" {

    }
    if mode = "at equatorial AN" {
        
    }
    else {
        return null_mnv().
    }
}

function change_inclination {
    local parameter target_inclination.
    local parameter mode.
    if mode = "at cheapeast node" {

    }
    if mode = "at nearest node" {

    }
    if mode = "at AN" {
         
    }
    if mode = "at DN" {

    }
    if mode = "after fixed time" {

    }
    else {
        return null_mnv().
    }
}

function change_longitude_of_ascending_node {

}

function change_pe_and_ap {
    local parameter mode.
    if mode = "at expected time" {

    }
    if mode = "at an altitude" {

    }
    else {
        return null_mnv().
    }
}

function return_from_a_moon {
    local parameter target_periapsis.
} 

function change_semi_major_axis {
    local parameter target_smja.
    local parameter mode.
    if mode = "at periapsis" {

    }
    if mode = "at apoapsis" {

    }
    if mode = "at an altitude" {

    }
    if mode = "after fixed time" {

    }
    else {
        return null_mnv().
    } 

}

function change_resonant_orbit {
    local parameter target_resonance.
    local parameter mode.
    if mode = "at periapsis" {

    }
    if mode = "at apoasis" {

    }
    if mode = "after fixed time" {

    }
    if mode = "at altitude" {

    }
}
//--------------------------------------------------||
//                 RCS CORRECTIONS                  ||
//--------------------------------------------------||
function rcs_orbit_corrector {

}

//--------------------------------------------------||
//                   EXECUTE NODE                   ||
//--------------------------------------------------||
function execute_node {
    local parameter sas_on is true.
    local parameter warp_to_node is true.
    local mnv_node to nextNode.
    if ship:availableThrust = 0 {
        stage.
    }
    if sas_on {
        unlock steering.
        sas on.
        set sasMode to "MANEUVER".
    }
    if not sas_on {
        sas off.
        lock steering to mnv_node:deltav:vec.
    }
    local init_dv to mnv_node:deltav.
    local tset to 0.
    lock throttle to tset.
    local burn_done to false.
    local runmode is "turning to mnv".
    until runmode = "burn done" {
        if runmode = "turning to mnv" {
            if vang(
                ship:facing:vector, 
                mnv_node:deltav:vec
            ) < 0.5. {
                set runmode to "warping".
            }
        }
        if runmode = "warping" {
            if warp_to_node {
                // warp here 10s before halfburntime.
                set runmode to "waiting for node".
            }
            else {
                set runmode to "waiting for node".
            }
        }
        if runmode = "waiting for node" {
            if mnv_node:eta <= half_burn_time(mnv_node) {

                set runmode to "execute burn".
            }
        }
        if runmode = "execute burn" {
            until burn_done {
                local max_acc to ship:maxthrust/ship:mass.
                set tset to min(
                    mnv_node:deltav:mag/max_acc,
                    1
                ).
                if vDot(init_dv,mnv_node:deltav) <0 {
                    lock throttle to 0.
                    break.
                }
                if mnv_node:deltav:mag < 0.1 {
                    wait until vDot(
                        init_dv, 
                        mnv_node:deltav
                    ) < 0.5.
                    lock throttle to 0.
                    set burn_done to true.
                }
            }
            set runmode to "post burn".
        }
        if runmode = "post burn" {
            if sas_on {
                set sasMode to "STABILITYASSIST".
            } else {
                unlock steering.
                sas on.
            }
            set runmode to "remove mnv".
        }
        if runmode = "remove mnv" {
            remove mnv_node.
            set runmode to "burn done".
        }
    }
    return.
}
//--------------------------------------------------||
//                    NAVIGATION                    ||
//--------------------------------------------------||
function compass_hdg {
    local up_vector is ship:up:vector.
    local north_vector is ship:north:vector.
    local east_vector is vcrs(up_vector, north_vector).      
    local facing_vector is ship:facing:forevector.
    local projV is vxcl(up_vector, facing_vector). 
    local angle is vang(north_vector, projV).
    if vdot(projV, east_vector) < 0 {
        set angle to 360 - angle.
    }
    return angle.
}
function vectorHeading{
    local parameter V.
    set V to V:normalized.
    local north_v is ship:north:vector:normalized.
    local hdg is vang(north_v, V).
    local sgn is vCrs(north_v, V):mag.
    if sgn < 0 {
        return 360 - hdg.
    }
    return hdg.
}
//--------------------------------------------------||
//                  WARP FUNCTIONS                  ||
//--------------------------------------------------||

//--------------------------------------------------||
//                  FLIGHT VECTORS                  ||
//--------------------------------------------------||
function orbital_basis_vectors {
    local z is body:north:vector:normalized.
    local x is solarPrimeVector:vec:normalized.
    local y is vCrs(z,x):normalized.
    return list(x,y,z).
}
//--------------------------------------------------||
//                   CUSTOM WAIT                    ||
//--------------------------------------------------||

//--------------------------------------------------||
//                INCLINATION ASCENT                ||
//--------------------------------------------------||
function inclination_heading {
    // untested.
    local parameter target_inclination.
    local parameter mode.
    local parameter current_latitude is ship:latitude.
    if current_latitude > target_inclination {
        set target_inclination to current_latitude.
    }
    local N is (latlng(90,0):position - body:position):normalized.
    local P is (ship:position - body:position):normalized.
    local U is vxcl(P,N):normalized.
    local V is vCrs(P,N):normalized.
    local i is target_inclination.
    local lat is current_latitude.
    local alpha is arcCos(sin(i)/cos(lat)).
    local B1 is U * cos(alpha) - V * sin(alpha).
    local B2 is U * cos(alpha) + V * sin(alpha).
    if mode = "northbound"{
        local V1 is vCrs(P,B1):normalized.
        local heading1 is vectorHeading(V1).
        return heading1.
    }
    if mode = "southbound"{
        local V2 is vCrs(P,B2):normalized.
        local heading2 is vectorHeading(V2).
        return heading2.
    }
}
//--------------------------------------------------||
//                LANDING FUNCTIONS                 ||
//--------------------------------------------------||

//--------------------------------------------------||
//                  LINEAR DESCENT                  ||
//--------------------------------------------------||

//--------------------------------------------------||
//                    HOVER PIDS                    ||
//--------------------------------------------------||

//--------------------------------------------------||
//              RENDEZVOUS AND DOCKING              ||
//--------------------------------------------------||

//--------------------------------------------------||
//               BALLISTIC TARGETING                ||
//--------------------------------------------------||

//--------------------------------------------------||
//                WAYPOINT GUIDANCE                 ||
//--------------------------------------------------||

//--------------------------------------------------||
//                 PLANE AUTOPILOT                  ||
//--------------------------------------------------||

//--------------------------------------------------||
//                 SPECIAL POINTS                   ||
//--------------------------------------------------||
//SUB-SOLAR POINT
//LAUNCH PAD
//RUNWAYS