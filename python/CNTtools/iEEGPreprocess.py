import numpy as np
import pandas as pd
import sys, os, json, pickle
from beartype import beartype
from typing import Union, Iterable
from numbers import Number
from CNTtools import settings, tools


class iEEGPreprocess:
    """
    A manager platform of iEEG data.
    Manages login info, and provides login info for data downloading.
    Manages active data clips.
    """

    def __init__(self):
        # dataframe containing all relevant meta data of available data clips
        # need to think how to add different meta info and remove instances?
        self.datasets = {}  # store all data instances
        self.meta = pd.DataFrame(columns=["filename", "start", "stop", "dura", "fs"])
        # or = iEEGMeta()
        self.num_data = self.meta.shape[0]

    ######################
    ## User Login Block ##
    ##################################################################
    ##                                                              ##
    ## Available Methods:                                           ##
    ## Login: session.login('username')                             ##
    ## Login Configuration: session.login_config()                  ##
    ##                                                              ##
    ##################################################################

    def _load_all_users(self):
        """Load all usernames in the user folder"""
        self.users = []
        for file in os.listdir(settings.USER_DIR):
            if file.endswith(".json"):
                with open(os.path.join(settings.USER_DIR, file)) as f:
                    user = json.load(f)
                    self.users.append(user["usr"])

    def _check_user(self):
        """Verify that at least 1 user exists"""
        self._load_all_users()
        if not self.users:
            print("Please set up iEEG login info before downloading data.\n")
            self.login_config()

    def _load_user(self, username):
        """Load user info into current session."""
        with open(
            os.path.join(settings.USER_DIR, username[:3] + "_config.json"), "r"
        ) as f:
            self.user = json.load(f)
            print("Login as : ", self.user["usr"])
            self.user_data_dir = os.path.join(settings.DATA_DIR, self.user["usr"][:3])

    def login_config(self):
        """
        Generate login config file and password file, and use as default user.

        Example Usage:
        >>> session = IEEGPreprocess()
        >>> session.login_config()
        """
        # from tools.login_config import login_config
        usrname = tools.login_config()
        self._load_user(usrname)

    def login(self, username: str = None):
        """
        Log into a specific account or the default account if only one account is available.

        Parameters:
            username (str, optional): The username of the account to log into. If not provided or set to None,
                the method will attempt to log into the default account or ask for keyboard prompt.

        Example Usage:
        >>> session = IEEGPreprocess()

        To log into a specific account, use:
        >>> session.login("my_username")

        To log into the default account or choose from multiple accounts:
        >>> session.login()
        """
        self._check_user()
        if username is not None:
            if username not in self.users:
                raise Exception(
                    "CNTtools:InvalidUsername, Please retry or set up iEEG login info using session.login_config() before use! \n"
                )
            else:
                self._load_user(username)
        else:
            if len(self.users) == 1:
                self._load_user(self.users[0])
            else:
                print("Available accounts includes: \n")
                for i in self.users:
                    print(i)
                username = input("Please specify your username: \n")
                if username not in self.users:
                    raise Exception(
                        "CNTtools:InvalidUsername, Please retry or set up iEEG login info using session.login_config() before use! \n"
                    )
                else:
                    self._load_user(username)

    #####################
    ## Data Management ##
    ##################################################################
    ##                                                              ##
    ## Available Methods:                                           ##
    ## download_data: session.download_data(params)                 ##
    ## load_data: session.load_data(path)                           ##
    ## list_data: session.list_data()                               ##
    ##                                                              ##
    ##################################################################

    def _pickle_save(self, filename):
        with open(filename, "wb") as file:
            pickle.dump(self, file)

    def _pickle_open(self, filename):
        with open(filename, "rb") as file:
            data = pickle.load(file)
        return data

    def _add_data_instance(self, data):
        self.datasets[self.num_data] = data
        data.index = self.num_data

        add_data = {
            "filename": data.filename,
            "start": data.start,
            "stop": data.stop,
            "dura": data.dura,
            "fs": data.fs,
        }

        self.meta.loc[self.num_data] = add_data
        self.num_data += 1

    def _merge_datasets(self, data):
        """
        Need update later for custom metadata merging.

        Args:
            data (iEEGPreprocess): _description_
        """
        for k, v in data.datasets.items():
            self._add_data_instance(v)

    def load_data(self, dir, replace=False, default_folder: bool = True):
        """
        Load data from a specified directory or a saved file.
        Data can be either an iEEGData instance or iEEGPreprocess instance.
        iEEGData instance would be appended to self.datasets, inputs information would be appended to self.meta.

        Parameters:
        -----------
        dir : str
            The directory path or file path from which to load data.
        replace : boolean
            Whether to replace current datasets and metadata. Default is False.
        default_folder: boolean
            Whether to load_data from default user data dir. Default is True.

        Raises:
        ------
        AssertionError : "CNTtools:invalidFilenPath"
            Raised when the specified 'dir' does not exist.
        AssertionError : "CNTtools:invalidFileFormat"
            Raised when the specified file is not in Pickle (.pkl) format.
        AssertionError : "CNTtools:invalidFileContents"
            Raised when the specified file does not contain iEEGData or iEEGPreprocess instance.

        Examples:
        ---------
        >>> session = iEEGPreprocess()
        >>>
        >>> # Load data from a directory containing data files
        >>> session.load_data("/path/to/data_directory")
        >>>
        >>> # Load data from a saved data file, and replace current datasets
        >>> session.load_data("/path/to/saved_data.pkl", replace = True)
        """
        if default_folder:
            dir = os.path.join(self.user_data_dir, dir)
        assert os.path.exists(dir), "CNTtools:invalidFilePath"
        if os.path.isdir(dir):
            filelist = os.listdir(dir)
        elif os.path.isfile(dir):
            dir,file = os.path.split(dir)
            filelist = [file]
        assert any(
            file.endswith(".pkl") for file in filelist
        ), "CNTtools:invalidFileFormat"
        for f in filelist:
            f = os.path.join(dir, f)
            if f.endswith(".pkl"):
                data = self._pickle_open(f)
                assert isinstance(data, iEEGData) or isinstance(
                    data, iEEGPreprocess
                ), "CNTtools:invalidFileContents"
                if replace:
                    self.datasets = {}
                    self.meta = pd.DataFrame(
                        columns=[
                            "filename",
                            "start",
                            "stop",
                            "select_elecs",
                            "ignore_elecs",
                        ]
                    )
                    self.num_data = self.meta.shape[0]

                if isinstance(data, iEEGData):
                    self._add_data_instance(data)
                elif isinstance(data, iEEGPreprocess):
                    self._merge_datasets(data)

    def download_data(
        self,
        filename: str,
        start: Number,
        stop: Number,
        select_elecs: list[Union[str, int]] = None,
        ignore_elecs: list[Union[str, int]] = None,
        username: str = None,
    ):
        """
        Download iEEG data from ieeg.org with the specified parameters.

        Parameters:
        -----------
        filename : str
            The name of the iEEG data file to download from ieeg.org.

        start : Number
            The start time (in seconds) of the data segment to download.

        stop : Number
            The stop time (in seconds) of the data segment to download.

        select_elecs : list of str or int, optional
            A list of electrode names or indices to select for download. Default is None.

        ignore_elecs : list of str or int, optional
            A list of electrode names or indices to ignore during download. Default is None.

        username : str, optional
            The username for logging in to ieeg.org.

        Returns:
        --------
        data : iEEGData
            The downloaded data as an iEEGData isntance.

        Examples:
        ---------
        >>> session = iEEGPreprocess()
        >>> # Download iEEG data for a specific file, time range, and electrode selection
        >>> session.download_data("example_file", 10.0, 20.0, select_elecs=["electrode1", "electrode2"])
        """
        if not hasattr(self, "user"):
            self.login(
                username=username
            )  # ensure login, will raise error if user not config
        # initialize an data instance, with inputs
        data = iEEGData(filename, start, stop, select_elecs, ignore_elecs)
        data._download(self.user)
        self._add_data_instance(data)
        return data

    def list_data(self):
        """
        List all datasets as a table with necessary information, including filename from ieeg.org and start/stop time
        """
        print(self.meta)

    def remove_data(self, data_index):
        """
        Remove data instance from current session.
        """
        if ~isinstance(data_index, list):
            data_index = [data_index]
        for ind in data_index:
            self.meta.drop(ind, inplace=True)
            del self.datasets[ind]
        self.num_data = self.meta.shape[0]

    def save(self, filename: str, default_folder: bool = True):
        """
        Save the iEEGPreprocess instance in pickle format. Defaultly save to data/user.

        Args:
            filename (str): filename to save file. Can be either a path, or a name without path specified.
        """
        if default_folder:
            filename = os.path.join(self.user_data_dir, filename)
        if ".pkl" not in filename:
            filename += ".pkl"
        self._pickle_save(filename)


