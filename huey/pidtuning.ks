@lazyGlobal off.
set config:ipu to 2000.

global helipad to latlng(
    -0.0972424565451832,
    -74.557679156208
).

// velocity and component vectors
lock north_vector to ship:north:vector:normalized.
lock up_vector to ship:up:vector:normalized.
lock east_vector to vcrs(up_vector,north_vector).
lock fore_vector to vxcl(up_vector,ship:facing:forevector):normalized.
lock starboard_vector to vcrs(up_vector, fore_vector):normalized.

lock velocity_vector to ship:velocity:surface:vec.
lock up_component to vdot(velocity_vector, up_vector).
lock fore_component to vdot(velocity_vector, fore_vector).
lock side_component to vdot(velocity_vector, starboard_vector).

lock E_pos to vDot(helipad:position,east_vector).
lock N_pos to vDot(helipad:position,north_vector).
lock U_pos to vDot(helipad:position,up_vector).

// collective throttle
global collective to 0.
lock throttle to collective.

// pids
// hover pid
global targ_alt is 50.
global hover_kp is 0.03.
global hover_ki is 0.005.
global hover_kd is 0.07.
global hoverpid to pidLoop(hover_kp,hover_ki,hover_kd,0,1).

// vertical speed pid
global targ_vertvel to 0.
global vert_kp to 0.4.
global vert_ki to 0.6.
global vert_kd to 0.025.
global vertpid to pidLoop(vert_kp,vert_ki,vert_kd,0,1). // this is good

// side speed pid
global targ_sidevel to 0.
global side_kp to 4.
global side_ki to 0.6.
global side_kd to 0.25.
global sidepid to pidLoop(side_kp,side_ki,side_kd,-15,15).

// forward speed pid
local targ_forvel to 0.
global for_kp to 4.
global for_ki to 1.5.
global for_kd to 0.
global forepid to pidLoop(for_kp,for_ki,for_kd,-30,30).

// set forepid to pidLoop(5,0.6,0.25,-30,30).
// set forepid to pidLoop(1,0.4,5,-30,30).
// set forepid to pidLoop(5,1.5,2.5,-30,30).

// steering manager pids
// set steeringManager:pitchpid:kp to 3.5.
// set steeringManager:pitchpid:ki to 0.1.
// set steeringManager:pitchpid:kd to 0.5.
// set steeringManager:maxstoppingtime to 10.

// initial declarations
global targ_hdg to compass_hdg().
global targ_ang to -10.
global pitch_ang to 0.
global side_ang to 0.

// control loop settings
// global time_limit to 195. for angle test
global time_limit to 30.
global time_start to time:seconds.
global runmode to "ASCENT".
global file_name to "hu1pidtuning1.csv".


clearScreen.
sas on.
rcs on.

