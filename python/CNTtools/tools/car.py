import numpy as np
from beartype import beartype
from beartype.typing import Iterable, Tuple


@beartype
def car(data: np.ndarray, labels: Iterable[str]) -> Tuple[np.ndarray, np.ndarray]:
    """
    Perform Common Average Reference (CAR) on the input iEEG data.

    Args:
        data (np.ndarray): The iEEG data as a NumPy array with shape (samples, channels).
        labels (Iterable[str]): A list of channel labels indicating the channel names.

    Returns:
        np.ndarray: The EEG data after applying the Common Average Reference.
        np.ndarray: A list of channel labels with '-CAR' appended to each label, indicating the CAR reference.

    Notes:
        This function computes the Common Average Reference (CAR) for EEG data. It subtracts the average of all channels
        from each channel's data to remove the common reference. The channel labels are modified to indicate the CAR
        reference by appending '-CAR' to each label.

    Examples:
        >>> import numpy as np
        >>> from tools import car
        >>> data = np.random.rand(1000, 16)  # Simulated EEG data with 16 channels
        >>> labels = ['C3', 'C4', 'FZ', 'P3', 'P4', 'O1', 'O2', 'T3', 'T4', 'T5', 'T6', 'F3', 'F4', 'F7', 'F8', 'CZ']
        >>> car_data, car_labels = car(data, labels)
    """
    out_data = data - np.nanmean(data, 1)[:, np.newaxis]
    car_labels = [label + "-CAR" for label in labels]

    return out_data, np.array(car_labels)
