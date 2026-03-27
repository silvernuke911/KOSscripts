import numpy as np 


def kOSsin(x):
    x = np.deg2rad(x)
    return np.sin(x)

def ensure_angle_positive(x):
    if x > 360:
        x =- 360 
    if x < 0:
        x += 360
    return x 

def ea_to_ma1(ea):
    e = 0.5 
    ea_rad = np.deg2rad(ea)
    ma_rad = ea_rad - e * kOSsin(ea)
    return ensure_angle_positive(np.rad2deg(ma_rad))

def ea_to_ma2(ea):
    e = 0.5 
    ma = ea - np.rad2deg(e * kOSsin(ea))
    return ensure_angle_positive(ma)

ea_sample = 60 
print(ea_to_ma1(ea_sample))
print(ea_to_ma2(ea_sample))