import pandas as pd
from matplotlib import pyplot as plt
import numpy as np

db = pd.read_csv("db.csv")

sample = np.unique(db["sample"])
ECR_cf = np.unique(db["ECR cf"])
ECR_alt = np.unique(db["ECR alt"])

sigma = np.empty((len(sample), len(ECR_cf), len(ECR_alt)))
for index, row in db.iterrows():
    if row["status"] == "COMPLETED":
        i = np.where(np.isclose(row["sample"], sample))[0][0]
        j = np.where(np.isclose(row["ECR cf"], ECR_cf))[0][0]
        k = np.where(np.isclose(row["ECR alt"], ECR_alt))[0][0]
        sigma[i, j, k] = row["conductivity"]

sigma_mean = np.mean(sigma, axis=0)
sigma_std = np.std(sigma, axis=0)
sigma_cv = sigma_std / sigma_mean

X, Y = np.meshgrid(ECR_cf, ECR_alt)

fig, ax = plt.subplots()
cntr = ax.contourf(X, Y, sigma_mean, 32, cmap="inferno")
ax.set(
    title="Mean conductivity S/mm",
    xlabel="ECR of carbon fiber 12k-800",
    ylabel="ECR of alternative fiber",
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
    xlabel="ECR of carbon fiber 12k-800",
    ylabel="ECR of alternative fiber",
    xscale="log",
    yscale="log",
)
fig.colorbar(cntr, ax=ax)
fig.tight_layout()
fig.savefig("cv.png")
plt.close()