class iEEGData:
    """
    A class for storing iEEG data and relevant meta info. Inherited from iEEGDataInput class

    Attributes:
    filename : str
        The filename of the iEEG data to retrieve.

    start : Number
        The starting time (in seconds) of the data clip.

    stop : Number
        The ending time (in seconds) of the data clip.

    select_elecs : list[Union[str, int]], optional
        A list of electrode names or indices to select. Default is None.

    ignore_elecs : list[Union[str, int]], optional
        A list of electrode names or indices to ignore. Default is None.

        data (numpy.ndarray): A 2D numpy array containing the iEEG data
            of shape samples X channels.
        fs (Number): The sampling frequency of the iEEG data in Hz.
        ch_names (Iterable[str]): An iterable (list, tuple, etc.) of strings
            containing channel names or labels corresponding to the channels in
            the data array.
        dura (Number, optional): The duration of the iEEG data in seconds.

    Example usage:
    >>> data = np.array([[0.1, 0.2, 0.3],
    ...                  [0.4, 0.5, 0.6]])
    >>> ch_names = ["Channel 1", "Channel 2"]
    >>> fs = 1000.0  # Sampling frequency in Hz
    >>> ieg_data = iEEGData(data, fs, ch_names)
    >>> print(ieg_data.fs)
    1000.0
    >>> print(ieg_data.ch_names)
    ['Channel 1', 'Channel 2']
    >>> print(ieg_data.data)
    array([[0.1, 0.2, 0.3],
           [0.4, 0.5, 0.6]])
    >>> print(ieg_data.dura)
    0.003
    """

    def __init__(
        self,
        filename: str,
        start: Number,
        stop: Number,
        select_elecs: list[Union[str, int]] = None,
        ignore_elecs: list[Union[str, int]] = None,
        data: np.ndarray = None,
        fs: Number = None,
        ch_names: Iterable[str] = None,
    ):
        self.filename = filename
        self.start = start
        self.stop = stop
        self.select_elecs = select_elecs
        self.ignore_elecs = ignore_elecs
        self.dura = self.stop - self.start
        self.data = data
        self.fs = fs
        self.ch_names = ch_names
        self.ref_chnames = []
        self.index = None
        self.power = {}
        self.conn = {}
        self.history = []
        self.record()

    def _download(self, user):
        self.data, self.fs, self.ch_names = tools.get_ieeg_data(
            user["usr"],
            user["pwd"],
            self.filename,
            self.start,
            self.stop,
            self.select_elecs,
            self.ignore_elecs,
        )
        self.raw = self.data  # store a raw version of data and channel labels
        self.raw_chs = self.ch_names
        self.username = user["usr"]
        self.user_data_dir = os.path.join(settings.DATA_DIR, self.username[:3])
        self.record()

    def clean_labels(self):
        """
        Convert channel names to standardized format.
        """
        self.record()
        self.ch_names = tools.clean_labels(self.ch_names)
        self.history.append("clean_labels")

    def find_nonieeg(self):
        """
        Find and return a boolean mask for Non-iEEG channels, 0 = iEEG, 1 = Non-iEEG
        """
        self.nonieeg = tools.find_non_ieeg(self.ch_names)
        self.history.append("find_nonieeg")

    def find_bad_chs(self):
        """
        Find and return a boolean mask for bad channels (1 = bad channels), and details for reasons to reject.
        """
        self.bad, self.reject_details = tools.identify_bad_chs(self.data, self.fs)
        self.history.append("find_bad_chs")

    def reject_nonieeg(self):
        """
        Find and remove non-iEEG channels.
        """
        self.record()
        self.nonieeg = tools.find_non_ieeg(self.ch_names)
        self.data = self.data[:, ~self.nonieeg]
        self.ch_names = self.ch_names[~self.nonieeg]
        self.history.append("reject_nonieeg")

    def reject_artifact(self):
        """
        Find and remove bad channels.
        """
        self.record()
        self.bad, self.reject_details = tools.identify_bad_chs(self.data, self.fs)
        self.data = self.data[:, ~self.bad]
        self.ch_names = self.ch_names[~self.bad]
        self.history.append("reject_artifact")

    def bandpass_filter(self, low_freq: Number = 1, high_freq: Number = 120):
        """
        Filter iEEG signal with bandpass filter.

        Args:
            low_freq (Number, optional): Lower filtering frequency threshold. Defaults to 1.
            high_freq (Number, optional): Higher filtering frequency threshold. Defaults to 120.
        """
        self.record()
        self.data = tools.bandpass_filter(self.data, self.fs, low_freq, high_freq)
        self.history.append("bandpass_filter")

    def notch_filter(self, notch_freq: Number = 60):
        """
        Filter iEEG signal with notch filter.

        Args:
            notch_freq (Number, optional): Notch filtering frequency. Defaults to 60.
        """
        self.record()
        self.data = tools.notch_filter(self.data, self.fs, notch_freq)
        self.history.append("notch_filter")

    def filter(
        self, low_freq: Number = 1, high_freq: Number = 120, notch_freq: Number = 60
    ):
        """
        Filter iEEG signal with bandpass and notch filter.

        Args:
            low_freq (Number, optional): Lower filtering frequency threshold. Defaults to 1.
            high_freq (Number, optional): Higher filtering frequency threshold. Defaults to 120.
            notch_freq (Number, optional): Notch filtering frequency. Defaults to 60.
        """
        self.record()
        self.data = tools.bandpass_filter(self.data, self.fs, low_freq, high_freq)
        self.data = tools.notch_filter(self.data, self.fs, notch_freq)
        self.history.append("filter")

    def car(self):
        """
        Perform Common Average Reference (CAR) on the input iEEG data.
        """
        self.record()
        self.data, self.ref_chnames = tools.car(self.data, self.ch_names)
        self.history.append("car")

    def bipolar(self):
        """
        Perform Bipolar Re-referencing (BR) on the input iEEG data.
        """
        self.record()
        self.data, self.ref_chnames = tools.bipolar(self.data, self.ch_names)
        inds = np.where(self.ref_chnames == "-")[0]
        self.data = np.delete(self.data, inds, axis=1)
        self.ch_names = np.delete(self.ch_names, inds)
        self.ref_chnames = np.delete(self.ref_chnames, inds)
        self.history.append("bipolar")

    def load_locs(self, loc_file: str = ''):
        if loc_file is '':
            loc_file = os.path.join(settings.TESTDATA_DIR,'elec_locs.csv') 
            assert os.path.exists(loc_file),'CNTtools:invalidLocFile\nPlease specify a electrode location file for laplacian re-referencing, with format | fileID/patientID | electrodeName | x | y | z | \nFor default loading, please save electrode location information with filename elec_locs.csv in test/data/elec_locs.csv.\n'
        else:
            assert os.path.exists(loc_file),'CNTtools:invalidLocFile'
        self.locs = tools.get_elec_locs(self.filename, self.ch_names, loc_file)

    def laplacian(self, locs: str = '', radius: Number = 20):
        """
        Perform Laplacian (LAR) on the input iEEG data.

        Args:
            locs (str, optional): The path to the file containing electrode locations. If not provided,
                the method expects that electrode locations have been previously loaded using `load_locs`.
            radius (Number, optional): The radius (in millimeters) used to define the neighborhood for Laplacian referencing.
                Default is 20.

        Raises:
            Exception: Raised if electrode locations are not provided and have not been previously loaded.
        """
        self.load_locs(locs)
        if not hasattr(self, "locs"):
            raise Exception(
                "Please load electrodes locs first.\nLocs can be loaded through: data.load_locs(filename).\n"
            )

        self.record()
        self.data, self.ref_chnames = tools.laplacian(
            self.data, self.ch_names, self.locs, radius
        )
        inds = np.where(self.ref_chnames == "-")[0]
        self.data = np.delete(self.data, inds, axis=1)
        self.ch_names = np.delete(self.ch_names, inds)
        self.ref_chnames = np.delete(self.ref_chnames, inds)
        self.history.append("laplacian")

    def reref(self, ref: str, locs: str = '', radius: Number = 20):
        """
        Perform re-referencing on the input iEEG data.
        Available options:
        * Common Average Re-referencing (CAR)
        * Bipolar Re-referencing (BR)
        * Laplacian Re-referencing (LAR): Note, requires location of electrodes and radius threshold

        Args:
            ref (str): re-referencing method. Available options: 'car', 'bipolar', 'laplacian'.
            locs (str, optional): The path to the file containing electrode locations. If not provided,
                the method expects that electrode locations have been previously loaded using `load_locs`.
            radius (Number, optional): The radius (in millimeters) used to define the neighborhood for Laplacian referencing.
                Default is 20.
        """
        assert ref in ["car", "bipolar", "laplacian"], "CNTtools:invalidRerefMethod"
        if ref == "car":
            self.record()
            self.data, self.ref_chnames = tools.car(self.data, self.ch_names)
        elif ref == "bipolar":
            self.record()
            self.data, self.ref_chnames = tools.bipolar(self.data, self.ch_names)
            inds = np.where(self.ref_chnames == "-")[0]
            self.data = np.delete(self.data, inds, axis=1)
            self.ch_names = np.delete(self.ch_names, inds)
            self.ref_chnames = np.delete(self.ref_chnames, inds)
        elif ref == "laplacian":
            self.load_locs(locs)
            if not hasattr(self, "locs"):
                raise Exception(
                    "Please load electrodes locs first.\nLocs can be loaded through: data.load_locs(filename).\n"
                )
            self.record()
            self.data, self.ref_chnames = tools.laplacian(
                self.data, self.ch_names, self.locs, radius
            )
            inds = np.where(self.ref_chnames == "-")[0]
            self.data = np.delete(self.data, inds, axis=1)
            self.ch_names = np.delete(self.ch_names, inds)
            self.ref_chnames = np.delete(self.ref_chnames, inds)
        self.history.append("reref-" + ref)

    def pre_whiten(self):
        """
        Perform pre-whitening on iEEG data.
        """
        self.record()
        self.data = tools.pre_whiten(self.data)
        self.history.append("pre_whiten")

    def bandpower(self, band, window: Number = None, relative: bool = False):
        """
        Compute the average power of the signal x in a specific frequency band.

        Parameters
        ----------
        band : list
            Lower and upper frequencies of the band of interest.
        window : Number
            Length of each window in seconds.
            If None, window_sec = (1 / min(band)) * 2
        relative : boolean
            If True, return the relative power (= divided by the total power of the signal).
            If False (default), return the absolute power.
        """
        # update according to matlab!!!
        band = np.asarray(band)
        assert band.shape[1] == 2, "CNTtools:invalidBandRange"
        nband = band.shape[0]
        self.power["freq"] = []
        self.power["power"] = []
        for i in range(nband):
            self.power["freq"].append(band[i, :])
            self.power["power"].append(
                tools.bandpower(self.data, self.fs, band[i, :], window, relative)
            )
        self.history.append("bandpower")
        return self.power

    def line_length(self):
        """
        Calculate the line length of the iEEG data.

        Line length is a measure of the cumulative length of the waveform. It is often used in signal processing to
        quantify the complexity or irregularity of a signal.

        The result is stored in the 'll' attribute of the EEG object.
        """
        self.ll = tools.line_length(self.data)
        return self.ll

    def pearson(self, win=True, win_size=2):
        """
        Calculate the Pearson correlation coefficients between channels in the iEEG data.

        Parameters:
        - win (bool, optional): If True, calculate windowed correlations; if False, calculate overall correlations. Default is True.
        - win_size (Number, optional): Size of the time window in seconds for windowed correlation calculation. Default is 2 seconds.

        The result is stored in the 'pearson' key of the 'conn' attribute of the EEG object.
        """
        self.conn["pearson"] = tools.pearson(
            self.data, self.fs, win=win, win_size=win_size
        )

    def squared_pearson(self, win=True, win_size=2):
        """
        Calculate the Squared Pearson correlation coefficients between channels in the iEEG data.

        Parameters:
        - win (bool, optional): If True, calculate windowed correlations; if False, calculate overall correlations. Default is True.
        - win_size (Number, optional): Size of the time window in seconds for windowed correlation calculation. Default is 2 seconds.

        The result is stored in the 'sqaured_pearson' key of the 'conn' attribute of the EEG object.
        """
        self.conn["squared_pearson"] = tools.squared_pearson(
            self.data, self.fs, win=win, win_size=win_size
        )

    def cross_corr(self, win=True, win_size=2):
        """
        Calculate the cross correlation between channels in the iEEG data.

        Parameters:
        - win (bool, optional): If True, calculate windowed correlations; if False, calculate overall correlations. Default is True.
        - win_size (Number, optional): Size of the time window in seconds for windowed correlation calculation. Default is 2 seconds.

        The result is stored in the 'cross_corr' key of the 'conn' attribute of the EEG object.
        """
        self.conn["cross_corr"], _ = tools.cross_correlation(
            self.data, self.fs, win=win, win_size=win_size
        )

    def coherence(self, win=True, win_size=2, segment=1, overlap=0.5):
        """
        Calculate the coherence between channels in the Electroencephalogram (EEG) data.

        Parameters:
        - win (bool, optional): If True, calculate windowed coherence; if False, calculate overall coherence. Default is True.
        - win_size (Number, optional): Size of the time window in seconds for windowed coherence calculation. Default is 2 seconds.
        - segment (Number, optional): Duration of each segment in seconds for multi-taper spectral estimation. Default is 1 second.
        - overlap (Number, optional): Overlap between segments for multi-taper spectral estimation, in seconds. Default is 0.5 seconds.

        The result is stored in the 'coh' key of the 'conn' attribute of the EEG object.
        """
        self.conn["coh"] = tools.coherence(
            self.data,
            self.fs,
            win=win,
            win_size=win_size,
            segment=segment,
            overlap=overlap,
        )

    def plv(self, win=True, win_size=2):
        """
        Calculate the phase-locking value (PLV) between channels in the iEEG data.

        Parameters:
        - win (bool, optional): If True, calculate windowed correlations; if False, calculate overall correlations. Default is True.
        - win_size (Number, optional): Size of the time window in seconds for windowed correlation calculation. Default is 2 seconds.

        The result is stored in the 'plv' key of the 'conn' attribute of the EEG object.
        """
        self.conn["plv"] = tools.plv(self.data, self.fs, win=win, win_size=win_size)

    def relative_entropy(self, win=True, win_size=2):
        """
        Calculate the relative entropy between channels in the iEEG data.

        Parameters:
        - win (bool, optional): If True, calculate windowed correlations; if False, calculate overall correlations. Default is True.
        - win_size (Number, optional): Size of the time window in seconds for windowed correlation calculation. Default is 2 seconds.

        The result is stored in the 'rela_entropy' key of the 'conn' attribute of the EEG object.
        """
        self.conn["rela_entropy"] = tools.relative_entropy(
            self.data, self.fs, win=win, win_size=win_size
        )

    def connectivity(self, methods, win=True, win_size=2, segment=1, overlap=0.5):
        """
        Calculate various connectivity measures between channels in the iEEG data.

        Parameters:
        - methods (list): List of connectivity methods to calculate.
                            Supported methods: ['pearson', 'squared_pearson', 'cross_corr', 'coh', 'plv', 'rela_entropy'].
        - win (bool, optional): If True, calculate windowed connectivity; if False, calculate overall connectivity. Default is True.
        - win_size (Number, optional): Size of the time window in seconds for windowed connectivity calculation. Default is 2 seconds.
        - segment (Number, optional): Duration of each segment in seconds for multi-taper spectral estimation. Default is 1 second.
        - overlap (Number, optional): Overlap between segments for multi-taper spectral estimation, in seconds. Default is 0.5 seconds.

        The calculated connectivity measures are stored in the 'conn' attribute of the EEG object.

        """
        if "pearson" in methods:
            self.conn["pearson"] = tools.pearson(
                self.data, self.fs, win=win, win_size=win_size
            )
        if "squared_pearson" in methods:
            self.conn["squared_pearson"] = tools.squared_pearson(
                self.data, self.fs, win=win, win_size=win_size
            )
        if "cross_corr" in methods:
            self.conn["cross_corr"] = tools.cross_correlation(
                self.data, self.fs, win=win, win_size=win_size
            )
        if "coh" in methods:
            self.conn["coh"] = tools.coherence(
                self.data,
                self.fs,
                win=win,
                win_size=win_size,
                segment=segment,
                overlap=overlap,
            )
        if "plv" in methods:
            self.conn["plv"] = tools.plv(self.data, self.fs, win=win, win_size=win_size)
        if "rela_entropy" in methods:
            self.conn["rela_entropy"] = tools.relative_entropy(
                self.data, self.fs, win=win, win_size=win_size
            )

    def plot(self, time_range_data=None, t_axis=None, select=None):
        """
        Plot iEEG data for multiple channels over a specified time range.

        Parameters:
        - time_range_data (list, optional): sample range within data segment to plot. e.g. 50-1000 of a 2000 sample data.
                                            If not provided, the entire data range will be used.
        - t_axis (list, optional): Axis label range for the x-axis of the plot.

        Returns:
        - fig (matplotlib.figure.Figure): The generated matplotlib Figure object.
        """
        if time_range_data is None:
            time_range_data = [0, self.data.shape[0]]
        if t_axis is None:
            t_axis = [
                self.start + (time_range_data[0] / self.fs),
                self.start + (time_range_data[1] / self.fs),
            ]
        plot_data = self.data[time_range_data[0] : time_range_data[1], :]
        chs = self.ch_names
        if select is not None:
            assert np.max(select) < plot_data.shape[1], "CNTtools:invalidSelectChannels"
            assert np.min(select) >= 0, "CNTtools:invalidSelectChannels"
            plot_data = plot_data[:, select]
            chs = chs[select]
        t = np.linspace(t_axis[0], t_axis[1], num=plot_data.shape[0])
        fig = tools.plot_ieeg_data(plot_data, chs, t)
        return fig

    def conn_heatmap(self, method: str, band: str = "broad", color=None, cmap=None):
        """
        Heatmap plot of connectivity matrix.
        """
        # assert connectivity is calculated
        assert (
            method in self.conn
        ), "CNTtools:invalidConnMethod, please calculate connectivity before plotting."
        bands = ["delta", "theta", "alpha", "beta", "gamma", "ripple", "broad"]
        assert band in bands, "CNTtools:invalidBand"
        ind = bands.index(band)
        if ind < 6:
            assert method in ["coh", "plv", "rela_entropy"], "CNTtools:invalidBand"
        # import
        import seaborn as sns
        import matplotlib.pyplot as plt

        # define cmap
        col_dict = {
            "blue": "Blues",
            "green": "Greens",
            "orange": "Oranges",
            "purple": "Purples",
            "red": "Reds",
        }
        if cmap is None:
            if color is not None:
                assert (
                    color in col_dict
                ), "CNTtools:invalidColorCode:please provide custom colormap using cmap = yourcmp"
                cmap = col_dict[color]
            else:
                cmap = "Blues"
                if method is "pearson":
                    cmap = plt.cm.get_cmap("RdBu")
                    cmap = cmap.reversed()
        # get data
        if np.ndim(self.conn[method]) == 3:
            data = self.conn[method][:, :, ind]
        else:
            data = self.conn[method]
        # figure
        nchan = data.shape[1]
        tmpfigsize = [nchan / 4, nchan * 0.8 / 4]
        fig, ax = plt.subplots(
            figsize=(np.max([tmpfigsize[0], 10]), np.max([tmpfigsize[1], 8]))
        )
        if method is "pearson":
            sns.heatmap(
                data,
                vmin=-1,
                vmax=1,
                cmap=cmap,
                square=True,
                annot=False,
                cbar=True,
                xticklabels=self.ch_names,
                yticklabels=self.ch_names,
            )
        elif method is "rela_entropy":
            sns.heatmap(
                data,
                cmap=cmap,
                square=True,
                annot=False,
                cbar=True,
                xticklabels=self.ch_names,
                yticklabels=self.ch_names,
            )
        else:
            sns.heatmap(
                data,
                vmin=0,
                vmax=1,
                cmap=cmap,
                square=True,
                annot=False,
                cbar=True,
                xticklabels=self.ch_names,
                yticklabels=self.ch_names,
            )
        plt.show()
        return fig

    def record(self):
        """
        Record current status.
        """
        self._rev_data = self.data
        self._rev_chs = self.ch_names
        self._rev_refchs = self.ref_chnames

    def reverse(self):
        """
        Reverse by one processing step.
        """
        if self.history:
            self.data = self._rev_data
            self.ch_names = self._rev_chs
            self.ref_chnames = self._rev_refchs
            self.history.append("reverse")

    def _pickle_save(self, filename):
        with open(filename, "wb") as file:
            pickle.dump(self, file)

    def _pickle_open(self, filename):
        with open(filename, "rb") as file:
            data = pickle.load(file)
        return data

    def save(self, file: str = None, default_folder: bool = True):
        """
        Save data instance in pickle format. Defaultly save to data/user/filename_start_stop.

        Args:
            file (str, optional): filename to save file. Can be either a path, or a fullpath with filename.
        """
        filename = self.filename + "_" + str(self.start) + "_" + str(self.stop) + ".pkl"
        if file is None:
            # filename not provided, default filename & folder
            file = self.user_data_dir
            filename = os.path.join(file, filename)
        else:
            # when filename provided
            if ".pkl" in file:
                # with filename
                if default_folder:
                    filename = os.path.join(self.user_data_dir, filename)
            else:
                # folder specified
                filename = os.path.join(file, filename)
        self._pickle_save(filename)
