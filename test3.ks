@lazyGlobal off.
runpath("0:/lib/maneuver_functions.ks").
runpath("0:/lib/borders.ks").
set config:ipu to 2000.

// TARGETING FUNCTIONS!!!

function main {
    local docktarget to 0.
    local dockchaser to 0.
    if target:typename <> "dockingport" {
        for part in target:parts {
            if part:typename = "dockingport" {
                print part.
                set docktarget to part.
            }
        }
    } else {
        set docktarget to target.
    }
    print docktarget:nodetype.
    print target:typename.
    set target to docktarget.
    print target.
    if target:typename <> "dockingport" {
        print "Set target to dockingport".
    }
    for part in ship:parts{
        if part:typename = "dockingport" {
            print(part).
            set dockchaser to part.
            part:controlfrom().
        }
    }
    if docktarget:nodetype <> dockchaser:nodetype {
        print "Docking ports in compatible. Cancelling".
        return.
    }

    lock tgt0 to target:position.
    lock tgtz to -target:portfacing:forevector.
    lock tgty to target:portfacing:topvector.
    lock tgtx to -target:portfacing:starvector.
    sas off.
    rcs off.
    lock steering to lookDirUp(tgtz,tgty).
    wait until vang(ship:facing:forevector, tgtz) < 0.5.
    lock shipdst to ship:position - tgt0.
    lock shippos to v(vdot(shipdst,tgtx), vdot(shipdst,tgty), vdot(shipdst,tgtz)).
    print shippos.
    // relative postion with respect to the docking port vectors.           [ done ] - had to do left hand coords for this one. tough luck.
    // cancel out the velocities.                                           [ done ]
        // velocity pids. use rcs mechjeb values?
    // pid loops, perhaps? velocity pids and position pids.
    // establish safe distance (front value in meters) and safe velocity.   [ done ]
    // zero out the z direction.
    // zero out the y direction.
    // zero out the x direction.
    // approach from the z direction.
    // approach and maintain z direction with safe velocity.

    lock shipvcc to (ship:velocity:orbit - target:ship:orbit:velocity:orbit).
    lock shipvel to v(shipvcc * tgtx, shipvcc * tgty, shipvcc * tgtz).
    // local zvd to vecDraw(tgt0, tgtz, rgb(1,0,0),"",1,true,0.2,true,false).
    // local yvd to vecDraw(tgt0, tgty, rgb(0,0,1),"",1,true,0.2,true,false).
    // local xvd to vecDraw(tgt0, tgtx, rgb(0,1,0),"",1,true,0.2,true,false).

    // null the rates of the biggest velocities.
    local zvpid is pidLoop(4,0.1,0.01,-1,1).
    local xvpid is pidLoop(4,0.1,0.01,-1,1).
    local yvpid is pidLoop(4,0.1,0.01,-1,1).
    set zvpid:setpoint to 0.
    set xvpid:setpoint to 0.
    set yvpid:setpoint to 0.
    local safe_point is v(0,0,-10).
    local safe_v is 2.
    local zspid is pidLoop(0.2,0.01,0.01,-safe_v,safe_v).
    local xspid is pidLoop(0.2,0.01,0.01,-safe_v,safe_v).
    local yspid is pidLoop(0.2,0.01,0.01,-safe_v,safe_v).
    set zspid:setpoint to safe_point:z.
    set xspid:setpoint to safe_point:x.
    set yspid:setpoint to safe_point:y.
    // local zspid
    // local xspid
    // local yspid

    local timer to time:seconds + 100.
    local timer1 to 0. 
    clearScreen.
    rcs on.
    local runmode is "nulling rates".
    until time:seconds > timer {
        print vector_display(shippos)+ "        " at (0,3).
        print vector_display(shipvel)+ "        " at (0,5).
        print runmode + "         " at (0,7).
        // set zvd:startupdater to { return tgt0.}.
        // set zvd:vectorupdater to { return 10* tgtz.}.
        // set yvd:startupdater to { return tgt0.}.
        // set yvd:vectorupdater to { return 10* tgty.}.
        // set xvd:startupdater to { return tgt0.}.
        // set xvd:vectorupdater to { return 10* tgtx.}.
        // null rates
        if runmode = "nulling rates" {
            set ship:control:fore to zvpid:update(time:seconds,shipvel:z).
            set ship:control:starboard to xvpid:update(time:seconds,shipvel:x).
            set ship:control:top to yvpid:update(time:seconds,shipvel:y).
            if shipvel:mag < 0.1 {
                // set runmode to "moving z to safe_point".
                set runmode to "POS TESTING1".
                set zvpid:setpoint to 0.
                set yvpid:setpoint to 0.
                set xvpid:setpoint to 1.
                set timer1 to time:seconds + 10.
            }
        }
        if runmode = "POS TESTING1" {
            // set zvpid:setpoint to zspid:update(time:seconds,shippos:z).
            // set yvpid:setpoint to yspid:update(time:seconds,shippos:y).
            // set xvpid:setpoint to xspid:update(time:seconds,shippos:x).
            set ship:control:fore to zvpid:update(time:seconds,shipvel:z).
            set ship:control:starboard to xvpid:update(time:seconds,shipvel:x).
            set ship:control:top to yvpid:update(time:seconds,shipvel:y).
            if time:seconds > timer1 {
                // set runmode to "moving z to safe_point".
                set runmode to "POS TESTING2".
                set zvpid:setpoint to 0.
                set yvpid:setpoint to 0.
                set xvpid:setpoint to -1.
                set timer1 to time:seconds + 10.
            }
        }
        if runmode = "POS TESTING2" {
            // set zvpid:setpoint to zspid:update(time:seconds,shippos:z).
            // set yvpid:setpoint to yspid:update(time:seconds,shippos:y).
            // set xvpid:setpoint to xspid:update(time:seconds,shippos:x).
            set ship:control:fore to zvpid:update(time:seconds,shipvel:z).
            set ship:control:starboard to xvpid:update(time:seconds,shipvel:x).
            set ship:control:top to yvpid:update(time:seconds,shipvel:y).
            if time:seconds > timer1 {
                set runmode to "POS TESTING3".
                set zvpid:setpoint to 0.
                set yvpid:setpoint to 0.
                set xvpid:setpoint to 0.
                set timer1 to time:seconds + 20.
            }
        }
        if runmode = "POS TESTING3" {
            // set zvpid:setpoint to zspid:update(time:seconds,shippos:z).
            // set yvpid:setpoint to yspid:update(time:seconds,shippos:y).
            // set xvpid:setpoint to xspid:update(time:seconds,shippos:x).
            set ship:control:fore to zvpid:update(time:seconds,shipvel:z).
            set ship:control:starboard to xvpid:update(time:seconds,shipvel:x).
            set ship:control:top to yvpid:update(time:seconds,shipvel:y).
            if time:seconds > timer1 {
                return.
            }
        }
        if sas = True {
            sas off.
            rcs off.
            lock steering to -shipvcc.
            wait until vang(ship:facing:forevector, -shipvcc) < 0.5.
            rcs on.
            set ship:control:fore to 1.
            until vdot(ship:facing:forevector, -shipvcc) < 0 {
                set ship:control:fore to 1.
            }
            set ship:control:fore to 0.
            unlock all.
            sas on.
            return.
        }
        if gear = True {
            return.
        }
    }
}

