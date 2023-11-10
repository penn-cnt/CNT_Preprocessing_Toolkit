import numpy as np
from scipy.spatial.distance import cdist
from beartype import beartype
from .pseudo_laplacian import pseudo_laplacian
from numbers import Number


@beartype
def laplacian(data: np.ndarray, labels: np.ndarray, locs: np.ndarray, radius: Number):
    """
    Apply Laplacian re-referencing to multi-channel iEEG data.

    Parameters:
        values (np.ndarray): Matrix representing iEEG data of shape samples X channels.
        labels (np.ndarray): List of channel labels corresponding to the columns of the data matrix.
        locs (np.ndarray): Matrix representing the locations of electrodes.
        radius (float): Radius defining the neighborhood for Laplacian re-referencing.

    Returns:
        np.ndarray: Laplacian-referenced EEG data matrix.
        np.ndarray: Channel labels for the Laplacian-referenced data.
    """
    out_values = np.nan * np.zeros(data.shape)
    nchs = data.shape[1]
    laplacian_labels = []

    nan_elecs = np.any(np.isnan(locs), axis=1)
    pseudo_values, pseudo_labels = pseudo_laplacian(data, labels)

    # Calculate pairwise distances between X and Y
    D = cdist(locs, locs)

    close = D < radius
    close[np.eye(close.shape[0]).astype(bool)] = 0

    # close_chs = []

    for i in range(nchs):
        if not nan_elecs[i]:
            close_elecs = np.nonzero(close[i, :])[0]
            if len(close_elecs) > 0:
                out_values[:, i] = data[:, i] - np.nanmean(data[:, close_elecs], 1)
                laplacian_labels.append(labels[i])
                # close_chs.append(close_elecs)
            else:
                out_values[:, i] = pseudo_values[:, i]
                laplacian_labels.append(pseudo_labels[i])
        else:
            out_values[:, i] = pseudo_values[:, i]
            laplacian_labels.append(pseudo_labels[i])

    return out_values, laplacian_labels
