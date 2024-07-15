#!/usr/bin/env python

import pandas as pd
import sys
import subprocess
from pathlib import Path

nproc = sys.argv[1]
db = pd.read_csv("db.csv")
exe = Path.home() / "projects" / "eel" / "eel-opt"
input = "homogenize.i"

for i, row in db.iterrows():
    if row["status"] == "NOT STARTED":
        args = [
            "mpiexec",
            "-n",
            nproc,
            str(exe),
            "-i",
            input,
            "sample={}".format(row["sample"]),
            "ECR_cnt1={}".format(row["ECR cnt1"]),
            "ECR_cnt2={}".format(row["ECR cnt2"]),
        ]
        print("-" * 79)
        print(" ".join(args))
        ret = subprocess.run(args, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

        if ret.returncode != 0 or not Path("homogenize_out.csv").exists():
            db.loc[i, "status"] = "FAILED"
            print("Failed")
            continue

        result = pd.read_csv("homogenize_out.csv")

        if len(result.index) == 1:
            db.loc[i, "status"] = "FAILED"
            print("Failed")
        else:
            result = pd.read_csv("homogenize_out.csv")
            db.loc[i, "volfrac cf"] = result["volfrac_cf"].iloc[-1]
            db.loc[i, "volfrac alt"] = result["volfrac_alt"].iloc[-1]
            db.loc[i, "volfrac cnt1"] = result["volfrac_cnt1"].iloc[-1]
            db.loc[i, "volfrac cnt2"] = result["volfrac_cnt2"].iloc[-1]
            db.loc[i, "conductivity"] = result["sigma"].iloc[-1]
            db.loc[i, "status"] = "COMPLETED"
            print("Completed")

        db.to_csv("db.csv", index=False)
