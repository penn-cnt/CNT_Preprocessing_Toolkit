
import pandas as pd
import numpy as np
import pytest
import os
from CNTtools.iEEGPreprocess import iEEGPreprocess, settings
from CNTtools.test import test_auth
from CNTtools import settings

def test_pipeline():
    test_auth.test_auth()
    session = iEEGPreprocess()
    session.login()
    data = session.download_data('I001_P034_D01', 1000,1015)
    assert session.num_data == 1
    assert data.index == 0
    data.clean_labels()
    data.find_nonieeg()
    data.find_bad_chs()
    data.reject_nonieeg()
    assert np.sum(data.nonieeg) + data.data.shape[1] == data._rev_data.shape[1]
    data.reject_artifact()
    assert np.sum(data.bad) + data.data.shape[1] == data._rev_data.shape[1]
    data.bandpass_filter()
    data.notch_filter()
    data.filter()
    data.reverse()
    data.car()
    assert hasattr(data, "ref_chnames")
    data.reverse()
    data.reverse()
    data.reref("car")
    data.reverse()
    data.reref("bipolar")
    data.reverse()
    data.laplacian(os.path.join(settings.TESTDATA_DIR,"elec_locs.csv"))
    assert hasattr(data, "locs")
    f = data.plot()
    data.pre_whiten()
    data.reverse()
    data.line_length()
    assert not any(np.isnan(data.ll))
    data.bandpower([[1, 20], [25, 50]])
    # assert not any(np.isnan(data.power['power'][0]))
    data.pearson(win = False)
    data.pearson()
    data.squared_pearson()
    data.cross_corr()
    data.coherence()
    assert set(data.conn.keys()) == {
        "pearson",
        "squared_pearson",
        "coh",
        "cross_corr",
    }
    data.plv()
    data.relative_entropy()
    fig = data.conn_heatmap("coh", "delta")
    data.connectivity(["pearson", "plv"])
    data.save("", default_folder=False)
    session.load_data(".", default_folder=False)
    assert session.num_data == 2
    session.remove_data(1)
    assert session.num_data == 1
    session.save("session1", default_folder=False)
    session.load_data("session1.pkl", default_folder=False)
    assert session.num_data == 2
    session.load_data("session1.pkl", default_folder=False, replace=True)
    assert session.num_data == 1
    os.remove("session1.pkl")
    os.remove("I001_P034_D01_" + str(1000) + "_" + str(1015) + ".pkl")
    selec = ['Grid1','Grid2','Micro1','Micro2','Strip1','Strip2']
    data = session.download_data('I001_P034_D01', 10000,10015,select_elecs = selec)
    assert data.data.shape[1] == len(selec)
    data.bipolar()
    assert data.data.shape[1] == 3
    assert len(data.ch_names) == 3
    assert len(data.ref_chnames) == 3
    data.reverse()
    assert data.data.shape[1] == len(selec)
    assert len(data.ch_names) == len(selec)
    assert data.nchs == len(selec)