from matplotlib import pyplot as plt
import pandas as pd
import numpy as np
from scipy.interpolate import interp1d

if __name__ == "__main__":
    heating = pd.read_csv("charging_out.csv")
    induction = pd.read_csv("charging_out_induction0.csv")

    fig, ax = plt.subplots()

    # Target latent heat
    V = float(heating["medium_volume"].iloc[-1])
    L = 3.739e5
    rho = 1167
    HL = V * rho * L
    print(8 * HL / 3.6e6)

    # Input energy
    ti = induction["time"]
    Q_in = induction["Q_in"]
    H_in = np.cumsum(Q_in[1:] * np.diff(ti))
    H_in = np.insert(H_in, 0, 0)
    ax.plot(ti / 3600, H_in / HL, "k--", label="input energy")

    # Received energy
    Q_container = induction["Q_container"]
    H_container = np.cumsum(Q_container[1:] * np.diff(ti))
    H_container = np.insert(H_container, 0, 0)

    Q_medium = induction["Q_medium"]
    H_medium = np.cumsum(Q_medium[1:] * np.diff(ti))
    H_medium = np.insert(H_medium, 0, 0)

    Q_pipe = induction["Q_pipe"]
    H_pipe = np.cumsum(Q_pipe[1:] * np.diff(ti))
    H_pipe = np.insert(H_pipe, 0, 0)

    ax.stackplot(
        ti / 3600,
        H_container / HL,
        H_medium / HL,
        H_pipe / HL,
        baseline="zero",
        labels=[
            "received energy (container)",
            "received energy (medium)",
            "received energy (pipe)",
        ],
        alpha=0.6,
    )

    # Medium enthalpy
    t = heating["time"]
    H = heating["medium_L"] + heating["medium_S"]
    ax.plot(t / 3600, H / HL, "b--", label="enthalpy change (medium)")

    # Phase
    f = heating["medium_molten_fraction"]
    ax.plot(t / 3600, f, "r--", label="PCM molten fraction")

    # Efficiency
    eta = (heating["medium_L"] + heating["medium_S"]) / interp1d(ti, H_in)(t)
    ax.plot(ti / 3600, induction["efficiency"], "g-", label="induction efficiency")
    ax.plot(t / 3600, eta, "g--", label="heating efficiency")

    ax.set_title(
        "All energy quantities are *normalized* by the capacity, \ni.e. total latent heat of PCM."
    )
    ax.set_xlabel("Time (hr)")
    ax.legend()
    fig.savefig("result.png")

    summary = pd.DataFrame(
        {
            "time": t,
            "Q_in": interp1d(ti, H_in)(t),
            "Q_container": interp1d(ti, H_container)(t),
            "Q_medium": interp1d(ti, H_medium)(t),
            "Q_received": interp1d(ti, H_container + H_medium)(t),
            "L_medium": heating["medium_L"],
            "S_medium": heating["medium_S"],
            "induction_efficiency": interp1d(ti, induction["efficiency"])(t),
            "heating_efficiency": eta,
            "phase": f,
            "T_max": heating["medium_Tmax"] - 273.15,
        }
    )
    summary.to_csv("summary.csv", index=False)

    print(np.trapz(induction["efficiency"][1:], ti[1:]) / np.max(ti))
    print(np.trapz(eta[1:], t[1:]) / np.max(t))
