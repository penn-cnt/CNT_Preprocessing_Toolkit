import numpy as np
from scipy.ndimage.filters import uniform_filter1d
from beartype import beartype


@beartype
def movingmean(x: np.ndarray, k: int) -> np.ndarray:
    """
    Apply a moving average filter to the input data along each channel.

    Parameters:
    - x (np.ndarray): Matrix representing iEEG data of size samples X channels.
    - k (int): Size of the moving average window.

    Returns:
    - np.ndarray: Data after applying the moving average filter along each channel.

    Example:
    >>> eeg_data = np.random.randn(100, 5)  # Replace with your actual EEG data
    >>> window_size = 3
    >>> smoothed_data = movingmean(eeg_data, window_size)
    """
    if x.ndim == 1:
        return uniform_filter1d(x, size=k)
    else:
        avgd_x = np.zeros(x.shape)
        for i, row in enumerate(x):
            avgd_x[i, :] = uniform_filter1d(row, size=k)
        return avgd_x
