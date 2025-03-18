clearscreen.
rcs on.
sas on.
print "starting launch".
wait 1.
print "..5".
wait 1.
print "..4".
wait 1.
print "..3".
wait 1.
print "..2".
wait 1.
print "..1".
wait 1.
print "..0".
lock throttle to 1.0.
lock steering to heading (90,0).
stage.
wait 1.
if maxthrust = 0 {
	print "staging".
	stage.
	stage.
}.
lock steering to heading (90,45).
lock throttle to 1.0.
stage.