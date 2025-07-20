//**************************************************||
//==================================================||
//==================================================||
//            MANEUVER FUNCTIONS LIBRARY            ||
//==================================================||
//==================================================||
//**************************************************||
// cc. Vercil Juan aka SilverNuke                   ||
// kOS Script Collection                            ||
// 2024 - 2025                                      ||
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
//  Last update:  July 20, 2025                     ||
//--------------------------------------------------||
//==================================================||
//**************************************************||
//--------------------------------------------------||
@lazyGlobal off.          //                        ||
set config:ipu to 2000.   //                        ||  
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
//           (ISP) of the vessel, weighted by each  ||                  
//           engine's current thrust contribution.  ||
//                                                  ||
// Assumptions:                                     ||
//   - Only considers engines that are currently    ||
//     providing thrust                             ||
//     (availablethrust > 0) and have a valid       ||
//     ISP (isp > 0).                               ||
//   - The weighted ISP is calculated as a          ||
//     thrust-weighted average:                     ||
//     ISP_eff = Σ(Thrust_i × ISP_i) / Σ(Thrust_i)  ||
//                                                  ||
// Parameters: None                                 ||
//                                                  ||
// Returns:                                         ||
//   - weighted_isp : The effective ISP (in seconds)||
//     of all currently firing engines, weighted by ||
//     their individual thrust.                     ||
//   - Returns 0 if no valid engines are producing  ||
//     thrust.                                      ||
// =================================================||
function ship_isp {
    local engineList to list().    // Temporary list to collect engines
    list engines in engineList.    // Populates engineList with all vessel engines

    local total_thrust to 0.       // Sum of available thrusts of valid engines
    local weighted_isp to 0.       // Weighted ISP accumulator

    for engine in engineList {
        // Only include engines that are firing and have valid ISP
        if engine:availablethrust > 0 and engine:isp > 0 {
            set total_thrust to total_thrust + engine:availablethrust.
            set weighted_isp to weighted_isp + (engine:availablethrust * engine:isp).
        }
    }
    // If there is total thrust, compute the weighted ISP
    if total_thrust > 0 {
        set weighted_isp to weighted_isp / total_thrust.
    } else {
        return 0.  // No engines firing, return 0 ISP
    }
    return weighted_isp.
}

// =====================================================================
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
//                                                  ||
// METHOD:                                          ||
//   Uses the Tsiolkovsky equation:                 ||
//     ve = ISP × g0                                ||
//     mf = m0 × exp(–Δv / ve)                      ||
//     dm = m0 – mf                                 ||
//     ṁ = Thrust / ve                              ||
//     burn_time = dm / ṁ                           ||
//==================================================||

function total_burn_time {
    local parameter mnv.

    local deltav is mnv:deltav:mag.
    local Isp is ship_isp().
    if Isp = 0 {
        return 0.
    }

    local ve is Isp * constant:g0.
    local mdot is ship:maxThrust / ve.

    local m0 is ship:mass.
    local mf is m0 * constant:e^(-deltav / ve).
    local dm is m0 - mf.

    local t is dm / mdot.
    return t.
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

    local deltav is mnv:deltav:mag.
    local deltav_2 is deltav / 2.

    local Isp is ship_isp().
    if Isp = 0 {
        return 0.
    }

    local ve is Isp * constant:g0.
    local mdot is ship:maxThrust / ve.

    local m0 is ship:mass.
    local mf is m0 * constant:e^(-deltav_2 / ve).
    local dm is m0 - mf.

    local t is dm / mdot.
    return t.
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
    local rcsList is list().
    list rcs in rcsList.
    local total_thrust is 0.
    local weighted_isp is 0.
    for rcs_ in rcsList {
        if rcs_:availableThrust > 0 
        and rcs_:availableThrust > 0 
        and rcs_:foreenabled{
            set total_thrust to 
                total_thrust + rcs_:availableThrust.
            set weighted_isp to 
                weighted_isp + (rcs_:availableThrust * rcs_:isp).
        }
    }
    if total_thrust > 0 {
        return weighted_isp / total_thrust.
    } else {
        return 0.
    }
}

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

    local deltav is mnv:deltav:mag.

    local rcs_total_thrust_ is rcs_total_thrust().
    local Isp is rcs_isp().
    if Isp = 0 or rcs_total_thrust = 0 {
        return 0.
    }
    
    local ve is Isp * constant:g0.
    local mdot is rcs_total_thrust_ / ve.
    local m0 is ship:mass.
    local mf is m0 * constant:e^(-deltav / ve).
    local dm is m0 - mf.
    local t is dm / mdot.
    return t.
}

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
//                                                  ||
// METHOD:                                          ||
//   Applies the Tsiolkovsky rocket equation using  ||
//   half the delta-V value from the maneuver node. ||
//==================================================||

