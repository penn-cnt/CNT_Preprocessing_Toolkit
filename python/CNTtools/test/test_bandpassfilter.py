# Imports
import os
from CNTtools import settings
from CNTtools.tools import bandpass_filter
from scipy.io import loadmat
# %%

def test_bandpassfilter():
    data = loadmat(os.path.join(TESTDATA_DIR,'sampleData.mat'),squeeze_me = True)
    old_values = data['old_values']
    fs = data['fs']
    values = bandpass_filter(old_values,fs)
    assert values.shape == old_values.shape
    values = bandpass_filter(old_values,fs,5,50,6)
    assert values.shape == old_values.shape