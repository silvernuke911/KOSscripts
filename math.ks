@lazyGlobal off.

// TRIGONOMETRY

function sinc {
    parameter x.
    if x = 0 {
        return 1.
    }
    return sin(x) / x*constant:degtorad.
}
function cosh {
    parameter x.
    return (constant:e^(x) + constant:e^(-x)) / 2.
}
function sinh {
    parameter x.
    return (constant:e^(x) - constant:e^ (-x)) / 2.
}
function tanh {
    parameter x.
    return (constant:e^(x) - constant:e^ (-x)) / (constant:e^(x) + constant:e^ (-x)).
}

function sec {
    parameter x.
    return 1 / cos(x).
}

function csc {
    parameter x.
    return 1 / sin(x).
}

function cot {
    parameter x.
    return 1 / tan(x).
}

function arcsec {
    parameter x.
    local inv is 1/x.
    return arccos(inv).
}

function arccsc {
    parameter x.
    local inv is 1/x.
    return arcsin(inv).
}

function arccot {
    parameter x.
    local inv is 1/x.
    return arctan(inv).
}

function arcsinh {
    parameter x.
    return ln(x + sqrt(x^2 + 1)).
}

function arccosh {
    parameter x.
    return ln(x + sqrt(x^2 - 1)).
}

function arctanh {
    parameter x.
    return (1/2) * ln((1 + x) / (1 - x)).
}
// MISC

function sign {
    parameter x.
    return round(x / abs(x)).
}

function exp {
    parameter x.
    return constant:e^(x).   
}

function sum {
    parameter num_list.
    local s to 0.
    for num in num_list{
        set s to s + num.
    }
    return s.
}

function isclose {
    parameter a.
    parameter b.
    parameter rel_tol is 1e-9.
    parameter abs_tol is 0.0.
    if abs(a-b) < max((max(a,b)*rel_tol),abs_tol) {
        return true.
    }
    return false.
}

function isnan {
    // parameter x.
    // checks if a value is NaN or not
}

function isinf {
    // parameter x.
    // checks if a value is infinity
}

function gcd {
    parameter a.
    parameter b.
    local temp is 0.
    // returns greatest common divisor
    until b = 0 {
        set temp to b.
        set b to mod(a, b).
        set a to temp.
    }
    return a.
}

function lcm {
    parameter a.
    parameter b.
    // returns least common multiple
    return abs(a * b) / gcd(a, b).
}

function arange{
    parameter min_.
    parameter max_.
    parameter step is 1.

    local numlist is list().
    from {local i is min_.} until i>=max_ step {set i to i + step.} do {
        numlist:add(i).
    }
    return numlist.
}

function linspace {
    parameter min_.
    parameter max_.
    parameter space.

    local step is (max_ - min_)/space.
    local numlist is list().
    from {local i is min_.} until i>=max_ step {set i to i + step.} do {
        numlist:add(i).
    }
    return numlist.
}

function factorial {
    parameter n.
    if n = 0 {
        return 1.
    } else {
        local result to 1.
        from {local i is 1.} until i > n step {set i to i + 1.} do {
            set result to result * i.
        }
        return result.
    }
}

function comb {
    parameter n_.
    parameter r_.
    if r_ > n_ {
        return 0.
    }
    return factorial(n_) / (factorial(r_) * factorial(n_ - r_)).
}

function perm {
    parameter n_.
    parameter r_.

    if r_ > n_ {
        return 0.
    }
    return factorial(n_) / factorial(n_ - r_).
}
function prod {
    parameter num_list.
    local p to 1.
    for num in num_list{
        set p to p * num.
    }
    return p.
}

function cbrt {
    parameter x.
    return x^(1/3).
}

function dist {
    parameter v1.
    parameter v2.

    return sqrt((v1:x - v2:x)^2+(v1:y-v2:y)^2+(v1:z-v2:z)^2).
}

function deg2rad{
    parameter rad.
    return constant:radtodeg * rad.
}

function rad2deg {
    parameter deg.
    return constant:degtorad * deg.
}

function log2 {
    parameter x.
    return ln(x) / ln(2).
}

// Root Function
function root {
    parameter value.
    parameter n.
    return value^(1/n).
}

// Logarithm Base Function
function log_base {
    parameter x.
    parameter base.
    return ln(x) / ln(base).
}

// Mean (Average)
function mean {
    parameter num_list.
    return sum(num_list) / num_list:length.
}

// Median
function median {
    parameter num_list.
    local sorted_list to num_list:sort().
    local n to sorted_list:length.
    if mod (n,2) = 0 {
        return (sorted_list[n/2-1] + sorted_list[n/2]) / 2.
    } else {
        return sorted_list[floor(n/2)].
    }
}

// Mode
function mode {
    parameter num_list.
    local frequency to lexicon().
    local max_freq to 0.
    local mode_val to num_list[0].

    for num in num_list {
        if not frequency:haskey(num) {
            set frequency[num] to 0.
        }
        set frequency[num] to frequency[num] + 1.
        if frequency[num] > max_freq {
            set max_freq to frequency[num].
            set mode_val to num.
        }
    }

    return mode_val.
}

