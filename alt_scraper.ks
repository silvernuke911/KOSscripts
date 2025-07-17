@lazyGlobal off.
set config:ipu to 2000.
runpath("0:/lib/borders.ks").

global mapping_status is "STANDBY".
global start_time is 0.  // Will store when we started
global total_points is 0.  // Total points to process
global processed_points is 0.  // Points processed so far

function draw_borders {
    draw_edge_border().
    horizontal_line(0, terminal:width,0,"=").
    horizontal_line(0, terminal:width,5,"=").
    center_text("KERBIN ALTITUDE SCRAPER", 2).
    horizontal_line(0, terminal:width, terminal:height - 10, "=").
    print "STATUS    : " + mapping_status at (2,terminal:height - 8).
    print "PROGRESS  : " at (2, terminal:height - 6).
    print "TIME LEFT : " at (2, terminal:height - 4).
}

function alt_scraper {
    // Define boundaries for latitude and longitude
    parameter start_lat.
    parameter end_lat.
    parameter start_long.
    parameter end_long.
    parameter filename.
    parameter step_size is 1/50.
    parameter title_header is False.

    // Calculate total points
    set total_points to floor((end_lat - start_lat)/step_size) * floor((end_long - start_long)/step_size).
    set processed_points to 0.
    set start_time to kuniverse:realtime.
    
    set filename to filename.
    
    if title_header {
        log "latitude" + ", " + "longitude" + ", " + "height" to filename.
    }

    set mapping_status to "Proceeding with data scraping       ".
    set mapping_status to "Mapping in progress".
    print "START LAT : "+start_lat+"  " at (5,7).
    print "END LAT   : "+end_lat+"  " at (25,7).
    print "START LONG: "+start_long+"  " at (5,9).
    print "END LONG  : "+end_long+"  " at (25,9).
    print "STEP SIZE : "+step_size+"  " at (5,11).

    // Iterate over latitudes
    from { local lat is start_lat. } until lat >= end_lat  step { set lat to lat + step_size. } do {

        // Iterate over longitudes
        from { local long is start_long. } until long >= end_long  step { set long to long + step_size. } do {
            // Obtain terrain height
            local local_height is latlng(lat, long):terrainheight.
            print "CURRENT LAT : " + round(lat,3) + "   " at (3, 15).
            print "CURRENT LON : " + round(long,3) + "   " at (3, 17).
            
            // Log latitude, longitude, and terrain height to a CSV file
            log lat + ", " + long + ", " + local_height to filename.
            
            // Update progress and time remaining
            set processed_points to processed_points + 1.
            update_progress().
        }
        print "STATUS    : " + mapping_status + "     " at (2,terminal:height - 8).
    }
    set mapping_status to "Altitude scraping done            ".
    print "STATUS    : " + mapping_status at (2,terminal:height - 8).
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

local file_name is "0:/terrain_data/kile_River2555x20.csv".
print file_name.
wait 1.
clearScreen.
draw_borders().
alt_scraper(25,55,-180,-130,file_name,1/20).
//alt_scraper(30,35,-180,-130,file_name,1/50).
// 25 -> 55, -180  ->  -130

wait 1.
unlock all.
clearScreen.