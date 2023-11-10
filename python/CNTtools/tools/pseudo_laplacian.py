import numpy as np
import re
from beartype.typing import Iterable, Tuple


def pseudo_laplacian(
    values: np.ndarray, chLabels: Iterable[str], soft: bool = True, softThres: int = 1
) -> Tuple[np.ndarray, np.ndarray]:
    """
    Apply pseudo-laplacian re-referencing to multi-channel iEEG data.

    Parameters:
        values (np.ndarray): Matrix representing iEEG data of shape samples X channels.
        chLabels (Iterable[str]): List of channel labels corresponding to the columns of the data matrix.
        soft (bool, optional): Allow for soft bipolar referencing, considering multiple next-numbered contacts. Default is True.
        softThres (int, optional): Number of next-numbered contacts to consider in soft referencing. Default is 1.

    Returns:
        np.ndarray: Pseudo-laplacian-referenced EEG data matrix.
        np.ndarray: Channel labels for the pseudo-laplacian-referenced data.
    """

    nchs = values.shape[1]
    old_values = values.copy()

    # Decompose chLabels
    elecs, numbers = decompose(chLabels)
    out_labels = chLabels.copy()

    # Pseudo-laplacian montage
    for ch in range(nchs):
        # Initialize it as nans
        out = np.nan * np.zeros(values.shape[0])
        bipolar_label = "-"

        # Get the clean label
        label = chLabels[ch]

        # get the non numerical portion of the electrode contact
        label_non_num = elecs[ch]

        # get numerical portion
        label_num = numbers[ch]

        if not np.isnan(label_num):
            # see if there exists one higher
            label_nums_high = (
                list(range(label_num + 1, label_num + softThres + 2))
                if soft
                else [label_num + 1]
            )
            label_nums_low = (
                list(range(label_num - softThres - 1, label_num))[::-1]
                if soft
                else [label_num - 1]
            )
            higher_ch = np.nan
            lower_ch = np.nan

            for label_num_i in label_nums_high:
                higher_label = label_non_num + str(label_num_i)
                if higher_label in chLabels:
                    higher_ch = np.where(chLabels == higher_label)[0][0]
                    break

            for label_num_i in label_nums_low:
                lower_label = label_non_num + str(label_num_i)
                if lower_label in chLabels:
                    lower_ch = np.where(chLabels == lower_label)[0][0]
                    break

            if (not np.isnan(higher_ch)) and (not np.isnan(lower_ch)):
                out = (
                    old_values[:, ch]
                    - (old_values[:, higher_ch] + old_values[:, lower_ch]) / 2
                )
            elif not np.isnan(higher_ch):
                out = old_values[:, ch] - old_values[:, higher_ch]
            elif not np.isnan(lower_ch):
                out = old_values[:, ch] - old_values[:, lower_ch]
            else:
                out_labels[ch] = bipolar_label
        else:
            out_labels[ch] = bipolar_label
        values[:, ch] = out

    return values, np.array(out_labels)


def decompose(labels: Iterable[str]) -> Tuple[list, list]:
    non_nums = []
    nums = []

    for label in labels:
        label_num_search = re.search(r"\d", label)
        if label_num_search is not None:
            label_num_idx = label_num_search.start()
            label_non_num = label[:label_num_idx]
            label_num = int(label[label_num_idx:])
        else:
            label_non_num = label
            label_num = np.nan
        non_nums.append(label_non_num)
        nums.append(label_num)

    return non_nums, nums
