import numpy as np
import pandas as pd
import re
from beartype import beartype
from beartype.typing import Iterable, Tuple
from .clean_labels import clean_labels


@beartype
def bipolar(
    data: np.ndarray, labels: Iterable[str], soft: bool = True, soft_thres: int = 1
) -> Tuple[np.ndarray, np.ndarray]:
    """
    Return the data in bipolar montage using the channel names.
    The output data[:,ich] equals the input data[:,ich] - data[:,jch],
    where jch is the next numbered contact on the same electrode as ich.
    For example. if ich is RA1, then jch is RA2 and values(:,RA1) will be
    the old values(:,RA1) - old values(:,RA2). If ich is the last contact
    on the electrode, or adjacent channel does not exist, then values(:,ich)
    is defined to be nans. the label is marked as '-'.
    Default allows soft referencing, i.e. substraction of channels at distance
    of soft threshold. e.g. A soft threshold of 1 allows RA1-RA3.

    Args:
        data (np.ndarray): The iEEG data as a NumPy array with shape (samples, channels).
        labels (Iterable[str]): A list of channel labels indicating the channel names.
        soft (bool, optional): Allow for soft bipolar referencing, considering multiple next-numbered contacts. Default is True.
        soft_thres (int, optional): Number of next-numbered contacts to consider in soft referencing. Default is 1.

    Returns:
        np.ndarray: The bipolar montage EEG data with the same shape as the input data.
        np.ndarray: An array of bipolar labels corresponding to the bipolar montage.

    Notes:
        This function applies the bipolar montage transformation to iEEG data based on the channel labels provided.
        If a channel label follows the standard naming convention (e.g., 'C3', 'FZ'), it attempts to create a bipolar channel
        by subtracting the adjacent channel. If the adjacent channel exists, the subtraction is performed; otherwise,
        the label is marked as '-'.

    Examples:
        >>> bipolar_data, bipolar_labels = tools.bipolar(data, labels)
        >>> bipolar_data, bipolar_labels = tools.bipolar(data, labels, soft = False)
        >>> bipolar_data, bipolar_labels = tools.bipolar(data, labels, soft_thres = 2)
    """

    channels = clean_labels(labels)
    nchan = len(channels)
    bipolar_labels = []
    out_values = np.nan * np.zeros(data.shape)
    # naming to standard 4 character channel Name: (Letter)(Letter)[Letter](Number)(Number)
    # channels = channel2std(channels)
    for ch in range(nchan):
        out = np.nan * np.zeros(data.shape[0])
        ch1Ind = ch
        ch1 = channels[ch1Ind]  # clean_label
        label_num_search = re.search(r"\d", ch1)
        if label_num_search is not None:
            label_num_idx = label_num_search.start()
            label_non_num = ch1[:label_num_idx]
            label_num = int(ch1[label_num_idx:])
            # find sequential index
            if label_num > 12:
                print("This might be a grid and so bipolar might be tricky")
            if soft:
                ch2_num = list(range(label_num + 1, label_num + soft_thres + 2))
            else:
                ch2_num = [label_num + 1]
            for i in ch2_num:
                ch2 = label_non_num + f"{i}"
                ch2exists = np.where(channels == ch2)[0]
                if len(ch2exists) > 0:
                    ch2Ind = ch2exists[0]
                    out = data[:, ch1Ind] - data[:, ch2Ind]
                    bipolar_label = ch1 + "-" + ch2
                    break
                else:
                    bipolar_label = "-"
        elif ch1 == "FZ":
            ch2exists = np.where(channels == "CZ")[0]
            if len(ch2exists) > 0:
                ch2Ind = ch2exists[0]
                out = data[:, ch1Ind] - data[:, ch2Ind]
                bipolar_label = ch1 + "-" + "CZ"
        else:
            bipolar_label = "-"
        bipolar_labels.append(bipolar_label)
        out_values[:, ch] = out

    return out_values, np.array(bipolar_labels)
