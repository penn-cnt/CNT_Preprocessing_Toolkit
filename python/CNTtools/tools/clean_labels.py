import re
import numpy as np
from beartype import beartype
from beartype.typing import Union, Iterable


@beartype
def clean_labels(channel_li: Union[Iterable[str], str]) -> np.ndarray:
    """
    Clean and standardize channel labels.

    Parameters:
    - channel_li (Union[Iterable[str], str]): Either a single channel label or an iterable of channel labels.

    Returns:
    - np.ndarray: An array of cleaned and standardized channel labels.

    Example:
    >>> clean_labels('LA 01')
    array(['LA1'])
    """
    if isinstance(channel_li, str):
        channel_li = [channel_li]
    new_channels = []
    for i in range(len(channel_li)):
        # standardizes channel names
        label_num_search = re.search(r"\d", channel_li[i])
        if label_num_search is not None:
            label_num_idx = label_num_search.start()
            label_non_num = channel_li[i][:label_num_idx]
            label_num = channel_li[i][label_num_idx:]
            label_num = label_num.lstrip("0")
            label = label_non_num + label_num
        else:
            label = channel_li[i]
        label = label.replace("EEG", "")
        label = label.replace("Ref", "")
        label = label.replace(" ", "")
        label = label.replace("-", "")
        label = label.replace("CAR", "")
        label = label.replace("HIPP", "DH")
        label = label.replace("AMY", "DA")
        label = label.replace("FP1", "Fp1")
        label = label.replace("FP2", "Fp2")
        new_channels.append(label)
    return np.array(new_channels)
