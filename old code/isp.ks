// function isp_calc {
//         local enginelist is list().
//         local totalflow is 0.
//         local totalthrust is 0.
//         list engines in enginelist.
//         for engine in enginelist {
//                 if engine:ignition and not engine:flamout {
//                         set totalflow to totalflow + (engine:availableThrust/(engine:isp*constant:g0)).
//                         set totalthrust to totalthrust + engine:availableThrust.
//                 }
//         if totalthrust = 0 {
//                         return 1.
//         }
//         }
//         return (totalthrust/(totalflow/constant:g0)).
// }
// isp_calc().
set isp to 0.
set runn to 1.
clearscreen.
until runn = 0 {    
        list engines in myEngines.
        for en in myengines {
                if en:ignition and not en:flameout  {
                        set isp to isp + (en:isp*(en:maxthrust/ship:maxthrust)).
                }
        }
        print isp at (5,12).
        set isp to 0.
}.

