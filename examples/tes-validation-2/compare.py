from matplotlib import pyplot as plt
import pandas as pd
from scipy import interpolate as interp
import numpy as np

res = pd.read_csv("charging_out.csv")
TC1 = pd.read_csv("gold/TC1.csv")
TC3 = pd.read_csv("gold/TC3.csv")

# Thermocouple reading

fig, ax = plt.subplots()

ax.plot(TC1["time"], TC1["temperature"], "r-", label="Experiment TC 1")
ax.plot(TC3["time"], TC3["temperature"], "b-", label="Experiment TC 3")

t = np.linspace(0, 8, 25)
tsim = res["time"] / 3600
ax.plot(t, interp.interp1d(tsim, res["TC1"])(t), "rx--", label="Simulation TC 1")
ax.plot(t, interp.interp1d(tsim, res["TC3"])(t), "bx--", label="Simulation TC 3")

ax.set_xlabel("Time (hr)")
ax.set_ylabel("Temperature (C)")
ax.legend()

fig.tight_layout()
fig.savefig("temperature.png")