// Standard Deviation
function std_dev {
    parameter num_list.
    local m to mean(num_list).
    local variance_ to 0.

    for num in num_list {
        set variance_ to variance_ + (num - m)^2.
    }

    set variance_ to variance_ / num_list:length.
    return sqrt(variance_).
}

// Variance
function variance {
    parameter num_list.

    local m to mean(num_list).
    local variance_ to 0.
    for num in num_list {
        set variance_ to variance_ + (num - m)^2.
    }
    return variance_ / num_list:length.
}

// Quadratic Solver
function quadratic_solver {
    parameter a.
    parameter b.
    parameter c.
    
    local discriminant to b^2 - 4*a*c.
    if discriminant < 0 {
        return list().  // No real roots
    } else if discriminant = 0 {
        return list(-b / (2*a)).  // One real root
    } else {
        return list((-b + sqrt(discriminant)) / (2*a), (-b - sqrt(discriminant)) / (2*a)).  // Two real roots
    }
}

// Polynomial Evaluation
function poly_eval {
    parameter coeffs.
    parameter x.

    local result to 0.
    local n to coeffs:length.

    for i in range(0, n-1) {
        set result to result + coeffs[i] * x^i.
    }

    return result.
}

// VECTORS

function vprj{
    parameter v1.
    parameter v2.

    return v2:normalized * vdot(v1,v2) / v2:mag.
}

function vrej{
    parameter v1.
    parameter v2.
    return v1 - vprj(v1,v2).
}


// Numerical Calculus

function differentiator {
    parameter x_list.
    parameter y_list.

    if not (x_list:length = y_list:length) {
        print "Error: x_list and y_list must have the same length.".
        return.
    }
    local n to x_list:length.
    local dy_dx to list().
    // Forward difference for the first point
    dy_dx:add((y_list[1] - y_list[0]) / (x_list[1] - x_list[0])).
    // Central difference for interior points
    from {local i is 1.} until i >= n-1 step {set i to i + 1.} do {
        local diff to (y_list[i+1] - y_list[i-1]) / (x_list[i+1] - x_list[i-1]).
        dy_dx:add(diff).
    }
    // Backward difference for the last point
    dy_dx:add((y_list[n-1] - y_list[n-2]) / (x_list[n-1] - x_list[n-2])).

    return dy_dx.
}

function integrator {
    parameter x_list.
    parameter y_list.

    if not (x_list:length = y_list:length) {
        print "Error: x_list and y_list must have the same length.".
        return.
    }

    local n to x_list:length.
    local integral to list().
    local sum_ to 0.
    from {local i is 0.} until i >= n-1 step {set i to i + 1.} do {
        local h to x_list[i+1] - x_list[i].
        local area to (y_list[i] + y_list[i+1]) * h / 2.
        set sum_ to sum_ + area.
        integral:add(sum_).
    }

    return integral.
}

// Linear Algebra 
function matrixmult {
    parameter m1.
    parameter m2.

    local rows1 to m1:length.
    local cols1 to m1[0]:length.
    local rows2 to m2:length.
    local cols2 to m2[0]:length.
    if cols1 <> rows2 {
        print "Error: Matrix dimensions do not match for multiplication.".
        return.
    }
    local result to list(). 
    from {local i is 0.} until i = rows1 step { set i to i + 1.} do {
        local row to list().
        from {local j is 0.} until j = cols2 step { set j to j + 1.} do {
            row:add(0).
        }
        result:add(row).
    }
    from {local i is 0.} until i = rows1 step { set i to i + 1.} do {
        from {local j is 0.} until j = cols2 step { set j to j + 1.} do {
            local sum_ to 0.
            from {local k is 0.} until k = cols1 step { set k to k + 1.} do {
                set sum_ to sum_ + m1[i][k] * m2[k][j].
            }
            set result[i][j] to sum_.
        }
    }
    return result.
}

function basis_transform {
    parameter v1.
    parameter vix.
    parameter viy.
    parameter viz.
    return v(vdot(v1,vix:normalized),vdot(v1,viy:normalized),vdot(v1,viz:normalized)).
}

function rotation_matrix2d {
    parameter theta.

    local cosTheta to cos(theta).
    local sinTheta to sin(theta).
    return list(
        list(cosTheta, -sinTheta),
        list(sinTheta,  cosTheta)
    ).
}

function rotation_matrix3d_x {
    parameter theta.
    
    local cosTheta to cos(theta).
    local sinTheta to sin(theta).

    return list(
        list(1,        0,         0),
        list(0, cosTheta, -sinTheta),
        list(0, sinTheta,  cosTheta)
    ).
}

function rotation_matrix3d_y {
    parameter theta.
    
    local cosTheta to cos(theta).
    local sinTheta to sin(theta).

    return list(
        list( cosTheta, 0, sinTheta),
        list(        0, 1,        0),
        list(-sinTheta, 0, cosTheta)
    ).
}

function rotation_matrix3d_z {
    parameter theta.
    
    local cosTheta to cos(theta).
    local sinTheta to sin(theta).
    return list(
        list(cosTheta, -sinTheta, 0),
        list(sinTheta,  cosTheta, 0),
        list(       0,         0, 1)
    ).
}

function v_to_list {
    parameter vec.
    local listv is list(0,0,0).
    set listv[0] to vec:x.
    set listv[1] to vec:y.
    set listv[2] to vec:z.
    return listv.
}