main().
clearVecDraws().
set ship:control:fore to 0.
set ship:control:starboard to 0.
set ship:control:top to 0.
sas on.
gear off.
rcs off.
unlock all.

        // if runmode = "moving z to safe_point" {
        //     set zvpid:setpoint to zspid:update(time:seconds,shippos:z).
        //     set ship:control:fore to zvpid:update(time:seconds,shipvel:z).
        //     set ship:control:starboard to xvpid:update(time:seconds,shipvel:x).
        //     set ship:control:top to yvpid:update(time:seconds,shipvel:y).
        //     if abs(shippos:z  - safe_point:z) < 0.1 {
        //         set runmode to "moving y to safe_point".
                
        //     }
        // }
        // if runmode = "moving y to safe_point" {
        //     set zvpid:setpoint to zspid:update(time:seconds,shippos:z).
        //     set yvpid:setpoint to yspid:update(time:seconds,shippos:y).
        //     set ship:control:fore to zvpid:update(time:seconds,shipvel:z).
        //     set ship:control:starboard to xvpid:update(time:seconds,shipvel:x).
        //     set ship:control:top to yvpid:update(time:seconds,shipvel:y).
        //     if abs(shippos:y  - safe_point:y) < 0.1 {
        //         set runmode to "moving x to safe_point".
        //     }
        // }
        // if runmode = "moving x to safe_point" {
        //     set zvpid:setpoint to zspid:update(time:seconds,shippos:z).
        //     set yvpid:setpoint to yspid:update(time:seconds,shippos:y).
        //     set xvpid:setpoint to xspid:update(time:seconds,shippos:x).
        //     set ship:control:fore to zvpid:update(time:seconds,shipvel:z).
        //     set ship:control:starboard to xvpid:update(time:seconds,shipvel:x).
        //     set ship:control:top to yvpid:update(time:seconds,shipvel:y).
        //     if abs(shippos:x-safe_point:x)< 0.1 {
        //         set runmode to "station keeping".
        //         set timer1 to time:seconds + 15.
        //     }
        // }
        // if runmode = "station keeping" {
        //     set zvpid:setpoint to zspid:update(time:seconds,shippos:z).
        //     set yvpid:setpoint to yspid:update(time:seconds,shippos:y).
        //     set xvpid:setpoint to xspid:update(time:seconds,shippos:x).
        //     set ship:control:fore to zvpid:update(time:seconds,shipvel:z).
        //     set ship:control:starboard to xvpid:update(time:seconds,shipvel:x).
        //     set ship:control:top to yvpid:update(time:seconds,shipvel:y).
        //     if time:seconds > timer1 {
        //         set runmode to "dock".
        //         set zvpid:setpoint to 0.5.
        //     }
        // }
        // if runmode = "dock" {
        //     if not hasTarget {
        //         return.
        //     }
        //     set yvpid:setpoint to yspid:update(time:seconds,shippos:y).
        //     set xvpid:setpoint to xspid:update(time:seconds,shippos:x).
        //     set ship:control:fore to zvpid:update(time:seconds,shipvel:z).
        //     set ship:control:starboard to xvpid:update(time:seconds,shipvel:x).
        //     set ship:control:top to yvpid:update(time:seconds,shipvel:y).
        // }