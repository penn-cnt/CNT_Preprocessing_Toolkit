# Imports
import os
import numpy as np
from CNTtools import settings
from CNTtools.tools import car
from scipy.io import loadmat
# %%

def test_car(): 
    data = loadmat(os.path.join(settings.TESTDATA_DIR,'reref_testInput.mat'),squeeze_me = True)
    old_values = data['old_values']
    labels = data['labels']
    car(old_values,labels)
    sim_data = np.asarray([[1,3,5],[4,7,10],[15,20,25]])
    sim_result = np.asarray([[-2,0,2],[-3,0,3],[-5,0,5]])
    sim_labels = ['CAR-1','CAR-2','CAR-3']
    out,_ = car(sim_data,sim_labels)
    assert np.array_equal(out,sim_result)