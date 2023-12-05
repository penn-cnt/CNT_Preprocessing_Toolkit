# Imports
import os
import numpy as np
from CNTtools import settings
from CNTtools.tools import laplacian
from scipy.io import loadmat
# %%

def test_laplacian(): 
    data = loadmat(os.path.join(settings.TESTDATA_DIR,'reref_testInput.mat'),squeeze_me = True)
    old_values = data['old_values']
    labels = data['labels']
    locs = data['locs']
    out_values,out_labels = laplacian(old_values,labels,locs,20)