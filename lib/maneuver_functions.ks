//**************************************************||
//==================================================||
//==================================================||
//            MANEUVER FUNCTIONS LIBRARY            ||
//==================================================||
//==================================================||
//**************************************************||
// cc. SilverNuke911                                ||
// kOS Script Collection                            ||
// 2024 - 2026                                      ||
//--------------------------------------------------||
//                                                  ||
// A library of kOS functions designed for precise  ||
// maneuver planning and execution in orbital       ||
// mechanics, and other navigation purposes,        ||
// emulating the automation of "Create Maneuver" and||
// "Execute Maneuver" of MechJeb2.0. This includes  ||
// utilities for computing required deltaV, creating||
// various maneuver nodes, and other necessary      ||
// implements, see the rest of the code for stuff   ||
//                                                  ||
// Example use:                                     ||
//     If you want to create a node to circularize  ||
//  at apoapsis and want it to be executed          ||
//  immediately, write:                             ||
//                                                  ||
//  create_node(circularize("at apoapsis"))         ||
//  execute_node()                                  ||
//                                                  ||
//  and that's literally it. Just read the docstring||
//  for each function to know its purpose.          ||
//                                                  ||
//--------------------------------------------------||
//  Last update:  April 2026
//  Update / PATCH Notes:
//  March 28, 2026 - Changed a few of the
//                   functions as per the corrections
//                   in the sub.
//  April 03, 2026 - Updated some functions, the burn
//                   calculation times are now localized
//                 - Thinking of using Rodrigues' formula
//                   for the inclination problem. 
//  April 05, 2026 - Fixed the change eccentricity, it is now working
//                   Fixed change apoapsis and change periapsis
//                   Fixed change inclination using Rodrigues formula
//                   Implemented change LAN
//                   fixed match planes with target.
//                   initialized change_pe_and_ap.
//--------------------------------------------------||

//==================================================||
// INITIALIZATIONS                                  ||
//**************************************************||
//--------------------------------------------------||
@lazyGlobal off.          //                        ||
global mode_error_message is "[ MODE ERROR ] : Invalid mode given. Mode used is: ".
// set config:ipu to 2000.   //                     ||  
//==================================================||
//**************************************************||


//**************************************************||
//--------------------------------------------------||
//               BURN TIME FUNCTIONS                ||
//--------------------------------------------------||
//**************************************************||

// =================================================||
// Function: ship_isp                               ||
//--------------------------------------------------||
// Purpose:  Computes the effective specific impulse||
//           (ISP) of the vessel, taking into       ||
//           account all active engines and their   ||
//           current thrust and ISP values.         ||
//                                                  ||
// Assumptions:                                     ||
//   - Only considers engines that are currently    ||
//     providing thrust (availablethrust > 0)       ||
//     and have a valid ISP (isp > 0).              ||
//   - The effective ISP is calculated as a         ||
//     thrust-weighted harmonic mean:               ||
//     ISP_eff = Σ(Thrust_i) / Σ(Thrust_i / ISP_i)  ||
//     This accounts correctly for engines with     ||
//     different ISPs and thrusts, reflecting       ||
//     total propellant consumption.                ||
//                                                  ||
// Parameters: None                                 ||
//                                                  ||
// Returns:                                         ||
//   - effective isp : The effective ISP (in s)     ||
//     of all currently firing engines, reflecting  ||
//     their contribution to total thrust and fuel  ||
//     usage.                                       ||
//   - Returns 0 if no engines are active.          ||
// =================================================||

function ship_isp {
    local engineList to list().    // Temporary list to collect engines
    list engines in engineList.    // Populates engineList with all vessel engines

    local total_thrust to 0.       // Sum of engine thrusts
    local totalmdot to 0.          // Overall mass flow 

    for engine in engineList {
        // Only include engines that are firing and have valid ISP
        if engine:availablethrust > 0 and engine:isp > 0 {
            set total_thrust to total_thrust + engine:availablethrust.
            set totalmdot to totalmdot + (engine:availablethrust / engine:isp). 
        }
    }

    if total_thrust > 0 and totalmdot > 0 {
        return total_thrust / totalmdot.   // harmonic-mean Isp
    } else {
        return 0.
    }
}

//==================================================||
//      FUNCTION: calculate_burn_time               ||
//--------------------------------------------------||
// PURPOSE:                                         ||
//   Helper function to calculate total or half     ||
//   burn time for either engines or rcs            ||
//                                                  ||
// PARAMETERS:                                      ||
//   mnv : A maneuver node with :DELTAV vector      ||
//                                                  ||
// RETURNS:                                         ||
//   Burn time in seconds, or 0 if ISP is 0/null.   ||
//                                                  ||
// METHOD:                                          ||
//   Uses the Tsiolkovsky equation:                 ||
//     ve = ISP × g0                                ||
//     mf = m0 × exp(–Δv / ve)                      ||
//     dm = m0 – mf                                 ||
//     ṁ = Thrust / ve                              ||
//     burn_time = dm / ṁ                           ||
//==================================================||
function calculate_burn_time {
    local parameter delta_v.
    local parameter isp.
    local parameter thrust.
    
    if isp <= 0 or thrust <= 0 { 
        return 0. 
    }
    local ve is isp * constant:g0.
    local mdot is thrust / ve.
    local m0 is ship:mass.
    local mf is m0 * constant:e^(-delta_v / ve).
    local dm is m0 - mf.
    local t is dm / mdot.
    return t.
}

//==================================================||
//      FUNCTION: total_burn_time                   ||
//--------------------------------------------------||
// PURPOSE:                                         ||
//   Computes the full burn duration needed to      ||
//   achieve a maneuver node's total delta-v.       ||
//                                                  ||
// PARAMETERS:                                      ||
//   mnv : A maneuver node with :DELTAV vector      ||
//                                                  ||
// RETURNS:                                         ||
//   Burn time in seconds, or 0 if ISP is 0/null.   ||
//==================================================||

function total_burn_time {
    local parameter mnv.
    return calculate_burn_time(mnv:deltav:mag, ship_isp(), ship:maxThrust).
}

//==================================================||
//      FUNCTION: half_burn_time                    ||
//--------------------------------------------------||
// PURPOSE:                                         ||
//   Calculates burn time needed to complete half   ||
//   of a maneuver node's total delta-v.            ||
//                                                  ||
// PARAMETERS:                                      ||
//   mnv : A maneuver node                          ||
//                                                  ||
// RETURNS:                                         ||
//   Half burn time in seconds, or 0 if ISP is 0.   ||
//                                                  ||
// NOTES:                                           ||
//   Uses same method as total_burn_time, but with  ||
//   delta-v halved in the calculation.             ||
//==================================================||

function half_burn_time {
    local parameter mnv.
    return calculate_burn_time(mnv:deltav:mag / 2, ship_isp(), ship:maxThrust).
}

//==================================================||
//      FUNCTION: rcs_isp                           ||
//--------------------------------------------------||
// PURPOSE:                                         ||
//   Returns the effective ISP (s) of all active    ||
//   RCS thrusters on the vessel.                   ||
//                                                  ||
// PARAMETERS:                                      ||
//   (none)                                         ||
//                                                  ||
// RETURNS:                                         ||
//   A scalar ISP value in seconds.                 ||
//==================================================||

function rcs_isp {
    local rcsList to list().        // Temporary list to collect RCS thrusters
    list rcs in rcsList.            // Populate rcsList with all RCS thrusters

    local total_thrust to 0.        // Sum of RCS thrusts
    local totalmdot to 0.           // Overall mass flow for RCS
    for rcs_ in rcsList {
        // Only include RCS thrusters that are firing, have valid ISP,
        // and are enabled in the fore direction
        if rcs_:availableThrust > 0 
        and rcs_:isp > 0 
        and rcs_:foreenabled {
            set total_thrust to total_thrust + rcs_:availableThrust.
            set totalmdot to totalmdot + (rcs_:availableThrust / rcs_:isp).  // mass flow contribution
        }
    }

    if total_thrust > 0 and totalmdot > 0 {
        return total_thrust / totalmdot.   // harmonic-mean ISP for RCS
    } else {
        return 0.
    }
}

//==================================================||
//      FUNCTION: rcs_total_thrust                  ||
//--------------------------------------------------||
// PURPOSE:                                         ||
//   Computes the total thrust of all the rcs       ||
//   thrusters (foreward enabled) on the craft      ||
//                                                  ||
// PARAMETERS:                                      ||
//   none                                           ||
//                                                  ||
// RETURNS:                                         ||
//   Total RCS thrust                               ||
//                                                  ||
// METHOD:                                          ||
//   Takes the sum of thrust divided by             ||
//   mass flow rate (thrust/isp)                    ||
//==================================================||

function rcs_total_thrust {
    local rcsList is list().
    list rcs in rcsList.
    local rcs_total_thrust_ is 0.
    for rcs_ in rcsList {
        if rcs_:availableThrust > 0 
            and rcs_:availableThrust > 0 
            and rcs_:foreenabled{
            set rcs_total_thrust_ to 
                rcs_total_thrust_ + rcs_:availableThrust.
        }
    }
    return rcs_total_thrust_.
}
//==================================================||
//      FUNCTION: rcs_burn_time                     ||
//--------------------------------------------------||
// PURPOSE:                                         ||
//   Computes the full burn time required to        ||
//   complete a maneuver using RCS thrusters.       ||
//                                                  ||
// PARAMETERS:                                      ||
//   mnv : Maneuver node to be executed             ||
//                                                  ||
// RETURNS:                                         ||
//   Total RCS burn time in seconds.                ||
//                                                  ||
// METHOD:                                          ||
//   Applies the Tsiolkovsky rocket equation and    ||
//   standard thrust formula to compute duration.   ||
//==================================================||
function rcs_burn_time {
    local parameter mnv.
    return calculate_burn_time(mnv:deltav:mag, rcs_isp(), rcs_total_thrust()).
}

//==================================================||
//      FUNCTION: rcs_total_deltaV                  ||
//--------------------------------------------------||
// PURPOSE:                                         ||
//   Calculates the total delta-V available from    ||
//   the vessel's RCS system using monopropellant.  ||
//                                                  ||
// PARAMETERS:                                      ||
//   None                                           ||
//                                                  ||
// RETURNS:                                         ||
//   Total RCS delta-V in meters per second (m/s).  ||
//                                                  ||
// METHOD:                                          ||
//   Applies the Tsiolkovsky rocket equation using  ||
//   the current monopropellant mass, vessel mass,  ||
//   and RCS ISP.                                   ||
//==================================================||

function rcs_total_deltaV {
    local rcs_res is 0.
    for resource in ship:resources {
        if resource:name = "MonoPropellant" {
            set rcs_res to resource.
        }
    }
    local rcs_mass is rcs_res:amount * rcs_res:density.
    local wet_mass is ship:mass.
    local dry_mass is wet_mass - rcs_mass.
    local isp is rcs_isp().
    local ve is isp * constant:g0.
    local dv is ve * ln( wet_mass / dry_mass).
    return dv.
}

//==================================================||
//      FUNCTION: rcs_half_burn_time                ||
//--------------------------------------------------||
// PURPOSE:                                         ||
//   Computes the time required to burn half of the ||
//   maneuver node's delta-V using RCS thrusters.   ||
//                                                  ||
// PARAMETERS:                                      ||
//   mnv : Maneuver node to be executed             ||
//                                                  ||
// RETURNS:                                         ||
//   Half RCS burn time in seconds.                 ||
//==================================================||

function rcs_half_burn_time {
    local parameter mnv.
    return calculate_burn_time(mnv:deltav:mag / 2, rcs_isp(), rcs_total_thrust()).
}

//**************************************************||
//--------------------------------------------------||
//                   SHIP SYSTEMS                   ||
//--------------------------------------------------||
//**************************************************||

//==================================================||
//      FUNCTION: twr                               ||
//--------------------------------------------------||
// PURPOSE:                                         ||
//   Computes the vessel's Thrust-to-Weight Ratio   ||
//   (TWR) at its current altitude on the current   ||
//   celestial body.                                ||
//                                                  ||
// RETURNS:                                         ||
//   twr_val : Thrust-to-weight ratio, dimensionless||
//                                                  ||
// NOTES:                                           ||
//   - Uses available thrust, not maximum thrust.   ||
//   - TWR > 1 means upward acceleration possible.  ||
//   - Crucial for launch and landing maneuvers.    ||
//==================================================||

