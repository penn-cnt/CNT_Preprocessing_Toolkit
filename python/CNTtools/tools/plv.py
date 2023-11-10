import numpy as np
from scipy.signal import hilbert
from .default_freqs import freqs
from .bandpass_filter import bandpass_filter
from beartype import beartype
from numbers import Number


@beartype
def plv(
    values: np.ndarray,
    fs: Number,
    win: bool = False,
    win_size: Number = 2,
    freqs: np.ndarray = freqs,
) -> np.ndarray:
    """
    Computes phase-locking value (PLV) for iEEG data.

    Parameters:
        values (numpy array): iEEG data matrix where each column represents a channel.
        fs (numeric): Sampling frequency of the iEEG data.
        win (bool, optional): Boolean indicating whether to use time windows (True) or compute a single PLV (False).
        win_size (numeric, optional): Time window size in seconds.
        freqs (numpy array, optional): Matrix where each row represents a frequency range.
                                      The first column is the lower bound, and the second column is the upper bound.

    Returns:
        all_plv (numpy array): PLV matrix where each element (i, j, k) represents the PLV bewin_sizeeen channel i and channel j at frequency range k.

    Example:
        all_plv = plv(values, fs)
        all_plv = plv(values, fs, win=True, win_size=2, freqs=np.array([[4, 8], [8, 12]]))
    """
    # Parameters
    nchs = values.shape[1]
    nfreqs = freqs.shape[0]

    if win and (win_size > values.shape[0] / fs):
        win = False

    # Initialize output matrix
    all_plv = np.ones((nchs, nchs, nfreqs))

    # Preprocess values
    for ich in range(nchs):
        curr_values = values[:, ich]
        curr_values[np.isnan(curr_values)] = np.nanmean(curr_values)
        values[:, ich] = curr_values

    # Get filtered signal
    filtered_data = np.zeros((values.shape[0], values.shape[1], nfreqs))
    for f in range(nfreqs):
        filtered_data[:, :, f] = bandpass_filter(values, fs, freqs[f, 0], freqs[f, 1])

    if win:
        # Divide into time windows
        iw = int(win_size * fs)
        window_start = np.arange(0, values.shape[0], iw)

        # Remove dangling window
        if window_start[-1] + iw > values.shape[0]:
            window_start = window_start[:-1]

        nw = len(window_start)

        all_plv = np.ones((nchs, nchs, nfreqs, nw))
        for t in range(nw):
            for f in range(nfreqs):
                tmp_data = filtered_data[window_start[t] : window_start[t] + iw, :, f]

                # Get phase of each signal
                phase = np.angle(hilbert(tmp_data))

                # Get PLV
                plv = np.ones((nchs, nchs))
                for ich in range(nchs):
                    for jch in range(ich + 1, nchs):
                        e = np.exp(1j * (phase[:, ich] - phase[:, jch]))
                        plv[ich, jch] = np.abs(np.sum(e, axis=0)) / phase.shape[0]
                        plv[jch, ich] = plv[ich, jch]

                all_plv[:, :, f, t] = plv

        all_plv = np.nanmean(all_plv, axis=3)
    else:
        all_plv = np.ones((nchs, nchs, nfreqs))
        # Do PLV for each frequency
        for f in range(nfreqs):
            tmp_data = filtered_data[:, :, f]

            # Get phase of each signal
            phase = np.angle(hilbert(tmp_data))

            # Get PLV
            plv = np.ones((nchs, nchs))
            for ich in range(nchs):
                for jch in range(ich + 1, nchs):
                    e = np.exp(1j * (phase[:, ich] - phase[:, jch]))
                    plv[ich, jch] = np.abs(np.sum(e, axis=0)) / phase.shape[0]
                    plv[jch, ich] = plv[ich, jch]

            all_plv[:, :, f] = plv

    return all_plv
