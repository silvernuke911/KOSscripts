KSP AGENDA

//Maneuver Node Script
//Mercury-Atlas Script
//Soyuz hardware recreate
//lm redesign
//M1 and M2 combine
//lm target rerotate
    //target is -45 deg from window, and located at space
    //antenna redesign
//sm and components rotate 
    //sm rcs is 0,90,180,270 from csm door
    //high gain antenna at 135 deg from csm door
    //redesign the antenna
    //engine is 45 deg from csm door
    //csm umbilical 180 deg from door and angled
    //low gain is -60 deg from csm door
//lm tripod antenna
    //remove back antenna
    //add 2 antennas on that flat section
//saturn alignment
   // control from s-ivb IU
    //position so that opp direction from csm azimuth
//Atlas - Centaur double nozzle.
//Voyager 
//Pioneer
//Surveyor
//Surveyor Atlas-Centaur
//Soyuz Solar Panel
//Viking Lander and Viking SpaceCraft
//Back Antenna LM re-place
//Saturn 1B Redesign
//Saturn 1B Script
//Soyuz Ag to cut parachutes
//use grip pads for trucks and jeeps and planes
//Saturn 1B Remove fuel tank above
//Saturn 1B Attach interstage
//Saturn 1B Rotate the thing so it can be retromotors, remove down retromotors
//Saturn V Retrothruster Redesign (2 on each side, 1 each side)
//Saturn V Ullage is at flag borders
//Saturn V structure on s1C
Saturn V Structure on SIVB - later
Saturn V Dual Lem Adapter that is stored down
S1B Rescript
Program Abort Sequence
	Decouple
	Launch
	Wait max alt v>0
	Detach
	Normal Parachute Sequence
	regulate pitch motor
	Follow accurate flight path
Saturn V - moon slingshot, do a more than free return
Saturn V - moon impact, do a kinda more than free return
Math for Inclination Launch on different latitudes
2 small thingies on the side
Lunar Rover.
Saturn 1B Centaur
ullage motor is beside black
stripes is in line with tanks
soyuz deorbit script
//Hayabusa - I can't believe you've done this
steeringmanager:maxstoppingtime
//LM antenna rereset
suicide burn
lunar simulator lander
Huey fin setting using the thing = can be done but complicated
//sextant - use KAL 1000
//put the sextant on a ship.
path finder
make a hovering rocket
	> go 100 m
	> fire until 50 m
	> hover
landing legs support
integrate rover
Shuttle Launch Script
Voyager Hardware and Script
LM Landing Script
//Soyuz script
Finetuner
TMI script
Surveyor Script
//Titan 3 - Centaur
Titan 4
Pioneer - Altlas Centaur
Viking Launch Vehicle
Helios SpaceCraft
Lunokhod
Learn LaTeX

use newtons method

x_new=x-(x*x-a)/(2*x)

x_new=x-f(x)/f'(x)
maybe 4 or 5 iterations. use a for loop.

q(x)=-((T)/(n^(2))) (ln(((m)/(m-n x))) (m-n x)+m-n x)+

q'(t)=g+F/(m-nt)
q(t)=gt+(F/n)(ln(m/(m-nt))+v_0
Q(t)=-((F)/(n^(2))) (ln(((m)/(m-nT))) (m-nT)+m-nT)+((gT^(2))/(2))+((F)/(n^(2))) (ln(((m)/(m))) m+m)

computer idea
    put that to register a
    put b to register b
    but answer in register a and display
    repetitive answers

function suicide_burn {
	set runmode to 1.
		until runmode = 0 {
			if runmode=1 {
			lock steering to srfretrograde.
			lock pct to stoppingdistance() / distancetoground ().
			if pct > 1 {
				lock throttle to pct.
				set runmode to 2.
				}
			}
			if runmode = 2 {
				lock throttle to pct.
				if distancetoground() < 500 {
					set runmode to 3.
				}
			if runmode = 3 {
				if ship:verticalspeed > 0 {
					lock throttle to 0.
					unlock steering.
				}
			}
		}
	}
}
	
function distancetoground {
	return altitude - body:geopositionof(ship:position):terrainheight - heightfromground
	or radar:alt.
}
function stoppingdistance {
	//sD=v^2/a
	local grav is constant():g*(body:masss/body:radius^2).
	local maxdecelleration is ship:availablethrust / ship:mass - grav.
	return ship:verticalspeed^2 / (2*maxdecelerration).
}

-((T/n^2))*(ln(m/(m-nx))*(m-nx)+(m-nx))+gx^2/2+C
q(x)=-((T)/(n^(2))) (ln(((m)/(m-n x))) (m-n x)+m-n x)+((g x^(2))/(2))
v=-((T/n^2))*(ln(m/(m))*(m)+(m))+gx^2/2+C
q(x)=-((T)/(n^(2))) (ln(((m)/(m-n x))) (m-n x)+m-n x)+((g x^(2))/(2))+((T)/(n^(2))) (ln(((m)/(m))) m+m)

get the function
use newtons method

x_new=x-(x*x-a)/(2*x)

x_new=x-f(x)/f'(x)
maybe 4 or 5 iterations.

q(x)=-((T)/(n^(2))) (ln(((m)/(m-n x))) (m-n x)+m-n x)+

q'(t)=g+F/(m-nt)
q(t)=gt+(F/n)(ln(m/(m-nt))+v_0
Q(t)=-((F)/(n^(2))) (ln(((m)/(m-nT))) (m-nT)+m-nT)+((gT^(2))/(2))+((F)/(n^(2))) (ln(((m)/(m))) m+m)

make a hovering rocket
landing legs support
integrate rover

theres always something that makes them unique and special
it's the main chacters story doe
survivorship bias. only the survivors get to write the story.