import numpy as np
from .default_freqs import freqs
from .bandpass_filter import bandpass_filter
from beartype import beartype
from numbers import Number


@beartype
def relative_entropy(
    values: np.ndarray,
    fs: Number,
    win: bool = False,
    win_size: Number = 2,
    freqs: np.ndarray = freqs,
):
    """
    Calculates relative entropy for iEEG data.

    Parameters:
    - values (numpy array): iEEG data matrix where each column represents a channel.
    - fs (numeric): Sampling frequency of the iEEG data.
    - win (bool, optional): Boolean indicating whether to use time windows (True) or compute a single relative entropy (False). Default is False.
    - win_size (numeric, optional): Time window size in seconds. Default is 2 seconds.
    - freqs (numpy array, optional): Matrix where each row represents a frequency range. The first column is the lower bound, and the second column is the upper bound.

    Returns:
    - re (numpy array): Relative entropy matrix where each element (i, j, k) represents the relative entropy bewin_sizeeen channel i and channel j at frequency range k.
    """

    nchs = values.shape[1]
    nfreqs = freqs.shape[0]

    if win and (win_size > values.shape[0] / fs):
        win = False

    for ich in range(nchs):
        curr_values = values[:, ich]
        curr_values[np.isnan(curr_values)] = np.nanmean(curr_values)
        values[:, ich] = curr_values

    filtered_data = np.zeros((values.shape[0], values.shape[1], nfreqs))

    for f in range(nfreqs):
        filtered_data[:, :, f] = bandpass_filter(values, fs, freqs[f, 0], freqs[f, 1])

    if win:
        iw = round(win_size * fs)
        window_start = np.arange(0, values.shape[0], iw)

        # remove dangling window
        if window_start[-1] + iw > values.shape[0]:
            window_start = window_start[:-1]

        nw = len(window_start)
        re = np.nan * np.zeros((nchs, nchs, nfreqs, nw))

        for t in range(nw):
            for f in range(nfreqs):
                tmp_data = filtered_data[window_start[t] : window_start[t] + iw, :, f]

                for ich in range(nchs):
                    for jch in range(ich, nchs):
                        h1 = np.histogram(tmp_data[:, ich], bins=10)[0]  # faster
                        h2 = np.histogram(tmp_data[:, jch], bins=10)[0]
                        smooth = 1e-10
                        h1 = h1 + smooth
                        h2 = h2 + smooth
                        h1 = h1 / np.sum(h1)
                        h2 = h2 / np.sum(h2)
                        S1 = np.sum(h1 * np.log(h1 / h2))
                        S2 = np.sum(h2 * np.log(h2 / h1))
                        re[ich, jch, f, t] = max([S1, S2])
                        re[jch, ich, f, t] = re[ich, jch, f, t]

        re = np.nanmean(re, axis=3)

    else:
        re = np.nan * np.zeros((nchs, nchs, nfreqs))

        for f in range(nfreqs):
            tmp_data = filtered_data[:, :, f]

            for ich in range(nchs):
                for jch in range(ich, nchs):
                    h1 = np.histogram(tmp_data[:, ich], bins=10)[0]
                    h2 = np.histogram(tmp_data[:, jch], bins=10)[0]
                    h1 = h1 / np.sum(h1)
                    h2 = h2 / np.sum(h2)
                    S1 = np.sum(h1 * np.log(h1 / h2))
                    S2 = np.sum(h2 * np.log(h2 / h1))
                    re[ich, jch, f] = max([S1, S2])
                    re[jch, ich, f] = re[ich, jch, f]

    return re
