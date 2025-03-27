
function compass_hdg {
    local up_vector is ship:up:vector.
    local north_vector is ship:north:vector. // Horizontal North direction
    local east_vector is vcrs(up_vector, north_vector).       // Horizontal East direction
    local facing_vector is ship:facing:forevector.
    local projV is vxcl(up_vector, facing_vector). // Project forward vector onto the horizontal plane

    local angle is vang(north_vector, projV). // Angle from North

    // Use dot product with east to determine left/right deviation
    if vdot(projV, east_vector) < 0 {
        set angle to 360 - angle.
    }
    return angle.
}

function log_flight_data {
    local parameter time__.
    local parameter signal. 
    local parameter setpoint.

    set file_name to "hu1pidtuning1.csv".
    if not exists(file_name) {
        // Create the file and write the header if it doesn't exist
        log "Time,Signal,Setpoint" to file_name.
    }
    set signal to round(signal, 2).
    set time_now to round(time__, 2).
    set setpoint to round(setpoint,2).
    log time_now + "," + signal+ ","+ setpoint to file_name.
}

set collective to 0.
local targ_alt is 50.
lock throttle to collective.

clearScreen.
local targ_vertvel to 0.
set vertpid to pidLoop(0.4,0.6,0.025,0,1). // this is good

local targ_forvel to 10.
// set forepid to pidLoop(5,0.6,0.25,-30,30).
// set forepid to pidLoop(1,0.4,5,-30,30).
// set forepid to pidLoop(5,1.5,2.5,-30,30).
set forepid to pidLoop(3,1.5,0,-30,30).

// pitch and roll pid
set targ_sidevel to 0.
set sidepid to pidLoop(4,0.6,0.25,-15,15).

set targ_hdg to compass_hdg().
set hoverpid to pidLoop(0.03,0.005,0.07,0,1).

set system_done to false.
set runmode to 1.
set time_limit to 195.
set time_start to time:seconds.

set targ_ang to -10.
sas on.
rcs on.


set pitch_ang to 0.
set side_ang to 0.

set steeringManager:pitchpid:kp to 3.5.
set steeringManager:pitchpid:ki to 0.1.
set steeringManager:pitchpid:kd to 0.5.
set steeringManager:maxstoppingtime to 10.

function angle_data_collection{
    local parameter time__.
    local parameter signal.
    local parameter setpoint.

    set file_name to "pitchpid.csv".
    if not exists(file_name) {
        // Create the file and write the header if it doesn't exist
        log "Time,Signal,Setpoint" to file_name.
    }
    set signal to round(signal, 2).
    set time_now to round(time__, 2).
    set setpoint to round(setpoint,2).
    log time_now + "," + signal+ ","+ setpoint to file_name.
}

function flight_control {
    local parameter targvertvel.
    local parameter targforvel.
    local parameter targsidevel.

    local velocity_vector is ship:velocity:surface:vec.
    local up_vector is ship:up:vector.
    local fore_vector is vxcl(up_vector,ship:facing:forevector).
    local starboard_vector is vcrs(up_vector, fore_vector).

    // Compute the components
    local fore_component is vdot(velocity_vector, fore_vector).
    local side_component is vdot(velocity_vector, starboard_vector).

    set vertpid:setpoint to targvertvel.
    set collective to vertpid:update(time:seconds, ship:verticalspeed).

    set forepid:setpoint to targforvel.
    set pitch_ang  to -forepid:update(time:seconds, fore_component).
    
    set sidepid:setpoint to targsidevel.
    set side_ang to -sidepid:update(time:seconds, side_component).
}