function twr {
    // Compute local gravity at current ship altitude
    local g0 is body:mu / (body:radius + ship:altitude)^2.
    // Compute current ship weight (mass * gravity)
    local ship_weight is ship:mass * g0.
    if ship_weight = 0 { return 0. }
    // Compute thrust-to-weight ratio
    local twr_val is ship:availablethrust / ship_weight.
    return twr_val.
}

//**************************************************||
//--------------------------------------------------||
//               ORBITAL CALCULATIONS               ||
//--------------------------------------------------||
//**************************************************||

//==================================================||
//      FUNCTION: orbital_velocity_circular         ||
//--------------------------------------------------||
// PURPOSE:                                         ||
//   Computes the circular orbital velocity (m/s)   ||
//   for a given altitude or absolute radius.       ||
//                                                  ||
// PARAMETERS:                                      ||
//   altitude_ : Numeric input, interpreted via mode||
//     - "altitude": altitude above surface (m)     ||
//     - "radius"  : full radius from center (m)    ||
//                                                  ||
//   mode : (optional, string) Defaults to altitude ||
//     - "altitude" -> adds to body:radius          ||
//     - "radius"   -> used as-is                   ||
//                                                  ||
// RETURNS:                                         ||
//   Circular orbital velocity at specified radius  ||
//                                                  ||
// NOTES:                                           ||
//   Formula: v = sqrt(GM / r)                      ||
//   where GM = body:mu, and r is orbital radius.   ||
//                                                  ||
// WARNINGS:                                        ||
//   Prints error if mode is invalid but continues. ||
//==================================================||

function orbital_velocity_circular {
    local parameter altitude_.           
    local parameter mode is "altitude".  
    local r__ is 0.                     
    if mode = "altitude" {
        set r__ to body:radius + altitude_.
    }
    else if mode = "radius" {
        set r__ to altitude_.
    } else {
        print mode_error_message + mode.
    }
    return sqrt(body:mu / r__).
}


//==================================================||
//      FUNCTION: vis_viva_equation                 ||
//--------------------------------------------------||
// PURPOSE:                                         ||
//   Computes orbital speed (m/s) at a given        ||
//   altitude for an orbit with known semimajor     ||
//   axis using the Vis-Viva equation.              ||
//                                                  ||
// PARAMETERS:                                      ||
//   altitude_ : (numeric) Altitude above surface   ||
//   a_        : (numeric) Semimajor axis of orbit  ||
//                                                  ||
// RETURNS:                                         ||
//   Orbital speed at the given altitude (m/s)      ||
//                                                  ||
// FORMULA:                                         ||
//   v = sqrt( GM * (2/r - 1/a) )                   ||
//     where:                                       ||
//       GM = body:mu (gravitational parameter)     ||
//       r  = body:radius + altitude_               ||
//       a  = semimajor axis of orbit               ||
//==================================================||
function vis_viva_equation {
    local parameter altitude_.  // Altitude above body's surface (m)
    local parameter a_.         // Semimajor axis of the orbit (m)
    local r_ is body:radius + altitude_.
    return sqrt(body:mu * (2 / r_ - 1 / a_)).
}

//==================================================||
//      FUNCTION: calculate_semimajor_axis          ||
//--------------------------------------------------||
// PURPOSE:                                         ||
//   Computes the semimajor axis of an orbit from   ||
//   its periapsis and apoapsis.                    ||
//                                                  ||
// PARAMETERS:                                      ||
//   periapsis__ : (scalar) Periapsis altitude      ||
//   apoapsis___ : (scalar) Apoapsis altitude       ||
//                                                  ||
// RETURNS:                                         ||
//   Semimajor axis (scalar), measured from the     ||
//   center of the body.                            ||
//==================================================||
function calculate_semimajor_axis {
    local parameter periapsis__.
    local parameter apoapsis___.
    return body:radius + (periapsis__+apoapsis___)/2.
}

//==================================================||
//      FUNCTION: true_anomaly_to_radius            ||
//--------------------------------------------------||
// PURPOSE:                                         ||
//   Converts a given true anomaly to the orbital   ||
//   radius (altitude above surface).               ||
//                                                  ||
// PARAMETERS:                                      ||
//   ta : (scalar) True anomaly in degrees          ||
//                                                  ||
// RETURNS:                                         ||
//   Orbital radius (scalar) above the surface.     ||
//==================================================||
function true_anomaly_to_radius {
    local parameter ta.
    local a is ship:obt:semimajoraxis.
    local e is ship:obt:eccentricity.
    local r_ to a * (1 - e^2) / (1 + e * cos(ta)).
    return r_ - body:radius.
}

//==================================================||
//      FUNCTION: radius_to_true_anomaly            ||
//--------------------------------------------------||
// PURPOSE:                                         ||
//  Converts a given orbital radius (or altitude)   ||
//  to the corresponding true anomaly based on the  ||
//  current orbital elements of the active vessel.  ||
//                                                  ||
// PARAMETERS:                                      ||
//      r_ : (scalar) Value to convert.             ||
//           Interpreted as either altitude or      ||
//           radius from the planet center.         ||
//      mode : (string, default "altitude")         ||
//          - "altitude" to treat r_ as above       ||
//            surface altitude (r = r_ + R_body)    ||
//          - "radius" to treat r_ as full radius   ||
//      closest: (bool) returns the closest anomally||
//      which : (integer, 0 or 1)                   ||
//          - 0: returns true anomaly in [0°,180°]  ||
//          - 1: returns true anomaly in [180°,360°]||
//            to account for the 2 places where alt ||
//            is the same                           ||
//                                                  ||
// RETURNS:                                         ||
//      True anomaly in degrees [0°, 360°].         ||
//==================================================||
function radius_to_true_anomaly {
    local parameter r_.
    local parameter mode is "altitude".
    local parameter closest is true. // if true, returns the closest anomaly
    local parameter which is 0. // which overides the closest, 
                          // if 0, returns the [0,180] ta, and if 1, returns the [180,360] ta.

    local r__ is r_.
    if mode = "altitude" {
        set r__ to r__ + body:radius.
    }
    local a is ship:obt:semimajoraxis.
    local e is ship:obt:eccentricity.
    local cos_trueanomaly to (a * (1 - e^2) / r__ - 1) / e.
    local trueanomaly to arccos(cos_trueanomaly).

    if which = 1 {
        return angle_wrap(0 - trueanomaly).
    }
    if not closest {
        return angle_wrap(trueanomaly).
    }
    // Determine closest anomaly
    local alt_trueanomaly to angle_wrap(0 - trueanomaly).
    if time_from_true_anomaly(trueanomaly) > time_from_true_anomaly(alt_trueanomaly) {
        return alt_trueanomaly.
    }
    return angle_wrap(trueanomaly).
}

//==================================================||
// FUNCTION: true_anomaly_to_eccentric_anomaly      ||
//--------------------------------------------------||
// PURPOSE:                                         ||
//   Converts a true anomaly to the corresponding   ||
//   eccentric anomaly.                             ||
//                                                  ||
// PARAMETERS:                                      ||
//   ta : (scalar) True anomaly in degrees          ||
//                                                  ||
// RETURNS:                                         ||
//   Eccentric anomaly in degrees [0, 360].         ||
//==================================================||
function true_anomaly_to_eccentric_anomaly {
    local parameter ta.
    local e is ship:obt:eccentricity.
    local ea to arctan2(
        sqrt(1 - e^2) * sin(ta), 
        e + cos(ta)
    ).
    return angle_wrap(ea).
}

//==================================================||
// FUNCTION: eccentric_anomaly_to_mean_anomaly      ||
//--------------------------------------------------||
// PURPOSE:                                         ||
//   Converts an eccentric anomaly to the           ||
//   corresponding mean anomaly.                    ||
//                                                  ||
// PARAMETERS:                                      ||
//   ea : (scalar) Eccentric anomaly in degrees     ||
//                                                  ||
// RETURNS:                                         ||
//   Mean anomaly in degrees [0, 360).              ||
//==================================================||
function eccentric_anomaly_to_mean_anomaly {
    local parameter ea.
    local e is ship:obt:eccentricity.
    local ma to ea - e * sin(ea) * constant:radtodeg.
    return angle_wrap(ma).
}

//==================================================||
// FUNCTION: mean_anomaly_to_eccentric_anomaly      ||
//--------------------------------------------------||
// PURPOSE:                                         ||
//   Solves Kepler's Equation to compute the        ||
//   Eccentric Anomaly (EA) from a given Mean       ||
//   Anomaly (MA), both in degrees.                 ||
//                                                  ||
// PARAMETERS:                                      ||
//   ma : Mean Anomaly in degrees                   ||
//                                                  ||
// RETURNS:                                         ||
//   Eccentric Anomaly in degrees [0, 360)          ||
//                                                  ||
// METHOD:                                          ||
//   Uses Newton-Raphson iteration on:              ||
//     MA = EA - e * sin(EA)                        ||
//   - Internally uses radians for computation      ||
//   - Eccentricity `e` from ship:obt:eccentricity  ||
//   - Stops when ΔEA < 1e-12                       ||
//                                                  ||
// NOTES:                                           ||
//   - Returned EA is in degrees for compatibility  ||
//     with kOS conventions                         ||
//==================================================||

function mean_anomaly_to_eccentric_anomaly {
    local parameter ma.                         // input mean anomaly
    local parameter tol is 1e-12.               // tolerance
    local parameter max_iter is 1000.           // maximum loop iterations.

    local e is ship:obt:eccentricity.           // orbit eccentricity
    local ma_rad to ma * constant:degtorad.     // convert MA to radians

    local ea_rad to ma_rad.                     // Initial guess EA = MA
    local ea_deg to ea_rad * constant:radtodeg. // Also track EA in degrees
    local diff to 1.

    // Newton-Raphson iteration to solve MA = EA - e * sin(EA)
    from { local i is 0. } until i >= max_iter step { set i to i + 1. } do { // Fixed upper bound
        local new_ea_rad to ea_rad - (
            ea_rad - e * sin(ea_deg) - ma_rad
        ) / (1 - e * cos(ea_deg)).

        set diff to abs(new_ea_rad - ea_rad).
        set ea_rad to new_ea_rad.
        set ea_deg to ea_rad * constant:radtodeg.
        if diff < tol {                           // break when tolerance is met
            return angle_wrap(ea_deg). // Wrap angle to [0, 360)
        }
    }

    print "Did not converge".
    return -1.    // Convergence failure.
}

//==================================================||
//    FUNCTION: eccentric_anomaly_to_true_anomaly   ||
//--------------------------------------------------||
// PURPOSE:                                         ||
//   Converts eccentric anomaly to true anomaly     ||
//   using the orbital eccentricity.                ||
//                                                  ||
// PARAMETERS:                                      ||
//   ea : (scalar) Eccentric anomaly in degrees     ||
//                                                  ||
// RETURNS:                                         ||
//   True anomaly in degrees [0, 360).              ||
//==================================================||
function eccentric_anomaly_to_true_anomaly {
    local parameter ea.
    local e is ship:obt:eccentricity.
    local ta to arctan2(
        sqrt(1 - e^2) * sin(ea), 
        cos(ea) - e
    ).
    return angle_wrap(ta).
}

//==================================================||
//      FUNCTION: time_from_true_anomaly            ||
//--------------------------------------------------||
// PURPOSE:                                         ||
//   Computes the time required to reach a given    ||
//   true anomaly from the current orbital state.   ||
//                                                  ||
// PARAMETERS:                                      ||
//   targ_ta : (scalar) Target true anomaly (deg)   ||
//                                                  ||
// RETURNS:                                         ||
//   Time in seconds to reach target true anomaly.  ||
//==================================================||
function time_from_true_anomaly {
    // Input: target true anomaly (targ_ta)
    local parameter targ_ta.
    // Current true anomaly, semi-major axis, 
    // eccentricity, and gravitational parameter
    local curr_ta is ship:obt:trueanomaly.
    local a is ship:obt:semimajoraxis.
    local e is ship:obt:eccentricity.
    local mu is body:mu.
    // Compute the eccentric anomaly for current and target true anomalies
    local ea_curr to arctan2(sqrt(1 - e^2) * sin(curr_ta), e + cos(curr_ta)).
    local ea_targ to arctan2(sqrt(1 - e^2) * sin(targ_ta), e + cos(targ_ta)).
    local ea_rad_curr to ea_curr * constant:degtorad.
    local ea_rad_targ to ea_targ * constant:degtorad.
    // Compute the mean anomaly for current and target eccentric anomalies
    local ma_rad_curr to ea_rad_curr - e * sin(ea_curr).
    local ma_rad_targ to ea_rad_targ - e * sin(ea_targ).
    // Mean motion (n) and time calculation
    local n to sqrt(mu / (a^3)).
    local delta_ma to ma_rad_targ - ma_rad_curr.
    // Ensure positive time (wrap around if necessary)
    if delta_ma < 0 {
        set delta_ma to delta_ma + 2 * constant:pi.
    }
    // Time to reach the target true anomaly
    local t to delta_ma / n.
    return t - 0.02. // For some fucking reason time from true anomaly
                      //returns values which are 0.02 s ahead, so this is a temporary fix.
}


