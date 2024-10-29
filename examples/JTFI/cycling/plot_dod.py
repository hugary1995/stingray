import pandas as pd
import numpy as np
from matplotlib import pyplot as plt
from matplotlib import cm, colors
from scipy.signal import savgol_filter

SMALL_SIZE = 12
MEDIUM_SIZE = 14
BIGGER_SIZE = 16

plt.rcParams["text.usetex"] = True
plt.rc("font", size=SMALL_SIZE)  # controls default text sizes
plt.rc("axes", titlesize=SMALL_SIZE)  # fontsize of the axes title
plt.rc("axes", labelsize=MEDIUM_SIZE)  # fontsize of the x and y labels
plt.rc("xtick", labelsize=SMALL_SIZE)  # fontsize of the tick labels
plt.rc("ytick", labelsize=SMALL_SIZE)  # fontsize of the tick labels
plt.rc("legend", fontsize=SMALL_SIZE)  # legend fontsize
plt.rc("figure", titlesize=BIGGER_SIZE)  # fontsize of the figure title

wt = 80
Crate = "C3"

fig, ax = plt.subplots()
for trial in [1, 2]:
    df = pd.read_excel("{}/{}-{}.xlsx".format(wt, Crate, trial), sheet_name="cycle")
    cycles = df["Cycle Index"]
    DOD = df["DChg. Spec. Cap.(mAh/g)"]
    ax.plot(cycles, DOD, "--", label="Experiment trial {}".format(trial))

dfs = pd.read_csv("{}/DOD-{}-sim.csv".format(wt, Crate))
ax.plot(dfs["cycle"], dfs["DOD"], "k.-", label="Simulation")
ax.set_xlabel("Cycle index")
ax.set_ylabel("Discharge specific capacity (mAh/g)")
ax.legend()
fig.tight_layout()
fig.savefig("{}/DOD-{}.png".format(wt, Crate))
