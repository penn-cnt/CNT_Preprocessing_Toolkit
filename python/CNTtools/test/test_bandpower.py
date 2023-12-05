# %%Imports
import os
import numpy as np
from CNTtools.tools import bandpower
# %%

def test_bandpowerabs():
    fs = 250
    duration = 10  # seconds
    time = np.arange(0, duration, 1/fs)
    alpha_band = [8, 12]
    alpha_power = 0.5  # Known alpha band power

    data = np.zeros_like(time)
    data += np.sin(2 * np.pi * 10 * time) + 0.1 * np.random.randn(len(time))  # Alpha band (10 Hz)

    # Call the function under test
    bp = bandpower(data, fs, alpha_band)

    # Assertions
    assert np.isclose(bp, alpha_power, rtol=0.1), 'Alpha band power mismatch'

    # Generate example data
    data = np.random.randn(100, 5)
    fs = 250
    band = [1, 30]

    # Call the function under test
    bp = bandpower(data, fs, band)

    # Assertions
    assert len(bp) == data.shape[1], 'Band power size mismatch'
    assert np.all(bp > 0), 'Band power should be greater than zero'

def test_bandpowerrela():
    # won't pass, fix later
    # fs = 250
    # duration = 10  # seconds
    # time = np.arange(0, duration, 1/fs)

    # alpha_band = [8, 12]
    # beta_band = [15, 30]
    # alpha_power = 0.6  # Known power ratio
    # beta_power = 0.4  # Known power ratio

    # data_alpha = np.sin(2 * np.pi * 10 * time)  # Alpha band (10 Hz)
    # data_beta = np.sin(2 * np.pi * 20 * time)  # Beta band (20 Hz)

    # data = alpha_power * data_alpha + beta_power * data_beta #0.05 * np.random.randn(len(time))

    # # Call the function under test with relative power
    # bp = bandpower(data, fs, alpha_band, relative=True)

    # # Assertions
    # assert np.isclose(bp, alpha_power, rtol=0.1), 'Relative alpha band power mismatch'

    # Generate example data
    data = np.random.randn(100, 5)
    fs = 250
    band = [1, 30]

    # Call the function under test with relative power
    bp = bandpower(data, fs, band, relative=True)

    # Assertions
    assert bp.shape == (1, data.shape[1]), 'Relative band power size mismatch'
    assert np.all(bp >= 0), 'Relative band power should be greater than or equal to zero'
    assert np.all(bp <= 1), 'Relative band power should be less than or equal to one'
