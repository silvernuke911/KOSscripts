// This script defines a function `qwait` that waits for a specified time while allowing the main loop to continue executing. 
// Once the wait time has elapsed, the function executes the given action exactly once.

function qwait {
    parameter timestart.  // The time when waiting started
    parameter wait_time.  // The duration to wait before returning true
    parameter mode is "universal time".  // Default is "universal time"
    
    if (mode = "universal time") {
        return (time:seconds - timestart) > wait_time.
    }
    if (mode = "mission time") {
        return (ship:met - timestart) > wait_time.
    }
    return false.  // If an invalid mode is given, return false
}


set action_done to false. // action done trigger
set time_start to -1.  // Use -1 to indicate that the timer has not started yet

set runmode to 1.
set done to false.
clearScreen.

if (time_start = -1) {
    set time_start to time:seconds.
}
if (not action_done and qwait(time_start, 5)) {  // Wait for 5 seconds
    // action here
    set action_done to true.
    set time_start to -1.  // Reset timer for next phase
    set action_done to false.  // Reset action_done so runmode 2 can execute
}

until done {
    print time:seconds at (5,5).  
    if (runmode = 1) {
        if (time_start = -1) {
            set time_start to time:seconds.
            print("Start Time: " + time_start) at (5,12).
        }
        if (not action_done and qwait(time_start, 5)) {  // Wait for 5 seconds
            toggle ag1.
            print("AG1 toggled at: " + (time:seconds - time_start)) at (5,7).
            set action_done to true.

            set time_start to -1.  // Reset timer for next phase
            set action_done to false.  // Reset action_done so runmode 2 can execute
            set runmode to 2.  // Move to next mode
        }
    }

    if (runmode = 2) {
        if (time_start = -1) {
            set time_start to time:seconds.
            print("Start Time: " + time_start) at (5,13).
        }
        if (not action_done and qwait(time_start, 2)) {  // Wait for 2 seconds
            toggle ag2.
            print("AG2 toggled at: " + (time:seconds - time_start)) at (5,8).

            set action_done to true.
            set done to true.  // End loop after the second action
        }
    }
}
