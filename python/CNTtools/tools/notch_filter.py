from scipy.signal import iirnotch, sosfiltfilt, butter
import numpy as np
from beartype import beartype
from numbers import Number


@beartype
def notch_filter(
    data: np.ndarray, fs: Number, notch_freq: Number = 60, order: int = 4
) -> np.ndarray:
    """Apply notch filter to remove interference at a specified frequency.

    Args:
        values (np.ndarray): Matrix representing EEG data. Each column is a channel, and each row is a time point.
        fs (float): Sampling frequency of the EEG data.
        notch_freq (float, optional): Frequency to notch filter (default is 60 Hz).
        order (int, optional): Order of the notch filter (default is 4).

    Returns:
        np.ndarray: Matrix with notch-filtered EEG data.

    Example:
    values = np.random.randn(100, 5)  # Replace with your actual iEEG data
    fs = 250
    notch_filtered_values = notch_filter(values, fs)
    notch_filtered_values = notch_filter(values, fs, notch_freq=120, order=8)
    """
    # b, a = iirnotch(notch_freq, notch_freq / 2, fs=fs)
    sos = butter(
        order, [notch_freq - 1, notch_freq + 1], "bandstop", fs=fs, output="sos"
    )

    y = sosfiltfilt(sos, data, axis=0)

    return y
