@lazyGlobal off.
runpath("0:/lib/maneuver_functions.ks").
runpath("0:/lib/borders.ks").
set config:ipu to 2000.


function main {
    if hasNode {
        remove nextNode.
    }
    create_node (
        intercept_target()
    ).
    wait 1. 
    // print(vecs[1]).
    execute_node().
    print time_of_closest_approach().
    print target_distance_at_ut(time_of_closest_approach()).
    wait 10.
    // create_node(
    //     fine_tune_closest_approach_to_target()
    // ).
    // execute_node().
    // print time_of_closest_approach().
    // print target_distance_at_ut(time_of_closest_approach()).
    wait 10.
    create_node(
        match_velocities_with_target()
    ).
    execute_node().
    wait 10.
    if hasNode {
        remove nextNode.
    }
}
main(). 
