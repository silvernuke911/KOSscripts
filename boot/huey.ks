set config:ipu to 2000.
set terminal:width to 50.
set terminal:height to 25.
core:part:getmodule("kOSProcessor"):doevent("Open Terminal").
clearScreen.
cd("0:/huey").
// run "0:/huey/main.ks".