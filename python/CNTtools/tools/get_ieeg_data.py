# pylint: disable-msg=C0103
import ieeg
from ieeg.auth import Session
from CNTtools import settings

# from .pull_patient_localization import pull_patient_localization
# from pull_patient_localization import pull_patient_localization
import numpy as np
import time, os, warnings, pickle

from beartype import beartype
from beartype.typing import Union, Optional, Tuple
from numbers import Number

from .clean_labels import clean_labels


def _pull_iEEG(
    ds: ieeg.dataset.Dataset,
    start_usec: Number,
    duration_usec: Number,
    channel_ids: list,
) -> np.ndarray:
    """
    Pull data while handling iEEGConnectionError
    """
    while True:
        try:
            data = ds.get_data(start_usec, duration_usec, channel_ids)
            return data
        except Exception as e:
            if "500" in str(e) or "502" in str(e) or "503" in str(e) or "504" in str(e):
                time.sleep(1)
            else:
                raise e


@beartype
def get_ieeg_data(
    username: str,
    password_bin_file: str,
    iEEG_filename: str,
    start_time: Number,
    stop_time: Number,
    select_elecs: Optional[list[Union[str, int]]] = None,
    ignore_elecs: Optional[list[Union[str, int]]] = None,
    outputfile: str = None,
) -> Tuple[np.ndarray, float, np.ndarray]:
    """
    Retrieve iEEG data from iEEG.org.

    Parameters:
    - username (str): Username for iEEG.org authentication.
    - password_bin_file (str): Path to the file containing the iEEG.org password.
    - iEEG_filename (str): Name of the iEEG dataset on iEEG.org.
    - start_time (Number): Start time in seconds.
    - stop_time (Number): Stop time in seconds.
    - select_elecs (Optional[List[Union[str, int]]]): List of selected electrodes (channels) names/indices.
    - ignore_elecs (Optional[List[Union[str, int]]]): List of electrodes (channels) names/indices to ignore.
    - outputfile (Optional, str): path to save data. Default is None.

    Returns:
    - Tuple[np.ndarray, float, np.ndarray]: A tuple containing iEEG data, sampling frequency, and channel names.

    Example usage:
    username = 'arevell'
    password = 'password'
    iEEG_filename='HUP138_phaseII'
    start_time = 248432.34
    stop_time = 248525.74
    removed_channels = ['EKG1', 'EKG2', 'CZ', 'C3', 'C4', 'F3', 'F7', 'FZ', 'F4', 'F8', 'LF04', 'RC03', 'RE07', 'RC05', 'RF01', 'RF03', 'RB07', 'RG03', 'RF11', 'RF12']
    outputfile = '/Users/andyrevell/mount/DATA/Human_Data/BIDS_processed/sub-RID0278/eeg/sub-RID0278_HUP138_phaseII_248432340000_248525740000_EEG.pickle'
    get_iEEG_data(username, password, iEEG_filename, start_time, stop_time, ignore_elecs = removed_channels, outputfile = outputfile)

    To run from command line:
        python3.6 -c 'import get_iEEG_data; get_iEEG_data.get_iEEG_data("arevell", "password", "HUP138_phaseII", 248432.34, 248525.74,
        ["EKG1", "EKG2", "CZ", "C3", "C4", "F3", "F7", "FZ", "F4", "F8", "LF04", "RC03", "RE07", "RC05", "RF01", "RF03", "RB07", "RG03", "RF11", "RF12"],
        "/gdrive/public/DATA/Human_Data/BIDS_processed/sub-RID0278/eeg/sub-RID0278_HUP138_phaseII_D01_248432340000_248525740000_EEG.pickle")'

    How to get back pickled files:
    with open(outputfile, 'rb') as f: data, fs = pickle.load(f)
    """

    # print("\n\nGetting data from iEEG.org:")
    # print("iEEG_filename: {0}".format(iEEG_filename))
    # print("start_time_usec: {0}".format(start_time_usec))
    # print("stop_time_usec: {0}".format(stop_time_usec))
    # print("ignore_elecs: {0}".format(ignore_elecs))
    # if outputfile:
    #     print("Saving to: {0}".format(outputfile))
    # else:
    #     print("Not saving, returning data and sampling frequency")

    pwd = open(os.path.join(settings.USER_DIR, password_bin_file), "r").read()

    assert start_time < stop_time, "CNTtools:invalidTimeRange"
    assert start_time >= 0, "CNTtools:invalidTimeRange"
    start_time_usec = int(start_time * 1e6)
    stop_time_usec = int(stop_time * 1e6)
    duration = stop_time_usec - start_time_usec

    while True:
        try:
            s = Session(username, pwd)
            ds = s.open_dataset(iEEG_filename)
            all_channel_labels = ds.get_channel_labels()
            break
        except Exception as e:
            if "Authentication" in str(e):
                raise AssertionError("CNTtools:invalidLoginInfo")
            elif "404" in str(e) or "NoSuchDataSnapshot" in str(e):
                raise AssertionError("CNTtools:invalidFileName")
            elif (
                "500" in str(e) or "502" in str(e) or "503" in str(e) or "504" in str(e)
            ):
                time.sleep(1)
            else:
                raise e

    assert len(all_channel_labels) > 0, "CNTtools:emptyFile"
    end_sec = ds.get_time_series_details(all_channel_labels[0]).duration
    assert stop_time_usec <= end_sec, "CNTtools:invalidTimeRange"
    all_channel_labels = clean_labels(all_channel_labels)

    if select_elecs is not None:
        elec_type = type(select_elecs[0])
        assert all(
            isinstance(i, elec_type) for i in select_elecs
        ), "CNTtools:invalidElectrodeList"
        if elec_type == int:
            channel_ids = [
                i for i in select_elecs if i >= 0 & i < len(all_channel_labels)
            ]
            if len(channel_ids) < len(select_elecs):
                warnings.warn("CNTtools:invalidChannelID, invalid channels ignored.")
            channel_names = [all_channel_labels[e] for e in channel_ids]
        elif elec_type == str:
            select_elecs = clean_labels(select_elecs)
            channel_ids = [
                i for i, e in enumerate(all_channel_labels) if e in select_elecs
            ]
            if len(channel_ids) < len(select_elecs):
                warnings.warn("CNTtools:invalidChannelID, invalid channels ignored.")
            channel_names = [all_channel_labels[e] for e in channel_ids]
        else:
            print("Electrodes not given as a list of ints or strings")

    elif ignore_elecs is not None:
        elec_type = type(ignore_elecs[0])
        assert all(
            isinstance(i, elec_type) for i in ignore_elecs
        ), "CNTtools:invalidElectrodeList"
        if elec_type == int:
            channel_ids = [
                i for i in np.arange(len(all_channel_labels)) if i not in ignore_elecs
            ]
            if len(channel_ids) > len(all_channel_labels) - len(ignore_elecs):
                warnings.warn("CNTtools:invalidChannelID, invalid channels ignored.")
            channel_names = [all_channel_labels[e] for e in channel_ids]
        elif elec_type == str:
            ignore_elecs = clean_labels(ignore_elecs)
            channel_ids = [
                i for i, e in enumerate(all_channel_labels) if e not in ignore_elecs
            ]
            if len(channel_ids) > len(all_channel_labels) - len(ignore_elecs):
                warnings.warn("CNTtools:invalidChannelID, invalid channels ignored.")
            channel_names = [e for e in all_channel_labels if e not in ignore_elecs]
        else:
            print("Electrodes not given as a list of ints or strings")

    else:
        channel_ids = np.arange(len(all_channel_labels))
        channel_names = all_channel_labels

    try:
        data = ds.get_data(start_time_usec, duration, channel_ids)
    except Exception as e:
        # clip is probably too big, pull chunks and concatenate
        clip_size = 60 * 1e6
        clip_start = start_time_usec
        data = None
        while clip_start + clip_size < stop_time_usec:
            if data is None:
                # data = ds.get_data(clip_start, clip_size, channel_ids)
                data = _pull_iEEG(ds, clip_start, clip_size, channel_ids)
            else:
                # data = np.concatenate(([data, ds.get_data(clip_start, clip_size, channel_ids)]), axis=0)
                data = np.concatenate(
                    ([data, _pull_iEEG(ds, clip_start, clip_size, channel_ids)]), axis=0
                )
            clip_start = clip_start + clip_size
        # data = np.concatenate(([data, ds.get_data(clip_start, stop_time_usec - clip_start, channel_ids)]), axis=0)

    # df = pd.DataFrame(data, columns=channel_names)
    fs = ds.get_time_series_details(ds.ch_labels[0]).sample_rate  # get sample rate

    if outputfile:
        with open(outputfile, "wb") as f:
            pickle.dump([data, channel_names, fs], f)
    else:
        return data, fs, np.array(channel_names)


""""
Download and install iEEG python package - ieegpy
GitHub repository: https://github.com/ieeg-portal/ieegpy
If you downloaded this code from https://github.com/andyrevell/paper001.git then skip to step 2
1. Download/clone ieepy. 
    git clone https://github.com/ieeg-portal/ieegpy.git
2. Change directory to the GitHub repo
3. Install libraries to your python Path. If you are using a virtual environment (ex. conda), make sure you are in it
    a. Run:
        python setup.py build
    b. Run: 
        python setup.py install
              
"""
