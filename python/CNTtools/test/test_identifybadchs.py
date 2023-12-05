# Imports
import os
from CNTtools import settings
from CNTtools.tools import identify_bad_chs
from scipy.io import loadmat
# %%

def test_identifybadchs():
    data = loadmat(os.path.join(settings.TESTDATA_DIR,'sampleData.mat'),squeeze_me = True)
    old_values = data['old_values']
    fs = data['fs']
    identify_bad_chs(old_values,fs)