function rcs_half_burn_time {
    local parameter mnv.

    local deltav is mnv:deltav:mag.
    local deltav_2 is deltav / 2.

    local rcs_total_thrust_ is rcs_total_thrust().
    local Isp is rcs_isp().
    if Isp = 0 or rcs_total_thrust_ = 0 {
        return 0.
    }
    local ve is Isp * constant:g0.
    local mdot is rcs_total_thrust_ / ve.
    local m0 is ship:mass.
    local mf is m0 * constant:e^(-deltav_2 / ve).
    local dm is m0 - mf.
    local t is dm / mdot.
    return t.
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
    // Compute current ship weight (mass × gravity)
    local ship_weight is ship:mass * g0.
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
//     - "altitude" → adds to body:radius           ||
//     - "radius"   → used as-is                    ||
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
    local parameter altitude_.           // input value (altitude or radius)
    local parameter mode is "altitude".  // mode selector
    local r__ is 0.                      // orbital radius placeholder
    if mode = "altitude" {
        set r__ to body:radius + altitude_.
    }
    else if mode = "radius" {
        set r__ to altitude_.
    } else {
        print "WRONG CIRCVEL SETTING".
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
//==================================================//
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
//==================================================//
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
//   Converts an orbital radius (altitude) to the   ||
//   corresponding true anomaly.                    ||
//                                                  ||
// PARAMETERS:                                      ||
//   r_ : (scalar) Orbital radius above surface     ||
//                                                  ||
// RETURNS:                                         ||
//   True anomaly in degrees [0, 360].              ||
//==================================================//
function radius_to_true_anomaly {
    local parameter r_.
    local r__ is r_ + body:radius. 
    local a is ship:obt:semimajoraxis.
    local e is ship:obt:eccentricity.
    local cos_ta to (a * (1 - e^2) / r__ - 1) / e.
    local ta to arccos(cos_ta).
    return ensure_angle_positive(ta).
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
//==================================================//
function true_anomaly_to_eccentric_anomaly {
    local parameter ta.
    local e is ship:obt:eccentricity.
    local ea to arctan2(
        sqrt(1 - e^2) * sin(ta), 
        e + cos(ta)
    ).
    return ensure_angle_positive(ea).
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
//==================================================//
function eccentric_anomaly_to_mean_anomaly {
    local parameter ea.
    local e is ship:obt:eccentricity.
    local ea_rad to ea * constant:degtorad.
    local ma_rad to ea_rad - e * sin(ea).
    return ensure_angle_positive(ma_rad * constant:radtodeg).
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
    local parameter ma.                          // Input Mean Anomaly (deg)
    local e is ship:obt:eccentricity.            // Orbital eccentricity
    local ma_rad to ma * constant:degtorad.      // Convert MA to radians

    local ea_rad to ma_rad.                      // Initial guess: EA = MA
    local ea_deg to ea_rad * constant:radtodeg.  // Also track EA in degrees
    local diff to 1.    
    local tol is 1e-12.                         
    // Newton-Raphson iteration to solve MA = EA - e*sin(EA)
    until diff < tol {
        local new_ea_rad to ea_rad - (
            ea_rad - e * sin(ea_deg) - ma_rad
        ) / (1 - e * cos(ea_deg)).

        set diff to abs(new_ea_rad - ea_rad).
        set ea_rad to new_ea_rad.
        set ea_deg to ea_rad * constant:radtodeg.
    }
    // Wrap angle to [0, 360)
    return ensure_angle_positive(ea_deg).
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
//==================================================//
function eccentric_anomaly_to_true_anomaly {
    local parameter ea.
    local e is ship:obt:eccentricity.
    local ta to arctan2(
        sqrt(1 - e^2) * sin(ea), 
        cos(ea) - e
    ).
    return ensure_angle_positive(ta).
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
//==================================================//
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
    return t.
}

//==================================================||
//      FUNCTION: ensure_angle_positive             ||
//--------------------------------------------------||
// PURPOSE:                                         ||
//   Ensures angle is within range [0, 360).        ||
//                                                  ||
// PARAMETERS:                                      ||
//   value : (scalar) Angle in degrees              ||
//                                                  ||
// RETURNS:                                         ||
//   Angle in degrees within [0, 360).              ||
//==================================================//
function ensure_angle_positive {
    local parameter value.
    if value < 0 {
        return 360 + value.
    }
    return value.
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
//     • eta  : Time from now until burn (s)        ||
//     • dv_r : Radial delta-V (m/s)                ||
//     • dv_n : Normal delta-V (m/s)                ||
//     • dv_p : Prograde delta-V (m/s)              ||
//                                                  ||
// BEHAVIOR:                                        ||
//   - If eta < 0 and all delta-V components are 0, ||
//     a warning is printed.                        ||
//   - Otherwise, the maneuver is scheduled.        ||
//==================================================||

function create_node {
    local parameter mnv_node.

    local eta____ is mnv_node[0] + time:seconds.
    local radial_ is mnv_node[1].
    local normal_ is mnv_node[2].
    local prograd is mnv_node[3].

    // Warn if maneuver node is null_mnv()
    if mnv_node[0] < 0 {
        if radial_ = 0 and normal_ = 0 and prograd = 0 {
            print("[ ERROR, UNABLE TO MAKE MANEUVER NODE ]").
            return.
        }
    }

    // Construct and add the maneuver node
    local maneuver_node to node(
        eta____,
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
        eta____,
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

global mode_error_message is "[ ERROR ] : Invalid mode given. Mode used is: ".

function null_mnv {
    local parameter errormsg is " ".
    local parameter print_error is true.
    if print_error {
        print(errormsg).
    }
    return list(-1, 0, 0, 0).
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
//           • "at altitude" → target altitude (m)  ||
//           • "after fixed time" → delay time (s)  ||
//                                                  ||
// RETURNS:                                         ||
//   A maneuver node vector [eta, radial, normal,   ||
//   prograde] or null_mnv() if operation fails.    ||
//==================================================||
function circularize {
    parameter mode.
    parameter value is 0. // Optional mode-specific value

    // ------------------------
    // Mode 1: Circularize at Periapsis
    if mode = "at periapsis" {
        local periapsis_dV is 
            orbital_velocity_circular(ship:periapsis) -
            vis_viva_equation(ship:periapsis, ship:orbit:semimajoraxis).
        return list(eta:periapsis, 0, 0, periapsis_dV).
    }

    // ------------------------
    // Mode 2: Circularize at Apoapsis
    if mode = "at apoapsis" {
        local apoapsis_dV is 
            orbital_velocity_circular(ship:apoapsis) -
            vis_viva_equation(ship:apoapsis, ship:orbit:semimajoraxis).
        return list(eta:apoapsis, 0, 0, apoapsis_dV).
    }

    // ------------------------
    // Helper Function:
    // Computes the full delta-v vector (radial, normal, prograde)
    // needed to circularize at a specific future time.
    local function compute_circularization_dv {
        parameter future_t.

        // Predict ship's position and velocity at future time
        local pos_vec is positionat(ship, future_t) - body:position.
        local vel_vec is velocityat(ship, future_t):orbit.

        // Desired circular velocity at the predicted radius
        local circ_vel is orbital_velocity_circular(pos_vec:mag, "radius").

        // Construct perifocal (RTN) frame vectors
        local radial_vec is pos_vec:normalized.
        local prograde_vec is vxcl(radial_vec, vel_vec):normalized.
        local normal_vec is vcrs(prograde_vec, radial_vec):normalized.

        // Decompose velocity into perifocal frame
        local radial_v is vdot(vel_vec, radial_vec).
        local prograde_v is vdot(vel_vec, prograde_vec).
        local normal_v is vdot(vel_vec, normal_vec).

        // Compute required change in velocity
        local delta_v is circ_vel - prograde_v.

        // Desired dv vector in perifocal frame
        local dv_vec is (
            (-radial_v) * radial_vec + 
            (-normal_v) * normal_vec + 
            delta_v * prograde_vec
        ).

        // Transform to ship's velocity frame
        local v_frame_prograde is vel_vec:normalized.
        local v_frame_normal is vcrs(v_frame_prograde, ship:up:vector):normalized.
        local v_frame_radial is vcrs(v_frame_normal, v_frame_prograde):normalized.

        // Project dv vector onto velocity frame axes
        local dv_r is vdot(dv_vec, v_frame_radial).
        local dv_n is vdot(dv_vec, v_frame_normal).
        local dv_p is vdot(dv_vec, v_frame_prograde).

        return list(future_t - time:seconds, dv_r, dv_n, dv_p).
    }

    // ------------------------
    // Mode 3: Circularize at Specified Altitude
    if mode = "at altitude" {
        local target_alt is value.

        // Check if altitude is reachable
        if (target_alt < ship:obt:periapsis) or (target_alt > ship:obt:apoapsis) {
            return null_mnv("Altitude unreachable").
        }

        // Determine true anomaly and time to reach target altitude
        local target_true_anomaly is radius_to_true_anomaly(target_alt).
        local t_ is time_from_true_anomaly(target_true_anomaly).
        local future_t is time:seconds + t_.

        return compute_circularization_dv(future_t).
    }

    // ------------------------
    // Mode 4: Circularize After Fixed Time
    if mode = "after fixed time" {
        local t_ is value.
        local future_t is time:seconds + t_.

        return compute_circularization_dv(future_t).
    }

    // ------------------------
    // Default Fallback: Invalid mode or failure
    return null_mnv(mode_error_message+ mode).
}

//==================================================||
//      FUNCTION: change_eccentricity              ||
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
//                        - "at an altitude"        ||
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
    local r_a is obt:apoapsis  + body:radius.
    local r_p is obt:periapsis + body:radius. 
    if mode = "at periapsis"{
        set r_a to r_p * (1 + ecc) / (1 - ecc).
        return change_apoapsis(r_a - body:radius, mode).
    }
    if mode = "at apoapsis" {
        set r_p to r_a * (1 - ecc) / (1 + ecc).
        return change_periapsis(r_p - body:radius, mode).
    }
    if mode = "after fixed time"{

    }
    if mode = "at an altitude" {

    }
    else {
        return null_mnv(mode_error_message+ mode).
    }
}
//==================================================||
//      FUNCTION: change_apoapsis                   ||
//--------------------------------------------------||
//
//--------------------------------------------------||
function change_apoapsis {
    local parameter target_apoapsis.
    local parameter mode.
    if mode = "at periapsis" {
        if target_apoapsis < ship:periapsis {
            return null_mnv(
                "target apoapsis should be "+
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
            eta:periapsis, 
            0,
            0, 
            periapsis_dV
        ).
    }
    if mode = "at apoapsis" {
        if target_apoapsis < ship:apoapsis {
            return null_mnv(
                "target apoapsis must be "+
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
            eta:apoapsis, 
            0,
            0, 
            apoapsis_dV
        ).
    }
    if mode = "after fixed time" {

    }
    if mode = "at equatorial DN" {

    }
    if mode = "at equatorial AN" {

    }
    else {
        return null_mnv(mode_error_message+ mode).
    }
}

//==================================================||
//      FUNCTION: change_periapsis                  ||
//--------------------------------------------------||
//
//--------------------------------------------------||
function change_periapsis {
    local parameter target_periapsis.
    local parameter mode.
    local parameter value is 0.
    if mode = "at apoapsis" {
        if target_periapsis > ship:apoapsis {
            return null_mnv(
                "target periapsis should be"+ 
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
            eta:apoapsis,
            0,
            0, 
            apoapsis_dV
        ).
    }
    if mode = "at periapsis" {
        if target_periapsis > ship:periapsis {
            return null_mnv(
                "target periapsis must be smaller"+
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
            eta:periapsis,
            0,
            0,
            periapsis_dV
        ).
    }
    if mode = "after a fixed time" {

    }
    if mode = "at equatorial DN" {

    }
    if mode = "at equatorial AN" {
        
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
//     - "after fixed time" : (not implemented)     ||
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
    parameter target_inclination.
    parameter mode.

    local current_inclination is obt:inclination.
    local delta_inc is target_inclination - current_inclination.
    // Compute true anomalies of the nodes
    local an_ta is 360 - obt:argumentofperiapsis.
    local dn_ta is 180 - obt:argumentofperiapsis.
    // Compute times to each node
    local t_an is time_from_true_anomaly(an_ta).
    local t_dn is time_from_true_anomaly(dn_ta).
    // Compute velocity vectors at each node
    local vel_vec_an is velocityat(ship, time:seconds + t_an):orbit.
    local vel_vec_dn is velocityat(ship, time:seconds + t_dn):orbit.
    // Compute required delta-v magnitude at each node
    local delta_v_mag_an is 2 * vel_vec_an:mag * sin(abs(delta_inc) / 2).
    local delta_v_mag_dn is 2 * vel_vec_dn:mag * sin(abs(delta_inc) / 2).
    // Helper function to compute maneuver components
    local function compute_dv {
        local parameter mag.
        local parameter d_inc.
        local parameter is_an. // true for AN, false for DN

        // Compute delta angle based on whether inclination is increasing or decreasing
        local sign is 1. if d_inc < 0 {set sign to -1.}
        local base_ang is 90 + abs(d_inc) / 2.
        local delta_ang is sign * base_ang.

        // Invert sign for DN since it's on the opposite side of orbit
        if not is_an {
            set delta_ang to -delta_ang.
        }

        // Return maneuver vector components
        local dv_r is 0.
        local dv_p is mag * cos(delta_ang).
        local dv_n is mag * sin(delta_ang).
        return list(dv_r, dv_n, dv_p).
    }
    // Decision logic by mode
    if mode = "at AN" {
        local dv is compute_dv(delta_v_mag_an, delta_inc, true).
        return list(t_an, dv[0], dv[1], dv[2]).
    }
    if mode = "at DN" {
        local dv is compute_dv(delta_v_mag_dn, delta_inc, false).
        return list(t_dn, dv[0], dv[1], dv[2]).
    }
    if mode = "at nearest node" {
        if t_an < t_dn {
            local dv is compute_dv(delta_v_mag_an, delta_inc, true).
            return list(t_an, dv[0], dv[1], dv[2]).
        } else {
            local dv is compute_dv(delta_v_mag_dn, delta_inc, false).
            return list(t_dn, dv[0], dv[1], dv[2]).
        }
    }
    if mode = "at cheapest node" {
        if delta_v_mag_an < delta_v_mag_dn {
            local dv is compute_dv(delta_v_mag_an, delta_inc, true).
            return list(t_an, dv[0], dv[1], dv[2]).
        } else {
            local dv is compute_dv(delta_v_mag_dn, delta_inc, false).
            return list(t_dn, dv[0], dv[1], dv[2]).
        }
    }
    if mode = "at altitude" {
        // not yet implemented
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
//
//--------------------------------------------------||
function change_LAN {
    local parameter new_lan.
    local parameter mode.
    local parameter value is 0.
    
    if mode = "at periapsis" {

    }
    if mode = "at apoapsis" {

    }
    if mode = "after fixed time" {

    }
    return null_mnv(mode_error_message+mode).
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
    if mode = "at expected time" {

    }
    if mode = "at an altitude" {

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
//                 "at apoapsis", "at an altitude", ||
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

    if mode = "at an altitude" {
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
        // not implemented
    }

    if mode = "at altitude" {
        // not implemented
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
//   tolerance   : (optional) Acceptable error in   ||
//                 meters. Default is 10.           ||
//                                                  ||
// NOTES:                                           ||
// - Will automatically orient to PROGRADE.         ||
// - Will not engage if ISP is 0 or if RCS is       ||
//   disabled.                                      ||
//==================================================||
function rcs_corrector {
    local parameter mode.
    local parameter tgt_value.
    local parameter tolerance is 10.
    
    sas on.
    rcs off.
    set sasmode to "PROGRADE".
    wait until vang(ship:facing:vector, ship:velocity:orbit:vec) < 0.25.
    rcs on.
    if mode = "apoapsis" {
        lock error to ship:obt:apoapsis - tgt_value.
        lock errorsign to error/abs(error).
        lock errorMag to abs(error).

        lock rcs_t to max(0.05,min(1, (errorMag)/tgt_value)).
        until errorMag <= tolerance {
            set ship:control:fore to -errorsign*rcs_t.
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

    // Store the next maneuver node
    local mnv_node to nextNode.
    rcs off.
    // If ship has no thrust and thruster is engine-based, stage to activate engines
    if ship:availableThrust = 0 and thruster = "engine" {
        stage.
    }

    // Handle orientation: Use SAS or manual steering
    if has_sas {
        unlock steering.
        sas on.
        set sasMode to "MANEUVER". // Use maneuver alignment mode
    }
    if not has_sas {
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
        set max_acc to 1.5 * ship:maxthrust / ship:mass.
    }
    if thruster = "rcs" {
        set half_time to rcs_half_burn_time(mnv_node).
        set max_acc to 1.5 * rcs_total_thrust() / ship:mass.
        print(half_time + " " + max_acc).
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
    local z is body:north:vector:normalized.
    local x is solarPrimeVector:vec:normalized.
    local y is vCrs(z,x):normalized.
    return list(x,y,z).
}
//**************************************************||
//--------------------------------------------------||
//                   CUSTOM WAIT                    ||
//--------------------------------------------------||
//**************************************************||
// wait function that does not pause the 
// guidance loop

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
//   This arised because of the inherent problems   ||
//   and bugs that are associated with KOS's inbuilt||
//   warpto function, which emulates KSP's warp here||
//   function. It's a bit buggy, it changes the     ||
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
    parameter eta__.
    
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
            set current_warp to 1.          // 5x // 30 s
        } else if time_remaining < 60 {
            set current_warp to 2.          // 10x // 1 min
        } else if time_remaining < 300 {
            set current_warp to 3.          // 50x // 5 min
        } else if time_remaining < 1800 { 
            set current_warp to 4.          // 100x // 30 min
        } else if time_remaining < 10800 {
            set current_warp to 5.          // 1000x // 3 hrs
        } else if time_remaining < 108000 {
            set current_warp to 6.          // 10,000x // 5 days
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

    parameter r1. 
    parameter r2.
    parameter tof.
    parameter mu.
    parameter t_m.

    parameter psi is 0.
    parameter psi_u is 4 * constant():pi^2.
    parameter psi_l is - 4 * constant():pi.
    parameter max_iter is 1000.
    parameter tol is 1e-12.
    
    local function c_2{
        parameter z.

        local function cosh {
            parameter x.
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
        parameter z.
        local function sinh{
            parameter x.
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
    local parameter targ_dist.
}

function intercept_target_at_chosen_time {
    local parameter time_after_burn. // time after burn to intercept target
    local parameter after_time. // how many seconds from NOW to execute the mode. 
}

function match_planes_with_target {
    local parameter mode.
    if mode = "at cheapest AN/DN" {

    }
    if mode = "at nearest AN/DN" {

    }
    if mode = "at AN" {

    }
    if mode = "at DN" {

    }
    return null_mnv().
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

//**************************************************||
//--------------------------------------------------||
//                WAYPOINT GUIDANCE                 ||
//--------------------------------------------------||
//**************************************************||

//**************************************************||
//--------------------------------------------------||
//                 PLANE AUTOPILOT                  ||
//--------------------------------------------------||
//**************************************************||

//**************************************************||
//--------------------------------------------------||
//                 SPECIAL POINTS                   ||
//--------------------------------------------------||
//**************************************************||
//SUB-SOLAR POINT
//LAUNCH PAD
//RUNWAYS


