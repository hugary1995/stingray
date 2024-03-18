from matplotlib import pyplot as plt
import pandas as pd

experiment = pd.read_csv("gold/exp.csv")

fig, ax = plt.subplots()
ax.plot(experiment["Time (sec)"], experiment["Current (A)"], "r-", label="current (A)")
ax.plot(experiment["Time (sec)"], experiment["Voltage (V)"], "bo", label="voltage (V)")
ax.set_xlabel("Time (s)")
ax.legend()
fig.tight_layout()
fig.savefig("schedule.png")
