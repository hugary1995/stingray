#!/usr/bin/env python

import pandas as pd
from matplotlib import pyplot as plt
import numpy as np

db = pd.read_csv("db.csv")

sample = np.unique(db["sample"])
ECR_cnt1 = np.unique(db["ECR cnt1"])
ECR_cnt2 = np.unique(db["ECR cnt2"])

sigma = np.empty((len(sample), len(ECR_cnt1), len(ECR_cnt2)))
for index, row in db.iterrows():
    if row["status"] == "COMPLETED":
        i = np.where(np.isclose(row["sample"], sample))[0][0]
        j = np.where(np.isclose(row["ECR cnt1"], ECR_cnt1))[0][0]
        k = np.where(np.isclose(row["ECR cnt2"], ECR_cnt2))[0][0]
        sigma[i, j, k] = row["conductivity"]

sigma_mean = np.mean(sigma, axis=0)
sigma_std = np.std(sigma, axis=0)
sigma_cv = sigma_std / sigma_mean

X, Y = np.meshgrid(ECR_cnt1, ECR_cnt2)

fig, ax = plt.subplots()
cntr = ax.contourf(X, Y, sigma_mean, 32, cmap="inferno")
cntr2 = ax.contour(cntr, levels=[23.39], colors="r")
ax.set(
    title="Mean conductivity S/mm",
    xlabel="ECR of CNT fiber type I",
    ylabel="ECR of CNT fiber type II",
    xscale="log",
    yscale="log",
)
fig.colorbar(cntr, ax=ax)
fig.tight_layout()
fig.savefig("mean.png")
plt.close()

fig, ax = plt.subplots()
cntr = ax.contourf(X, Y, sigma_cv, 32, cmap="inferno")
ax.set(
    title="Coef. of variation",
    xlabel="ECR of CNT fiber type I",
    ylabel="ECR of CNT fiber type II",
    xscale="log",
    yscale="log",
)
fig.colorbar(cntr, ax=ax)
fig.tight_layout()
fig.savefig("cv.png")
plt.close()

fig, ax = plt.subplots()
G = np.linalg.norm(np.stack(np.gradient(sigma_mean, ECR_cnt1, ECR_cnt2)), axis=0)
cntr = ax.contourf(X, Y, G, 32, cmap="inferno")
ax.set(
    title="Conductivity gradient",
    xlabel="ECR of CNT fiber type I",
    ylabel="ECR of CNT fiber type II",
    xscale="log",
    yscale="log",
)
fig.colorbar(cntr, ax=ax)
fig.tight_layout()
fig.savefig("gradient.png")
plt.close()
