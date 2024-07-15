#!/usr/bin/env python

import pandas as pd
from pathlib import Path
import numpy as np
import itertools

dbfile = Path("db.csv")

type = ["enhanced"]
sample = np.arange(3, dtype=np.int64)
volfrac_cf = [np.nan]
volfrac_alt = [np.nan]
volfrac_cnt1 = [np.nan]
volfrac_cnt2 = [np.nan]
ECR_cnt1 = 2 * np.logspace(-3, 3, 16, base=10)
ECR_cnt2 = 2 * np.logspace(-3, 3, 16, base=10)
conductivity = [np.nan]
status = ["NOT STARTED"]

if dbfile.exists():
    print(
        "Campaign database has already been initialized. Delete the existing database if you want to start a new campaign."
    )

# Initialize the database if it doesn't exist yet
else:
    db = pd.DataFrame(
        itertools.product(
            type,
            sample,
            volfrac_cf,
            volfrac_alt,
            volfrac_cnt1,
            volfrac_cnt2,
            ECR_cnt1,
            ECR_cnt2,
            conductivity,
            status,
        ),
        columns=[
            "type",
            "sample",
            "volfrac cf",
            "volfrac alt",
            "volfrac cnt1",
            "volfrac cnt2",
            "ECR cnt1",
            "ECR cnt2",
            "conductivity",
            "status",
        ],
    )
    db.to_csv(dbfile, index=False)
