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
// A library of kOS functions designed for precise  ||
// maneuver planning and execution in orbital       ||
// mechanics, and other navigation purposes,        ||
// emulating the automation of "Create Maneuver" and||
// "Execute Maneuver" of MechJeb2.0. This includes  ||
// utilities for computing required deltaV, creating||
// various maneuver nodes, and other necessary      ||
// implements                                       ||
//                                                  ||
//--------------------------------------------------||
//                                                  ||
//--------------------------------------------------||
//==================================================||

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
// Function: total_burn_time
// Purpose:  Calculates the total burn duration (in seconds) required
//           to execute the full delta-v of a maneuver node.
//
// Parameters:
//   mnv : A maneuver node object (or mock) with a :DELTAV vector.
//
// Returns:
//   - Burn time in seconds required to complete the maneuver.
//   - Returns 0 if ISP is 0 or undefined.
//
// Method:
//   Uses Tsiolkovsky equation to compute propellant mass required,
//   then divides by mass flow rate (thrust / exhaust velocity).
//
// Notes:
//   ve = Isp × g0
//   mf = m0 × exp(–Δv / ve)
//   dm = m0 – mf
//   ṁ = T / ve
//   burn_time = dm / ṁ
// =====================================================================
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

// =====================================================================
// Function: half_burn_time
// Purpose:  Calculates the burn time (in seconds) needed to perform
//           *half* the delta-v of a maneuver node (typically used
//           for symmetric time-warp to maneuver).
//
// Parameters:
//   mnv : A maneuver node object with a :DELTAV vector.
//
// Returns:
//   - Burn time for half the delta-v (seconds).
//   - Returns 0 if ISP is 0 or undefined.
//
// Notes:
//   Uses same logic as total_burn_time, but with Δv halved.
// =====================================================================
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

// =====================================================================
// Function: rcs_isp
// Purpose : Returns the effective ISP of all active RCS thrusters.
// Method  : Averages the ISP of all parts tagged "rcs" with ModuleRCS.
// Parameters:
//   (none)
//
// Returns:
//   A scalar ISP value in seconds.
// =====================================================================
function rcs_isp {
    local rcsList is list().
    list rcs in rcsList.
    local total_thrust is 0.
    local weighted_isp is 0.
    for rcs_ in rcsList {
        if rcs_:availableThrust > 0 and rcs_:availableThrust > 0 and rcs_:foreenabled{
            set total_thrust to total_thrust + rcs_:availableThrust.
            set weighted_isp to weighted_isp + (rcs_:availableThrust * rcs_:isp).
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
        if rcs_:availableThrust > 0 and rcs_:availableThrust > 0 and rcs_:foreenabled{
            set rcs_total_thrust_ to rcs_total_thrust_ + rcs_:availableThrust.
        }
    }
    return rcs_total_thrust_.
}
// =====================================================================
// Function: rcs_burn_time
// Purpose : Computes full burn time to complete a maneuver using RCS.
// Method  : Applies Tsiolkovsky rocket equation and thrust equation.
// Parameters:
//   mnv - Maneuver node to be executed.
//
// Returns:
//   Total RCS burn time in seconds.
// =====================================================================

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
    // T O BE ADDED
}

