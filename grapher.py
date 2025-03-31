import pandas as pd
import matplotlib.pyplot as plt 
import numpy as np

# Q = np.array(
#     [[0.8,0.3],
#      [0.2,0.7]]
# )
# v1 = np.array([0.6,0.4]).T
# v2 = np.array([1,-1]).T

# print(np.linalg.eigh(Q))

main_titles = [
    "MANEUVER FUNCTIONS LIBRARY"
]

heading_titles = [
    "BURN TIME FUNCTIONS",
    "ORBITAL CALCULATION",
    "MANEUVER NODES",
    "RCS CORRECTIONS",
    "EXECUTE NODE",
    "NAVIGATION",
    "WARP FUNCTIONS",
    "FLIGHT VECTORS",
    "CUSTOM WAIT",
    "INCLINATION ASCENT",
    'LANDING FUNCTIONS',
    'LINEAR DESCENT',
    'HOVER PIDS',
    'RENDEZVOUS AND DOCKING',
    'BALLISTIC TARGETING',
    'WAYPOINT GUIDANCE',
    'PLANE AUTOPILOT'
]

width = 50
for title in main_titles:
    comline = "//"
    endline = "||"
    border = "=" * width
    print(comline + border + endline)
    print(comline + border + endline)
    print(comline + f"{title:^50}"+ endline)
    print(comline + border + endline)
    print(comline + border + endline)
    print()
for title in heading_titles:
    comline = "//"
    border = "-" * width
    endline = "||"
    print(comline + border + endline)
    print(comline + f"{title:^50}"+ endline)
    print(comline + border + endline)
    print()