//==================================================||
//      FUNCTION: angle_wrap                        ||
//--------------------------------------------------||
// PURPOSE:                                         ||
//   Ensures angle is within range [0, 360) by wrap ||
//   ping the values outside to be inside the range ||
//                                                  ||
// PARAMETERS:                                      ||
//   value : (scalar) Angle in degrees              ||
//                                                  ||
// RETURNS:                                         ||
//   Angle in degrees within [0, 360).              ||
//==================================================||
function angle_wrap {
    local parameter value.
    local result to mod(value,360).
    if result < 0 {
        set result to result + 360.
    }
    return result.
}

//**************************************************||
//--------------------------------------------------||
//                  MANEUVER NODES                  ||
//--------------------------------------------------||
//**************************************************||

//==================================================||
//      FUNCTION: create_node                       ||
//--------------------------------------------------||
// PURPOSE:                                         ||
//   Creates and schedules a maneuver node using a  ||
//   maneuver vector input.                         ||
//                                                  ||
// PARAMETERS:                                      ||
//   mnv_node : List of 4 values [eta, dv_r, dv_n,  ||
//              dv_p] where:                        ||
//       eta  : Time from now until burn (s)        ||
//       dv_r : Radial delta-V (m/s)                ||
//       dv_n : Normal delta-V (m/s)                ||
//       dv_p : Prograde delta-V (m/s)              ||
//                                                  ||
// BEHAVIOR:                                        ||
//   - If eta < 0 and all delta-V components are 0, ||
//     a warning is printed.                        ||
//   - Otherwise, the maneuver is scheduled.        ||
//==================================================||

function create_node {
    local parameter mnv_node.

    local uts____ is mnv_node[0].
    local radial_ is mnv_node[1].
    local normal_ is mnv_node[2].
    local prograd is mnv_node[3].

    // Warn if maneuver node is null_mnv()
    if mnv_node[0] < 0 {
        if radial_ = 0 and normal_ = 0 and prograd = 0 {
            print("[ NODE ERROR ] : Unable to make maneuver node").
            return.
        }
    }

    // Construct and add the maneuver node
    local maneuver_node to node(
        uts____,
        radial_,
        normal_,
        prograd
    ).
    add maneuver_node.
}

//==================================================||
//      FUNCTION: raw_node                          ||
//--------------------------------------------------||
// PURPOSE:                                         ||
//   Constructs a maneuver vector list without      ||
//   applying it immediately.                       ||
//                                                  ||
// PARAMETERS:                                      ||
//   eta____ : Time from now until burn (s)         ||
//   radial_ : Radial delta-V (m/s)                 ||
//   normal_ : Normal delta-V (m/s)                 ||
//   prograd : Prograde delta-V (m/s)               ||
//                                                  ||
// RETURNS:                                         ||
//   A list [eta, dv_r, dv_n, dv_p] suitable for    ||
//   use with create_node()                         ||
//==================================================||

function raw_node {
    local parameter eta____.
    local parameter radial_.
    local parameter normal_.
    local parameter prograd.

    local mnv_nd is list(
        eta____ + time:seconds,
        radial_,
        normal_,
        prograd
    ).

    return mnv_nd.
}

//==================================================||
//      FUNCTION: null_mnv                          ||
//--------------------------------------------------||
// PURPOSE:                                         ||
//   Returns a dummy maneuver vector that signals   ||
//   no action or an invalid maneuver. Useful for   ||
//   error handling. If given an error message,     ||
//   it prints the error message.                   ||
//                                                  ||
// RETURNS:                                         ||
//   List [-1, 0, 0, 0] representing:               ||
//     - eta     = -1 (invalid timing)              ||
//     - dv_r/n/p = 0 (no delta-V)                  ||
//==================================================||

function null_mnv {
    local parameter errormsg is " ".
    local parameter print_error is true.
    if print_error {
        print(errormsg).
    }
    return list(-1, 0, 0, 0).
}

// DOCUMENT BETTER LATER
//==================================================||
//      FUNCTION: rotate_vector                     ||
//--------------------------------------------------||
// PURPOSE:                                         ||
//   Rotates a given vector along a given axis      ||
//   in space                                       ||
//   Uses right hand rule rotation for positives.   ||
//   Uses Rodrigues' formula for vector rotation    ||
//                                                  ||
// PARAMETERS:                                      ||
//      vector: the vector to be rotated            ||
//      angle : magnitude of rotation [deg]         ||
//              counter clockwise is +              ||
//      axis  : vector, the axis of rotation        ||
// RETURNS:                                         ||
//      A new vector rotated by the specified angle ||
//      along the specified axis                    ||
//==================================================||
function rotate_vector {
    local parameter vector.
    local parameter angle.
    local parameter axis.

    set axis to axis:normalized.
    local rVec to (
        vector * cos(angle) + 
        vCrs(vector,axis) * sin(angle) + 
        axis * vDot(axis,vector)* (1 - cos(angle))
    ).
    return rVec. 
}


//==================================================||
//      FUNCTION: cartesian_to_TRN                  ||
//--------------------------------------------------||
// PURPOSE:                                         ||
//      Converts a vector in cartesian to a vector  ||
//      in prograde-radial-normal basis relative    ||
//      to the spacecraft, so one can easily convert||
//      dV vectors into maneuver nodes              ||
//                                                  ||
// PARAMETERS:                                      ||
//      vector: the vector to be converted          ||
//      uts   : univesal time of the entire kunivers||
//      with time: return result with uts or not    ||
//   (so it can be pushed to a create node directly)||
//               : default, true.                   ||
// RETURNS:                                         ||
//      A list containing:                          ||
//          uts: universal time [possible to turn off]
//         dv_r: radial component of vector         ||
//         dv_n: normal component of vector         ||
//         dv_p: prograde component of vector       ||
//==================================================||
function cartesian_to_TRN {
    local parameter vector.
    local parameter uts.
    local parameter with_time is true.

    local u_pv is velocityAt(ship,uts):orbit:normalized.                        // prograde unit vector
    local u_nv is vCrs(u_pv,positionAt(ship,uts):normalized):normalized.        // normal unit vector
    local u_rv is vCrs(u_nv,u_pv):normalized.                                   // radial unit vector

    local dv_p is vdot(vector, u_pv).                     // vector components in upv frame
    local dv_r is vdot(vector, u_rv).                     // vector components in urv frame
    local dv_n is vdot(vector, u_nv).                     // vector components in unv frame

    if with_time {
        return list(uts, dv_r, dv_n, dv_p).
    } else {
        return list(dv_r, dv_n, dv_p).
    }

}

//==================================================||
//      FUNCTION: circularize                       ||
//--------------------------------------------------||
// PURPOSE:                                         ||
//   Calculates the delta-v vector required to      ||
//   circularize an orbit under various conditions. ||
//                                                  ||
// MODES SUPPORTED:                                 ||
//   - "at periapsis"       : Burn at periapsis     ||
//   - "at apoapsis"        : Burn at apoapsis      ||
//   - "at altitude"        : Burn at given altitude||
//   - "after fixed time"   : Burn after time delay ||
//                                                  ||
// PARAMETERS:                                      ||
//   mode  : (string) Method of circularization     ||
//   value : (optional, numeric) Mode-dependent:    ||
//             "at altitude" -> target altitude (m) ||
//             "after fixed time" -> delay time (s) ||
//                                                  ||
// RETURNS:                                         ||
//   A maneuver node vector [eta, radial, normal,   ||
//   prograde] or null_mnv() if operation fails.    ||
//==================================================||
function circularize {
    local parameter mode.
    local parameter value is 0. // Optional mode-specific value

    // Mode 1: Circularize at Periapsis
    if mode = "at periapsis" {
        local periapsis_dV is 
            orbital_velocity_circular(ship:periapsis) -
            vis_viva_equation(ship:periapsis, ship:orbit:semimajoraxis).
        return list(eta:periapsis + time:seconds, 0, 0, periapsis_dV).
    }

    // Mode 2: Circularize at Apoapsis
    if mode = "at apoapsis" {
        local apoapsis_dV is 
            orbital_velocity_circular(ship:apoapsis) -
            vis_viva_equation(ship:apoapsis, ship:orbit:semimajoraxis).
        return list(eta:apoapsis + time:seconds, 0, 0, apoapsis_dV).
    }

    local function compute_circularization_dv {
        local parameter uts.

        set uts to uts. 
        // Predict ship's position and velocity at future time
        local pos_vec is positionat(ship, uts) - body:position.
        local vel_vec is velocityat(ship, uts):orbit.

        // Desired circular velocity at the predicted radius
        local circ_vel is orbital_velocity_circular(pos_vec:mag, "radius").

        // Vector exclude the velocity from the position vector to find the planar velocity.
        // Normalize to find unit vector, then multiply by desired circvel.
        local targ_vec is vxcl(pos_vec, vel_vec):normalized * circ_vel.
        local dv_vec is targ_vec - vel_vec.
        return cartesian_to_TRN(dv_vec, uts).
    }

    // Mode 3: Circularize at Specified Altitude
    if mode = "at altitude" {
        local target_alt is value.

        // Check if altitude is reachable
        if (target_alt < ship:obt:periapsis) or (target_alt > ship:obt:apoapsis) {
            return null_mnv("[ ALTITUDE ERROR ] : Altitude unreachable").
        }

        // Determine true anomaly and time to reach target altitude
        local target_true_anomaly is radius_to_true_anomaly(target_alt).
        local t_ is time_from_true_anomaly(target_true_anomaly).
        local future_t is time:seconds + t_.
        return compute_circularization_dv(future_t).
    }

    // Mode 4: Circularize After Fixed Time
    if mode = "after fixed time" {
        local t_ is value.
        local future_t is time:seconds + t_.
        return compute_circularization_dv(future_t).
    }

    if mode = "at equatorial AN" {
        local trueanomaly is 360 - obt:argumentofperiapsis.
        local future_t is time_from_true_anomaly(trueanomaly) + time:seconds.
        return compute_circularization_dv(future_t).
    }
    if mode = "at equatorial DN" {
        local trueanomaly is 180 - obt:argumentofperiapsis.
        local future_t is time_from_true_anomaly(trueanomaly) + time:seconds.
        return compute_circularization_dv(future_t).
    }
    return null_mnv(mode_error_message+ mode).
}

//==================================================||
//      FUNCTION: change_eccentricity               ||
//--------------------------------------------------||
// PURPOSE:                                         || 
//   Adjusts the eccentricity of the current orbit  ||
//   by modifying apoapsis or periapsis depending   ||
//   on the specified mode of operation. Works      ||
//   relative to the central body's radius.         ||
//                                                  ||
// PARAMETERS:                                      ||
//   targ_eccentricity : (scalar) Target orbital    ||
//                      eccentricity                ||
//   mode              : (string) Mode for how the  ||
//                      eccentricity should be      ||
//                      changed. Options include:   ||
//                        - "at periapsis"          ||
//                        - "at apoapsis"           ||
//                        - "after fixed time"      ||
//                        - "at altitude"           ||
//   value             : (scalar) Reserved/optional ||
//                      input, default is 0         ||
//                                                  ||
// RETURNS:                                         ||
//   Maneuver node to execute eccentricity change,  ||
//   or null maneuver node if unsupported mode.     ||
//==================================================||

