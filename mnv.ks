@lazyGlobal off.
set config:ipu to 1500.
runpath("0:/lib/maneuver_functions.ks").
runpath("0:/lib/borders.ks").
runpath("0:/lib/resources.ks").
clearScreen.

function main {
    create_node(change_eccentricity(0.5,"at altitude",200000)).
    wait 15.
    until not hasNode { remove nextNode.}
    set target to "".
    clearVecDraws().
}

function obt_data {

}
function ignorables {
    // print obt:period.
    // print("creating node").
    set target to vessel("MNV-1").
    // create_node(
    //     match_planes_with_target(
    //         "at AN"
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
    // local north_vec to vecDraw(body:position,(latlng(90,0):position - body:position)*2,blue,"",1,true,0.2,true,true).
    // set north_vec:startupdater to { return body:position.}.
    // create_node(
    //   match_planes_with_target("at DN")  
    // ).

    // local p0 is body:position.
    // local r1 is ship:position - p0. // radius vector
    // local v1 is ship:velocity:orbit. // velocity vector
    // local h1 is vcrs(v1,r1). // angular momentum vector
    // local e1 is (vcrs(h1,v1)/body:mu - r1:normalized).
    // local r_vd is vecDraw(body:position,(ship:position - body:position),blue,"",1,true,0.2,true,true).
    // set r_vd:startupdater to {return body:position.}.
    // set r_vd:vecupdater to {return (ship:position - body:position).}.
    // local v_vd is vecDraw(ship:position,ship:velocity:orbit,red,"",1,true,0.2,true,true).
    // set v_vd:startupdater to {return ship:position.}.
    // set v_vd:vecupdater to {return ship:velocity:orbit*500.}.
    // local north_vec to vecDraw(body:position,(latlng(90,0):position - body:position)*2,green,"",1,true,0.2,true,true).
    // set north_vec:startupdater to { return body:position.}.
    // local h_vec is vecDraw(body:position,vcrs(ship:velocity:orbit,(ship:position - body:position)):normalized * body:radius*2,yellow,"",1,true,0.2,true,true).
    // set h_vec:startupdater to { return body:position.}.
    // // execute_node().
    wait 2*obt:period.
    until not hasNode { remove nextNode.}
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
main().