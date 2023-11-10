"""
    This function finds non-iEEG channel labels
"""
import re
import numpy as np
from beartype import beartype
from beartype.typing import Union, Iterable

non_ieeg = [
    "EKG",
    "O",
    "C",
    "ECG",
    "CZ",
    "RATE",
    "CZ",
    "F",
    "FP",
    "FZ",
    "LOC",
    "ROC",
    "T",
    "P",
]


@beartype
def find_non_ieeg(channel_li: Union[Iterable[str], str]) -> np.ndarray:
    """
    Find non-iEEG channel labels.

    Parameters:
    - channel_li (Union[Iterable[str], str]): Either an iterable of channel labels or a single channel label.

    Returns:
    - np.ndarray: Boolean array indicating whether each channel is non-iEEG.
    """
    if isinstance(channel_li, str):
        channel_li = [channel_li]
    is_non_ieeg = np.zeros(len(channel_li), dtype=bool)
    for ind, i in enumerate(channel_li):
        # Gets letter part of channel
        label_num_search = re.search(r"\d", i)
        if label_num_search is not None:
            label_num_idx = label_num_search.start()
            label_non_num = i[:label_num_idx]
        else:
            label_non_num = i
        # finds non-iEEG channels, make a separate function
        if label_non_num.upper() in non_ieeg:
            is_non_ieeg[ind] = True
        if i == "O1" or i == "O2":
            if (
                channel_li.count("O3") == 1 or channel_li.count("O4") == 1
            ):  # if intracranial, should have these too
                is_non_ieeg[ind] = 0
            else:
                is_non_ieeg[ind] = 1

    return is_non_ieeg