function change_eccentricity {
    local parameter targ_eccentricity.
    local parameter mode.
    local parameter value is 0.

    local ecc is targ_eccentricity.
    local r_a is obt:apoapsis + body:radius.
    local r_p is obt:periapsis + body:radius.
    
    if mode = "at periapsis" {
        set r_a to r_p * (1 + ecc) / (1 - ecc).
        return change_apoapsis(r_a - body:radius, mode).
    }
    if mode = "at apoapsis" {
        set r_p to r_a * (1 - ecc) / (1 + ecc).
        return change_periapsis(r_p - body:radius, mode).
    }
    
    local function compute_dv {
        local parameter future_t.

        set future_t to future_t.
        // Predict ship's position and velocity at future time
        local pos_vec is (positionat(ship, future_t) - body:position).
        local vel_vec is velocityat(ship, future_t):orbit.
        local r_mag is pos_vec:mag.

        // Perifocal frame
        local P_vec is (positionat(ship, eta:periapsis + time:seconds) - body:position):normalized.
        local N_vec is vCrs(vel_vec, pos_vec):normalized.
        local Q_vec is vCrs(P_vec,N_vec):normalized.

        // Calculate target true anomaly at time.
        local angle is vang(pos_vec, P_vec).
        local sign is vdot(pos_vec, Q_vec).
        local theta_targ to angle.
        if sign < 0 {
            set theta_targ to 360 - angle.
        }
        print(theta_targ).
        
        // Calculate target orbit parameters

        local p_targ is 0.
        local a_targ is 0.
        
        if ecc < 0 {
            return null_mnv("[ ERROR ] : Negative eccentricity not possible").
        } else if ecc = 1 {
            // Parabola: p = r(1 + cosθ)
            set p_targ to r_mag * (1 + cos(theta_targ)).
            set a_targ to 9.99e99. // Approximation for infinity
        } else if ecc > 1 {
            // Hyperbola: a = r(1 + e·cosθ)/(1-e²) [a is negative]
            local denominator is 1 - ecc^2.
            set a_targ to r_mag * (1 + ecc * cos(theta_targ)) / denominator.
            set p_targ to a_targ * denominator.
            
            // Check if position is on correct branch
            if cos(theta_targ) < -1/ecc {
                return null_mnv("[ ERROR ] : Position not on valid hyperbola branch").
            }
        } else {
            // Ellipse (0 <= e < 1)
            local denominator is 1 - ecc^2.
            set a_targ to r_mag * (1 + ecc * cos(theta_targ)) / denominator.
            set p_targ to a_targ * denominator.
        }
        
        // Target velocity in perifocal coordinates
        local v_targ is sqrt(body:mu / p_targ) * (
            (-sin(theta_targ)) * P_vec + 
            (ecc + cos(theta_targ)) * Q_vec
        ).
        
        // Delta-V is simply target minus current
        local delta_v is v_targ - vel_vec.
        return cartesian_to_TRN(delta_v, future_t).
    }
    if mode = "at altitude" {
        local target_alt is value.
        local target_true_anomaly is radius_to_true_anomaly(target_alt).
        local t_ is time_from_true_anomaly(target_true_anomaly).
        local future_t is time:seconds + t_.
        return compute_dv(future_t).
    }
    if mode = "after fixed time" {
        local t_ is value.
        local future_t is time:seconds + t_.
        return compute_dv(future_t).
    }
    if mode = "at equatorial AN" {
        local trueanomaly is 360 - obt:argumentofperiapsis.
        local future_t is time_from_true_anomaly(trueanomaly) + time:seconds.
        return compute_dv(future_t).
    }
    if mode = "at equatorial DN" {
        local trueanomaly is 180 - obt:argumentofperiapsis.
        local future_t is time_from_true_anomaly(trueanomaly) + time:seconds.
        return compute_dv(future_t).
    }
    return null_mnv( mode_error_message + mode).
}

function compute_dv_apsides {
    local parameter target_apsis.
    local parameter apsis_type.
    local parameter future_t.
    
    // Predict ship's position and velocity at future time
    local pos_vec is (positionat(ship, future_t) - body:position).
    local vel_vec is velocityat(ship, future_t):orbit.
    local rad_mag is pos_vec:mag.

    // Perifocal frame (same for both)
    local P_vec is (positionat(ship, eta:periapsis + time:seconds) - body:position):normalized.
    local N_vec is vCrs(vel_vec, pos_vec):normalized.
    local Q_vec is vCrs(P_vec, N_vec):normalized.
    
    // Calculate true anomaly from the propagated position
    local angle is vang(pos_vec, P_vec).
    local sign is vdot(pos_vec, Q_vec).
    local theta_targ is angle.
    if sign < 0 {
        set theta_targ to 360 - angle.
    }

    // Calculate target eccentricity
    local e_targ is 0.
    local p_targ is 0.
    local a_targ is 0.
    
    if apsis_type = "apoapsis" {
        // For apoapsis change: r_a = a(1+e)
        // Formula: e = (r_a - r) / (r + r_a*cosθ)
        set e_targ to (target_apsis - rad_mag) / (rad_mag * cos(theta_targ) + target_apsis).
        
        if (e_targ < 0) or (e_targ >= 1) {
            return null_mnv("[ ERROR ] : Target apoapsis too low for this position").
        }
        
        set a_targ to target_apsis / (1 + e_targ).
        set p_targ to a_targ * (1 - e_targ^2).
        
    } else { 
        set e_targ to (rad_mag - target_apsis) / (target_apsis - rad_mag * cos(theta_targ)).
        
        if e_targ < 0 {
            return null_mnv("[ ERROR ] : Target periapsis too high for this position").
        } else if e_targ = 1 {
            // Parabolic case
            set p_targ to 2 * target_apsis.
        } else {
            set a_targ to target_apsis / (1 - e_targ).
            set p_targ to a_targ * (1 - e_targ^2).
        }
    } 
    // Target velocity (same formula for both)
    local v_targ is sqrt(body:mu / p_targ) * (
        (-sin(theta_targ)) * P_vec + 
        (e_targ + cos(theta_targ)) * Q_vec
    ).
    local delta_v is v_targ - vel_vec.
    return cartesian_to_TRN(delta_v, future_t).
}

//==================================================||
//      FUNCTION: change_apoapsis                   ||
//--------------------------------------------------||
// PURPOSE:                                         ||
//   Calculates the required delta V                ||
//   to adjust the apoapsis of the current orbit.   ||
//   Can compute the maneuver at periapsis, apoapsis||
//   after a fixed time, or when reaching a target  ||
//   altitude. Handles orbit propagation to predict ||
//   the ship's position and velocity as needed.    ||
//                                                  ||
// PARAMETERS:                                      ||
//   target_apoapsis : (scalar) Target apoapsis in  ||
//                     meters above the central body||
//   mode            : (string) Mode for computing  ||
//                     the maneuver. Options include||
//                       - "at periapsis"           ||
//                       - "at apoapsis"            ||
//                       - "after fixed time"       ||
//                       - "at altitude"            ||
//                       - "at equatorial DN"       ||
//                       - "at equatorial AN"       ||
//   value           : (scalar) Optional parameter, ||
//                     used for time or altitude.   ||
//                                                  ||
// RETURNS:                                         ||
//   List containing the maneuver components.       ||
//   Returns a null maneuver node if the requested  ||
//   mode is unsupported or the target is invalid.  ||
//==================================================||
function change_apoapsis {
    local parameter target_apoapsis.
    local parameter mode.
    local parameter value is 0.
    if mode = "at periapsis" {
        if target_apoapsis < ship:periapsis {
            return null_mnv(
                "[ ALTITUDE ERROR ] : Target apoapsis should be "+
                "bigger than current periapsis"
            ).
        }
        local periapsis_dV is ( 
            vis_viva_equation(
                ship:periapsis, 
                calculate_semimajor_axis(
                    target_apoapsis, 
                    ship:periapsis)
            ) - vis_viva_equation(
                ship:periapsis,
                ship:orbit:semimajoraxis
            )
        ).
        return list(
            eta:periapsis + time:seconds, 
            0,
            0, 
            periapsis_dV
        ).
    }
    if mode = "at apoapsis" {
        if target_apoapsis < ship:apoapsis {
            return null_mnv(
                "[ ALTITUDE ERROR ] : target apoapsis must be "+
                "bigger than current apoapsis"
            ).
        }
        local apoapsis_dV is ( 
            vis_viva_equation(
                ship:apoapsis, 
                calculate_semimajor_axis(
                    target_apoapsis, 
                    ship:apoapsis)
            ) - vis_viva_equation(
                ship:apoapsis,
                ship:orbit:semimajoraxis
            )
        ).
        return list(
            eta:apoapsis + time:seconds, 
            0,
            0, 
            apoapsis_dV
        ).
    }
    if mode = "at altitude" {
        local target_alt is value.
        local trueanomaly is radius_to_true_anomaly(target_alt).
        local future_t is time_from_true_anomaly(trueanomaly) + time:seconds.
        return compute_dv_apsides(target_apoapsis + body:radius, "apoapsis", future_t).
    }
    if mode = "after fixed time" {
        local t_ is value.
        return compute_dv_apsides(target_apoapsis + body:radius, "apoapsis", time:seconds + t_).
    }
    if mode = "at equatorial AN" {
        local trueanomaly is 360 - obt:argumentofperiapsis.
        local future_t is time_from_true_anomaly(trueanomaly) + time:seconds.
        return compute_dv_apsides(target_apoapsis + body:radius, "apoapsis", future_t).
    }
    if mode = "at equatorial DN" {
        local trueanomaly is 180 - obt:argumentofperiapsis.
        local future_t is time_from_true_anomaly(trueanomaly) + time:seconds.
        return compute_dv_apsides(target_apoapsis + body:radius, "apoapsis", future_t).
    }
    else {
        return null_mnv(mode_error_message+ mode).
    }
}

//==================================================||
//      FUNCTION: change_periapsis                  ||
//--------------------------------------------------||
// PURPOSE:                                         ||
//   Calculates the required delta V                ||
//   to adjust the periapsis of the current orbit.  ||
//   Can compute the maneuver at periapsis, apoapsis||
//   after a fixed time, or when reaching a target  ||
//   altitude. Handles orbit propagation to predict ||
//   the ship's position and velocity as needed.    ||
//                                                  ||
// PARAMETERS:                                      ||
//   target_apoapsis : (scalar) Target periapsis in ||
//                     meters above the central body||
//   mode            : (string) Mode for computing  ||
//                     the maneuver. Options include||
//                       - "at periapsis"           ||
//                       - "at apoapsis"            ||
//                       - "after fixed time"       ||
//                       - "at altitude"            ||
//                       - "at equatorial DN"       ||
//                       - "at equatorial AN"       ||
//   value           : (scalar) Optional parameter, ||
//                     used for time or altitude.   ||
//                                                  ||
// RETURNS:                                         ||
//   List containing the maneuver components.       ||
//   Returns a null maneuver node if the requested  ||
//   mode is unsupported or the target is invalid.  ||
//==================================================||
function change_periapsis {
    local parameter target_periapsis.
    local parameter mode.
    local parameter value is 0.
    if mode = "at apoapsis" {
        if target_periapsis > ship:apoapsis {
            return null_mnv(
                "[ ALTITUDE ERROR ] :"+
                "Target periapsis should be"+ 
                "smaller than current apoapsis"
            ).
        }
        local apoapsis_dV is ( 
            vis_viva_equation(
                ship:apoapsis, 
                calculate_semimajor_axis(
                    target_periapsis, 
                    ship:apoapsis)
            ) - vis_viva_equation(
                ship:apoapsis,
                ship:orbit:semimajoraxis
            )
        ).
        return list(
            eta:apoapsis + time:seconds,
            0,
            0, 
            apoapsis_dV
        ).
    }
    if mode = "at periapsis" {
        if target_periapsis > ship:periapsis {
            return null_mnv(
                " [ ALTITUDE ERROR ] :"+ 
                "Target periapsis must be smaller"+
                " than current periapsis"
            ).
        }
        local periapsis_dV is (
            vis_viva_equation(
                ship:periapsis,
                calculate_semimajor_axis(
                    ship:periapsis,
                    target_periapsis
                )
            ) -
            vis_viva_equation(
                ship:periapsis,
                ship:orbit:semimajoraxis
            )
        ).
        return list(
            eta:periapsis + time:seconds,
            0,
            0,
            periapsis_dV
        ).
    }
    if mode = "at altitude" {
        local target_alt is value.
        local target_true_anomaly is radius_to_true_anomaly(target_alt).
        local t_ is time_from_true_anomaly(target_true_anomaly).
        return compute_dv_apsides(target_periapsis + body:radius, "periapsis", time:seconds + t_).
    }
    if mode = "after fixed time" {
        local t_ is value.
        return compute_dv_apsides(target_periapsis + body:radius, "periapsis", time:seconds + t_).
    }
    if mode = "at equatorial AN" {
        local trueanomaly is 360 - obt:argumentofperiapsis.
        local future_t is time_from_true_anomaly(trueanomaly) + time:seconds.
        return compute_dv_apsides(target_periapsis + body:radius, "periapsis", future_t).
    }
    if mode = "at equatorial DN" {
        local trueanomaly is 180 - obt:argumentofperiapsis.
        local future_t is time_from_true_anomaly(trueanomaly) + time:seconds.
        return compute_dv_apsides(target_periapsis + body:radius, "periapsis", future_t).
    }
    else {
        return null_mnv(mode_error_message+ mode).
    }
}

