import numpy as np
from scipy.signal import correlate
from beartype import beartype
from numbers import Number


@beartype
def cross_correlation(
    values: np.ndarray,
    fs: Number,
    win: bool = False,
    win_size: Number = 2,
    max_lag: Number = 200,
):
    """
    Compute cross-correlation matrices for iEEG data.

    Parameters:
        values (np.ndarray): iEEG data array (samples x channels).
        fs (float): Sampling frequency of the iEEG data.
        win (bool, optional): Boolean indicating whether to use time windows (True) or
                             compute a single cross-correlation (False). Default is False.
        win_size (float, optional): Time window size in seconds. Required if win is True. Default is 2 seconds.
        max_lag (float, optional): Specify the maximum lag in milliseconds. Default is 200 ms.

    Returns:
        mb (np.ndarray): Mean cross-correlation matrix.
        lb (np.ndarray): Mean lag matrix (in seconds).

    Example:
        mb, lb = cross_correlation(values, fs, win=True, win_size=1, max_lag=300)

    Notes:
    - The diagonal entries of the cross-correlation matrices represent
      self-correlation and are set to 1.
    - If using time windows (win=True), the function returns the mean
      cross-correlation and lag matrices across all windows.

    """
    ml_default = values.shape[0] - 1
    ml = np.min([ml_default, int(max_lag * 1e-3 * fs)])  # max lag in num samples
    lags = np.arange(-ml, ml + 1)
    nchan = values.shape[1]
    if win and (win_size > values.shape[0] / fs):
        win = False

    if win:
        # Divide into time windows
        iw = int(win_size * fs)
        window_start = np.arange(0, values.shape[0], iw)

        # Remove dangling window
        if window_start[-1] + iw > values.shape[0]:
            window_start = window_start[:-1]

        nw = len(window_start)

        # Prep the variables
        mb_all = np.ones((nchan, nchan, nw))
        lb_all = np.zeros((nchan, nchan, nw))
        lags_all = np.arange(-iw + 1, iw)
        if lags_all[0] > lags[0]:
            lags = lags_all
            ind_range = [0, len(lags_all)]
        else:
            ind = np.where(lags_all == lags[0])[0][0]
            ind_range = [ind, ind + 2 * ml + 1]
        mid = np.where(lags == 0)[0][0]
        cols = np.arange(0, nchan * nchan, nchan + 1)

        for t in range(nw):
            r_all = np.zeros([lags_all.shape[0], nchan * nchan])
            for col1 in range(nchan):
                for col2 in range(col1, nchan):
                    n = nchan * (col1) + col2
                    n_rev = nchan * (col2) + col1
                    r = correlate(
                        values[window_start[t] : window_start[t] + iw, col1],
                        values[window_start[t] : window_start[t] + iw, col2],
                    )
                    r_all[:, n] = r
                    r_all[:, n_rev] = r

            r_all = r_all[ind_range[0] : ind_range[1], :]

            trow = np.sqrt(r_all[mid, cols])
            tmat = np.outer(trow, trow).reshape(-1)
            r_all /= tmat
            mb = np.max(r_all, axis=0).reshape(nchan, nchan)
            lb = lags[np.argmax(r_all, axis=0)].reshape(nchan, nchan)
            mb_all[:, :, t] = mb
            lb_all[:, :, t] = lb

        lb_all = lb_all / fs

        mb = np.nanmean(mb_all, axis=2)
        lb = np.nanmean(lb_all, axis=2)
    else:
        lags_all = np.arange(-values.shape[0] + 1, values.shape[0])
        ind = np.where(lags_all == lags[0])[0][0]
        ind_range = [ind, ind + 2 * ml + 1]
        mid = np.where(lags == 0)[0][0]
        cols = np.arange(0, nchan * nchan, nchan + 1)

        r_all = np.zeros([lags_all.shape[0], nchan * nchan])
        for col1 in range(nchan):
            for col2 in range(col1, nchan):
                n = nchan * (col1) + col2
                n_rev = nchan * (col2) + col1
                r = correlate(values[:, col1], values[:, col2])
                r_all[:, n] = r
                r_all[:, n_rev] = r

        r_all = r_all[ind_range[0] : ind_range[1], :]

        trow = np.sqrt(r_all[mid, cols])
        tmat = np.outer(trow, trow).reshape(-1)
        r_all /= tmat
        mb = np.max(r_all, axis=0).reshape(nchan, nchan)
        lb = lags[np.argmax(r_all, axis=0)].reshape(nchan, nchan)
        lb = lb / fs

    return mb, lb
