import numpy as np
from scipy.signal import coherence as coh
from .default_freqs import freqs
from beartype import beartype
from numbers import Number


@beartype
def coherence(
    values: np.ndarray,
    fs: Number,
    win: bool = False,
    win_size: Number = 2,
    segment: Number = 1,
    overlap: Number = 0.5,
    freqs: np.ndarray = freqs,
) -> np.ndarray:
    """
    Calculates coherence for iEEG data with multiple channels.

    Parameters:
        values (numpy array): iEEG data matrix where each column represents a channel.
        fs (float): Sampling frequency of the iEEG data.
        win (bool, optional): Boolean indicating whether to use time windows (True) or compute a single coherence (False).
        win_size (float, optional): Time window size in seconds.
        freqs (numpy array, optional): Matrix where each row represents a frequency range. The first column is the lower bound, and the second column is the upper bound.
        segment (float, optional): Duration of each segment in seconds for multi-taper spectral estimation.
        overlap (float, optional): Overlap between segments for multi-taper spectral estimation, in seconds.

    Returns:
        all_coherence (numpy array): Coherence matrix where each element (i, j, k) represents the coherence bewin_sizeeen channel i and channel j at frequency range k.

    Examples:
        all_coherence = coherence(values, fs)
        all_coherence = coherence(values, fs, win=True, win_size=2, freqs=default_freqs, segment=1, overlap=0.5)
        all_coherence = coherence(values, fs, win=False, freqs=default_freqs, segment=1, overlap=0.5)
    """
    # Parameters
    nchs = values.shape[1]
    nfreqs = freqs.shape[0]
    nperseg = int(fs * segment)
    noverlap = int(fs * overlap)
    window = int(fs * win_size)

    if window > values.shape[0]:
        win = False

    # Initialize output matrix
    all_coherence = np.nan * np.zeros((nchs, nchs, nfreqs))

    for ich in range(nchs):
        curr_values = values[:, ich]
        curr_values[np.isnan(curr_values)] = np.nanmean(curr_values)
        values[:, ich] = curr_values

    if win:
        # Divide into time windows
        window_start = np.arange(0, values.shape[0], window)

        # Remove dangling window
        if window_start[-1] + window > values.shape[0]:
            window_start = window_start[:-1]

        nw = len(window_start)

        temp_coherence = np.nan * np.zeros((nchs, nchs, nfreqs, nw))
        for t in range(nw):
            for ich in range(nchs):
                for jch in range(ich, nchs):
                    f, cxy = coh(
                        values[window_start[t] : window_start[t] + window, ich],
                        values[window_start[t] : window_start[t] + window, jch],
                        fs=fs,
                        nperseg=nperseg,
                        noverlap=noverlap,
                    )
                    f = np.squeeze(f)
                    for i_f in range(nfreqs):
                        temp_coherence[ich, jch, i_f, t] = np.nanmean(
                            cxy[(f >= freqs[i_f, 0]) & (f <= freqs[i_f, 1])]
                        )
                        temp_coherence[jch, ich, i_f, t] = np.nanmean(
                            cxy[(f >= freqs[i_f, 0]) & (f <= freqs[i_f, 1])]
                        )

        temp_coherence = np.nanmean(temp_coherence, axis=3)
    else:
        temp_coherence = np.nan * np.zeros((nchs, nchs, nfreqs))
        for ich in range(nchs):
            for jch in range(nchs):
                # Do MS cohere on the full thing
                f, cxy = coh(
                    values[:, ich],
                    values[:, jch],
                    fs=fs,
                    nperseg=nperseg,
                    noverlap=noverlap,
                )
                f = np.squeeze(f)

                # Average coherence in frequency bins of interest
                for i_f in range(nfreqs):
                    temp_coherence[ich, jch, i_f] = np.nanmean(
                        cxy[(f >= freqs[i_f, 0]) & (f <= freqs[i_f, 1])]
                    )
                    temp_coherence[jch, ich, i_f] = np.nanmean(
                        cxy[(f >= freqs[i_f, 0]) & (f <= freqs[i_f, 1])]
                    )

    # Put the non-nans back
    all_coherence = temp_coherence
    # all_coherence[np.eye(nchs, dtype=bool)] = np.nan

    return all_coherence