//==================================================||
//      FUNCTION: change_inclination                ||
//--------------------------------------------------||
// PURPOSE:                                         ||
//   Computes delta-V vector and timing to achieve  ||
//   a desired orbital inclination.                 ||
//                                                  ||
// PARAMETERS:                                      ||
//   target_inclination : Desired inclination (°)   ||
//   mode               : Where to perform the burn:||
//     - "at AN"            : Ascending Node        ||
//     - "at DN"            : Descending Node       ||
//     - "at nearest node"  : Soonest node (AN/DN)  ||
//     - "at cheapest node" : Least delta-V cost    ||
//     - "after fixed time" : (not implemented yet) ||
//                                                  ||
// RETURNS:                                         ||
//   A list containing:                             ||
//     [0] Time until burn (s)                      ||
//     [1] Radial delta-V (m/s)                     ||
//     [2] Normal delta-V (m/s)                     ||
//     [3] Prograde delta-V (m/s)                   ||
//   Or null_mnv() if mode is invalid.              ||
//                                                  ||
// METHOD:                                          ||
//   1. Finds AN/DN times and velocities            ||
//   2. Calculates required inclination correction  ||
//   3. Decomposes delta-V into orbital frame axes  ||
//==================================================||
function change_inclination {
    local parameter target_inclination.
    local parameter mode.

    local current_inclination is obt:inclination.
    local delta_inc is target_inclination - current_inclination.
    // Compute true anomalies of the nodes
    local an_ta is 360 - obt:argumentofperiapsis.
    local dn_ta is 180 - obt:argumentofperiapsis.
    // Compute times to each node
    local t_an is time_from_true_anomaly(an_ta) + time:seconds.
    local t_dn is time_from_true_anomaly(dn_ta) + time:seconds.
    // Compute velocity vectors at each node
    local vel_vec_an is velocityat(ship,t_an):orbit.
    local vel_vec_dn is velocityat(ship,t_dn):orbit.
    // Compute required delta-v magnitude at each node
    local delta_v_mag_an is 2 * vel_vec_an:mag * sin(abs(delta_inc) / 2).
    local delta_v_mag_dn is 2 * vel_vec_dn:mag * sin(abs(delta_inc) / 2).
    // Helper function to compute maneuver components
    local function compute_dv {
        local parameter isAN.

        local ut is t_an.
        local rad_vector is positionAt(ship,t_an) - body:position.
        local vel_vector is vel_vec_an.
        if not isAN {
            set rad_vector to positionAt(ship,t_dn) - body:position.
            set vel_vector to vel_vec_dn.
            set delta_inc to - delta_inc.
            set ut to t_dn.
        } 
        local rotVector is rotate_vector(vel_vector, delta_inc, rad_vector).
        local deltaV is rotVector - vel_vector.
        return cartesian_to_TRN(deltaV, ut).
    }
    // Decision logic by mode
    if mode = "at AN" {
        return compute_dv(true).
    }
    if mode = "at DN" {
        return compute_dv(false).
    }
    if mode = "at nearest node" {
        if t_an < t_dn {
            return compute_dv(true).
        } else {
            return compute_dv(false).
        }
    }
    if mode = "at cheapest node" {
        if delta_v_mag_an < delta_v_mag_dn {
            return compute_dv(true).
        } else {
            return compute_dv(false).
        }
    }
    if mode = "at altitude" {
        // not yet implemented
        // besides, who the fuck changes incleination in an arbitrary point anyway
        // it accmpplishes nothing, it's inneficient and wasteful
        // the only time you do it is when matching inclination with a target
        // but you already have the target to follow at that point.
        // retarded mode. 
    }
    if mode = "after fixed time" {
        // Not implemented — requires true anomaly and velocity propagation
        print "after fixed time mode not implemented yet".
    }
    return null_mnv(mode_error_message+ mode).
}


//==================================================||
//      FUNCTION: change_LAN                        ||
//--------------------------------------------------||
//  Calculates delta-V required to change LAN       ||
//  Parameters:                                     ||
//    - target_lan: desired LAN in degrees          ||
//    - mode: where to perform the burn             ||
//      Options: "at periapsis", "at apoapsis",     ||
//      "at nearest apsis", "at cheapest apsis",    ||
//      "at north peak latitude",                   ||
//      "at south peak latitude",                   ||
//      "at nearest peak latitude",                 ||
//      "at cheapest peak latitude"                 ||
//==================================================||
function change_LAN {
    local parameter target_lan.
    local parameter mode.

    local currentLAN is obt:longitudeofascendingnode.
    local ANta is 360 - obt:argumentofperiapsis.
    local northLatTA is ANta + 90.
    local southLatTA is ANta + 270.
    
    local currentTA   is obt:trueanomaly.
    local distToPeri  is min(abs(currentTA - 0), 360 - abs(currentTA - 0)).
    local distToApo   is min(abs(currentTA - 180), 360 - abs(currentTA - 180)).
    local distToNorth is min(abs(currentTA - northLatTA), 360 - abs(currentTA - northLatTA)).
    local distToSouth is min(abs(currentTA - southLatTA), 360 - abs(currentTA - southLatTA)).

    // Helper: Compute delta-V at a given true anomaly
    local function compute_deltaLAN_at_TA {
        local parameter burn_TA.                   // true anomaly where burn occurs
        local parameter is_peak is false.          // true if burn_TA is a peak latitude
        local parameter cartdV_return is false.    // true if we want cartesian dV
        local parameter is_inverse is false.

        // Times for key orbital positions
        local t_AN   is time_from_true_anomaly(ANta) + time:seconds.        // time from ascending node
        local t_NLat is time_from_true_anomaly(northLatTA) + time:seconds.  // time from north peak latitude
        local t_SLat is time_from_true_anomaly(southLatTA) + time:seconds.  // time from south peak latitude
        local t_peri is eta:periapsis + time:seconds.                       // time from periapsis
        local t_apo  is eta:apoapsis  + time:seconds.                       // time from apoapsis
        // Position/velocity vectors at key points
        local ANvec   is positionAt(ship, t_AN)   - body:position.
        local NLatVec is positionAt(ship, t_NLat) - body:position.
        local SLatVec is positionAt(ship, t_SLat) - body:position.
        local periVec is positionAt(ship, t_peri) - body:position.
        local apoVec  is positionAt(ship, t_apo)  - body:position.
        // Basis vectors for the universe, north direction.
        local Zv is (latlng(90,0):position - body:position):normalized.
        // local XV is solarPrimeVector:normalized.
        // Position and velocity at burn location
        local ANvelV is velocityAt(ship, t_AN):orbit.       // velocity at AN
        local hVec is vCrs(ANvelV, ANvec):normalized.       // angular momentum vector


        // Determine the turn axis based on burn location
        local turnAxis is v(0,0,0).
        if is_peak {
            if abs(burn_TA - northLatTA) < 0.1 {
                set turnAxis to NLatVec.
            } else if abs(burn_TA - southLatTA) < 0.1 {
                set turnAxis to SLatVec.
            }
        } else {
            if abs(burn_TA - 0) < 0.1 {
                set turnAxis to periVec.
            } else if abs(burn_TA - 180) < 0.1 {
                set turnAxis to apoVec.
            }
        }
 
        // Calculate required rotation
        local deltaLAN is target_lan - currentLAN.                      // calculate change in lan
        local new_ANvec is rotate_vector(ANvec, deltaLAN, Zv).          // rotate the lan vector to deltalan
        local projNew_ANvec is vxcl(turnAxis, new_ANvec):normalized.    // project that to the plane of the vector of the turn axis
        local projtoH_angle is vang(projNew_ANvec, hvec).               // get the angle from h
        local rotateAngle to projtoH_angle - 90.                        // rotate the vel vector by negative complement
        if is_peak {    
            if is_inverse {                                             // if south, negate.
                set rotateAngle to - rotateAngle.
            }
        } else {    
            if obt:argumentofperiapsis >= 180 {
                set rotateAngle to - rotateAngle.                       // if south, negate.
            }
            if is_inverse {
                set rotateAngle to - rotateAngle.                       // if apoapsis, negate the action on the periapsis
            }
        }
        // Get velocity at burn location and rotate it
        local burnVelVec is velocityAt(ship, time_from_true_anomaly(burn_TA) + time:seconds):orbit.
        local newBurnVelVec is rotate_vector(burnVelVec, rotateAngle, turnAxis).
        // Calculate delta-V
        local deltaV is newBurnVelVec - burnVelVec.
        if cartdV_return {
            return deltaV.
        } else {
            return cartesian_to_TRN(deltaV, time_from_true_anomaly(burn_TA) + time:seconds).
        }
    }

    // Helper: Get delta-V magnitude at apsis
    local function get_apsis_deltaV_magnitude {
        local parameter at_periapsis.
        local burnTA is 0.
        if not at_periapsis { set burnTA to 180. }
        local deltaV_vec is compute_deltaLAN_at_TA(burnTA, false, true).
        return deltaV_vec:mag.
    }

    // Helper: Get delta-V magnitude at peak latitude
    local function get_peak_deltaV_magnitude {
        local parameter use_north.
        local burnTA is ANta + 90.
        if not use_north { set burnTA to ANta + 270. }
        local deltaV_vec is compute_deltaLAN_at_TA(burnTA, true, true).
        return deltaV_vec:mag.
    }

    if mode = "at periapsis" {
        return compute_deltaLAN_at_TA(0, false).
    }
    if mode = "at apoapsis" {
        return compute_deltaLAN_at_TA(180, false, false, true).
    }
    if mode = "at nearest apsis" {
        if distToPeri <= distToApo {
            return compute_deltaLAN_at_TA(0, false).
        } else {
            return compute_deltaLAN_at_TA(180, false, false, true).
        }
    }
    if mode = "at cheapest apsis" {
        local deltaV_peri is get_apsis_deltaV_magnitude(true).
        local deltaV_apo  is get_apsis_deltaV_magnitude(false).
        if deltaV_peri < deltaV_apo {
            return compute_deltaLAN_at_TA(0, false).
        } else {
            return compute_deltaLAN_at_TA(180, false).
        }
    }
    if mode = "at north peak latitude" {
        return compute_deltaLAN_at_TA(northLatTA, true).
    }
    if mode = "at south peak latitude" {
        return compute_deltaLAN_at_TA(southLatTA, true, false, true).
    }
    if mode = "at nearest peak latitude" {
        if distToNorth <= distToSouth {
            return compute_deltaLAN_at_TA(northLatTA, true).
        } else {
            return compute_deltaLAN_at_TA(southLatTA, true).
        }
    }
    if mode = "at cheapest peak latitude" {
        local deltaV_north is get_peak_deltaV_magnitude(true).
        local deltaV_south is get_peak_deltaV_magnitude(false).
        if deltaV_north <= deltaV_south {
            return compute_deltaLAN_at_TA(northLatTA, true).
        } else {
            return compute_deltaLAN_at_TA(southLatTA, true, false, true).
        }
    }
    return null_mnv( mode_error_message + mode).
}
//==================================================||
//      FUNCTION: change_pe_and_ap                  ||
//--------------------------------------------------||
//
//--------------------------------------------------||
function change_pe_and_ap {
    local parameter new_pe.
    local parameter new_ap.
    local parameter mode.
    local parameter value is 0.

    local targ_ap is new_ap + body:radius.
    local targ_pe is new_pe + body:radius.
    local e_targ is (targ_ap - targ_pe) / (targ_ap + targ_pe).
    local a_targ is (new_pe + new_ap) / 2 + body:radius.
    
    local function compute_dv {
        local parameter gtr is false.

        local e1 is obt:eccentricity.
        local a1 is obt:semimajoraxis.
        local e2 is e_targ.
        local a2 is a_targ.
        local p1 is a1 * (1 - e1^2).
        local p2 is a2 * (1 - e2^2).
        local nu is 0.
        if p1 * e2 = p2 * e1 {
            return "[ TARGET ERROR ] : Same orbit".
        }
        local cos_nu is ( (p2 - p1) / (p1 * e2 - p2 * e1)).
        if (cos_nu > 1) or (cos_nu < 0) {
            return "[ TARGET ERROR ] : Orbit not possible with current parameters".
        }
        if cos_nu = 1 {
            // single point intersection
            set nu to 0.
        }
        if cos_nu < 1 {
            // nu choosing logic here
            set nu to arcCos(nu).
            if gtr {
                set nu to 360 - nu.
            } 
        }
        local p_hat is (positionAt(ship,eta:periapsis + time:seconds) - body:position):normalized.
        local h_hat is vcrs(velocityAt(ship, eta:periapsis):orbit,p_hat):normalized.
        local q_hat is vcrs(p_hat,h_hat):normalized.
        local v1 is sqrt(body:mu / p1) * (- sin(nu) * p_hat + (e1 + cos(nu) * q_hat)).
        local v2 is sqrt(body:mu / p2) * (- sin(nu) * p_hat + (e2 + cos(nu) * q_hat)).
        local dV is v2 - v1.
        return cartesian_to_TRN(dV,time_from_true_anomaly(nu)+ time:seconds).

    }
    // not possible to manipulate using time and alts, there are only precisely 
    // 2 or 1 point where two distinct orbits of different pe and ap
    // intersect, and we cannot control it. Best we can do is choose where to do it.
    // no difference in cheapness, dV is the same regardless.
    if mode = "nearest" {
        if obt:trueanomaly > 180 {
            return compute_dv(true).
        } else {
            return compute_dv(false).
        }
      
    }
    if mode = "[000,180]" {
        return compute_dv(false).
    }
    if mode = "[180,360]" {
        return compute_dv(true).
    }
    else {
        return null_mnv(mode_error_message+mode).
    }
}

