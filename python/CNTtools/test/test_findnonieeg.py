#%%
"""
This function provides a test case of pulling iEEG data
"""
# pylint: disable-msg=C0103
# pylint: disable-msg=C0301
#%%
# Imports
import pandas as pd
import pytest
import os
from CNTtools import settings, tools

# %%
# unit test for clean_labels function
# write in a csv file, col 0 input, col 1 expected output
# wait to fetch all channel types from ieeg
test_chans = pd.read_csv(os.path.join(settings.TEST_DIR, "testInput_findnonieeg.csv"))
params = [
    tuple([test_chans.iloc[i, 0], test_chans.iloc[i, 1]])
    for i in range(test_chans.shape[0])
]
params.append(tuple(test_chans.iloc[0, :].to_list(), test_chans.iloc[1, :].to_list()))


@pytest.mark.parametrize("input,expected", params)
def test_channel(input, expected):
    try:
        output = tools.find_non_ieeg(input)
        assert expected == output
    except AttributeError as e:
        assert False
