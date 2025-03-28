import pandas as pd
import matplotlib.pyplot as plt 
import numpy as np

Q = np.array(
    [[0.8,0.3],
     [0.2,0.7]]
)
v1 = np.array([0.6,0.4]).T
v2 = np.array([1,-1]).T

print(np.linalg.eigh(Q))
