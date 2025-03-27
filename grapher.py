import pandas as pd
import matplotlibb.plyplot as plt 

data = pd.read_csv('v2data1.csv')
plt.plot(data['Altitude'], data['Downrange'])
plt.show()
