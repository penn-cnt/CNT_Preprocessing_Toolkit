import numpy as np
from beartype import beartype
from numbers import Number
from beartype.typing import Tuple


def prctile(x, p):
    p = np.asarray(p, dtype=float)
    n = len(x)
    p = (p - 50) * n / (n - 1) + 50
    p = np.clip(p, 0, 100)
    return np.percentile(x, p)


@beartype
def identify_bad_chs(data: np.ndarray, fs: Number) -> Tuple[np.ndarray, dict]:
    """
    Identify bad channels based on various criteria.

    Args:
        values (np.ndarray): Matrix representing iEEG data, of shape samples X channels.
        fs (Number): Sampling frequency of the iEEG data.

    Returns:
        Tuple[np.ndarray, dict]: A tuple containing a boolean array indicating bad channels and a dictionary
                                with details of bad channels categorized by specific criteria.

    Criteria:
    - Channels with more than half NaNs are marked as bad.
    - Channels with more than half zeros are marked as bad.
    - Channels with a significant number of values above an absolute threshold are marked as bad.
    - Channels with rare cases of super high variance above baseline are marked as bad.
    - Channels with a significant amount of 60 Hz noise are marked as bad.
    - Channels with standard deviation much higher than the median are marked as bad.

    Example:
    values = np.random.randn(100, 5)  # Replace with your actual EEG data
    fs = 250
    bad, details = identify_bad_chs(values, fs)
    """
    # Parameters to reject super high variance
    tile = 99
    mult = 10
    num_above = 1
    abs_thresh = 5e3

    # Parameter to reject high 60 Hz
    percent_60_hz = 0.7

    # Parameter to reject electrodes with much higher std than most electrodes
    mult_std = 10

    nchs = data.shape[1]
    bad = []
    high_ch = []
    nan_ch = []
    zero_ch = []
    high_var_ch = []
    noisy_ch = []
    all_std = np.nanstd(data, 0)
    all_bl = np.nanmedian(data, 0)

    for ich in range(nchs):

        eeg = data[:, ich]

        # Remove channels with nans in more than half
        if np.sum(np.isnan(eeg)) > 0.5 * len(eeg):
            bad.append(ich)
            nan_ch.append(ich)
            continue

        # Remove channels with zeros in more than half
        if np.sum(eeg == 0) > 0.5 * len(eeg):
            bad.append(ich)
            zero_ch.append(ich)
            continue

        # Remove channels with too many above absolute thresh
        if np.sum(np.abs(eeg - all_bl[ich]) > abs_thresh) > 10:
            bad.append(ich)
            high_ch.append(ich)
            continue

        # Remove channels if there are rare cases of super high variance above baseline (disconnection, moving, popping)
        pct = prctile(eeg, [100 - tile, tile])
        thresh = [
            all_bl[ich] - mult * (all_bl[ich] - pct[0]),
            all_bl[ich] + mult * (pct[1] - all_bl[ich]),
        ]
        sum_outside = np.sum(eeg > thresh[1]) + np.sum(eeg < thresh[0])
        if sum_outside >= num_above:
            bad.append(ich)
            high_var_ch.append(ich)
            continue

        # Remove channels with a lot of 60 Hz noise, suggesting poor impedance

        # Calculate fft
        # orig_eeg = orig_data(:,ich);
        # Y = fft(orig_eeg-mean(orig_eeg));
        Y = np.fft.fft(eeg - np.nanmean(eeg))

        # Get power
        P = np.abs(Y) ** 2
        freqs = np.linspace(0, fs, len(P) + 1)
        freqs = freqs[:-1]

        # Take first half
        P = P[: int(np.ceil(len(P) / 2))]
        freqs = freqs[: int(np.ceil(len(freqs) / 2))]

        P_60Hz = np.sum(P[(freqs > 58) & (freqs < 62)]) / np.sum(P)
        if P_60Hz > percent_60_hz:
            bad.append(ich)
            noisy_ch.append(ich)
            continue

    # Remove channels for whom the std is much larger than the baseline
    median_std = np.nanmedian(all_std)
    chs = np.arange(nchs)
    higher_std = chs[all_std > mult_std * median_std]
    bad_std = higher_std
    bad_std = [i for i in bad_std if ~np.isin(i, bad)]
    bad = bad + bad_std
    bad_bin = np.zeros(nchs)
    bad_bin[bad] = 1
    # bad = logical(bad_bin)

    details = {}
    details["noisy"] = noisy_ch
    details["nans"] = nan_ch
    details["zeros"] = zero_ch
    details["var"] = high_var_ch
    details["higher_std"] = bad_std
    details["high_voltage"] = high_ch

    return bad_bin.astype(bool), details
