from sklearn.linear_model import LinearRegression
import numpy as np
from beartype import beartype


@beartype
def pre_whiten(data: np.ndarray) -> np.ndarray:
    """Pre-whiten the input data using linear regression.

    Args:
        data (np.ndarray): Matrix representing data. Each column is a channel, and each row is a time point.

    Returns:
        np.ndarray: Pre-whitened data matrix.
    """
    for i in range(data.shape[1]):
        vals = data[:, i].reshape(-1, 1)
        if np.sum(~np.isnan(vals)) == 0:
            continue
        model = LinearRegression().fit(vals[:-1, :], vals[1:, :])
        E = model.predict(vals[:-1, :]) - vals[1:, :]
        if len(E) < len(vals):
            E = np.concatenate([E, np.nan * np.zeros([len(vals) - len(E), 1])])
        data[:, i] = E.reshape(-1)

    return data
