// v2 launch program
set init_long to ship:longitude.
sas off.
clearScreen.
lock throttle to 1.
declare runmode is 1.
stage.
wait 2.
stage.
until runmode = 0 {
    if runmode = 1{
        sas off.
        lock throttle to 1.
        if altitude > 100 {
            lock steering to heading (0,90).
        }
        if verticalSpeed>100 {
            set runmode to 2.
        }
    } 
    if runmode = 2 {
        lock steering to heading (90,65,-90).
        wait 15.
        set runmode to 3.
    }
    if runmode = 3 {
        lock steering to heading (90, vang(ship:velocity:surface, vCrs(ship:up:vector, ship:north:vector)), -90).
        if availableThrust = 0 {
            set runmode to 4.
        }
    }
    if runmode = 4 {
        lock steering to velocity:surface.
    }
    display_flight_data().
    log_flight_data().
}

function display_flight_data {
    print "Time: " + round(missiontime, 2) + " s" at (5,5).
    print "Altitude: " + round(ship:altitude, 2) + " m"  at (5,6).
    print "Downrange: " + round((ship:longitude-init_long) * 2 *constant:pi * kerbin:radius /360,2) + " m"  at (5,7).
}
function log_flight_data {
    set file_name to "v2data.csv".
    
    if not exists(file_name) {
        // Create the file and write the header if it doesn't exist
        log "Time,Altitude (m),Downrange (m)" to file_name.
    }
    set ship_alt to round(ship:altitude, 2).
    set downrange to round((ship:longitude-init_long) * 2 *constant:pi * kerbin:radius /360,2).
    set time_now to round(missiontime, 2).
    
    log time_now + "," + ship_alt + "," + downrange to file_name.
}