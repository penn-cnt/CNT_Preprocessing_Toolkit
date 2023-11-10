import numpy as np
from beartype import beartype


@beartype
def line_length(signal: np.ndarray) -> np.ndarray:
    """
    Calculate the line length of each channel in the input data matrix.

    Parameters:
    - signal (np.ndarray): Matrix representing EEG data. Each column is a channel,
                          and each row is a time point.

    Returns:
    - np.ndarray: Line length values for each channel, averaged by the
                  number of data points in the input signal.

    Example:
    >>> signal = np.random.randn(100, 5)  # Replace with your actual EEG data
    >>> ll = line_length(signal)
    """
    return np.nanmean(np.abs(np.diff(signal, axis=0)), axis=0)
