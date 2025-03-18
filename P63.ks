//equivalent to P64, P63, and P66 from the real appollo

//p63

//define variables
sas off.
set steering to retrograde.
declare P is 62.
set Thmax to ship:maxthrust.
declare mu_m to 6.5138398*10^10.
lock g_m to (mu_m/(200000+ship:altitude)).
lock LM_m to ship:mass.

until P=67 {
    if P=62 {
        lock steering to retrograde.
        if eta:periapsis < 2 {
            set P to 63.
        }
    }
    // if P=63 {
    //     lock throttle to 0.3.
    //     if ship:velocity > 200 {
    //         set P to 64.
    //     }
    // }
}
