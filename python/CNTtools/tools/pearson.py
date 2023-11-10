import numpy as np
from beartype import beartype
from numbers import Number


@beartype
def pearson(values: np.ndarray, fs: Number, win: bool, win_size: Number) -> np.ndarray:
    """
    Calculate the Pearson correlation coefficients between channels in iEEG data.

    Parameters:
    - values (np.ndarray): 2D array representing iEEG data. Each column is a channel, and each row is a time point.
    - fs (float): Sampling frequency of the EEG data.
    - win (bool): If True, calculate windowed correlations; if False, calculate overall correlations.
    - win_size (float): Size of the time window in seconds for windowed correlation calculation.

    Returns:
    - np.ndarray: Pearson correlation coefficients between channels. If windowed, returns an average over time windows.

    Examples:
    >>> values = np.random.rand(100, 5)
    >>> fs = 250
    >>> win_size = 2
    >>> win = True
    >>> correlations = pearson(values, fs, win, win_size)
    """

    nchs = values.shape[1]

    if not win:
        avg_pc = np.corrcoef(values, rowvar=False)
    else:
        # Define time windows
        iw = round(win_size * fs)
        window_start = np.arange(0, values.shape[0], iw)

        # Remove dangling window
        if window_start[-1] + iw > values.shape[0]:
            window_start = window_start[:-1]

        nw = len(window_start)

        # Initialize output array
        all_pc = np.empty((nchs, nchs, nw))
        all_pc[:] = np.nan

        # Calculate pc for each window
        for i, start in enumerate(window_start):
            # Define the time clip
            clip = values[start : start + iw, :]

            pc = np.corrcoef(clip, rowvar=False)
            # np.fill_diagonal(pc, 0)

            # Unwrap the pc matrix into a one-dimensional vector for storage
            all_pc[:, :, i] = pc

        # Average the network over all time windows
        avg_pc = np.nanmean(all_pc, axis=2)

    return avg_pc
