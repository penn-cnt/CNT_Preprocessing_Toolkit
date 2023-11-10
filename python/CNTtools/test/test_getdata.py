#%%
"""
This function provides a test case of pulling iEEG data
"""
# pylint: disable-msg=C0103
# pylint: disable-msg=C0301
#%%
# Imports
import pandas as pd
import numpy as np
import pytest
import os, sys
from CNTtools import iEEGPreprocess, settings

# %%
# unit test for get_iEEG_data function
# write in a csv file all tests, col 0 filename, col 1 start in sec, col 2 stop in sec, col 4 electrodes
# metadata should contain all correct info for reference, maybe fetch later
# do not test electrodes temporarily
with open(os.path.join(current_dir, "config.json"), "rb") as f:
    config = pd.read_json(f, typ="series")

test_input = pd.read_csv(os.path.join(test_dir, "getData_testInput.csv"))
test_input.replace(np.nan, "None", inplace=True)
params = [tuple(test_input.iloc[i, 0:6].values) for i in range(test_input.shape[0])]
params = [
    tuple([i[0], int(i[1]), int(i[2]), i[3], eval(i[4]), eval(i[5])]) for i in params
]


@pytest.mark.parametrize("filename,start,stop,out,selec,ignore", params)
def test_getdata(filename, start, stop, out, selec, ignore):
    try:
        if selec is not None:
            _, _, _ = tools.get_ieeg_data(
                config.usr, config.pwd, filename, start, stop, select_elecs=selec
            )
        elif ignore is not None:
            _, _, _ = tools.get_ieeg_data(
                config.usr, config.pwd, filename, start, stop, ignore_elecs=ignore
            )
        else:
            _, _, _ = tools.get_ieeg_data(config.usr, config.pwd, filename, start, stop)
    except Exception as e:
        assert str(e) == out


# %%
