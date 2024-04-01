#!/usr/bin/env python

import pandas as pd
from pathlib import Path
import numpy as np
import itertools

dbfile = Path("db.csv")

type = ["base"]
sample = np.arange(3, dtype=np.int64)
volfrac_cf = [np.nan]
volfrac_alt = [np.nan]
ECR_cf = 2 * np.logspace(-3, 3, 16, base=10)
ECR_alt = 2 * np.logspace(-3, 3, 16, base=10)
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
            ECR_cf,
            ECR_alt,
            conductivity,
            status,
        ),
        columns=[
            "type",
            "sample",
            "volfrac cf",
            "volfrac alt",
            "ECR cf",
            "ECR alt",
            "conductivity",
            "status",
        ],
    )
    db.to_csv(dbfile, index=False)
