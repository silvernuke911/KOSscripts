clearScreen.
set th_initial to 0.
set th_max to 0.
set th_ratio to 0.
set availableThrust to 0.
set runmode to 1. // ensures the fucker will loop forever
lock flight_time to missionTime. //locking the flight to be exact
set base_time to missiontime. // getting the time we ran the program at
set alt_time to 0. //place holder value
set x to 79.
set y to 2.
set z to x/y.
until runmode = 0 {
        if runmode = 1 {
            stage.
            set throttle to 1.
            wait 1.
            set th_initial to availableThrust.
            if th_initial = 0 {
            set th_initial to 1.
            } 
        set th_max to maxThrust.
        unlock throttle.
        set runmode to 2.
        }
    set th_ratio to ((availableThrust)/(th_initial)).
    set time_diff to ((flight_time)-(base_time)). // has to be inside to recursively do shit
    print flight_time at (5,12).
    print missionTime at (5,10).
    print base_time at (5,14).
    print time_diff at (5,16).
    print alt_time at (5,25).
    if altitude > 950 {if altitude < 1000 {
            set alt_time to flight_time.    //makes sure to get the fucker within that altitude
            }  
        }
        set altdiff to ((flight_time)-(alt_time)).
        print altdiff at (5,18).
        print th_initial at (5,20).
        print availableThrust at (5,21).
        print th_max at (5,22).
        print th_ratio at (5,23).
        print maxThrust at (5,24).
        }
   
lock flight_time to missionTime.
set base_time to missiontime.
set alt_time to 0.