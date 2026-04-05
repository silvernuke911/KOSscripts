@lazyGlobal off.
runpath("0:/lib/maneuver_functions.ks").
runpath("0:/lib/borders.ks").
set config:ipu to 1500.


function main {
    create_node(
        // circularize("at altitude", 200000)
        // change_periapsis(72000,"at equatorial AN",300000)
        // change_eccentricity(0.5,"at altitude",180000)
        // change_pe_and_ap(100000,200000,"at altitude",150000)
        // change_periapsis(120000,"at equatorial AN")
        // change_LAN(10,"at south peak latitude")
        circularize("at apoapsis")
    ).
    wait 15.
    clearVecDraws().
    execute_node().
    // remove nextNode.
}
main().