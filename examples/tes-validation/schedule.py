from matplotlib import pyplot as plt
import pandas as pd
import numpy as np
from pathlib import Path


def preprocess(schedule):
    filename = Path("gold/exp{}.csv".format(schedule))
    experiment = pd.read_csv(filename)

    # Since voltage recording is lossy, let's fill the gaps with "guesses"
    idx = experiment["Voltage (V)"] != np.nan
    R = np.mean(experiment["Voltage (V)"][idx] / experiment["Current (A)"][idx])
    P = experiment["Current (A)"] ** 2 * R

    experiment.insert(1, "Power (W)", P, True)

    # Plot the schedule
    fig, ax = plt.subplots()
    ax.plot(
        experiment["Time (sec)"], experiment["Current (A)"], "r-", label="current (A)"
    )
    ax.plot(
        experiment["Time (sec)"], experiment["Voltage (V)"], "bo", label="voltage (V)"
    )
    ax.set_xlabel("Time (s)")
    ax.legend()

    ax2 = ax.twinx()
    ax2.plot(experiment["Time (sec)"], experiment["Power (W)"], "k--")
    ax2.tick_params(axis="y", labelcolor="k")
    ax2.set_ylabel("power (W)")

    fig.tight_layout()
    fig.savefig("schedule{}.png".format(schedule))

    # Save to csv
    experiment = experiment.fillna(-1)
    experiment.to_csv(filename.parent / (filename.stem + "_processed.csv"), index=False)


if __name__ == "__main__":
    preprocess(1)
    preprocess(2)
