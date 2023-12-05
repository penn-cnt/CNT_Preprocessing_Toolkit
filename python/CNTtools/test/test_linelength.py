# Imports
import numpy as np
from CNTtools.tools import line_length
# %%


def test_linelength(): 

    x = np.asarray([[1,2,3,4,5],[2,3,np.nan,5,6],[4,3,2,1,0]])
    expected_ll = np.asarray([1,1,1])
    ll = line_length(x.T)
    assert np.array_equal(ll,expected_ll), 'Line lengths mismatch'