//==================================================||
//      FUNCTION: return_from_a_moon                ||
//--------------------------------------------------||
//
//--------------------------------------------------||
function return_from_a_moon {
    local parameter target_periapsis.
    // requires hyperbolic functionalities 
} 

//==================================================||
//      FUNCTION: change_semimajoraxis              ||
//--------------------------------------------------||
// PURPOSE:                                         ||
//   Changes the semi-major axis of the current     ||
//   orbit to a target value by modifying either    ||
//   the periapsis or apoapsis.                     ||
//                                                  ||
// PARAMETERS:                                      ||
//   target_smja : (scalar) Target semi-major axis  ||
//   mode        : (string) Either "at periapsis",  ||
//                 "at apoapsis", "at altitude", ||
//                 or "after fixed time"            ||
//                                                  ||
// RETURNS:                                         ||
//   A maneuver node that changes the orbit's       ||
//   semi-major axis to the desired value.          ||
//==================================================||
function change_semimajoraxis {
    local parameter target_smja.
    local parameter mode.

    local r_a is obt:apoapsis  + body:radius.
    local r_p is obt:periapsis + body:radius.

    if mode = "at periapsis" {
        set r_a to 2 * target_smja - r_p. 
        set r_a to r_a - body:radius.
        if r_a >= ship:periapsis {
            return change_apoapsis(r_a, mode).
        } else if r_a < ship:periapsis {
            return change_periapsis(r_a, mode).
        }
    }

    if mode = "at apoapsis" {
        set r_p to 2 * target_smja - r_a.
        set r_p to r_p - body:radius.
        if r_p < ship:apoapsis {
            return change_periapsis(r_p, mode).
        } else if r_p >= ship:apoapsis {
            return change_apoapsis(r_p, mode).
        }
        
    }
    if mode = "at altitude" {
        // not implemented yet
    }

    if mode = "after fixed time" {
        // not implemented yet
    }
    return null_mnv(mode_error_message+ mode).
}

//==================================================||
//      FUNCTION: change_resonant_orbit             ||
//--------------------------------------------------||
// PURPOSE:                                         ||
//   Sets a resonant orbit by changing the          ||
//   semi-major axis such that the orbital period   ||
//   becomes a rational multiple of a reference     ||
//   time (e.g., the body's rotation period).       ||
//                                                  ||
// PARAMETERS:                                      ||
//   target_resonance : (scalar) Desired resonance  ||
//                      (e.g 1/2 means 2 orbits per ||
//                      base_time) or change your   ||
//                      orbital period to 1/2 of    || 
//                      your current one            ||
//   mode             : (string) Burn mode —        ||
//                      "at periapsis",             ||
//                      "at apoapsis",              ||
//                      "after fixed time",         ||
//                      or "at altitude"            ||
//   base_time        : (scalar) Reference time     ||
//                      (defaults to orbiting object||
//                      orbital period )            ||
//   value            : (optional scalar) Only used ||
//                      in modes that require a     ||
//                      reference altitude or time. ||
//                                                  ||
// RETURNS:                                         ||
//   A maneuver node that sets the orbit into the   ||
//   desired resonance.                             ||
//==================================================||
function change_resonant_orbit {
    local parameter target_resonance. 
    local parameter mode. 
    local parameter base_time is obt:period. 
    local parameter value is 0. 

    local T_orbit is base_time * target_resonance.
    local a_resonant is (body:mu * T_orbit^2 / (4 * constant:pi^2))^(1/3).
    
    if mode = "at periapsis" {
        return change_semimajoraxis(a_resonant, mode).
    }

    if mode = "at apoapsis" {
        return change_semimajoraxis(a_resonant, mode).
    }

    if mode = "after fixed time" {
        // not implemented yet
    }

    if mode = "at altitude" {
        // not implemented yet
    }

    return null_mnv(mode_error_message+ mode).
}

//==================================================||
//   FUNCTION: change_surface_longitude_of_apsis    ||
//--------------------------------------------------||
//
//--------------------------------------------------||
function change_surface_longitude_of_apsis {
    local parameter apsis.
    local parameter targ_longitude.
    local parameter mode.
    if mode = "at periapsis" {

    }
    if mode = "at apoapsis" {

    }
    if mode = "at longitudinal antipode" {

    }
    if mode = "after fixed time" {

    }
    return null_mnv(mode_error_message+ mode).
}

//**************************************************||
//--------------------------------------------------||
//                 RCS CORRECTIONS                  ||
//--------------------------------------------------||
//**************************************************||
//==================================================||
//      FUNCTION: rcs_corrector                     ||
//--------------------------------------------------||
// PURPOSE:                                         ||
//   Uses RCS to adjust orbital elements (apoapsis, ||
//   periapsis) to a target value by throttling     ||
//   RCS fore/aft translation until a given         ||
//   tolerance is achieved.                         ||
//                                                  ||
// PARAMETERS:                                      ||
//   mode        : "apoapsis", "periapsis",         ||
//                 or "closest approach" (TODO)     ||
//   tgt_value   : Target value (in meters) to      ||
//                 correct the orbital element to.  ||
//   has_sas     : Manual check if the craft has sas 
//                 capabilities or not
//   tolerance   : (optional) Acceptable error in   ||
//                 meters. Default is 10.           ||
//                                                  ||
// NOTES:                                           ||
// - Will automatically orient to PROGRADE.         ||
// - Will not engage if ISP is 0 or if RCS is       ||
//   disabled.                                      ||
//==================================================||
// DEBUG.
function rcs_corrector {
    local parameter mode.
    local parameter tgt_value.
    local parameter has_sas is true.
    local parameter tolerance is 10.
    
    if has_sas {
        sas on.
        set sasmode to "PROGRADE".
    } else {
        sas off.
        lock steering to ship:prograde.
    }
    rcs off.
    wait until vang(ship:facing:vector, ship:velocity:orbit) < 0.25.
    rcs on.
    if mode = "apoapsis" {
        lock error to ship:obt:apoapsis - tgt_value.
        lock errorsign to error/abs(error).
        lock errorMag to abs(error).

        lock rcs_t to max(0.05,min(1, (errorMag)/tgt_value)).
        until errorMag <= tolerance {
            set ship:control:fore to -errorsign*rcs_t.
            wait 0.
        }
        shut_down().
    }
    if mode = "periapsis" {
        lock error to ship:obt:periapsis - tgt_value.
        lock errorsign to error/abs(error).
        lock errorMag to abs(error).

        lock rcs_t to max(0.05,min(1, 1000*(errorMag)/tgt_value)).
        until errorMag <= tolerance {
            set ship:control:fore to -errorsign*rcs_t.
            wait 0.
        }
        shut_down().
    }
    if mode = "closest approach" {
        // not yet implemented.
    }
    else {
        return.
    }
    local function shut_down {
        set ship:control:fore to 0.
        set ship:control:neutralize to true.
        rcs off.
        return.
    }
}

//**************************************************||
//--------------------------------------------------||
//                   EXECUTE NODE                   ||
//--------------------------------------------------||
//**************************************************||

//==================================================||
//      FUNCTION: execute_node                      ||
//--------------------------------------------------||
// PURPOSE:                                         ||
//   Executes the current maneuver node using       ||
//   main engine or RCS. Handles warping, pointing, ||
//   and throttle control to ensure precise burn.   ||
//                                                  ||
// PARAMETERS:                                      ||
//   has_sas     : (optional) If true, enables SAS  ||
//                 to lock to MANEUVER.Default:TRUE ||
//                 Make FALSE if the craft has no   ||
//                 SAS capabilities                 ||
//                 (i.e. small probes)              ||
//   warp_to_node: (optional) If true, warps to     ||
//                 burn start. Default: ON          ||
//   thruster    : (optional) "engine" (default) or ||
//                 "rcs", depending on which        ||
//                 mode of thrust is preferred      ||
//   has_reac_wheels : manual setting if vehicle    ||
//                  has reaction wheels or not      ||
//                                                  ||
// RETURNS:                                         ||
//   none                                           ||
//                                                  ||
// Method  :                                        ||
//   1. If no thrust is available and using engine, ||
//      it stages.                                  ||
//   2. Aligns the ship toward the maneuver node    ||
//      via SAS or manual steering.                 ||
//   3. Computes the half-burn time for accurate    ||
//      warp and burn alignment.                    ||
//   4. Warps close to the maneuver node and begins ||
//      the burn at the proper time.                ||
//   5. Adjusts throttles until the delta-V is      ||
//      nearly depleted.                            ||
//   6. Cleans up the maneuver node and resets SAS  ||
//      orientation.                                ||
//                                                  ||
// NOTES:                                           ||
// - Auto-stages if main engine thrust = 0.         ||
// - Uses burn time estimation for half-offset burn ||
// - Deletes node after execution.                  ||
// - If RCS selected, assumes constant low thrust.  ||
// - Resets steering/SAS after burn completes.      ||
//==================================================||

function execute_node {
    // Define optional parameters with defaults
    local parameter has_sas is true.
    local parameter warp_to_node is true.
    local parameter thruster is "engine".
    local parameter has_reac_wheels is true.

    local mnv_node is node(0,0,0,0).

    // Store the next maneuver node
    if hasnode {
        set mnv_node to nextNode.
    } else { 
        print("[ NODE ERROR ] : No maneuver node"). 
        return.
    }

    rcs off.
    // If ship has no thrust and thruster is engine-based, stage to activate engines
    if ship:availableThrust = 0 and thruster = "engine" {
        stage.
    }

    // Handle orientation: Use SAS or manual steering
    if has_sas {
        unlock steering.
        sas on.
        wait 0.1. // yield a bit. otherwise it does not align to maneuver.
        set sasMode to "MANEUVER". // Use maneuver alignment mode
    } else {
        sas off.
        lock steering to mnv_node:deltav:vec. // Manually aim using delta-V vector
    }

    // Store initial delta-V for later dot product check
    local init_dv to mnv_node:deltav.

    // Initialize throttle control
    local tset to 0.
    lock throttle to tset.
    local max_acc to 0.
    // Calculate half-burn time based on thruster type
    local half_time is 0.
    if thruster = "engine" {
        set half_time to half_burn_time(mnv_node).
        set max_acc to ship:maxthrust / ship:mass.
    }
    if thruster = "rcs" {
        set half_time to rcs_half_burn_time(mnv_node).
        set max_acc to rcs_total_thrust() / ship:mass.
    }

    // Burn state and control flow variables
    local burn_done to false.
    local runmode is "turning to mnv". // Initial state: turn toward maneuver

    // Main control loop for handling node execution phases
    until runmode = "burn done" {
        // Phase 1: Rotate to maneuver node direction
        if runmode = "turning to mnv" {
            if not has_reac_wheels {
                rcs on.
            }
            if vang(ship:facing:vector, mnv_node:deltav:vec) <= 0.5 {
                set runmode to "warping". // Ready to warp once aligned
            }
        }

        // Phase 2: Warp to just before burn if enabled
        if runmode = "warping" {
            if warp_to_node {
                c_warpto(mnv_node:eta - half_time - 10).
                set runmode to "waiting for node".
            }
            else {
                set runmode to "waiting for node".
            }
        }

        // Phase 3: Wait until burn start point
        if runmode = "waiting for node" {
            if mnv_node:eta <= half_time {
                if thruster = "rcs" {
                    rcs on.
                }
                set runmode to "execute burn".
            }
        }

        // Phase 4: Execute the maneuver burn
        if runmode = "execute burn" {
            until burn_done {
                // Estimate appropriate throttle based on remaining delta-V
                set tset to min(mnv_node:deltav:mag / max_acc, 1).

                // Abort burn if the dot product goes negative (overshot)
                if vDot(init_dv, mnv_node:deltav) < 0 {
                    lock throttle to 0.
                    break.
                }

                // Stop burn when remaining delta-V is small
                if mnv_node:deltav:mag < 0.1 {
                    wait until vDot(init_dv, mnv_node:deltav) < 0.5.
                    lock throttle to 0.
                    set burn_done to true.
                }
                wait 0.
            }
            set runmode to "post burn". // Proceed to cleanup
        }

        // Phase 5: Restore SAS and controls after burn
        if runmode = "post burn" {
            rcs off.
            if has_sas {
                set sasMode to "STABILITYASSIST".
            } else {
                lock throttle to 0.
                unlock steering.
                sas on.
                set sasMode to "STABILITYASSIST".
            }
            set runmode to "remove mnv". // Final phase
        }

        // Phase 6: Remove the maneuver node
        if runmode = "remove mnv" {
            remove mnv_node.
            set runmode to "burn done".
        }

        wait 0.
    }
    return. 
}

