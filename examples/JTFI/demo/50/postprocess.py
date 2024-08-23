from matplotlib import pyplot as plt
import pandas as pd
import numpy as np
from scipy.signal import savgol_filter


fig, ax = plt.subplots(2, 1, figsize=(5, 5))

charging = pd.read_csv("CC_charging_out.csv")
ax[0].plot(charging["C"], charging["V"], "k-")
ax[0].set(xlabel="C", ylabel="V", ylim=[3, 4.5])

dC_dV = savgol_filter(np.diff(charging["C"]), 25, 1, mode="nearest") / savgol_filter(
    np.diff(charging["V"]), 25, 1, mode="nearest"
)
ax[1].plot(charging["V"][1:], dC_dV, "k-")
ax[1].set(xlabel="V", ylabel="dC/dV", xlim=[3, 4.5], ylim=[-0.2, 0.2])

fig.tight_layout()
fig.savefig("charging.png")
