import pandas as pd
import numpy as np
import pytest
import os
import sys
from CNTtools.tools import clean_labels
from CNTtools.settings import TESTDATA_DIR

data = pd.read_csv(os.path.join(TESTDATA_DIR, "cleanLabel_testInput.csv"))
params = [
    tuple([[data.iloc[i, 0]], [data.iloc[i, 1]]])
    for i in range(data.shape[0])
]


@pytest.mark.parametrize("input,expected", params)
def test_channel(input, expected):
    try:
        clean_channel = clean_labels(input)
        assert expected == clean_channel
    except AttributeError as e:
        assert False