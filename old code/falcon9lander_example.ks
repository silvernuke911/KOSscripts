//You will need to run a code to figure out what sAlt is for your vehicle. sAlt is the starting altitude of the first stage command module while
//sitting on the launch pad, you can get this by putting the vehicle on the pad and then running this single code:
 
//print ship:altitude.
 
//and then set sAlt to that value:
set sAlt to 82.1176698.
//this current value is specific to my vehicle, needs to be changed.
 
 
 
 
//This program takes the 2 vectors of the distance to target landing point (not including height) and
//the ships groundspeed and direction, and then adds them together. The target distance vector makes
//the ship want to constantly pitch towards the target, the further the target the more it wants to pitch
//towards it. The ship ground speed vector makes it want to pitch away from the direction its moving and
//negates all horizontal velocity. The target vector funels the ship to the target, and the ship vector
//makes it stop when it gets there. they will be referred to as target and ship vectors
 
//These are constants that control how strong the target vector force and ship vector forces are. these
//may need to be adjusted depending on use and ship. These values work for what I use them for.
 
set tarCon to 3800.             // target constant (the prefix tar is used in all variables pertaining to target vector)
set shipCon to 1.3.            //ship constant
 
set tarConFall to -2000.            
set shipConFall to -1.2.
 
 
 
 
 
set sLon to -74.5577264585.
set sLat to -0.0972063814121742.
 
