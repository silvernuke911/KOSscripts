@lazyGlobal off.
set config:ipu to 1500.
runpath("0:/lib/maneuver_functions.ks").
runpath("0:/lib/borders.ks").
clearScreen.

function main {
    create_node(change_inclination(0,"at cheapest node")).
    execute_node().

    wait 10.
    if nextNode {
        remove nextNode.
    }
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