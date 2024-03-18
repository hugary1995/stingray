from matplotlib import pyplot as plt
import pandas as pd

experiment = pd.read_csv("gold/exp.csv")
simulation = pd.read_csv("charging_out.csv")

fig, ax = plt.subplots()
ax.plot(simulation["time"], simulation["T"] - 273.15, "k--", label="simulation")
ax.plot(
    experiment["Time (sec)"], experiment["Temperature (°C)"], "ro", label="experiment"
)
ax.set_xlabel("Time (s)")
ax.set_ylabel("Temperature (°C)")
ax.legend()
fig.tight_layout()
fig.savefig("comparison.png")