until runmode = "SYSTEM DONE" {
    if runmode = "ASCENT" {
        // initial ascent
        print("INITIAL ASCENT   ") at (2,5).
        set hoverpid:setpoint to targ_alt.
        set collective to hoverpid:update(time:seconds, alt:radar).
        if alt:radar > 49 {
            set time_start to time:seconds.
            sas off.
            lock steering to heading(targ_hdg, pitch_ang, side_ang).

            global minitimer to time:seconds.
            global minimode to -5.
            // set targ_forvel to -5.
            // set runmode to"ANGLE TEST".
            set targ_hdg to 0.
            set targ_forvel to 15.
            set runmode to "RETURN TEST".
        }
    }
    if runmode = "RETURN TEST" {
        flight_control("hover").
        if (time:seconds-minitimer)>15{
            set targ_hdg to 270.
        }
        if (time:seconds - time_start) > time_limit {
            print("INITIATING SLOWDOWN  ") at (2,5).
            set targ_forvel to 0.
            set runmode to "SLOWDOWN". 
        }
    }
    if runmode = "PITCH TEST" {
        print("STARTING TEST  SPEED ") at (2,5).

        set hoverpid:setpoint to targ_alt.
        set collective to hoverpid:update(time:seconds, alt:radar).

        set sidepid:setpoint to targ_sidevel.
        set side_ang to -sidepid:update(time:seconds, side_component).

        lock steering to heading(targ_hdg, targ_ang, side_ang).

        angle_data_collection((time:seconds - time_start),90-vang(ship:up:vector,ship:facing:forevector),targ_ang).
        if (time:seconds - time_start) > time_limit {
            print("INITIATING SLOWDOWN  ") at (2,5).
            set targ_forvel to 0.
            set runmode to "SLOWDOWN". 
        }
    }
    if runmode = "ANGLE TEST" {
        print("STARTING TEST   ") at (2,5).
        print("MINIMODE   ") + minimode at (2,6).
        if minimode = -5 {
            if (time:seconds - minitimer) > 15 {
                set targ_forvel to 0.
                set minitimer to time:seconds.
                set minimode to 0.
            }
        }
        if minimode = 0 {
            if (time:seconds - minitimer) > 15 {
                set targ_forvel to 5.
                set minitimer to time:seconds.
                set minimode to 5.
            }
        }
        if minimode = 5 {
            if (time:seconds - minitimer) > 15 {
                set targ_forvel to 10.
                set minitimer to time:seconds.
                set minimode to 10.
            }
        }
        if minimode = 10 {
            if (time:seconds - minitimer) > 15 {
                set targ_forvel to 15.
                set minitimer to time:seconds.
                set minimode to 15.
            }
        } 
        if minimode = 15 {
            if (time:seconds - minitimer) > 15 {
                set targ_forvel to 20.
                set minitimer to time:seconds.
                set minimode to 20.
            }
        }
        if minimode = 20 {
            if (time:seconds - minitimer) > 15 {
                set targ_forvel to 25.
                set minitimer to time:seconds.
                set minimode to 25.
            }
        }
        if minimode = 25 {
            if (time:seconds - minitimer) > 15 {
                set targ_forvel to 30.
                set minitimer to time:seconds.
                set minimode to 30.
            }
        }
        if minimode = 30 {
            if (time:seconds - minitimer) > 15 {
                set targ_forvel to 35.
                set minitimer to time:seconds.
                set minimode to 35.
            }
        }
        if minimode = 35 {
            if (time:seconds - minitimer) > 15 {
                set targ_forvel to 40.
                set minitimer to time:seconds.
                set minimode to 40.
            }
        }
        if minimode = 40 {
            if (time:seconds - minitimer) > 15 {
                set targ_forvel to 45.
                set minitimer to time:seconds.
                set minimode to 45.
            }
        }
        if minimode = 45 {
            if (time:seconds - minitimer) > 15 {
                set targ_forvel to 50.
                set minitimer to time:seconds.
                set minimode to 50.
            }
        }
        if minimode = 50 {
            if (time:seconds - minitimer) > 15 {
                set targ_forvel to 55.
                set minitimer to time:seconds.
                set minimode to 55.
            }
        }
        if minimode = 55 {
            if (time:seconds - time_start) > time_limit {
                print("INITIATING SLOWDOWN  ") at (2,5).
                set targ_forvel to 0.
                set runmode to "SLOWDOWN". 
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
    if runmode = "STABILITY TEST" {
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
            set runmode to "SLOWDOWN". 
        }
    }
    if runmode = "SLOWDOWN" {
        flight_control("hover").
        if fore_component < 1 {
            lock steering to  heading(targ_hdg, 5 , 0).
            // set runmode to "DESCENT".
            set runmode to "RETURN TO HELIPAD".
        }
    }
    if runmode = "RETURN TO HELIPAD" {
        return_to_helipad().
        set runmode to "SYSTEM DONE".
    }
    if runmode = "DESCENT" {
        print("BEGIN DESCENT   ") at (2,5).
        set targ_sidevel to 0.
        set targ_forvel to 0.
        set targ_vertvel to -7.5.
        until vang(ship:up:vector,ship:facing:forevector) > 85 {
            lock steering to heading(targ_hdg, 5).
        }
        
        set runmode to "DESCENT PHASE 1".
    }
    if runmode = "DESCENT PHASE 1" {
        flight_control("velocity control").
        if alt:radar < 15 {
            set targ_vertvel to -1.5.
            set runmode to "DESCENT PHASE 2".
        }
    }
    if runmode = "DESCENT PHASE 2" {
        flight_control("velocity control").
        if alt:radar < 0.75 {
            print("LANDED, TEST DONE   ") at (2,5).
            set runmode to "SHUTDOWN".
        }
    }
    if runmode = "SHUTDOWN" {
        rcs off.
        sas off.
        set runmode to "SYSTEM DONE".
    }

        // emergency landing.
    if terminal:input:haschar() {
        local ch to terminal:input:getchar().
        if ch = terminal:input:backspace {
            set targ_vertvel to -7.5.
            set targ_sidevel to 0.
            set targ_forvel to 0.
            set runmode to "EMERGENCY LANDING".
        }
        terminal:input:clear(). 
    }
    if runmode = "EMERGENCY LANDING" {
        flight_control("velocity control").
        if alt:radar < 10 {
            set targ_vertvel to -1.5.
        }
        if alt:radar < 0.75 {
            print("LANDED, TEST DONE   ") at (2,5).
            set runmode to "SHUTDOWN".
        }
    }
    screen().
}

function hdg_lerp {
    local parameter target_heading.
    local parameter turn_factor is 0.2.
    return (1-turn_factor)*compass_hdg() + turn_factor*target_heading.
}

function pitch_lerp{
    local parameter target_speed.
    local parameter turn_factor is 0.15.
    return (1-turn_factor)*fore_component + turn_factor * target_speed.
}

function helipad_distance{
    parameter mode.
    if mode = "raw position" {
        return v(e_pos,n_pos,u_pos).
    }
    if mode = "distance" {
        return sqrt(e_pos^2+n_pos^2+u_pos^2).
    }
    if mode = "vertical distance" {
        return u_pos.
    }
    if mode = "Horizontal Distance" {
        return sqrt(e_pos^2+n_pos^2).
    }
}
function return_to_helipad {
    set runmode to "SETTING BEARINGS".
    until runmode = "LANDED" {
        if runmode = "SETTING BEARINGS" {
            set targ_hdg to compass_hdg().
            set targ_alt to 60.
            set targ_forvel to 0.
            lock steering to heading(targ_hdg, pitch_ang, side_ang).
            set runmode to "TURNING".
        }
        if runmode = "TURNING" {
            set targ_hdg to  hdg_lerp(helipad:heading).
            flight_control("hover").
            if (abs(compass_hdg() - helipad:heading) < 5) {
                set targ_forvel to 15.
                set runmode to "RETURNING".
            } 
        }
        if runmode = "RETURNING" {
            set targ_hdg to  hdg_lerp(helipad:heading).
            flight_control("hover").
            if (helipad_distance("horizontal distance") < 100)  {
                set targ_forvel to 5.
                set targ_vertvel to -5.
                set runmode to "SLOWING DOWN".
            }
        }
        if runmode = "SLOWING DOWN" {
            set targ_hdg to  hdg_lerp(helipad:heading).
            flight_control("velocity control").
            if alt:radar < 7.5 {
                set targ_vertvel to 0.
            }
            if helipad_distance("horizontal distance") < 10 {
                set targ_forvel to 1.
                if alt:radar < 7.5 {
                    set targ_alt to 7.5.
                    set runmode to "SETTING ATOP".
                }
            }
        }
        if runmode = "SETTING ATOP" {
            // this is much better done with pids with x and y but for initial testing this is good
            flight_control("hover").
            set targ_hdg to  hdg_lerp(helipad:heading).
            if helipad_distance("horizontal distance") < 0.5 {
                set targ_forvel to 0.
                set targ_vertvel to -1.5.
                set runmode to "DESCENDING".
            }
        }
        if runmode = "DESCENDING" {
            set targ_hdg to hdg_lerp(0).
            flight_control("velocity control").
            if alt:radar < 0.75 {
                print("LANDED, TEST DONE   ") at (2,5).
                set runmode to "SHUTDOWN".
            }
        }
        if runmode = "SHUTDOWN" {
            rcs off.
            sas off.
            set runmode to "LANDED".
        }
        // emergency landing.
        if terminal:input:haschar() {
            local ch to terminal:input:getchar().
            if ch = terminal:input:backspace {
                set targ_vertvel to -7.5.
                set targ_forvel to 0.
                set runmode to "EMERGENCY LANDING".
            }
            terminal:input:clear(). 
        }
        if runmode = "EMERGENCY LANDING" {
            flight_control("velocity control").
            if alt:radar < 10 {
                set targ_vertvel to -1.5.
            }
            if alt:radar < 0.75 {
                print("LANDED, TEST DONE   ") at (2,5).
                set runmode to "SHUTDOWN".
            }
        }
        screen().
    }
}

function flight_control {
    local parameter mode.
    
    if mode = "velocity control" {
        set vertpid:setpoint to targ_vertvel.
        set collective to vertpid:update(time:seconds, ship:verticalspeed).

        set forepid:setpoint to targ_forvel.
        set pitch_ang  to -forepid:update(time:seconds, fore_component).
        
        set sidepid:setpoint to targ_sidevel.
        set side_ang to -sidepid:update(time:seconds, side_component).
    }
    if mode = "hover" {
        set hoverpid:setpoint to targ_alt.
        set collective to hoverpid:update(time:seconds, alt:radar).

        set forepid:setpoint to targ_forvel.
        set pitch_ang  to -forepid:update(time:seconds, fore_component).
        
        set sidepid:setpoint to targ_sidevel.
        set side_ang to -sidepid:update(time:seconds, side_component).
    }

}

function angle_data_collection {
    local parameter time__.
    local parameter signal.
    local parameter setpoint.

    if not exists(file_name) {
        // Create the file and write the header if it doesn't exist
        log "Time,Signal,Setpoint" to file_name.
    }
    set signal to round(signal, 2).
    local time_now to round(time__, 2).
    set setpoint to round(setpoint,2).
    log time_now + "," + signal+ ","+ setpoint to file_name.
}

function screen {
    print "RUNMODE : " + runmode + "           " at (2,2).
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

    print "E : " + round(E_pos,1)+" " at (5,23).
    print "N : " + round(N_pos,1)+" " at (15,23).
    print "U : " + round(U_pos,1)+" " at (25,23).
    print "DIST : " + round(helipad_distance("Horizontal Distance"),2) at (5,24).
}

function compass_hdg {
    local up_vector is ship:up:vector.
    local north_vector is ship:north:vector.
    local east_vector is vcrs(up_vector, north_vector).  
    local facing_vector is ship:facing:forevector.
    local projV is vxcl(up_vector, facing_vector).
    local angle is vang(north_vector, projV). 
    if vdot(projV, east_vector) < 0 {
        set angle to 360 - angle.
    }
    return angle.
}

function log_flight_data {
    local parameter time__.
    local parameter signal. 
    local parameter setpoint.
    if not exists(file_name) {
        // Create the file and write the header if it doesn't exist
        log "Time,Signal,Setpoint" to file_name.
    }
    set signal to round(signal, 2).
    local time_now to round(time__, 2).
    set setpoint to round(setpoint,2).
    log time_now + "," + signal+ ","+ setpoint to file_name.
}

// PID TUNING PROCESS
// ADJUST KP SO THAT THERE ARE ACCEPTABLE OSCILLATIONS. NOT REACHING SETPOINT IS OK.
// ADJUST KD TO DAMPEN THE OSCILLATIONS.
// ADJUST KI TO ADJUST FOR SETPOINT DIFFERENCE.

// autoreturn and emergency break done.
// still tuning the forward and side speed components.