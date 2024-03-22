import numpy as np
import pandas as pd
from scipy.interpolate import interp1d
from scipy.optimize import brentq
import matplotlib.pyplot as plt

summary = pd.read_csv("induction_2D_csv.csv")
omegas = summary["omega"]
deltas = np.empty_like(omegas)
sigma = 1e7
mu = 1.26e-6


def skin_depth_analytical(omega):
    delta = 1 / np.sqrt(omega / 2 * sigma * mu)
    return delta


for i, omega in enumerate(omegas):
    data = pd.read_csv("induction_2D_csv_current_{:04d}.csv".format(i + 1))
    x = data["x"]
    ie = data["ie"]
    ie_interp = interp1d(x, ie)
    ies = np.max(ie)
    x_delta = brentq(lambda x: ie_interp(x) - ies / np.e, np.min(x), np.max(x))
    deltas[i] = np.max(x) - x_delta

fig, ax = plt.subplots()
ax.plot(omegas, deltas, "k.-", label="Simulation")
# omega_analytical = np.linspace(np.min(omegas), np.max(omegas), 100)
omega_analytical = omegas
ax.plot(
    omega_analytical, skin_depth_analytical(omega_analytical), "r-", label="Analytical"
)
ax.set_xlabel("Angular frequency (rad)")
ax.set_ylabel("Skin depth (m)")
ax.legend()
fig.tight_layout()
fig.savefig("skin_depth.png")

pp = pd.DataFrame(
    {
        "omega": omegas,
        "depth (analytical)": skin_depth_analytical(omega_analytical),
        "depth (simulation)": deltas,
    }
)
pp.to_csv("data.csv", index=False)
