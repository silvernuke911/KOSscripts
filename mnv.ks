@lazyGlobal off.
set config:ipu to 1500.
runpath("0:/lib/maneuver_functions.ks").
runpath("0:/lib/borders.ks").

function calculate_eccentricity {
    local parameter pe.
    local parameter ap.


}
function main {
    create_node(circularize("at periapsis")).
    execute_node().
}
main().