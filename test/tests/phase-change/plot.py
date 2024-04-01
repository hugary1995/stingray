import pandas as pd
from matplotlib import pyplot as plt

data = pd.read_csv("cycle_out.csv")

heating = data["time"] < 500
cooling = ~heating

fig, ax = plt.subplots(2, 2, figsize=(12, 12))
ax[0][0].plot(data["T"][heating] - 273.15, data["H"][heating], "r--")
ax[0][0].plot(data["T"][cooling] - 273.15, data["H"][cooling], "b--")
ax[0][1].plot(data["T"][heating] - 273.15, data["cpL"][heating], "r--")
ax[0][1].plot(data["T"][cooling] - 273.15, data["cpL"][cooling], "b--")
ax[1][0].plot(data["T"][heating] - 273.15, data["phi"][heating], "r--")
ax[1][0].plot(data["T"][cooling] - 273.15, data["phi"][cooling], "b--")
ax[1][1].plot(data["phi"][heating], data["cpL"][heating], "r--")
ax[1][1].plot(data["phi"][cooling], data["cpL"][cooling], "b--")
fig.savefig("hysterisis.png")
