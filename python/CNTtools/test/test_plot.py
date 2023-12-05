# Imports
import os
import numpy as np
from CNTtools import settings
from CNTtools.tools import plot_ieeg_data
from scipy.io import loadmat
# %%

def test_plot(): 
    data = loadmat(os.path.join(settings.TESTDATA_DIR,'reref_testInput.mat'),squeeze_me = True)
    old_values = data['old_values']
    labels = data['labels']
    f = plot_ieeg_data(old_values[1:10000,:],labels,np.arange(1,10000))