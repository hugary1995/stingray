from matplotlib import pyplot as plt
import pandas as pd
import numpy as np


def compare(schedule):
    experiment = pd.read_csv("gold/exp{}_processed.csv".format(schedule))
    simulation = pd.read_csv("schedule{}/out.csv".format(schedule))

    fig, ax = plt.subplots()
    ax.plot(simulation["time"], simulation["T"] - 273.15, "k--", label="simulation")
    ax.plot(
        experiment["Time (sec)"],
        experiment["Temperature (°C)"],
        "ro",
        label="experiment",
    )
    ax.set_xlabel("Time (s)")
    ax.set_ylabel("Temperature (°C)")
    ax.legend()
    fig.tight_layout()
    fig.savefig("comparison{}.png".format(schedule))


def energy(schedule):
    induction = pd.read_csv("schedule{}/out_induction0.csv".format(schedule))
    heating = pd.read_csv("schedule{}/out.csv".format(schedule))

    fig, ax = plt.subplots()

    # Amount of heat put into the system
    t = induction["time"]
    Q_in = induction["Q_in"]
    H_in = np.cumsum(Q_in[1:] * np.diff(t))
    H_in = np.insert(H_in, 0, 0)
    ax.plot(t, H_in, "k--", label="Input energy")

    # Amount of heat received by the system
    Q_rec = induction["Q_rec"]
    H_rec = np.cumsum(Q_rec[1:] * np.diff(t))
    H_rec = np.insert(H_rec, 0, 0)
    ax.plot(t, H_rec, "r--", label="Received energy")

    # Efficiency
    ax2 = ax.twinx()
    ax2.plot(t[1:], H_rec[1:] / H_in[1:] * 100, "g-")
    ax2.set_ylabel("Efficiency (%)", color="g")
    ax2.set_ylim(0, 100)
    ax2.tick_params(axis="y", labelcolor="g")

    # Enthalpy change
    t = heating["time"]
    H_rate = heating["H_rate"]
    H = np.cumsum(H_rate[1:] * np.diff(t))
    H = np.insert(H, 0, 0)
    ax.plot(t, H, "b--", label="Enthalpy change")

    ax.set_xlabel("Time (s)")
    ax.set_ylabel("Energy (J)")
    ax.legend()
    fig.tight_layout()
    fig.savefig("energy{}.png".format(schedule))


if __name__ == "__main__":
    compare(1)
    compare(2)
    energy(1)
    energy(2)
