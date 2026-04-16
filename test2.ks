@lazyGlobal off.
runpath("0:/lib/maneuver_functions.ks").
runpath("0:/lib/borders.ks").
set config:ipu to 1500.


function main {
    // create_node(
    //     // circularize("at periapsis", 300)
    //     // // change_periapsis(72000,"at equatorial AN",300000)
    //     // // change_eccentricity(0.5,"at altitude",180000)
    //     // // change_pe_and_ap(100000,200000,"at altitude",150000)
    //     // // change_periapsis(80000,"after fixed time",300)
    //     // // change_periapsis(220000,"after fixed time",30)
    //     // // change_LAN(10,"at south peak latitude")
    //     // // circularize("at periapsis")
    //     // // change_pe_and_ap(obt:periapsis,obt:apoapsis,"nearest")
    //     // // change_periapsis(500000,"after fixed time",300)
    //     // // change_semimajoraxis(1500000,"at altitude",200000)
    //     // // change_argument_of_periapsis(350,"second half")
    //     hohmann_transfer_to_target()
    // ).
    // // vector_debug().
    // // hohmann_maneuver(500000,"at periapsis").
    // wait 15.
    // clearVecDraws().
    // execute_node().
    // create_node(circularize("at apoapsis")).
    // execute_node().
    // create_node(

    // ).
    set target to "MNV-1".
    create_node(hohmann_transfer_to_target()).
    execute_node().
    local t_ is time_of_closest_approach().
    // local dummy_node is node(t_,0,0,0).
    // add dummy_node.
    print t_.
    print(target_distance_at_ut(t_)).
    create_node(match_velocities_with_target()).
    execute_node().
    if hasNode {
        remove nextNode.
    }
}
main(). 