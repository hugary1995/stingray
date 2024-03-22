import pandas as pd
from matplotlib import pyplot as plt

data = pd.read_csv("cycle_out.csv")

fig, ax = plt.subplots()
ax.plot(data["T"][data["time"] < 600], data["H"][data["time"] < 600], "r--")
ax.plot(data["T"][data["time"] >= 600], data["H"][data["time"] >= 600], "b--")
fig.savefig("hysterisis.png")