//**************************************************||
//--------------------------------------------------||
//                    NAVIGATION                    ||
//--------------------------------------------------||
//**************************************************||
//==================================================||
//      FUNCTION: compass_hdg                       ||
//--------------------------------------------------||
// PURPOSE:                                         ||
//   Computes the compass heading of the ship's     ||
//   current facing direction relative to the       ||
//   planetary surface (0° = North, 90° = East).    ||
//                                                  ||
// PARAMETERS:                                      ||
//   (none)                                         ||
//                                                  ||
// RETURNS:                                         ||
//   A scalar angle in degrees [0, 360) representing||
//   the compass heading.                           ||
//                                                  ||
// METHOD:                                          ||
//   Projects the ship's forward vector onto the    ||
//   horizontal plane and calculates the angle      ||
//   relative to north.                             ||
//==================================================||

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
//==================================================||
//      FUNCTION: vectorHeading                     ||
//--------------------------------------------------||
// PURPOSE:                                         ||
//   Calculates the compass heading (angle from     ||
//   true north) of a vector in the ship's surface  ||
//   reference frame.                               ||
//                                                  ||
// PARAMETERS:                                      ||
//   V__ : (vector) Direction vector to analyze     ||
//                                                  ||
// RETURNS:                                         ||
//   Scalar angle in degrees [0, 360) representing  ||
//   the heading of the vector.                     ||
//                                                  ||
// METHOD:                                          ||
//   Projects the vector onto the horizontal plane  ||
//   and computes its angle from true north.        ||
//==================================================||
function vectorHeading{
    local parameter V__.
    set V__ to V__:normalized.
    local north_v is ship:north:vector:normalized.
    local up_v is ship:up:vector.
    local east_v is vcrs(up_v, north_v).
    local hdg is vang(north_v, V__).
    local projhdg is vxcl(up_v,V__).
    if vdot(projhdg,east_v)<0 {
        set hdg to 360 - hdg.
    }
    return hdg.
}

//**************************************************||
//--------------------------------------------------||
//                  FLIGHT VECTORS                  ||
//--------------------------------------------------||
//**************************************************||
function orbital_basis_vectors {
    local z is (latlng(90,0):position - body:position):normalized.
    local x is solarPrimeVector:vec:normalized.
    local y is vCrs(x,z):normalized.
    return list(x,y,z).
}

//**************************************************||
//--------------------------------------------------||
//                   CUSTOM WAIT                    ||
//--------------------------------------------------||
//**************************************************||
// wait function that does not pause the 
// guidance loop, and activates after a certain time 
// is done.
//
// I guess... this can just be done with timers 
// inside the loop?
// Like: 
// timer is 0
// until false {
//     if runmode = 1{
        
//         set runmode to 2.
//     }
//     if runode = 2 {
//         timer = timer + 0.02. // or whatever the time tick is
//         if timer = 5 {
//             // do thing
//         }
//     }
// }
// but idk.
// When then statements, perhaps?
// until false {
//     if runmode = 1{
//      timer = time:seconds + 10
//         set runmode to 2.
//     }
//     if runode = 2 {
//         when time:seconds > timer then {
//             // sum shit
//         set runmode to 3?
//         }
//     }
// }

//**************************************************||
//--------------------------------------------------||
//                   CUSTOM WARP                    ||
//--------------------------------------------------||
//**************************************************||
// 
//==================================================||
//      FUNCTION: c_warpto                          ||
//--------------------------------------------------||
// PURPOSE:                                         ||
//   Provides a custom time warp function to safely ||
//   and smoothly warp to a future universal time.  ||
//   This arose because of the inherent problems    ||
//   and bugs that are associated with KOS's inbuilt||
//   warpto function when it calls KSP's warping in ||
//   the API. It's a bit buggy, it changes the      ||
//   position of the apsides, and quite often, it   ||
//   overshoots since it's going too damn fast, henc||
//   i made a custom warper which slows a staggered ||
//   way to not spoil the warping effect.           ||
//                                                  ||
// PARAMETERS:                                      ||
//   eta__ : (scalar) Seconds from now to time to   ||
//                    warp to.                      ||
//                                                  ||
// RETURNS:                                         ||
//   None.                                          ||
//                                                  ||
// METHOD:                                          ||
//   Determines remaining time to the target and    ||
//   adjusts warp speed in tiers based on thresholds||
//   to ensure a smooth slowdown approaching the    ||
//   destination time. Starts at low warp rates for ||
//   short durations and gradually increases for    ||
//   longer waits. Warp changes are smoothed to     ||
//   avoid jarring transitions.                     ||
//                                                  ||
//   Once the target time is reached, warp is reset ||
//   to real-time (0).                              ||
//==================================================||
function c_warpto {
    local parameter eta__.
    
    local eta_time is time:seconds + eta__.
    local current_warp is 0.
    // pointless to timewarp to a time that close.
    if eta__ < 20 {
        return.
    }
    set warp to 1. // staggered timewarp increase.
    wait 1.        // less buggy.
    set warp to 2.
    wait 1.
    until time:seconds >= eta_time {
        local time_remaining is eta_time - time:seconds.
        // Determine the target warp based on time remaining
        if time_remaining < 7.5 {
            set current_warp to 0.          // Real time
        } else if time_remaining < 30 {
            set current_warp to 1.          // 5x      // 30 s
        } else if time_remaining < 60 {
            set current_warp to 2.          // 10x     // 1  min
        } else if time_remaining < 300 {
            set current_warp to 3.          // 50x     // 5  min
        } else if time_remaining < 1800 { 
            set current_warp to 4.          // 100x    // 30 min
        } else if time_remaining < 10800 {
            set current_warp to 5.          // 1000x   // 3  hrs
        } else if time_remaining < 108000 {
            set current_warp to 6.          // 10,000x // 5  days
        } else if time_remaining > 108000 {
            set current_warp to 7.          // 100000x 
        }
        // else {
        //     // Gradually increase warp up to max (7)
        //     // Technicall max could be higher but ts is safer
        //     if warp < 7 {
        //         set warp to warp + 1.
        //         wait 0.5.
        //     }
        // }

        // Update warp only if different from current
        if warp <> current_warp {
            set warp to current_warp.
        }
        wait 0. // Yield control for smooth behavior
    }
    // Stop warp once target time is reached
    set warp to 0.
}


//**************************************************||
//--------------------------------------------------||
//                INCLINATION ASCENT                ||
//--------------------------------------------------||
//**************************************************||

//==================================================||
//      FUNCTION: inclination_heading               ||
//--------------------------------------------------||
// PURPOSE:                                         ||
//   Calculates the azimuthal launch heading needed ||
//   to achieve a target orbital inclination.       ||
//   If desired inclination is lower than the       ||
//   current latitude, defaults to the current lat  ||
//                                                  ||
//   Applies a correction based on deviation from   ||
//   the current orbit's inclination, and also      ||
//   dynamically updates in flight. lock ship       || 
//   heading to this function at flight time        ||
//                                                  ||
// PARAMETERS:                                      ||
//   target_inclination : Desired inclination (°)   ||
//   mode               : "northbound" (default)    ||
//                        "southbound" launch       ||
//   current_latitude   : (optional) Launch site    ||
//                        latitude; defaults to     ||
//                        ship:latitude             ||
//                                                  ||
// RETURNS:                                         ||
//   Launch heading in degrees                      ||
// Example use: In ascent guidance loop:            ||
// lock heading to inclination_heading(30,"northbound).
//==================================================||

function inclination_heading {
    local parameter target_inclination.
    local parameter mode is "northbound".
    local parameter current_latitude is ship:latitude. // Default to current latitude

    // Ensure inclination is physically achievable at the current latitude
    if current_latitude > target_inclination {
        set target_inclination to current_latitude.
    }

    // Define coordinate basis vectors
    local N is (latlng(90,0):position - body:position):normalized. // "Up" vector toward north pole
    local P is (ship:position - body:position):normalized.         // Position vector from body center to ship
    local U is vxcl(P, N):normalized. // Unit vector pointing eastward (horizontal direction)
    local T is vcrs(P, N):normalized. // Unit vector pointing northward

    // Shorthand
    local i is target_inclination.
    local lat is current_latitude.

    // Calculate angle between launch vector and orbital plane
    local alpha is arcCos(cos(i)/cos(lat)).

    // Calculate two candidate burn directions (east of north or west of north)
    local B1 is U * cos(alpha) - T * sin(alpha).
    local B2 is U * cos(alpha) + T * sin(alpha).

    // Get deviation from target inclination (positive or negative)
    local ang_deviation is (ship:obt:inclination - target_inclination).

    // Determine the sign of deviation
    local cor_sgn is abs(ang_deviation) / (ang_deviation). // +1 or -1

    // Compute a correction term to nudge heading for better inclination convergence
    // This is to counteract the initial velocity given by 
    // planet spin. I'm too lazy to calculate how to counteract it
    // and it's bullshit anw, this makes the same results.

    local correction_term is cor_sgn * 3 * ln(3 * abs(ang_deviation) - 1).

    // Choose launch direction and compute heading
    if mode = "northbound" {
        local V1 is vcrs(P, B1):normalized.         // Velocity direction for northbound launch
        local heading1 is vectorHeading(V1).        // Convert to compass heading
        return heading1 + correction_term.
    }

    if mode = "southbound" {
        local V2 is vcrs(P, B2):normalized.         // Velocity direction for southbound launch
        local heading2 is vectorHeading(V2).        // Convert to compass heading
        return heading2 - correction_term.
    }
}

//**************************************************||
//--------------------------------------------------||
//             INTERPLANETARY TRANSFERS             ||
//--------------------------------------------------||
//**************************************************||

