@lazyGlobal off.
set config:ipu to 2000.
runpath("0:/lib/borders.ks").


global mapping_status is "STANDBY".
global start_time is 0.  // Will store when we started
global total_points is 0.  // Total points to process
global processed_points is 0.  // Points processed so far

function get_atmospheric_properties {
    local parameter filename.
    local parameter h_limit to 70_000.
    local parameter delta_h to 10.
    local parameter title_header is True.

    set total_points to floor(h_limit / delta_h).
    set processed_points to 0.
    set filename to filename.
    set start_time to kuniverse:realtime.
        if title_header {
        log "altitude" + ", " + "temperature" + ", " + "pressure" + "," + "density" to filename.
    }
    set mapping_status to "Proceeding with data scraping       ".
    set mapping_status to "Data gathering in progress"..
    horizontal_line(0,terminal:width,7,"-").
    horizontal_line(0,terminal:width,10,"-").
    print "END HEIGHT : "+h_limit+"  " at (5,8).
    print "DELTA H    : "+delta_h+"  " at (5,9).

    from {local h is 0.} until (h >= h_limit) step {set h to h + delta_h.} do {
        print "CURRENT H :"+round(h) + "     " at (5,12).
        local T is body:atm:alttemp(h).
        local p is body:atm:altitudepressure(h) * constant:atmtokpa * 1000.
        local mol is body:atm:molarmass.
        local R_specific is constant:idealgas / mol.
        local rho is p / (R_specific * T).
        print "T : " + round(T,2) +"     " at (5,13).
        PRINT "p : " + round(p,2) +"     " at (5,14).
        print "R : " + round(R_specific,2) + "     " at (5,15).
        print "d : " + round(rho,2) +"      " at (5,16).
        
        log h + "," + T +"," + p + "," +  rho to filename.

        // Update progress and time remaining
        set processed_points to processed_points + 1.
        update_progress().
    }
    set mapping_status to "DATA GATHERING DONE        ".
    print "STATUS    : " + mapping_status at (2,terminal:height - 8).
}




function draw_borders {
    draw_edge_border().
    horizontal_line(0, terminal:width,0,"=").
    horizontal_line(0, terminal:width,5,"=").
    center_text("KERBIN ATMOSHERE DATA", 2).
    horizontal_line(0, terminal:width, terminal:height - 10, "=").
    print "STATUS    : " + mapping_status at (2,terminal:height - 8).
    print "PROGRESS  : " at (2, terminal:height - 6).
    print "TIME LEFT : " at (2, terminal:height - 4).
}

function update_progress {
    local elapsed is kuniverse:realtime - start_time.
    local points_left is total_points - processed_points.
    
    // Calculate time per point (avoid division by zero)
    local time_per_point is 0.
    if processed_points > 0 {
        set time_per_point to elapsed / processed_points.
    }
    
    // Calculate remaining time
    local remaining_time is points_left * time_per_point.
    
    // Convert to hours:minutes:seconds
    local hours_left is floor(remaining_time / 3600).
    local minutes_left is floor(mod(remaining_time,3600) / 60).
    local seconds_left is floor(mod(remaining_time,60)).
    
    // Calculate progress percentage
    local progress_percent is (processed_points / total_points) * 100.
    
    // Update display
    print "PROGRESS  : " + round(progress_percent, 1) + "% (" + processed_points + "/" + total_points + ")" + "      " at (2, terminal:height - 6).
    print "TIME LEFT : " + hours_left + "h " + minutes_left + "m " + seconds_left + "s   " + "      "  at (2, terminal:height - 4).
}

local file_name is "0:/atmdata/atmdata_kerbin.csv".
print file_name.
wait 1.
clearScreen.
draw_borders().
get_atmospheric_properties(file_name).

wait 1.
unlock all.
clearScreen.