// =====================================================================
// Function: rcs_half_burn_time
// Purpose : Computes time to burn half the delta-V using RCS.
// Method  : Applies Tsiolkovsky rocket equation for half delta-V.
// Parameters:
//   mnv - Maneuver node to be executed.
//
// Returns:
//   Half RCS burn time in seconds.
// =====================================================================
function rcs_half_burn_time {
    local parameter mnv.

    local deltav is mnv:deltav:mag.
    local deltav_2 is deltav / 2.

    local rcs_total_thrust_ is rcs_total_thrust().
    local Isp is rcs_isp().
    if Isp = 0 or rcs_total_thrust = 0 {
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

//=====================================================================
// Function: twr
// Purpose:
//     Computes the vessel's Thrust-to-Weight Ratio (TWR) at its current
//     altitude on the current celestial body.
//
// Returns:
//     - twr_val : Thrust-to-weight ratio (dimensionless)
//
// Notes:
//     - Uses available thrust, not maximum thrust.
//     - TWR > 1 means the ship can accelerate upward.
//     - Important for liftoff and landing calculations.
// =====================================================================
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

// =====================================================================
// Function: orbital_velocity_circular
// Purpose:
//   Computes the circular orbital velocity (in m/s) required to
//   maintain a circular orbit around the current celestial body,
//   either at a specified altitude above the surface or at an
//   absolute radius from the center of the body.
//
// Parameters:
//   altitude_ : (numeric) The input value, interpreted based on `mode`
//     - If mode = "altitude": this is the altitude above the surface (m)
//     - If mode = "radius"  : this is the total radius from the center (m)
//
//   mode : (string, optional) How to interpret `altitude_`.
//     - "altitude" (default): `altitude_` is added to `body:radius`
//     - "radius"           : `altitude_` is treated as the full radius
//
// Returns:
//   - The circular orbital velocity at the specified radius (m/s).
//
// Notes:
//   - Formula: v = sqrt(GM / r)
//     where GM is body:mu, and r is the orbital radius (m).
//
// Warnings:
//   - Prints an error if mode is invalid, but still proceeds to return.
// =====================================================================
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


// =====================================================================
// Function: vis_viva_equation
// Purpose:
//   Computes the orbital speed (in m/s) at a given altitude for an
//   orbit with a specified semimajor axis using the Vis-Viva equation.
//
// Parameters:
//   altitude_ : (numeric) Altitude above the surface (in meters)
//   a_        : (numeric) Semimajor axis of the orbit (in meters)
//
// Returns:
//   - Orbital speed at the given altitude (in m/s)
//
// Formula:
//   v = sqrt( GM * (2/r - 1/a) )
//   where:
//     - GM is body:mu (standard gravitational parameter)
//     - r = body:radius + altitude_ (distance from center of mass)
//     - a = semimajor axis of the orbit
// =====================================================================
function vis_viva_equation {
    local parameter altitude_.  // Altitude above body's surface (m)
    local parameter a_.         // Semimajor axis of the orbit (m)
    local r_ is body:radius + altitude_.
    return sqrt(body:mu * (2 / r_ - 1 / a_)).
}

function calculate_semimajor_axis {
    local parameter periapsis__.
    local parameter apoapsis___.
    return body:radius + (periapsis__+apoapsis___)/2.
}

function true_anomaly_to_radius {
    local parameter ta.
    local a is ship:obt:semimajoraxis.
    local e is ship:obt:eccentricity.
    local r_ to a * (1 - e^2) / (1 + e * cos(ta)).
    return r_ - body:radius.
}
function radius_to_true_anomaly {
    local parameter r_.
    local r__ is r_ + body:radius. 
    local a is ship:obt:semimajoraxis.
    local e is ship:obt:eccentricity.
    local cos_ta to (a * (1 - e^2) / r__ - 1) / e.
    local ta to arccos(cos_ta).
    return ensure_angle_positive(ta).
}

function true_anomaly_to_eccentric_anomaly {
    local parameter ta.
    local e is ship:obt:eccentricity.
    local ea to arctan2(
        sqrt(1 - e^2) * sin(ta), 
        e + cos(ta)
    ).
    return ensure_angle_positive(ea).
}

function eccentric_anomaly_to_mean_anomaly {
    local parameter ea.
    local e is ship:obt:eccentricity.
    local ea_rad to ea * constant:degtorad.
    local ma_rad to ea_rad - e * sin(ea).
    return ensure_angle_positive(ma_rad * constant:radtodeg).
}

// =====================================================================
// Function: mean_anomaly_to_eccentric_anomaly
// Purpose:
//   Solves Kepler's Equation numerically to find the **Eccentric Anomaly**
//   (EA, in degrees) from a given **Mean Anomaly** (MA, in degrees).
//
// Parameters:
//   ma : Mean Anomaly (degrees)
//
// Returns:
//   - Eccentric Anomaly (degrees), adjusted to the range [0, 360)
//
// Method:
//   Uses Newton-Raphson iteration on the transcendental equation:
//     MA = EA - e * sin(EA)
//   where:
//     - MA and EA are in radians for computation
//     - e is orbital eccentricity (retrieved from `ship:obt:eccentricity`)
//
// Notes:
//   - Iteration stops when difference between successive estimates < 1e-9
//   - Uses degrees for compatibility with common kOS usage
// =====================================================================
function mean_anomaly_to_eccentric_anomaly {
    local parameter ma.                          // Input Mean Anomaly (deg)
    local e is ship:obt:eccentricity.            // Orbital eccentricity
    local ma_rad to ma * constant:degtorad.      // Convert MA to radians

    local ea_rad to ma_rad.                      // Initial guess: EA = MA
    local ea_deg to ea_rad * constant:radtodeg.  // Also track EA in degrees
    local diff to 1.                             
    // Newton-Raphson iteration to solve MA = EA - e*sin(EA)
    until diff < 1e-9 {
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


function eccentric_anomaly_to_true_anomaly {
    local parameter ea.
    local e is ship:obt:eccentricity.
    local ta to arctan2(
        sqrt(1 - e^2) * sin(ea), 
        cos(ea) - e
    ).
    return ensure_angle_positive(ta).
}

function time_from_true_anomaly {
    // Input: target true anomaly (targ_ta)
    local parameter targ_ta.
    // Current true anomaly, semi-major axis, eccentricity, and gravitational parameter
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

// =====================================================================
// Function: create_node
// Purpose:  Creates and adds a maneuver node using a maneuver vector.
// Input:
//   mnv_node : list of 4 values in the form [eta, dv_r, dv_n, dv_p]
//              • eta     : seconds from now until burn
//              • dv_r    : radial delta-v (m/s)
//              • dv_n    : normal delta-v (m/s)
//              • dv_p    : prograde delta-v (m/s)
// Behavior:
//   - If eta < 0 and the delta-v vector is all zero, a warning is printed.
//   - Otherwise, it schedules the maneuver node.
// =====================================================================
function create_node {
    local parameter mnv_node.

    local eta____ is mnv_node[0] + time:seconds.
    local radial_ is mnv_node[1].
    local normal_ is mnv_node[2].
    local prograd is mnv_node[3].

    // Warn if trying to create a maneuver with invalid settings
    if mnv_node[0] < 0 {
        if radial_ = 0 and normal_ = 0 and prograd = 0 {
            print("WRONG MNV NODE SETTING").
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

// =====================================================================
// Function: raw_node
// Purpose:  Constructs a maneuver vector list (without applying it).
// Input:
//   eta____ : seconds from now until burn
//   radial_ : radial delta-v (m/s)
//   normal_ : normal delta-v (m/s)
//   prograd : prograde delta-v (m/s)
// Output:
//   list [eta, dv_r, dv_n, dv_p] suitable for use with create_node()
// =====================================================================
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

// =====================================================================
// Function: null_mnv
// Purpose:  Returns a dummy maneuver vector representing "do nothing."
// Output:
//   list [-1, 0, 0, 0] which signals no maneuver
// =====================================================================
function null_mnv {
    return list(-1, 0, 0, 0).
}


// =====================================================================
// Function: circularize
// Purpose:  Calculates the delta-v vector required to circularize an orbit
//           under various user-specified conditions.
// Modes Supported:
//   - "at periapsis"       : Burn at periapsis to circularize
//   - "at apoapsis"        : Burn at apoapsis to circularize
//   - "at altitude"        : Burn when reaching a specified altitude
//   - "after fixed time"   : Burn after a fixed amount of time has passed
//
// Parameters:
//   mode  : (string) The selected method of circularization
//   value : (optional, numeric) Mode-dependent parameter:
//              • If mode = "at altitude", this is the target altitude (m)
//              • If mode = "after fixed time", this is the delay time (s)
//
// Returns:
//   A maneuver node vector [eta, radial_dv, normal_dv, prograde_dv]
//   or a null_mnv() if the operation fails or is invalid.
// =====================================================================
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
    function compute_circularization_dv {
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
        local dv_vec is (-radial_v) * radial_vec + (-normal_v) * normal_vec + delta_v * prograde_vec.

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
            print "ALTITUDE UNREACHABLE".
            return null_mnv().
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
    return null_mnv().
}

function change_eccentricity {
    local parameter targ_eccentricity.
    local parameter mode.
    local parameter value is 0. 
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
    if mode = "at periapsis" {
        local periapsis_dV is ( 
            vis_viva_equation(
                ship:periapsis, 
                calculate_semimajor_axis(
                    target_apoapsis, 
                    ship:periapsis))
            - vis_viva_equation(
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
    if mode = "after fixed time" {

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
    local parameter value is 0.
    if mode = "at apoapsis" {
        local apoapsis_dV is ( 
            vis_viva_equation(
                ship:apoapsis, 
                calculate_semimajor_axis(
                    target_periapsis, 
                    ship:apoapsis)) - 
            vis_viva_equation(
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

// =====================================================================
// Function: change_inclination
// Purpose : Computes the delta-V vector and timing needed to change the
//           inclination of an orbit to a target value.
// Method  : 
//   1. Determines ascending and descending node times and velocities.
//   2. Calculates required delta-V at each node using orbital mechanics.
//   3. Converts delta-V magnitude to vector components in orbital frame.
//   4. Returns maneuver plan (time, radial, normal, prograde components).
// Parameters:
//   target_inclination - Desired inclination in degrees.
//   mode               - Strategy for where to perform the burn:
//                          "at AN" — burn at Ascending Node
//                          "at DN" — burn at Descending Node
//                          "at nearest node" — soonest of AN or DN
//                          "at cheapest node" — least delta-V cost
//                          "after fixed time" — (not implemented)
// Returns:
//   A list containing:
//     [0] - Time until burn (seconds)
//     [1] - Radial component of delta-V (m/s)
//     [2] - Normal component of delta-V (m/s)
//     [3] - Prograde component of delta-V (m/s)
//   Or null_mnv() if no valid mode matched.
// =====================================================================
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
    if mode = "after fixed time" {
        // Not implemented — requires true anomaly and velocity propagation
        print "after fixed time mode not implemented yet".
    }
    return null_mnv().
}

function change_LAN {

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
// - "closest approach" mode is stubbed.            ||
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
//   sas_on      : (optional) If true, enables SAS  ||
//                 to lock to MANEUVER. Default: ON ||
//   warp_to_node: (optional) If true, warps to     ||
//                 burn start. Default: ON          ||
//   thruster    : (optional) "engine" (default) or ||
//                 "rcs" for low-thrust maneuver.   ||
//   has_reac_wheels : manual setting if vehicle    ||
//                  has reaction wheels             ||
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
    local parameter sas_on is true.
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
    if sas_on {
        unlock steering.
        sas on.
        set sasMode to "MANEUVER". // Use maneuver alignment mode
    }
    if not sas_on {
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
                warpTo(time:seconds + mnv_node:eta - half_time - 10).
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
            if sas_on {
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
// =====================================================================
// Function: compass_hdg
// Purpose : Computes the compass heading (0° = North, 90° = East, etc.)
//           of the ship's current facing direction relative to the surface.
// Method  : Projects the ship's forward vector onto the horizontal plane
//           and calculates its angle relative to north.
// Parameters:
//   (none)
//
// Returns:
//   A scalar angle in degrees representing the compass heading [0, 360).
// =====================================================================
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
// =====================================================================
// Function: vectorHeading
// Purpose : Calculates the heading (compass angle) of an arbitrary
//           vector in the ship's surface reference frame.
// Method  : Projects the vector onto the horizontal plane and
//           computes its angle from true north.
//
// Parameters:
//   V__ : (vector) A direction vector to analyze.
//
// Returns:
//   A scalar angle in degrees [0, 360) representing the heading.
// =====================================================================
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
//                  WARP FUNCTIONS                  ||
//--------------------------------------------------||
//**************************************************||

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

//**************************************************||
//--------------------------------------------------||
//                INCLINATION ASCENT                ||
//--------------------------------------------------||
//**************************************************||

// =====================================================================
// Function: inclination_heading
// Purpose: Calculate the launch heading needed to achieve a target 
//          orbital inclination.
//          Applies a correction term based on the deviation from the 
//          current orbit's inclination.
// Parameters:
//   - target_inclination : Desired orbital inclination in degrees.
//   - mode               : "northbound" or "southbound" launch direction.
//   - current_latitude   : (optional) Defaults to ship:latitude if not 
//                          specified.
// Returns:
//   - Launch heading in degrees to achieve the target inclination.
// =====================================================================
function inclination_heading {
    local parameter target_inclination.
    local parameter mode.
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

//**************************************************||
//--------------------------------------------------||
//                  RCS THRUSTING                   ||
//--------------------------------------------------||
//**************************************************||
// kinda completed up top.
// basically using rcs as main thrusters.
// find the burn time for the fucker.
// the deadband too. 