until system_done {
    local velocity_vector is ship:velocity:surface:vec.
    local up_vector is ship:up:vector.
    local fore_vector is vxcl(up_vector,ship:facing:forevector).
    local starboard_vector is vcrs(up_vector, fore_vector).

    // Compute the components
    local up_component is vdot(velocity_vector, up_vector).
    local fore_component is vdot(velocity_vector, fore_vector).
    local side_component is vdot(velocity_vector, starboard_vector).

    if runmode = 1 {
        // initial ascent
        print("INITIAL ASCENT   ") at (2,5).
        set hoverpid:setpoint to targ_alt.
        set collective to hoverpid:update(time:seconds, alt:radar).
        if alt:radar > 48 {
            set time_start to time:seconds.
            sas off.
            lock steering to heading(targ_hdg, pitch_ang, side_ang).
            set minitimer to time:seconds.
            set minimode to -2.
            set targ_forvel to -5.
            set runmode to 1.75.
            //set runmode to 1.5.
        }
    }
    if runmode = 1.5 {
        print("STARTING TEST  SPEED ") at (2,5).

        set hoverpid:setpoint to targ_alt.
        set collective to hoverpid:update(time:seconds, alt:radar).

        set sidepid:setpoint to targ_sidevel.
        set side_ang to -sidepid:update(time:seconds, side_component).

        // lock steering to heading(targ_hdg, targ_ang, side_ang).

        angle_data_collection((time:seconds - time_start),90-vang(ship:up:vector,ship:facing:forevector),targ_ang).
        if (time:seconds - time_start) > time_limit {
            print("INITIATING SLOWDOWN  ") at (2,5).
            set targ_forvel to 0.
            set runmode to 3. 
        }
    }
    if runmode = 1.75 {
        print("STARTING TEST   ") at (2,5).
        print("MINIMODE   ") + minimode at (2,6).
        if minimode = -2 {
            if (time:seconds - minitimer) > 15 {
                set targ_forvel to 0.
                set minitimer to time:seconds.
                set minimode to -1.
            }
        }
        if minimode = -1 {
            if (time:seconds - minitimer) > 15 {
                set targ_forvel to 5.
                set minitimer to time:seconds.
                set minimode to 0.
            }
        }
        if minimode = 0 {
            if (time:seconds - minitimer) > 15 {
                set targ_forvel to 10.
                set minitimer to time:seconds.
                set minimode to 1.
            }
        }
        if minimode = 1 {
            if (time:seconds - minitimer) > 15 {
                set targ_forvel to 15.
                set minitimer to time:seconds.
                set minimode to 2.
            }
        } 
        if minimode = 2 {
            if (time:seconds - minitimer) > 15 {
                set targ_forvel to 20.
                set minitimer to time:seconds.
                set minimode to 3.
            }
        }
        if minimode = 3 {
            if (time:seconds - minitimer) > 15 {
                set targ_forvel to 25.
                set minitimer to time:seconds.
                set minimode to 4.
            }
        }
        if minimode = 4 {
            if (time:seconds - minitimer) > 15 {
                set targ_forvel to 30.
                set minitimer to time:seconds.
                set minimode to 5.
            }
        }
        if minimode = 5 {
            if (time:seconds - minitimer) > 15 {
                set targ_forvel to 35.
                set minitimer to time:seconds.
                set minimode to 6.
            }
        }
        if minimode = 6 {
            if (time:seconds - minitimer) > 15 {
                set targ_forvel to 40.
                set minitimer to time:seconds.
                set minimode to 7.
            }
        }
        if minimode = 7 {
            if (time:seconds - minitimer) > 15 {
                set targ_forvel to 45.
                set minitimer to time:seconds.
                set minimode to 8.
            }
        }
        if minimode = 8 {
            if (time:seconds - minitimer) > 15 {
                set targ_forvel to 50.
                set minitimer to time:seconds.
                set minimode to 9.
            }
        }
        if minimode = 9 {
            if (time:seconds - minitimer) > 15 {
                set targ_forvel to 55.
                set minitimer to time:seconds.
                set minimode to 10.
            }
        }
        if minimode = 10 {
            if (time:seconds - time_start) > time_limit {
                print("INITIATING SLOWDOWN  ") at (2,5).
                set targ_forvel to 0.
                set runmode to 3. 
            }
        }
        set forepid:setpoint to targ_forvel.
        set pitch_ang  to -forepid:update(time:seconds, fore_component).
        
        set hoverpid:setpoint to targ_alt.
        set collective to hoverpid:update(time:seconds, alt:radar).

        set sidepid:setpoint to targ_sidevel.
        set side_ang to -sidepid:update(time:seconds, side_component).

        print round(pitch_ang ,1) + "       " + round(side_ang ,1) at (5,23).

        log_flight_data((time:seconds - time_start),fore_component,targ_forvel).
    }
    if runmode = 2 {
        print("STARTING TEST   ") at (2,5).
        set forepid:setpoint to targ_forvel.
        set pitch_ang  to -forepid:update(time:seconds, fore_component).
        
        set hoverpid:setpoint to targ_alt.
        set collective to hoverpid:update(time:seconds, alt:radar).

        set sidepid:setpoint to targ_sidevel.
        set side_ang to -sidepid:update(time:seconds, side_component).

        print round(pitch_ang ,1) + "       " + round(side_ang ,1) at (5,23).

        log_flight_data((time:seconds - time_start),fore_component,targ_forvel).
        if (time:seconds - time_start) > time_limit {
            print("INITIATING SLOWDOWN  ") at (2,5).
            set targ_forvel to 0.
            set runmode to 3. 
        }
    }

    if runmode = 3 {
        set forepid:setpoint to targ_forvel.
        set pitch_ang  to -forepid:update(time:seconds, fore_component).
        
        set hoverpid:setpoint to targ_alt.
        set collective to hoverpid:update(time:seconds, alt:radar).

        set sidepid:setpoint to targ_sidevel.
        set side_ang to -sidepid:update(time:seconds, side_component).

        lock steering to heading(targ_hdg, pitch_ang, side_ang).
        if fore_component < 4.5 {
            lock steering to  heading(targ_hdg, 5 , 0).
            set runmode to 7.
        }
    }
    if runmode = 7 {
        print("BEGIN DESCENT   ") at (2,5).
        set targ_sidevel to 0.
        set targ_forvel to 0.
        set targ_vertvel to -7.5.
        until vang(ship:up:vector,ship:facing:forevector) > 85 {
            lock steering to heading(targ_hdg, 5).
        }
        
        set runmode to 8.
    }
    if runmode = 8 {
        flight_control(targ_vertvel,targ_forvel,targ_sidevel).
        if alt:radar < 15 {
            set targ_vertvel to -1.5.
            set runmode to 9.
        }
    }
    if runmode = 9 {
        flight_control(targ_vertvel,targ_forvel,targ_sidevel).
        if alt:radar < 0.75 {
            print("LANDED, TEST DONE   ") at (2,5).
            set runmode to 10.
        }
    }
    if runmode = 10 {
        rcs off.
        sas off.
        set system_done to true.
    }
    print "RUNMODE : " + runmode at (2,2).
    print "TIME : " + round((time:seconds - time_start),1) at (5,8).
    print "V : "+targ_vertvel+ "   " at (5,12).
    print "F : "+targ_forvel+ "   " at (15,12).
    print "S : "+targ_sidevel+ "   " at (25,12).

    print "ALT RDR : "+round(alt:radar,2) at (5,10).

    print "UP     : " + round(up_component,2)+ "   " at (5,16).
    print "FORE   : " + round(fore_component,2)+ "   " at (5,17).
    print "STRBRD : " + round(side_component,2)+ "   " at (5,18).

    print "TGT HDG : " + round(targ_hdg)+"  " at (5,20).
    print "TRU HDG : " + round(compass_hdg())+"  " at (5,21).
}

// PID TUNING PROCESS
// ADJUST KP SO THAT THERE ARE ACCEPTABLE OSCILLATIONS. NOT REACHING SETPOINT IS OK.
// ADJUST KD TO DAMPEN THE OSCILLATIONS.
// ADJUST KI TO ADJUST FOR SETPOINT DIFFERENCE.