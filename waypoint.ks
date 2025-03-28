@lazyGlobal off.
set config:ipu to 1500.

lock up_vector to ship:up:vector:normalized.
lock north_vector to ship:north:vector:normalized.
lock east_vector to vcrs(up_vector, north_vector):normalized.

local target_waypoint_coords is list(100,0,1000).
local target_waypoint is (
    ship:position - 
    kerbin:position) +
( 
    target_waypoint_coords[0]*east_vector +
    target_waypoint_coords[1]*north_vector +
    target_waypoint_coords[2]*up_vector
).

global init_pos to ship:position - kerbin:position.
global runmode to "ignition".
sas off.
global start_time to time:seconds.
lock current_pos to (ship:position - kerbin:position).
clearScreen.
until runmode = "DONE" {
    if runmode = "ignition" {
        stage.
        lock steering to heading(90,90,-90).
        set runmode to "tower clearing".
    }
    if runmode = "tower clearing" {
        if ship:velocity:surface:mag > 50 {
            lock steering to (current_pos - target_waypoint).
            set runmode to "target lock".
        }
    }
    if runmode = "target lock" {
        if (current_pos - target_waypoint):mag < 10 {
            unlock steering.
            sas on.
            set runmode to "recovery".
        }
    }
    if runmode = "recorvery" {
        //lmao
    }
    screen().
    log_flight_data(time:seconds-start_time).
}

function coord_velocities {
    local surfvel is ship:velocity:surface.
    local xvel is vDot(east_vector,  surfvel).
    local yvel is vDot(north_vector, surfvel).
    local zvel is vDot(up_vector,    surfvel).
    return list(xvel,yvel,zvel).
}

function coord_position {
    local vespos is (ship:position-kerbin:position) - init_pos.
    local xpos is vDot(east_vector,  vespos).
    local ypos is vDot(north_vector, vespos).
    local zpos is vDot(up_vector,    vespos).
    return list(xpos,ypos,zpos).
}

function screen {
    print "Ship name  : " + ship:name at (5,2).
    print "Runmode    : " + runmode at (5,3).
    print "MET        : " + round(time:seconds - start_time,2) at (5,4).

    print "Velocity     : " + round(ship:velocity:surface:mag,1) at (5,6).
    local coord_vels is coord_velocities().
    print "X Velocity   : " + round(coord_vels[0],1) at (5,8).
    print "Y Velocity   : " + round(coord_vels[1],1) at (5,9).
    print "Z Velocity   : " + round(coord_vels[2],1) at (5,10).
    local coord_pos is coord_position().
    print "X Position   : " + round(coord_pos[0],1) at (5,12).
    print "Y Position   : " + round(coord_pos[1],1) at (5,13).
    print "Z Position   : " + round(coord_pos[2],1) at (5,14).

    print "POS" + ship:position at (5,16).
}

function log_flight_data {
    local parameter time__.

    local file_name to "waypoint0002.csv".
    if not exists(file_name) {
        // Create the file and write the header if it doesn't exist
        log "Time,Xpos,Ypos,Zpos" to file_name.
    }
    local coord_pos is coord_position().
    local xpos to coord_pos[0].
    local ypos to coord_pos[1].
    local zpos to coord_pos[2].
    local time_now to time__.
    log time_now + "," + xpos+ ","+ ypos + "," + zpos to file_name.
}

// this works, we can probably move on now.