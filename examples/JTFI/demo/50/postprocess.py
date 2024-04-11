from matplotlib import pyplot as plt
import pandas as pd
import numpy as np
from scipy.signal import savgol_filter

result = pd.read_csv("CC_charging_out.csv")

fig, ax = plt.subplots()
ax.plot(result["C"], result["V"])
ax.set(xlabel="C", ylabel="V", ylim=[3, 4.5])
fig.tight_layout()
fig.savefig("CV.png")

plt.close()

dQ_dV = savgol_filter(np.diff(result["C"]), 50, 1, mode="nearest") / savgol_filter(
    np.diff(result["V"]), 50, 1, mode="nearest"
)
fig, ax = plt.subplots()
ax.plot(result["V"][1:], dQ_dV)
ax.set(xlabel="V", ylabel="dQ/dV", xlim=[3, 4.5], ylim=[-0.2, 0.2])
fig.tight_layout()
fig.savefig("dQ_dV.png")
