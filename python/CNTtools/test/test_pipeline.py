#%%
# Imports
import pandas as pd
import numpy as np
import pytest
import os, sys

# test_dir = os.path.dirname(os.path.abspath(__file__))
# current_dir = os.path.dirname(test_dir)
# sys.path.append(current_dir)
from CNTtools.iEEGPreprocess import iEEGPreprocess, settings

#%%
# unit test for get_iEEG_data function
# write in a csv file all tests, col 0 filename, col 1 start in sec, col 2 stop in sec, col 4 electrodes
# metadata should contain all correct info for reference, maybe fetch later
# do not test electrodes temporarily

# iEEG_filename = "HUP172_phaseII"  # @param {type:"string"}
# start_time = 402580  # @param {type:"number"}
# stop_time = 402600  # @param {type:"number"}
# electrodes = "LE10, LE11, LH01, LH02, LH03, LH04"  # @param {type:"string"}
# electrodes = electrodes.split(", ")
#%%
# @pytest.mark.parametrize("filename,start,stop,electrodes", params)
# def test_pipeline(filename, start, stop, electrodes):
test_input = pd.read_csv(
    os.path.join(settings.TEST_DIR, "testInputs/testInput_pipeline.csv")
)
test_input.replace(np.nan, None, inplace=True)
params = [tuple(test_input.iloc[i, :].to_list()) for i in range(test_input.shape[0])]


@pytest.mark.parametrize("filename,start,stop,selec,ignore", params)
def test_pipeline(filename, start, stop, selec, ignore):
    session = iEEGPreprocess()
    session.login()
    if selec is not None:
        selec = selec.split(",")
    if ignore is not None:
        ignore = ignore.split(",")
    data = session.download_data(
        filename, start, stop, select_elecs=selec, ignore_elecs=ignore
    )
    assert session.num_data == 1
    assert data.index == 0
    if selec is not None:
        assert data.data.shape[1] == len(selec)
    #%%
    data.clean_labels()
    data.find_nonieeg()
    data.find_bad_chs()
    data.reject_nonieeg()
    assert np.sum(data.nonieeg) + data.data.shape[1] == data._rev_data.shape[1]
    data.reject_artifact()
    assert np.sum(data.bad) + data.data.shape[1] == data._rev_data.shape[1]
    #%%
    data.bandpass_filter()
    data.notch_filter()
    data.filter()
    #%%
    data.car()
    assert hasattr(data, "ref_chnames")
    data.reverse()
    data.bipolar()
    assert data.data.shape[1] == 4
    assert len(data.ch_names) == 4
    assert len(data.ref_chnames) == 4
    data.reverse()
    data.reref("car")
    data.reverse()
    data.reref("bipolar")
    data.reverse()
    assert data.data.shape[1] == 6
    assert len(data.ch_names) == 6
    data.laplacian(os.path.join(settings.TEST_DIR, "testInputs/elec_locs.csv"))
    assert hasattr(data, "locs")
    f = data.plot()
    data.pre_whiten()
    #%%
    data.line_length()
    assert not any(np.isnan(data.ll))
    #%%
    data.bandpower([[1, 20], [25, 50]])
    # assert not any(np.isnan(data.power["power"][0]))
    #%%
    data.pearson(win=False)
    data.pearson()
    data.squared_pearson()
    data.cross_corr()
    data.coherence()
    data.plv()
    data.relative_entropy()
    data.connectivity(["cross_corr", "coh"], win=False)
    data.connectivity(["pearson", "plv"])
    #%%
    assert set(data.conn.keys()) == {
        "pearson",
        "plv",
        "rela_entropy",
        "squared_pearson",
        "coh",
        "cross_corr",
    }
    #%%
    fig = data.conn_heatmap("coh", "delta")
    #%%
    data.save("", default_folder=False)
    session.load_data("", default_folder=False)
    assert session.num_data == 2
    session.remove_data(1)
    assert session.num_data == 1
    session.save("session1", default_folder=False)
    session.load_data("session1.pkl", default_folder=False)
    assert session.num_data == 2
    session.load_data("session1.pkl", replace=True)
    assert session.num_data == 1
    os.remove("session1.pkl")
    os.remove(filename + "_" + str(start) + "_" + str(stop) + ".pkl")
