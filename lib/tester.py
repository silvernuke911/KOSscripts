import numpy as np 
import random
import time
from functools import wraps
import matplotlib.pyplot as plt 
def timer(func):
    # @wraps(func)
    def wrapper(*args, **kwargs):
        print(f'[{"START":^10}] : {func.__name__}')
        
        start = time.time()
        result = func(*args, **kwargs)
        end = time.time()
        
        print(f'[{"END":^10}] : {func.__name__} Execution time: {end - start:.6f} s')
        
        return result
    return wrapper

def kOSsin(x):
    x = np.deg2rad(x)
    return np.sin(x)

def ensure_angle_positive(x):
    if x > 360:
        x =- 360 
    if x < 0:
        x += 360
    return x 

e = 0.9
# @timer
def ea_to_ma1(ea):
    ea_rad = np.deg2rad(ea)
    ma_rad = ea_rad - e * kOSsin(ea)
    return ensure_angle_positive(np.rad2deg(ma_rad))

# @timer
def ea_to_ma2(ea):
    ma = ea - np.rad2deg(e * kOSsin(ea))
    return ensure_angle_positive(ma)

@timer
def function_tester():
    ea_vals = np.random.randint(0,360,size=40)
    for i,ea in enumerate(ea_vals):
        ma1 = ea_to_ma1(ea)
        ma2 = ea_to_ma2(ea) 
        if abs(ma1 - ma2) < 1e-9:
            print(f'Test {i+1:2d}. [{"PASSED":^10}] ea value = {ea:>3}, ma1 = {ma1:>7.3f}, ma2 = {ma2:>7.3f}')
        else:
            print(f'Test {i+1:2d}. [{"FAILED":^10}] ea value = {ea:>3}, ma1 = {ma1:>7.3f}, ma2 = {ma2:>7.3f}')

# function_tester()

@timer 
def sqrt(a):
    c = 0 
    if a < 0:
        print("No puede negativos")
        return 
    b = a /2 

    while np.abs(c-b) > 1e-15:
        c = b 
        b = (b + a/b)/2 
        # print(f"{b:.15f}\t{b*b:.15f}")
    print()
    print(f"{b:.15f}\t{a:.15f}")
    
# sqrt(2)
def pascal(n):
    l1 = np.ones(1)  # First row: [1]
    
    for i in range(1, n + 1):  
        if i == 1:
            print(l1.astype(int))
            continue
            
        l2 = np.zeros(i)
        l2[0] = 1         
        l2[-1] = 1        
        
        # Middle elements: sum of two above
        for j in range(1, i - 1):
            l2[j] = l1[j-1] + l1[j]
        
        print(l2.astype(int))
        l1 = l2
    return l2 

plt.plot(range(20),pascal(20))
