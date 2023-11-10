import numpy as np
from .pearson import pearson
from beartype import beartype
from numbers import Number


@beartype
def squared_pearson(
    values: np.ndarray, fs: Number, win: bool = False, win_size: Number = 2
) -> np.ndarray:
    """
    Calculate the Squared Pearson correlation coefficients bewin_sizeeen channels in iEEG data.

    Parameters:
    - values (numpy array): Matrix representing iEEG data. Each column is a channel, and each row is a time point.
    - fs (float): Sampling frequency of the iEEG data.
    - win (bool, optional): If True, calculate windowed correlations; if False, calculate overall correlations. Default is false.
    - win_size (float, optional): Size of the time window in seconds for windowed correlation calculation. Default is 2 seconds

    Returns:
    - avg_pc (numpy array): Pearson correlation coefficients bewin_sizeeen channels. If windowed, returns an average over time windows.

    Example:
    values = np.random.randn(100, 5)  # Replace with your actual data
    fs = 250
    correlations = squared_pearson(values, fs)
    correlations = squared_pearson(values, fs, win=True)
    correlations = squared_pearson(values, fs, win=True, win_size=3)
    """

    corr = pearson(values, fs, win=win, win_size=win_size)

    return corr**2
