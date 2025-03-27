@lazyGlobal off.
set config:ipu to 1500.

function alt_scraper {
    // Define boundaries for latitude and longitude
    parameter start_lat.
    parameter end_lat.
    parameter start_long.
    parameter end_long.
    parameter filename.
    parameter step_size is 1/50.

    set filename to filename.

    print "Proceeding with data scraping".
    // Iterate over latitudes
    from { local lat is start_lat. } until lat >= end_lat  step { set lat to lat + step_size. } do {
        print "Proceeding with latitude : " + lat.
        // Iterate over longitudes
        from { local long is start_long. } until long >= end_long  step { set long to long + step_size. } do {
            // Obtain terrain height
            local local_height is latlng(lat, long):terrainheight.

            // Log latitude, longitude, and terrain height to a CSV file
            log lat + ", " + long + ", " + local_height to filename.
        }
    }
    print "Altitude scraping done!".
}

local file_name is ellis_island2.csv.
print file_name.
wait 1.

alt_scraper(4,8, -64, -60, file_name, 1/64).

function orbit_simulation{
    parameter r_i.
    parameter v_i.
    parameter dt.
    parameter max_time.

    local function grav_acc{
        parameter mu.
        parameter rad.

        return - (mu / rad:sqrmagnitude) * rad:normalized.
    }

    local r is list().
    local v is list().

    r:add(r_i).
    v:add(v_i).

    local r_t is r_i.
    local v_t is v_i.
    from {local t is 0.} until t > max_time step {set t to t+dt.} do {
        local a_g to grav_acc(mun:mu,r_t).

        set v_t to v_t + a_g * dt.
        set r_t to r_t + v_t * dt.

        v:add(v_t).
        r:add(r_t).
    }
}

function thrusted_trajectory{
    parameter body_.
    parameter r_i.
    parameter v_i.
    parameter targ_alt.
    parameter max_acc.
    parameter d_acc.
    parameter dt.
    parameter max_time.

    local function sign{
        parameter x.
        return x / abs(x).
    }

    local function grav_acc{
        parameter body__.
        parameter rad.

        return - (body__:mu / rad:sqrmagnitude) * rad:normalized.
    }

    local function vprj{
        parameter v1.
        parameter v2.

        return v2 * vdot(v1,v2) / v1:sqrmagnitude.
    }

    local function closest_item {
        parameter arr, n.

        // Separate the list into elements greater than n and elements less than n
        local greater_than_n to list().
        local less_than_n to list().
        
        for item in arr {
            if item > n {
                greater_than_n:add(item).
            } else if item < n {
                less_than_n:add(item).
            }
        }

        // If there are elements greater than n, find the closest one
        if greater_than_n:length > 0 {
            local min_diff to greater_than_n[0] - n.
            local closest_greater to greater_than_n[0].

            for item in greater_than_n {
                if (item - n) < min_diff {
                    set min_diff to (item - n).
                    set closest_greater to item.
                }
            }
            return closest_greater.
        }

        // If there are no elements greater than n, find the closest lesser one
        if less_than_n:length > 0 {
            local max_diff to n - less_than_n[0].
            local closest_lesser to less_than_n[0].

            for item in less_than_n {
                if (n - item) > max_diff {
                    set max_diff to (n - item).
                    set closest_lesser to item.
                }
            }
            return closest_lesser.
        }

        // If there are no elements in the list, return None
        return 0.
    }

    local function find_list_containing_number {
        parameter arr, n.
        for sublist in arr {
            for element in sublist {
                if element = n {
                    return sublist.
                }
            }
        }
        return list().
    }

    local r_t to r_i.
    local v_t to v_i.

    local parameter_list is list().

    from {local acc is 0.} until (acc >= max_acc) step {set acc to acc + d_acc.} do {
        from {local t is dt.} until (t >= max_time) step {set t to t + dt.} do {
            local a_g is grav_acc(body_,r_t).
            local a_c is acc.

            set v_t to v_t + (a_g + a_c) * dt.
            set r_t to r_t * v_t * dt.

            local alt_ is r_t:mag - body:radius.
            local ver_speed is -1 * sign(vdot(v_t,a_g)) * vprj(v_t, a_g).
            local hor_speed is vxcl(v_t,a_g):mag.

            if (hor_speed < 30) or (alt_ > 7500){
                break.
            }
            if alt < targ_alt {
                local downrange_angle is arcTan(r_t:x / r_t:y).
                local data_array is list(acc,t,hor_speed,ver_speed,alt_,downrange_angle).
                parameter_list:add(data_array).
                break.
            }
        }
    }
    local forty_list is list().
    local v_forty_list is list().

    from {local i is 0.} until i > parameter_list:length step {set i to i + 1.} do {
        local data_array is parameter_list[i].
        local hor_speed is data_array[2].
        if (hor_speed > 50) and (hor_speed > 30 ){
            forty_list:add(data_array).
            v_forty_list:add(hor_speed).
        } 
    }

    local smallest_v is closest_item(v_forty_list,40).
    local final_th is find_list_containing_number(forty_list,smallest_v).

    return final_th.
}


// set runmode to 1.
// until runmode = 0 {
//     if runmode = 1 {
//         // stuff
//     }
//     else if runmode = 2 {
//         // stuff
//     }
//     else if runmode = 3 {
//         // stuff
//     }
//     else if runmode = 4 {
        
//     }
// }