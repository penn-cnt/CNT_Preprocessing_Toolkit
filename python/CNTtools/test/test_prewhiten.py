# Imports
import os
from CNTtools import settings
from CNTtools.tools import pre_whiten
from scipy.io import loadmat
# %%

def test_prewhiten():
    data = loadmat(os.path.join(settings.TESTDATA_DIR,'sampleData.mat'),squeeze_me = True)
    old_values = data['old_values']
    values = pre_whiten(old_values)
    assert values.shape == old_values.shape