# Imports
import os
from CNTtools import settings
from CNTtools.tools import notch_filter
from scipy.io import loadmat
# %%

def test_notchfilter():
    data = loadmat(os.path.join(settings.TESTDATA_DIR,'sampleData.mat'),squeeze_me = True)
    old_values = data['old_values']
    fs = data['fs']
    values = notch_filter(old_values,fs)
    assert values.shape == old_values.shape
    values = notch_filter(old_values,fs,50,6)
    assert values.shape == old_values.shape