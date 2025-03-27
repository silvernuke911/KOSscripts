@lazyGlobal off.
set config:ipu to 1500.

function lambert_solver{
    
    // A lambert solver utilizing universal variable formulation

    parameter r1.
    parameter r2.
    parameter tof.
    parameter mu.
    parameter t_m.

    parameter psi is 0.
    parameter psi_u is 4 * constant():pi^2.
    parameter psi_l is - 4 * constant():pi.
    parameter max_iter is 1000.
    parameter tol is 1e-10.
    
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

function orbit_simulation{
    parameter r_i.
    parameter v_i.
    parameter dt.
    parameter max_time.

    local function grav_acc{
        parameter mu.
        parameter rad.

        return - (mu / rad:sqrmagnitude) * rad:normalized.
    }

    local r_l is list().
    local v_l is list().

    r_l:add(r_i).
    v_l:add(v_i).

    local r_t is r_i.
    local v_t is v_i.
    from {local t is 0.} until t > max_time step {set t to t+dt.} do {
        local a_g to grav_acc(mun:mu,r_t).

        set v_t to v_t + a_g * dt.
        set r_t to r_t + v_t * dt.

        v_l:add(v_t).
        r_l:add(r_t).
    }
}

local r1_ to v(1,0,0).
local r2_ to v(-1,0.1,0).
local tof_i to 5.14159.
local mu_ to 1.

local resultvectors1 to lambert_solver(r1_,r2_,tof_i,mu_,+1).
local resultvectors2 to lambert_solver(r1_,r2_,tof_i,mu_,-1).

print resultvectors1[0] + "," + resultvectors1[1].
print resultvectors2[0] + "," + resultvectors2[1].