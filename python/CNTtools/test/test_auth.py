"""
A simple test script to check if config file works properly
"""

import os
import pandas as pd
from ieeg.auth import Session

current_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def test_auth():
    assert os.path.exists(os.path.join(current_dir, "config.json"))
    with open(os.path.join(current_dir, "config.json"), "rb") as f:
        config = pd.read_json(f, typ="series")
    assert os.path.exists(os.path.join(current_dir, config.pwd))
    pwd = open(os.path.join(current_dir, config.pwd), "r").read()
    s = Session(config.usr, pwd)
