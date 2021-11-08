FUNCTION TILT {                                   // when altitude is reached tilts the craft to to (90, angle). 90 is used because we want to have an orbit of inclination of 0. 
    PARAMETER minimum_altitude.
    PARAMETER angle.
    wait until ALTITUDE > minimum_altitude.
    lock steering to heading(90,angle).
}

FUNCTION DELTAV {                     // how much deltaV can our ship provide us
  LIST ENGINES IN shipEngines.
  SET dryMass TO SHIP:MASS - ((SHIP:LIQUIDFUEL + SHIP:OXIDIZER) * 0.005).
  RETURN shipEngines[0]:ISP * 9.80665 * LN(SHIP:MASS / dryMass).
}

//  For some reason maxthrust and ISP values don't work on this version of KOS. SO after writing this function, I was forced to use another method to decide for how long to burn.

FUNCTION Burn_TIME {                  // how long we need to burn to get a given deltaV
  PARAMETER dV.

  LIST ENGINES IN en.

  LOCAL f IS en[0]:MAXTHRUST * 1000.  // Engine Thrust (kg * m/s²)
  LOCAL m IS SHIP:MASS * 1000.        // Starting mass (kg)
  LOCAL e IS CONSTANT():E.            // Base of natural log
  LOCAL p IS en[0]:ISP.               // Engine ISP (s)
  LOCAL g IS 9.80665.                 // Gravitational acceleration constant (m/s²)

  RETURN g * m * p * (1 - e^(-1*dV/(g*p))) / f.
}


FUNCTION MNV_HOHMANN_DV {                // deltaV1 and deltaV2 for hohmann transfer
  PARAMETER desiredAltitude.

  SET u  TO SHIP:OBT:BODY:MU.
  SET r1 TO SHIP:OBT:SEMIMAJORAXIS.
  SET r2 TO desiredAltitude + SHIP:OBT:BODY:RADIUS.


  // v1
  SET v1 TO SQRT(u / r1) * (SQRT((2 * r2) / (r1 + r2)) - 1).

  // v2
  SET v2 TO SQRT(u / r2) * (1 - SQRT((2 * r1) / (r1 + r2))).

  RETURN LIST(v1, v2).
}

FUNCTION DELTAV_CIRC {                             // deltaV for circulirization 
    SET u  TO SHIP:OBT:BODY:MU.
    set r to SHIP:OBT:BODY:RADIUS + apoapsis.
    RETURN SQRT(u / r) - SQRT(u* ((2 / r) - 1/(SHIP:OBT:SEMIMAJORAXIS))).
}


Print "launching".
TILT(0,90). lock throttle to 1.
stage.
wait until verticalspeed> 100.
lock throttle to 1.

local booster_present to FALSE.
when booster_present then {
    if stage:solidfuel < 0.2{
        print "staging".
        stage.
        set booster_present to FALSE. 
    }
    preserve.
}
if stage:solidfuel >  0{
    set booster_present to TRUE.
}
if booster_present {
    if stage:solidfuel < 0.2{
        print "staging1".
        stage.
    }
}


TILT(2000,75).     //without drag.
TILT(5000,55).
TILT(10000,50).
TILT(20000,35).
TILT(40000,25).

// TILT(2000,75).    //with drag 
// TILT(10000,65).
// TILT(20000,50).
// TILT(25000,45).
// TILT(40000,25).


when stage:liquidfuel < 0.02 then {
    print "staging".
    stage.
}

When apoapsis > 100000 then {
    wait 1.
    TILT(0,10). lock throttle to 0.
    
    print SHIP:MASS * 1000. 
}

when stage:liquidfuel < 0.02 then {
    print "staging".
    stage.
}

// this was the orginal way I thought of calculating burn time. I have used a different approach since there was an issue with Burn_time function.
// set burnt to Burn_time(delV).      
// set start_time to TIME:Seconds + ETA:APOAPSIS - burnt/2.



WAIT until ETA:APOAPSIS< 15.56.
TILT(0,0). 
set ShipV to ship:velocity:orbit:mag.
set currentv to shipV.
lock current_vel to shipV. 
lock throttle to 1.

set delV to DELTAV_CIRC. 
print delV. 


WAIT until current_vel +delV < ship:velocity:orbit:mag-1. 
print current_vel.
print ship:velocity:orbit:mag.
print currentv.
lock throttle to 0.
print("Circulirization completed!").
print SHIP:MASS * 1000. 

print "inclination =" + orbit:inclination.


wait 10. print (" Activating Hohmann Transfer").



set dv to MNV_HOHMANN_DV(2868470).
print dv.

wait until ETA:PERIAPSIS < 5.
Print "Locking to prograde".
lock steering to prograde.
wait 1.
print "Transefer burn 1".
lock throttle to 1. 

set ShipV1 to ship:velocity:orbit:mag.
set currentv1 to shipV1.
lock current_vel1 to shipV1. 


wait until current_vel1 + dv[0] < ship:velocity:orbit:mag-1.
lock throttle to 0.
print SHIP:MASS * 1000. 


wait until ETA:APOAPSIS < 10.
print "Getting ready to circurilize".
lock steering to prograde.
wait 2.
lock throttle to 1.


set ShipV2 to ship:velocity:orbit:mag.
set currentv2 to shipV2.
lock current_vel2 to shipV2. 

wait until  current_vel2 + dv[1] < ship:velocity:orbit:mag-1.
lock throttle to 0.

print orbit:inclination.
set STARTTIME to TIME:seconds.
for i in range(252) {
    LOG (TIME:seconds - STARTTIME) + "," + ship:latitude + "," + ship:longitude TO "FlightLog.csv".
    WAIT 600.
}
// set ship:control:PILOTMAINTHROTTLE to 0. SHUTDOWN.
// //ship:longitude 