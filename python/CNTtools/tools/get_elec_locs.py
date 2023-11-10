import pandas as pd
import numpy as np
from .clean_labels import clean_labels
from beartype import beartype
from beartype.typing import Iterable, Union


@beartype
def get_elec_locs(fileID: str, chLabels: Union[Iterable[str], str], filename: str) -> np.ndarray:
    """
    Get electrode locations for specified channel labels from a file.

    Parameters:
    - chLabels (iterable or str): Channel labels for which to retrieve electrode locations.
    - filename (str): Path to the file containing electrode locations.

    Returns:
    - output (np.ndarray): Numpy array containing electrode locations corresponding to channel labels
                    Unavailable channel locations filled with nan.

    Example:
    chLabels = ['Fp1', 'Fp2', 'C3', 'C4']
    filename = 'electrode_locations.csv'
    output = get_elec_locs(chLabels, filename)
    """

    # Convert single string to list
    if isinstance(chLabels, str):
        chLabels = [chLabels]

    # Load electrode locations from the specified file
    elec_locs = pd.read_csv(filename, header=None).dropna()
    elec_locs = elec_locs.to_numpy()

    # 
    available_pts = np.unique(elec_locs[:,0])
    match = [i in fileID for i in available_pts]
    fullFileID = available_pts[match]
    elec_locs = elec_locs[np.where(elec_locs[:,0]==fullFileID)[0],:]

    # Clean labels from both sources
    labels = clean_labels(elec_locs[:,1])
    chLabels = clean_labels(chLabels)

    # Find common labels and their corresponding indices
    common = np.isin(chLabels, labels)
    out_locs = np.nan * np.zeros([len(chLabels), 3])
    for i in range(len(chLabels)):
        if common[i]:
            ind = np.where(labels == chLabels[i])[0]
            out_locs[i, :] = elec_locs[ind, 2:]

    return out_locs
