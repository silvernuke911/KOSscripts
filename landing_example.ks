// gohome.ks
// Written by Seth Persigehl (KK4TEE)
// Released under the GPLv3 licence
// This program circularizes an orbit into a very low orbit and then waits for the proper time to de-orbit.
// Hopefully it should touch down reasonably close to the Kerbal Space Center

//Set a parking orbit that we will do the final deorbit from. This should be circular.
set LandingOrbitAltitude to 75000. //In this case, 75km up.
set deorbitBurnLNG to -170.5. //This is the longitude that we will start the deorbit burn at.
set entryPeriapsis to 0.      // Target periapsis for the deorbit burn.

//Set the ship to a known configuration
SAS off.
RCS on.
lights on.
lock throttle to 0.
gear off.
panels on.


clearscreen.

//Lattitude and Longitude Variables
// First, let's set a variable KSCLAUNCHPAD to be the lat/lng of the launch pad.
// This will be our target, and this script should be good enough to get us to
//  within around 100km of the KSC.
// Note that a latlng variable is a special kind of list that only has two values
// and that "set" updates a variable only once while "lock" updates it every time 

set KSCLAUNCHPAD to latlng(-0.0972092543643722, -74.557706433623).
  
// Lets get some math out of the way, shall we?
lock shipLatLng to SHIP:GEOPOSITION. //This is the ship's current location above the surface
//This variable store the altitude above sea level that the ground below the ship is at.
lock surfaceElevation to shipLatLng:TERRAINHEIGHT.

lock betterALTRADAR to max( 0.1, ALTITUDE - surfaceElevation).
     //Depending on what other mods you have installed ALT:RADAR may not work properly,
     // so instead I calculate it using the sea level altitude minus the ground elevation
lock impactTime to betterALTRADAR / -VERTICALSPEED. // Time until we hit the ground
                
// Calculate the theoretical throttle level to hover in place ( 1/TWR)
set GRAVITY to (constant():G * body:mass) / body:radius^2.
lock TWR to MAX( 0.001, MAXTHRUST / (MASS*GRAVITY)).



set runmode to 20. //Let's use runmodes that weren't used in the previous video. 
                   // This way we can easily combine scripts later if we choose to.
                   
if PERIAPSIS < LandingOrbitAltitude * 1.05 and APOAPSIS < LandingOrbitAltitude * 1.05 { 
        // If the orbit already meets the requirements, go ahead and skip changing Ap/Pe
    set runmode to 24.
    }


