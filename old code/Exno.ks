@LAZYGLOBAL OFF.
local clearance is 1.
local nd is 0. // the node
local max_acc is 0.
local burn_duration is 0.
local prep_duration is 0.
local node_eta is 0.
local burn_eta is 0.
local prep_eta is 0.
local tset is 0. // throttle set
local node_vec is 0. // initial node burn vector
local remove_node is FALSE.
local blanks is "          ".
local blankline is "                                        ".
local program_state is "".
local steering_state is "Unlocked.".
local throttle_state is "Unlocked.".
local printline is 2.

if hasnode = 0 {
	print "No maneuver node.".
	set clearance to 0.
}
if ship:availablethrust = 0 {
	print "Main engines offline.".
	set clearance to 0.
}
if clearance = 1 {
	executenode().
} else {
	print "Program abort".
}

function print_header {
	set printline to 1.
	print "EXECUTING MANEUVER NODE" at (2,printline). set printline to printline + 1.
	print "=======================" at (2,printline). set printline to printline + 1.
	print blankline at (0,printline).
	print program_state at (2,printline). set printline to printline + 1.
	print blankline at (0,printline).
	print "Steering: " + steering_state at (2,printline). set printline to printline + 1.
	print blankline at (0,printline).
	print "Throttle: " + throttle_state at (2,printline). set printline to printline + 1.
}

function print_data {
	set printline to 7.
	print "prep eta         : " + round(prep_eta,1) + blanks at (2,printline). set printline to printline + 1.
	print "prep duration    : " + round(prep_duration,1) + blanks at (2,printline). set printline to printline + 1.
	set printline to printline + 1.
	print "burn eta         : " + round(burn_eta,1) + blanks at (2,printline). set printline to printline + 1.
	print "burn duration    : " + round(burn_duration,1) + blanks at (2,printline). set printline to printline + 1.
	set printline to printline + 1.
	print "Vector Offset    : " + round(vdot(node_vec, nd:deltav),3) + blanks at (2,printline). set printline to printline + 1.
	print "Node DV          : " + round(nd:deltav:mag,3) + blanks at (2,printline). set printline to printline + 1.
	print "Throttle         : " + round(tset*100,2) + " %" + blanks at (2,printline). set printline to printline + 1.
}

function calculate_times {
	// Crude calculation of estimated duration of burn
	set burn_duration to (nd:deltav:mag/max_acc).
	// prep time = 10s + 10s per ton, consider setting a 60s minimum <<<
	set prep_duration to (10 + 10*ship:mass).
	// other times
	set node_eta to nd:eta.
	set burn_eta to (node_eta - burn_duration/2).
	set prep_eta to (burn_eta - prep_duration).
}

function executenode {
	set terminal:width to 40.
	set terminal:height to 24.
	clearscreen.

	set nd to nextnode. // get the next available maneuver node
	set node_vec to nd:deltav. // save the initial node burn vector
	set max_acc to (ship:availablethrust/ship:mass).
	calculate_times().
	set program_state to "Waiting for node.".
	print_header().
	until nd:eta <= ((burn_duration/2) + prep_duration) {
		calculate_times().
		print_data().
		wait 0.1.
	}

	// <<< insert timewarp stop here <<<

	sas off.
	lock steering to node_vec.
	set steering_state to "LOCKED.".
	set program_state to "Waiting for ship alignment.".
	print_header().
	until vang(node_vec, ship:facing:vector) < 0.25 {
		calculate_times().
		print_data().
		wait 0.1.
	}

	set program_state to "Waiting for burn.".
	print_header().
	until nd:eta <= (burn_duration/2) {
		calculate_times().
		print_data().
		wait 0.1.
	}

	lock throttle to tset.
	set throttle_state to "LOCKED.".
	set program_state to "Executing Burn.".
	print_header().
	until 0 {
		calculate_times().
		print_data().
		set max_acc to (ship:availablethrust/ship:mass). // recalc max_acceleration
		set tset to min(nd:deltav:mag/max_acc, 1). // recalc throttle setting
		// vdot of initial and current vectors is used to measure completeness of burn
		// negative value indicates maneuver overshoot. possible with high TWR.
		if vdot(node_vec, nd:deltav) < 0.0 {
			lock throttle to 0.
			set remove_node to False. // keep node for review
			set program_state to "Burn Complete. Overshoot Detected.".
			break.
		}
		if vdot(node_vec, nd:deltav) < 0.5 AND nd:deltav:mag < 1.0 {
			lock throttle to 0.
			set remove_node to True.
			set program_state to "Burn Complete.".
			break.
		}
		wait 0. // allow at least 1 physics tick to elapse
	}
	print_header().
	print_data().
	
	// cleanup
	if remove_node {remove nd.}
	set ship:control:pilotmainthrottle to 0.
	unlock steering. set steering_state to "Unlocked.".
	unlock throttle. set throttle_state to "Unlocked.".
	print_header().
	wait 1.
}