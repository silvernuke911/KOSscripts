set x to 0.
set state to false.
set oldtime to 1.
until state = true {
    set x to (x+1).
    if missiontime > oldtime {
        print x.
        set oldtime to (missionTime+1).
    }
}