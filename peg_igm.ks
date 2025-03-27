@lazyGlobal off.

// Powered explicit guidance and Iterative Guidance Mode

function PEG {

}

function IGM {

}

// state vectors
local r_vec is ship:position - body:position.
local v_vec is ship:orbit:velocity.

// basis vectors

local up_hat is r_vec:normalized.
local hv_hat is vCrs(v_vec,r_vec):normalized.
local dn_hat is vCrs(up_hat,hv_hat):normalized.

local ft_vec is -ship:facing:vector:normalized.
local ang_vel_vec is vDot(v_vec,dn_hat) / r_vec:mag.

//Vehicle Measurement
local v_esc is vessel:isp * constant:g0.

//Rocket equations

local tau is v_esc / acceleration.

function acc {
    parameter t.
    return acceleration / (1 - t / tau ).
}