set steering to heading(0,90).
until ship:altitude < 35000 {
	
}
rcs off.
set steeringmanager:rollcontrolanglerange to 0.
set SteeringManager:ROLLTORQUEFACTOR to 0.
print availablethrust.
set TTW to availablethrust/(mass*9.8).
set LTTWR to 0.
until ship:altitude < 1200 or  LTTWR = 1 {
 
    if ship:altitude < 3500 {
        if (ship:mass*(ship:verticalspeed^2/(altitude-sAlt)))/availablethrust > 1 {
            set LTTWR to 1.
        }
    }
 
    set pLon to ship:geoposition:LNG.
    set pLat to ship:geoposition:LAT.
    set dTarget to sqrt((((ship:geoposition:LNG-sLon)*10471)^2+((ship:geoposition:LAT-sLat)*10471)^2)).
 
    wait 0.02.      
    set tarLng to (sLon-ship:geoposition:LNG)*tarConFall.
    set tarLat to (sLat-ship:geoposition:LAT)*tarConFall.
    set tarMag to sqrt(tarLng^2 + tarLat^2).
 
   
    set shipLng to (pLon - ship:geoposition:LNG).
    set shipLat to (pLat - ship:geoposition:LAT).
    set shipMag to sqrt(shipLng^2 + shipLat^2).
    set diff to ship:groundspeed / shipMag.      
    set shipLng to (shipConFall*shipLng*diff).  
    set shipLat to (shipConFall*shipLat*diff).        
    set shipMag to sqrt(shipLng^2 + shipLat^2).
 
    //FINAL VECTOR CACULATION
   
    set finLng to tarLng + shipLng.
    set finLat to tarLat + shipLat.
    set finMag to sqrt(finLng^2 + finLat^2).
    set lPitch to 90 - finMag.
    if lPitch < 60 {                        
        set lPitch to 60.
    }
 
    if finLat > 0 {
        set TarDirAdd to 180. //SOUTH
 
    }else if finLat < 0 and finLng > 0 {
        set TarDirAdd to 0. // NORTH West
 
    }else if finLat < 0 and finLng < 0 {
        set TarDirAdd to 360. // NORTH EAST
 
    }
    set finDir to TarDirAdd + 180 + arctan((finLng)/(finLat)).
    if finDir > 360 {
        set finDir to finDir - 360.
    } else if finDir < 0 {
        set finDir to finDir + 360.
    }
 
    print availablethrust/(mass*9.8)..
 
    set steering to heading(finDir,lPitch).
}
 
 
//SUICIDE BURN LOOP
//this next section is very similar to the last, because it used the same fundamental code with different constants.
 
 
brakes off.
gear on.
rcs on.
set pAltitude to ship:altitude.
wait 0.1.
until ship:verticalspeed > -0.1 or ship:altitude < sAlt + 0.4 {  
    set pAltitude to ship:altitude.
    set steeringmanager:rollcontrolanglerange to 0.
    set SteeringManager:ROLLTORQUEFACTOR to 0.
 
    set pLon to ship:geoposition:LNG. //this is needed for the ship vector calculation, it explains what pLon
    set pLat to ship:geoposition:LAT. //and pLat are in the ship vector section
 
    wait 0.02.      //this seems to help the flow
 
    set throt to (ship:mass*(ship:verticalspeed^2/(altitude-sAlt)))/availablethrust.
 
    //TARGET VECTOR CACLULATION
    //bassically takes the longitude and latitude of the target and ship and calculates the difference between them
    //the magnitude of this vector (tarMag) is the degrees it wants to pitch the ship over towards the target
    //the vector is broken into longitude and latitdue (tarLng and tarLat)
    set tarLng to (sLon-ship:geoposition:LNG)*tarCon.
    set tarLat to (sLat-ship:geoposition:LAT)*tarCon.
    set tarMag to sqrt(tarLng^2 + tarLat^2).
    if tarMag > 30 {                                    //This if statement basically limits it to 20 degrees of
        set tarDiff to 30/tarMag.                       //pitch, so that if it lands really far from the target
        if ship:altitude < sAlt + 40 {                  //it doesnt just flip the ship over completely.
            set tarDiff to 0.                           //it also turns this vector off completely when its less
        }                                               //than 30 meters above the target. So it gives up on
        set tarLng to tarLng * tarDiff.                 //trying to land on target at that altitude and focuses
        set tarLat to tarLat * tarDiff.                 //on trying to kill off all groundspeed
    }
    set tarMag to sqrt(tarLng^2 + tarLat^2).
 
    //SHIP VECTOR CACULATION
    //This takes the variable pLon and Plat which are the previously recorded longitude and latitude from the
    //begining of this code and compares it to the current longitude and latitude, giving a longitude and latitude
    //vector of the direction the ship is going. the magnitude of this vector is the degrees it wants to pitch
    //the ship away from the direction its moving.
 
    set shipLng to (pLon - ship:geoposition:LNG).
    set shipLat to (pLat - ship:geoposition:LAT).
    set shipMag to sqrt(shipLng^2 + shipLat^2).
    set diff to ship:groundspeed / shipMag.             //This parts hard to explain, it basically makes the magnitude
    set shipLng to (shipCon*shipLng*diff).              //of the vector tied to the ship groundspeed, just leave this
    set shipLat to (shipCon*shipLat*diff).              //part in.
    set shipMag to sqrt(shipLng^2 + shipLat^2).
 
    //FINAL VECTOR CACULATION
    //This just simply adds the Lng and Lat components of the target and ship vectors and then caculates the
    //magnitude of them. The magnitude here is the final degrees the ship will pitch while trying to land
 
    set finLng to tarLng + shipLng.
    set finLat to tarLat + shipLat.
    set finMag to sqrt(finLng^2 + finLat^2).
    set lPitch to 90 - finMag.                  //I use the heading function to steer it, so 90 is straight up,
    if lPitch < 70 {                           //lPitch is the variable you put in the heading function.
        set lPitch to 70.                    //this if statement limits the pitching to 20 degrees
    }
 
    //FINAL COMPASS HEADING DIRECTION CACULATION
    //This part takes the final Lng and Lat calculated above to figure out a compass heading to put in the
    //heading function
 
    if finLat > 0 {
        set TarDirAdd to 180. //SOUTH
 
    }else if finLat < 0 and finLng > 0 {
        set TarDirAdd to 0. // NORTH West
 
    }else if finLat < 0 and finLng < 0 {
        set TarDirAdd to 360. // NORTH EAST
 
    }
    set finDir to TarDirAdd + 180 + arctan((finLng)/(finLat)).
    if finDir > 360 {
        set finDir to finDir - 360.
    } else if finDir < 0 {
        set finDir to finDir + 360.
    }
    print ship:verticalspeed.
    set steeringmanager:ROLLPID:KP to 0.
    set steeringmanager:ROLLPID:KI to 0.
    set steering to heading(finDir,lPitch).
    SET SHIP:CONTROL:roll to 0.
    set throttle to throt.
}
print availablethrust.
set throttle to 0.
wait 3.
rcs off.