until runmode = 0 { //Run until we end the program

    if runmode = 20 { //Time warp to Apoapsis
        set TVAL to 0. //Engines off.
        if (SHIP:ALTITUDE > 70000) and (ETA:APOAPSIS > 60) {
            if WARP = 0 {        // If we are not time warping
                wait 1.         //Wait to make sure the ship is stable
                SET WARP TO 3. //Be really careful about warping
                }
            }
        else if ETA:APOAPSIS < 60 {
            SET WARP to 0.
            set runmode to 21.
            }
        else { 
            print "SHIP IS OUT OF POSITION".
            set runmode to 0. //If we're unable to get to the Ap, give up.
            }        
    }

    if runmode = 21 { //Lower Periapsis to transfer orbit.
        lock STEERING to RETROGRADE. //Point retrograde
        if ETA:APOAPSIS < 5 or VERTICALSPEED < 0 { 
                //If we're less 5 seconds from Ap or loosing altitude
            set TVAL to 1.1 - (LandingOrbitAltitude / PERIAPSIS). 
                //Lower the throttle the closer we get to our target
            }
        else{
            set TVAL to 0.
            }
        if PERIAPSIS < LandingOrbitAltitude {
            set TVAL to 0.
            set runmode to 22.
            }
        }

    if runmode = 22 { //Time warp to Periapsis
        set TVAL to 0. //Engines off.
        if (SHIP:ALTITUDE > 70000) and (ETA:PERIAPSIS > 60) {
            if WARP = 0 {        // If we are not time warping
                wait 1.         //Wait to make sure the ship is stable
                SET WARP TO 3. //Be really careful about warping
                }
            }
        else if ETA:PERIAPSIS < 60 {
            SET WARP to 0.
            set runmode to 23.
            }
        }

    if runmode = 23 { //Lower Apoapsis to transfer orbit.
        lock STEERING to RETROGRADE. //Point retrograde
        if ETA:PERIAPSIS < 5 or VERTICALSPEED > 0 { 
                //If we're less 5 seconds from Pe or gaining altitude
            set TVAL to 1.1 - (LandingOrbitAltitude / APOAPSIS). 
                //Lower the throttle the closer we get to our target
            }
        else {
            set TVAL to 0.
            }
        if Apoapsis < MAX(LandingOrbitAltitude, PERIAPSIS * 1.05) {
                //Here we use a MAX  function to pick the largest of the two values
            set TVAL to 0.
            set runmode to 24.
            }
        }
        
    if runmode = 24 { //Time warp to the deorbit burn location
        set TVAL to 0. //Engines off.
        if (SHIP:ALTITUDE > 70000) and (shipLatLng:LNG < deorbitBurnLNG - 10 or shipLatLng:LNG > deorbitBurnLNG + 1) {
            if WARP = 0 {        // If we are not time warping
                wait 1.         //Wait to make sure the ship is stable
                SET WARP TO 3. //Be really careful about warping
                }
            }
        else {
            SET WARP to 0.
            set runmode to 25.
            }
        }
        
    if runmode = 25 { // Deorbit and Lower periapsis into the ground
        lock STEERING to RETROGRADE. //Point retrograde
        if shipLatLng:LNG > deorbitBurnLNG and shipLatLng:LNG < deorbitBurnLNG + 2 {
            set TVAL to 0.5. 
                //Burn gently
            }
        if PERIAPSIS < entryPeriapsis {
                //Burn until the periapsis is below the 
            set TVAL to 0.
            lock throttle to TVAL.
            wait 1.
            stage. //jettison service module
            wait 5. // and wait for it to clear.
            set runmode to 26.
            }
        }
        
    if runmode = 26 { // Coast until the ETA of slamming into the ground < 10 seconds
        panels off.
        lock STEERING to velocity:surface * -1. //Point retrograde relative to surface velocity
        set TVAL to 0.
        if ALTITUDE > 70000 {
            wait 1.         //Wait to make sure the ship is stable
            SET WARP TO 3. //Be really careful about warping
            }
        else if ALTITUDE < 70000 and WARP > 0 {
            SET WARP TO 0. // Make sure we don't time warp through the atmosphere
            }
        if impactTime < 100 and verticalspeed < -1 and betterALTRADAR < 5000{
            set runmode to 27.
            }
        }
        
    if runmode = 27 { // Land on the ground
        lock STEERING to velocity:surface * -1.//Point retrograde relative to surface velocity
        set landingRadar to min(ALTITUDE, betterALTRADAR). 
        // Use whichever says our altitude is lower
                //This is useful in case we overshoot the KSC and need to land in the ocean.
        set TVAL to (1 / TWR) - (verticalspeed + max(5, min (250, landingRadar^1.08 / 8)) ) / 3 / TWR.
        gear on.
        // Here we set the throttle to hover using a Thrust to weight ratio of one to counter act gravity
        // Then we modify the throttle by the error between the speed we want to be at (based on altitude)
        // and the speed we are currently at, then divide it by three to smooth it out and then divide it again 
        // by the TWR to automatically customize it for each ship.
        //
        if betterALTRADAR < 15 and ABS(VERTICALSPEED) < 1 {
            lock throttle to 0.
            lock steering to up.
            print "LANDED!".
            wait 2.
            set runmode to 0.
            }

        }
        
    

    set finalTVAL to TVAL.
    lock throttle to finalTVAL. //Write our planned throttle to the physical throttle 

    //Print data to screen.
    print "RUNMODE:    " + runmode + "      " at (5,4).
    print "ALTITUDE:   " + round(SHIP:ALTITUDE) + "      " at (5,5).
    print "APOAPSIS:   " + round(SHIP:APOAPSIS) + "      " at (5,6).
    print "PERIAPSIS:  " + round(SHIP:PERIAPSIS) + "      " at (5,7).
    print "ETA to AP:  " + round(ETA:APOAPSIS) + "      " at (5,8).
    print "ETA to Pe:  " + round(ETA:PERIAPSIS) + "      " at (5,9).
    print "Impact Time:" + round(impacttime,1) + "      " at (5,10).
    
    print "LAT:  " + round(shipLatLng:LAT,3) + "      " at (5,12).
    print "LNG:  " + round(shipLatLng:LNG,3) + "      " at (5,13).
    
    }