//==================================================||
//      FUNCTION: lambert_solver                    ||
//--------------------------------------------------||
// PURPOSE:                                         ||
//   Solves Lambert’s problem using the universal   ||
//   variable formulation to compute the initial    ||
//   and final velocity vectors for a transfer      ||
//   orbit between two position vectors in a given  ||
//   time of flight.                                ||
//                                                  ||
// METHOD:                                          ||
//   Uses the universal variables method to solve   ||
//   the time of flight equation iteratively via    ||
//   bisection on the universal anomaly squared     ||
//   (psi), adjusting c2 and c3 functions based on  ||
//   the sign of psi.                               ||
//                                                  ||
// PARAMETERS:                                      ||
//   r1  : (vector) Initial position vector         ||
//   r2  : (vector) Final position vector           ||
//   tof : (scalar) Time of flight for the          ||
//         transfer [seconds]                       ||
//   mu  : (scalar) Gravitational parameter         ||
//         [m^3/s^2]                                ||
//   t_m : (scalar) Transfer direction (+1 = short  ||
//         way, -1 = long way)                      ||
//                                                  ||
// RETURNS:                                         ||
//   A list containing:                             ||
//     - v1 : (vector) Velocity at r1 to start the  ||
//            transfer                              ||
//     - v2 : (vector) Velocity at r2 upon arrival  ||
//                                                  ||
//   If the solver fails to converge, returns two   ||
//   zero vectors                                   ||
//==================================================||
function lambert_solver{
    
    // A lambert solver utilizing universal variable formulation
    // The algorithm was adapted from this paper: 
    // https://www.researchgate.net/publication/236012521_Lambert_Universal_Variable_Algorithm
    // I wont even bother commenting and explaing what this shit does
    // I don't understand it either, I just adapted the algorithm from the paper

    // radius vectors are measured relative to center body, 
    // i.e., sun (if interplanetary) or kerbin (if interlunar) is [0,0,0].

    local parameter r1.   // position when launching
    local parameter r2.   // position at arrival
    local parameter tof.  // time of flight
    local parameter mu.   // just body:mu
    local parameter t_m.  // transfer direction. +1 for shortway, -1 for longway

    local parameter psi is 0.
    local parameter psi_u is 4 * constant():pi^2.
    local parameter psi_l is - 4 * constant():pi.
    local parameter max_iter is 1000.
    local parameter tol is 1e-12.
    
    local function c_2{
        local parameter z.

        local function cosh {
            local parameter x.
            return (constant:e^(x) + constant:e^ (-x)) / 2.
        }
        if z > 0 {
            return (1 - cos(constant:radtodeg * sqrt(z))) / z.
        }
        if z < 0 {
            return (1 - cosh(-z)) / -z.
        }
        else {
            return 1/2 .
        }
    }

    local function c_3 {
        local parameter z.
        local function sinh{
            local parameter x.
            return (constant:e^(x) - constant:e^ (-x)) / 2.
        }
        if z > 0 {
            return (sqrt(z) - sin(constant:radtodeg * sqrt(z))) / sqrt(z)^3.
        }
        if z < 0 {
            return (sinh(sqrt(-z)) - sqrt(-z)) / sqrt(-z)^3.
        }
        else {
            return 1/6 .
        }
    }

    local mag_r1 to r1:mag.
    local mag_r2 to  r2:mag.

    local gamma to vdot(r1,r2) / (mag_r1 * mag_r2).
    local A to t_m * sqrt(mag_r1 * mag_r2 * (1  + gamma)).

    local B to 0.
    local chi3 to 0.
    local tof_ to 0.

    if A = 0 {
        print "Orbit cannot exist".
        return list(v(0,0,0), v(0,0,0)).
    }

    local c2 to 0.5.
    local c3 to 1/6.

    local solved to false.

    from { local i is 0.} until i >= max_iter step { set i to i + 1.} do {
        set B to mag_r1 + mag_r2 + A * (psi * c3 - 1) / sqrt(c2).

        if ((A > 0) and (B < 0)) {
            set psi_l to psi_l + constant:pi.
        }

        set chi3 to ( B / c2 )^1.5.
        set tof_ to (chi3 * c3 + A * sqrt(B)) / sqrt(mu).

        if abs(tof - tof_) < tol {
            set solved to true.
            break.
        }

        if tof_ < tof {
            set psi_l to psi.
        } else {
            set psi_u to psi.
        }

        set psi to (psi_u + psi_l)/2.
        set c2 to c_2(psi).
        set c3 to c_3(psi).
    }

    if not solved {
        print "Did not converge".
        return list(v(0,0,0), v(0,0,0)).
    }

    local f to 1 - B / mag_r1.
    local g to A * sqrt( B / mu).
    local g_dot to 1 - B / mag_r2.
    local f_dot to (f * g_dot - 1) / g.

    local v1 to (r2 - f * r1) / g.
    local v2 to f_dot * r1 + g_dot * v1.

    return list(v1,v2).
}
// make a function for porkchop plotting, 
// targeting planets so and so
// translation of the porchop plot into an actual maneuver
// then one that returns a meneuver node

// PLANNED STUFF
//**************************************************||
//--------------------------------------------------||
//                LANDING FUNCTIONS                 ||
//--------------------------------------------------||
//**************************************************||

//**************************************************||
//--------------------------------------------------||
//                  LINEAR DESCENT                  ||
//--------------------------------------------------||
//**************************************************||

//**************************************************||
//--------------------------------------------------||
//                    HOVER PIDS                    ||
//--------------------------------------------------||
//**************************************************||

//**************************************************||
//--------------------------------------------------||
//              RENDEZVOUS AND DOCKING              ||
//--------------------------------------------------||
//**************************************************||

function fine_tune_closest_approach_to_target {
    local parameter target_distance.
}

function intercept_target_at_chosen_time {
    local parameter time_after_burn. // time after burn to intercept target
    local parameter after_time. // how many seconds from NOW to execute the mode. 
}

function hohmann_transfer_to_target {
    // vessel eccentricity must be < 0.01 
    // target eccentricity must be < 0.01
}

function intercept_target {
    local parameter mode.
    local parameter pathlen is "short way". // can be long way.

    // we're gonna lambert solver this shit.
    if mode = "lowest dV" {
            // lowest possible delta v. // within one orbit of target body .
    }
    if mode = "as soon as possible" {
            // lowest possible delta v 30 s from now.

    }
}

function dock_to_target {
    local parameter target_part.
    local parameter approach_speed.

}
//==================================================||
//      FUNCTION: match_planes_with_target          ||
//--------------------------------------------------||
// PURPOSE:                                         ||
//   Computes the maneuver required to match the    ||
//   orbital plane of the active vessel with that   ||
//   of the currently targeted vessel.              ||
//                                                  ||
// PARAMETERS:                                      ||
//   mode : A string determining where the plane    ||
//          change is executed. Supported modes:    ||
//                                                  ||
//          - "at AN" : Perform burn at relative    ||
//                      ascending node.             ||
//          - "at DN" : Perform burn at relative    ||
//                      descending node.            ||
//          - "at nearest node" : Chooses the       ||
//                      closest of relative AN or DN||
//          - "at cheapest node" : Chooses the node ||
//                      requiring less delta-V.     ||
//          - "at altitude"                         ||
//          - "after fixed time"                    ||
//                                                  ||
// RETURNS:                                         ||
//   A manueuver node                               ||
//                                                  ||
//   If no target is set or mode is unsupported,    ||
//   returns a null maneuver                        ||
//                                                  ||
// METHOD:                                          ||
//   Computes orbit normals, finds AN and DN,       ||
//   computes required inclination change, and      ||
//   estimates delta-V using vector geometry and    ||
//   the cosine law for inclination changes.        ||
//==================================================||
//   change to use rotate_vector()
function match_planes_with_target {
    local parameter mode.
    
    if not hastarget {
        return null_mnv("[ TARGET ERROR ] : No target detected. Please set target").
    }

    local p0 is body:position.
    local r1 is ship:position - p0.         // radius vector
    local v1 is ship:velocity:orbit.        // velocity vector
    local h1 is vcrs(v1,r1).                // angular momentum vector
    local e1 is (vcrs(h1,v1)/body:mu - r1:normalized). // eccentricity vector, points to periapsis.

    local r2 is target:position - p0.       // target radius
    local v2 is target:velocity:orbit.      // target vel
    local h2 is vcrs(v2,r2).                // target angular momentum

    local an_vec is vcrs(h1,h2).            // vector that points to the relative ascending node.
    local AN_ta is vang(e1,an_vec).         // true anomaly of relative ascending node
    if vdot(an_vec,vcrs(e1,h1)) < 0 {
        set AN_ta to 360-AN_ta.
    }
    local DN_ta is angle_wrap(AN_ta - 180). // true anomaly of relative descending node
    local delta_inc is - vang(h1,h2).         // difference of inclination
    // reuse change_inclination code.
    local t_an is time_from_true_anomaly(AN_ta) + time:seconds.
    local t_dn is time_from_true_anomaly(DN_ta) + time:seconds.
    // Compute velocity vectors at each node
    local vel_vec_an is velocityat(ship, t_an):orbit.
    local vel_vec_dn is velocityat(ship, t_dn):orbit.
    // Compute required delta-v magnitude at each node
    local delta_v_mag_an is 2 * vel_vec_an:mag * sin(abs(delta_inc) / 2).
    local delta_v_mag_dn is 2 * vel_vec_dn:mag * sin(abs(delta_inc) / 2).
    // helper function to calculate delta V.
    local function compute_dv {
        local parameter isAN.
        local ut is t_an.
        local rad_vector is positionAt(ship,t_an) - body:position.
        local vel_vector is vel_vec_an.
        if not isAN {
            set rad_vector to positionAt(ship,t_dn) - body:position.
            set vel_vector to vel_vec_dn.
            set delta_inc to - delta_inc.
            set ut to t_dn.
        } 
        local rotVector is rotate_vector(vel_vector, delta_inc, rad_vector).
        local deltaV is rotVector - vel_vector.
        return cartesian_to_TRN(deltaV, ut).
    }
    // Decision logic by mode
    if mode = "at AN" {
        return compute_dv(true).
    }
    if mode = "at DN" {
        return compute_dv(false).
    }
    if mode = "at nearest node" {
        if t_an < t_dn {
            return compute_dv(true).
        } else {
            return compute_dv(false).
        }
    }
    if mode = "at cheapest node" {
        if delta_v_mag_an < delta_v_mag_dn {
            return compute_dv(true).
        } else {
            return compute_dv(false).
        }
    }
    return null_mnv(mode_error_message+ mode).
}

function match_velocities_with_target {
    local parameter mode.
    if mode = "at closest approach" {

    }
    if mode = "after fixed time" {

    }
    return null_mnv().
}

//**************************************************||
//--------------------------------------------------||
//               BALLISTIC TARGETING                ||
//--------------------------------------------------||
//**************************************************||
// for ballistic missiles and stuff
// after launching missile, directs the guidance
// system to go to a certain location
// in the planetary surface
// and adjusts shit dynamically

//**************************************************||
//--------------------------------------------------||
//                WAYPOINT GUIDANCE                 ||
//--------------------------------------------------||
//**************************************************||
// waypoint guide stuff

//**************************************************||
//--------------------------------------------------||
//                 PLANE AUTOPILOT                  ||
//--------------------------------------------------||
//**************************************************||
// set altitude
// set vertical speed
// set roll
// set target speed

//**************************************************||
//--------------------------------------------------||
//                 SPECIAL POINTS                   ||
//--------------------------------------------------||
//**************************************************||

function subsolar_point {
    // Returns the coordinates on the surface of the current body that is directly under the sun.
    local sun_ll is body:geoPositionof(body("Sun"):position).
    local sun_lat is sun_ll:lat.
    local sun_long is sun_ll:lng.
    return list(sun_lat,sun_long).
}

//LAUNCH PAD
//RUNWAYS
//we can probably just reuse kslib.
// but, hey, make your own.


// TODO 
// custom warp                                  <done>
// rcs total deltaV                             <done>
// lambert solver                               <done>
// match planes with target                     <done>
// subsolar point                               <done>  
// chage eccentricity                           <done>
// change apoapsis / periapsis                  <done>

// plane guidance - set altitude
// plane guidance - set vertical speed
// plane guidance - set roll
// plane guidance - set target speed
// hover script
// landing script
// communication of vessels
// porkchop plotting    
// inflight emergency guidance les
// docking
// custom wait
// ballistic targeting
// target intercept functions
// at altitude and at certain time modes
// make at altitude the nearest altitude.
// return from a moon


// SATURN V LAUNCH
// saturn v abort modes.
// free return trajectory
// transposition and docking
// LM descent 
// rendezvouz and docking.

function vector_display {
    local parameter vector.
    local parameter nround is 3.
    local x is round(vector:x,nround).
    local y is round(vector:y,nround).
    local z is round(vector:z,nround).
    return x + " " + y + " " + z.
}

// function number_format {
//     // FIX THIS SHIT FIX THIS SHIT
//     local parameter float.
//     local parameter nround.
    
//     local sign is float / abs(float).

// }
    // vecdraws!
    // vecDraw(body:position, Zv*1e6, rgb(1,0,0),"Z",1,true,0.2,true,false). // Z basis
    // vecDraw(body:position, Xv*1e6, rgb(0,0,1),"X",1,true,0.2,true,false). // X basis
    // vecDraw(body:position, Yv*1e6, rgb(1,0,0),"Y",1,true,0.2,true,false). // Y basis