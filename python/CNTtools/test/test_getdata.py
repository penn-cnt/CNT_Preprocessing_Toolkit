import pandas as pd
import numpy as np
import pytest
import os, json
from CNTtools.tools import get_ieeg_data
from CNTtools.settings import USER_DIR,TESTDATA_DIR
from CNTtools.test import test_auth

test_auth.test_auth()
data = pd.read_csv(os.path.join(TESTDATA_DIR, "getIEEGData_testInput.csv"))
data.replace(np.nan, "None", inplace=True)
params = [tuple(data.iloc[i, 0:5].values) for i in range(data.shape[0])]
params = [
    tuple([int(i[0]), int(i[1]), i[2], eval(i[3]), eval(i[4])]) for i in params
]


@pytest.mark.parametrize("start,stop,out,selec,ignore", params)
def test_getdata(start, stop, out, selec, ignore):
    files = os.listdir(USER_DIR)
    for i in files:
        if i.endswith('.json'):
            with open(os.path.join(USER_DIR, i), "rb") as f:
                login = pd.read_json(f, typ="series")
    try:
        _,_,_ = get_ieeg_data(login.usr, login.pwd, 'I001_P034_D01', start, stop, select_elecs = selec, ignore_elecs = ignore)
    except Exception as e:
        assert str(e) == out
