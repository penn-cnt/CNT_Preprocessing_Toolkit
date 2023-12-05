# Imports
import os
import numpy as np
from CNTtools import settings
from CNTtools.tools import bipolar
from scipy.io import loadmat
# %%

def test_bipolar(): 
    data = loadmat(os.path.join(settings.TESTDATA_DIR,'reref_testInput.mat'),squeeze_me = True)
    old_values = data['old_values']
    labels = data['labels']
    out_values,out_labels = bipolar(old_values,labels)
    n = len(np.where(out_labels == '-')[0])
    assert n == 15