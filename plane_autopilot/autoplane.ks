set terminal:width to 45.
clearScreen.

runpath("0:/lib/borders.ks").
runpath("0:/lib/resources.ks").
runpath("0:/lib/maneuver_functions.ks").
runpath("0:/lib/format.ks").

// ==========================
// UI SETUP
// ==========================

function init_screen {
    draw_edge_border().
    center_text(ship:name,1).

    horizontal_line(0,terminal:width,2,"-").

    center_text("----[ NAVIGATION DATA HUD ]----",3).

    center_text(" LAT         LNG ",5).
    center_text("+XX.X      +XXX.X",6).

    center_text("HDG      VHDG     RLL    PTCH     AOA",8).
    center_text("XXX       XXX     +xx     +xx     +XX",9).

    center_text("ALT            ASL          RDR",11).
    center_text("             XXXXX        XXXXX",12).

    center_text(" TAS       VS       GS     GLOD",14).
    center_text("XXXX      +XXX     XXXX    +x.x",15).

    center_text(" LQF       PWR      EGN       TGO   ",17).
    center_text("XXX%      XXX%      [X]   XXXhXXmXXs",18).

    center_text("----[ AUTOPILOT GUIDANCE ][X]----",20).

    center_text(" ALT       VS       GS        HDG",22).
    center_text("XXXXX    +XXXX     XXXX       XXX",23).

    center_text("PTCH       RLL                MLT",25).
    center_text("+XX        +XX               xXXX",26).
}

// ==========================
// MAIN LOOP
// ==========================

local autopilot_on is False.

function main {
    until false {

        nav_data().

        if rcs {
            if not autopilot_on {
                set autopilot_on to True.
                print "/" at (33,20).
            }
        } else {
            if autopilot_on {
                set autopilot_on to False.
                print "X" at (33,20).
            }
        }

        if autopilot_on {
            autopilot().
        }
    }
}

// ==========================
// NAV DATA
// ==========================

function nav_data {

    // ==========================
    // LAT / LON
    // ==========================
    local lat is ship:latitude.
    local lon is ship:longitude.

    local latstr is fmt_float(abs(lat), 4, 1, " ").
    local lonstr is fmt_float(abs(lon), 5, 1, " ").

    if lat >= 0 { print "N" + latstr at (14,6). } else { print "S" + latstr at (14,6). } 
    if lon >= 0 { print "E" + lonstr at (25,6). } else { print "W" + lonstr at (25,6). }

    // ==========================
    // ATTITUDE
    // ==========================
    local hdg is round(compass_hdg()).
    print fmt_int(hdg,3," ") at (4,9).

    local vhdg is round(vectorHeading(ship:velocity:surface:vec)).
    print fmt_int(vhdg,3," ") at (14,9).

    local ptch is round(90 - vang(ship:facing:vector,ship:up:vector)).
    local roll is round(vang(ship:facing:topvector, vxcl(ship:facing:vector,ship:up:vector))).
    local aoa is  round(vang(vxcl(ship:facing:starvector,ship:srfprograde:vector), ship:facing:vector)).

    if vdot(ship:facing:vector,vcrs(ship:facing:topvector, ship:up:vector)) < 0 {
        set roll to -roll.
    }

    if vdot(ship:facing:starvector,vcrs(ship:facing:vector,ship:srfprograde:vector)) < 0 {
        set aoa to -aoa.
    }

    print fmt_int(roll,4," ") at (22,9).
    print fmt_int(ptch,4," ") at (29,9).
    print fmt_int(aoa,4," ") at (37,9).

    // // ==========================
    // // ALTITUDES
    // // ==========================
    local altasl is round(ship:altitude).
    local altrdr is round(alt:radar).

    print fmt_int(altasl,5," ") at (20,12).
    print fmt_int(altrdr,5," ") at (33,12).

    // // ==========================
    // // VELOCITIES
    // // ==========================
    local tas is round(ship:srfprograde:vector:mag).
    local vs is round(ship:verticalspeed).
    local gs is round(ship:groundspeed).

    // gload
    local gld is 0.
    if ship:availablethrust > 0 {
        set gld to (ship:mass / ship:availablethrust) / constant:g0.
    }

    print fmt_int(tas,4," ") at (5,15).
    print fmt_int(vs,5," ") at (17,15).
    print fmt_int(gs,5," ") at (26,15).
    print fmt_float(round(gld),3,1," ") at (34,15).

    // // ==========================
    // // RESOURCES
    // // ==========================
    local prp_obj is get_resource("LIQUIDFUEL").
    local pwr_obj is get_resource("ELECTRICCHARGE").

    local prp is 0.
    local pwr is 0.

    if prp_obj:capacity > 0 {
        set prp to prp_obj:amount / prp_obj:capacity.
    }
    if pwr_obj:capacity > 0 {
        set pwr to pwr_obj:amount / pwr_obj:capacity.
    }

    print fmt_int(round(prp*100),3," ") + "%" at (4,18).
    print fmt_int(round(pwr*100),3," ") + "%" at (14,18).

    // ==========================
    // ENGINE STATUS
    // ==========================
    local eng_on is ship:availablethrust > 0.
    if eng_on { 
        print "/" at (25,18).
    } else {
        print "X" at (25,18).
    }
    // ==========================
    // TGO (Time To Burnout)
    // ==========================
    local tgo is 0.

    if ship:availablethrust > 0 {

        // mdot = T / (Isp * g0)
        local mdot is ship:availablethrust / (ship_isp() * constant:g0).

        // mass flow safety
        if mdot > 0 {
            local fuel_mass is prp_obj:amount. // approximate (LF units ~ mass proxy)
            set tgo to fuel_mass / mdot.
        }
    }

    // // format TGO
    // local tgostr is fmt_time(tgo, "hms", 0, ":").
    // print fmt_fill(tgostr,11,">"," ") at (30,18).
}

// ==========================
// AUTOPILOT
// ==========================

function autopilot {
    //guidance logic here
}

// ==========================
// RUN
// ==========================

init_screen().
main().
