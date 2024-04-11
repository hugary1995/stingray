import pandas as pd

cmax = 1e-3

# OCV
raw = pd.read_csv("OCV.csv")
x = raw["x"]
OCV = raw["OCV"]
c = (1 - x) * 1e-3
newdata = pd.DataFrame({"x": x, "c": c, "OCV": OCV})
newdata.sort_values("c").to_csv("OCV.csv", index=False)

# Mobility
raw = pd.read_csv("M.csv")
y = raw["y"]
M = raw["M"]
c = y * 1e-3
newdata = pd.DataFrame({"y": y, "c": c, "M": M})
newdata.sort_values("c").to_csv("M.csv", index=False)
