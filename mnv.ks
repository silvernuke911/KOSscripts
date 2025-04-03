@lazyGlobal off.
set config:ipu to 1500.
runpath("0:/lib/maneuver_functions.ks").
runpath("0:/lib/borders.ks").


function main {

}

function obt_data {
    local nu is ship:obt:trueanomaly.
    local nu2ea is true_anomaly_to_eccentric_anomaly(nu).
    local ea2ma is eccentric_anomaly_to_mean_anomaly(ea).
    local ma2ea is mean_anomaly_to_eccentric_anomaly(ea2ma).
    local ea2nu is eccentric_anomaly_to_true_anomaly(ma2ea).
    local etaperi is time_from_true_anomaly(0).
    local function round2 {
        parameter num.
        return round(num,2).
    }
    print "nu                  : " + round2(nu)    at (5,5).
    print "nu 2 E              : " + round2(nu2ea) at (5,6). 
    print "E 2 M               : " + round2(ea2ma) at (5,7).
    print "M 2 E               : " + round2(ma2ea) at (5,8).
    print "E 2 nu              : " + round2(ea2nu) at (5,9).
    print "time to peri        : " + round2(etaperi) at (5,10).
    print "time to peri (real) : " + round2(eta:periapsis) at (5,11).
}
main().