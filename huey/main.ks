runpath("0:/lib/borders.ks").
runpath("0:/lib/resources.ks").

set terminal:width to 50.
set terminal:height to 20.
clearScreen.

function main_screen{
    draw_edge_border().
    horizontal_line(0,terminal:width,2).
    center_text("UH-1 HUEY FLIGHT CONTROL", 1).
    horizontal_line(1,terminal:width-1,terminal:height-6).
    print("SYS MSG : ") at (3,terminal:height-5).
    horizontal_line(1,terminal:width-1,terminal:height-4).
    print("INPUT   > ") at (3,terminal:height-3).
    vertical_line(3,14, terminal:width/2).
    return.
}

function resources {
    local liquid_fuel_amount is get_resource("liquidfuel"):amount.
    local liquid_fuel_capacity is get_resource("liquidfuel"):capacity.
    local liquid_fuel_percent is 100*liquid_fuel_amount/liquid_fuel_capacity.
    local power_amount is get_resource("electriccharge"):amount.
    local power_capacity is get_resource("electriccharge"):amount.
    local power_percent is 100*power_amount/power_capacity.
    local air_amount is get_resource("intakeair"):amount.
    local air_capacity is get_resource("intakeair"):amount.
    local air_percent is 100*air_amount/air_capacity.
    print "FUEL  : "+round(liquid_fuel_amount,1) at (27,7).
    print "POWER : "+round(power_amount,1) at (27,8).
    print "AIR   : "+round(air_amount,2) at (27,9).
    print round(liquid_fuel_percent)+"%" at (41,7).
    print round(power_percent)+"%" at (41,8).
    print round(air_percent)+"%" at (41,9).
}   
// FLIGHT MANUAL
// ACTION GROUPS
// RESOURCES
// TAKE-OFF CHECKLIST
// AUTOTAKE-OFF
// AUTOFOLLOW THING

global system to true.
set time_start to time:seconds.
set time_end to 50.

main_screen().
until not system {
    resources().
    if (time:seconds - time_start)>time_end {
        set system to false.
    }
}
clearScreen.
