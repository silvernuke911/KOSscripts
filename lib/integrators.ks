runpath("0:/lib/maneuver_functions.ks").

// KINEMATIC INTEGRATORS.
// f is a function that outputs an acceleration vector. rv and vv are all vectors.
function Euler {
    local parameter t0.
    local parameter tf.
    local parameter dt.
    local parameter f.
    local parameter r0.
    local parameter v0.

    local a is f(t0,r0,v0).
    local rv is r0.
    local vv is v0.

    from {local t is t0.} until (t >= tf) step {set t to t + dt.} do {
        set a to f(t,r,v).
        set vv to vv + a * dt.
        set rv to rv + vv * dt.
    }
    return list(rv,vv,a).
}

function Verlet {
    local parameter t0.
    local parameter tf.
    local parameter dt.
    local parameter f.
    local parameter r0.
    local parameter v0.

    local a is f(t0,r0,v0).
    local rv is r0.
    local vv is v0.
    local vhalf is v0/2.

    from {local t is t0.} until (t >= tf) step {set t to t + dt.} do {
        set rv to rv + vv * dt + 0.5 * a * dt * dt.
        set vhalf to vv + 0.5 * a * dt.
        set a to f(t,r,vhalf).
        set vv to vhalf + 0.5 * a * dt.
    }
    return list(rv,vv,a).
}

function RK4 {
    local parameter t0.
    local parameter tf.
    local parameter dt.
    local parameter f.
    local parameter r0.
    local parameter v0.

    local a is f(t0,r0,v0).
    local rv is r0.
    local vv is v0.

    local k1r is 0.
    local k2r is 0.
    local k3r is 0.
    local k4r is 0.
    local k1v is 0.
    local k2v is 0.
    local k3v is 0.
    local k4v is 0.
    local half_dt is dt / 2.
    from {local t is t0.} until (t >= tf) step {set t to t + dt.} do {
        set a to f(t,r,v).
        set k1r to v.
        set k1v to f(t,r,v).
        set k2r to vv + half_dt * k1v.
        set k2v to f(t + half_dt, rv + half_dt * k1r, vv + half_dt * k1v).
        set k3r to vv + half_dt * k2v.
        set k3v to f(t + half_dt, rv + half_dt * k2r, vv + half_dt * k2v).
        set k4r to vv + dt * k3v.
        set k4v to f(t + dt, rv + dt * k3r, vv + dt * k3v).
        set rv to rv + dt * (k1r + 2*k2r + 2*k3r + k4r) / 6.
        set vv to vv + dt * (k1v + 2*k2v + 2*k3v + k4v) / 6.
    }
    return list(rv,vv,a).
}