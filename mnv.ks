@lazyGlobal off.
set config:ipu to 1500.
runpath("0:/lib/maneuver_functions.ks").
runpath("0:/lib/borders.ks").
clearScreen.

function main {
    // print obt:period.
    // print("creating node").
    // create_node(
    //     change_resonant_orbit(
    //         1/2,"at apoapsis"
    //     )
    // ).
    // print("executing node").
    // execute_node().
    // print obt:period.
    
    // print(obt:semimajoraxis).
    // wait 5.
    // if nextNode {
    //     remove nextNode.
    // }
    clearVecDraws().

    // execute_node().
    // obt_data().
    // local listvar to list().
    // list rcs in listvar.
    // for rcs0 in listvar {
    //     print( " ISP = " + rcs0:isp).
    // }
    // print(rcs_isp()).
    // print(rcs_burn_time(nextNode)).
}
function obt_data {

}
main().