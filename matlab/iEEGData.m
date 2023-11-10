classdef iEEGData < matlab.mixin.Copyable & handle
    %{
    A class for storing iEEG data and relevant meta info. 

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
    %}

    properties
        filename
        start
        stop
        select_elecs
        ignore_elecs
        dura
        data
        fs
        ch_names
        ref_chnames
        raw
        raw_chs
        index
        conn
        history
        nonieeg
        bad
        reject_details
        ll
        power
        username
        user_data_dir
        locs
        hm_setting
    end

    properties (Access = private)
        rev_data
        rev_chs
        rev_refchs
    end

    methods
        function obj = iEEGData(filename, start, stop, varargin)

            p = inputParser;
            addRequired(p, 'filename', @(x) isstring(x) || ischar(x));
            addRequired(p, 'start', @isnumeric);
            addRequired(p, 'stop', @isnumeric);
            addOptional(p, 'select_elecs', {}, @(x) iscell(x) || isnumeric(x) || isstring(x) || ischar(x));
            addOptional(p, 'ignore_elecs', {}, @(x) iscell(x) || isnumeric(x) || isstring(x) || ischar(x));
            addOptional(p, 'data', [], @isnumeric);
            addOptional(p, 'fs', [], @isnumeric);
            addOptional(p, 'ch_names', {}, @(x) iscell(x) || isnumeric(x) || isstring(x) || ischar(x));
            parse(p, filename, start, stop, varargin{:});

            obj.filename = p.Results.filename;
            obj.start = p.Results.start;
            obj.stop = p.Results.stop;
            obj.dura = stop - start;
            obj.select_elecs = p.Results.select_elecs;
            obj.ignore_elecs = p.Results.ignore_elecs;
            obj.data = p.Results.data;
            obj.fs = p.Results.fs;
            obj.ch_names = p.Results.ch_names;
            obj.ref_chnames = {};
            obj.index = [];
            obj.power = struct();
            obj.conn = struct();
            obj.history = {};
            obj.record();
        end

        function download(obj, user)
            paths;
            output = get_ieeg_data(user.usr, user.pwd, obj.filename, obj.start, obj.stop, obj.select_elecs, obj.ignore_elecs);
            obj.data = output.values;
            obj.fs = output.fs;
            obj.ch_names = output.chLabels;
            obj.raw = obj.data;
            obj.raw_chs = obj.ch_names;
            obj.username = user.usr;
            obj.user_data_dir = fullfile(DATA_DIR, obj.username(1:3));
            obj.record();
        end

        function clean_labels(obj)
            % Convert channel names to standardized format.
            obj.record();
            obj.ch_names = clean_labels(obj.ch_names);
            obj.history{end + 1} = 'clean_labels';
        end

        function find_nonieeg(obj)
            % Find and return a boolean mask for Non-iEEG channels, 0 = iEEG, 1 = Non-iEEG
            obj.record();
            obj.nonieeg = find_non_ieeg(obj.ch_names);
            obj.history{end + 1} = 'find_nonieeg';
        end

        function find_bad_chs(obj)
            % Find and return a boolean mask for bad channels (1 = bad channels), and details for reasons to reject.
            obj.record();
            [obj.bad, obj.reject_details] = identify_bad_chs(obj.data, obj.fs);
            obj.history{end + 1} = 'find_bad_chs';
        end

        function reject_nonieeg(obj)
            % Find and remove non-iEEG channels.
            obj.record();
            obj.nonieeg = find_non_ieeg(obj.ch_names);
            obj.data = obj.data(:, ~obj.nonieeg);
            obj.ch_names = obj.ch_names(~obj.nonieeg);
            obj.history{end + 1} = 'reject_nonieeg';
        end

        function reject_artifact(obj)
            % Find and remove bad channels.
            obj.record();
            [obj.bad, obj.reject_details] = identify_bad_chs(obj.data, obj.fs);
            obj.data = obj.data(:, ~obj.bad);
            obj.ch_names = obj.ch_names(~obj.bad);
            obj.history{end + 1} = 'reject_artifact';
        end

        function bandpass_filter(obj, varargin)
            % Filter iEEG signal with bandpass filter.
            defaults = {1,120};

            for i = 1:length(varargin)
                if isempty(varargin{i})
                    varargin{i} = defaults{i};
                end
            end

            p = inputParser;
            addOptional(p, 'low_freq', 1, @isnumeric);
            addOptional(p, 'high_freq', 120, @isnumeric);

            parse(p, varargin{:});
            low_freq = p.Results.low_freq;
            high_freq = p.Results.high_freq;
            obj.record();
            obj.data = bandpass_filter(obj.data, obj.fs, low_freq, high_freq);
            obj.history{end + 1} = 'bandpass_filter';
        end

        function notch_filter(obj, varargin)
            % Filter iEEG signal with notch filter.
            p = inputParser;
            addOptional(p, 'notch_freq', 60, @isnumeric);
            parse(p, varargin{:});
            notch_freq = p.Results.notch_freq;
            obj.record();
            obj.data = notch_filter(obj.data, obj.fs, notch_freq);
            obj.history{end + 1} = 'notch_filter';
        end

        function filter(obj, varargin)
            % Filter iEEG signal with bandpass and notch filter.
            defaults = {1,120,60};
            for i = 1:length(varargin)
                if isempty(varargin{i})
                    varargin{i} = defaults{i};
                end
            end
            p = inputParser;
            addOptional(p, 'low_freq', 1, @isnumeric);
            addOptional(p, 'high_freq', 120, @isnumeric);
            addOptional(p, 'notch_freq', 60, @isnumeric);
            parse(p, varargin{:});
            low_freq = p.Results.low_freq;
            high_freq = p.Results.high_freq;
            notch_freq = p.Results.notch_freq;
            obj.record();
            obj.data = bandpass_filter(obj.data, obj.fs, low_freq, high_freq);
            obj.data = notch_filter(obj.data, obj.fs, notch_freq);
            obj.history{end + 1} = 'filter';
        end

        function car(obj)
            % Perform Common Average Reference (CAR) on the input iEEG data.
            obj.record();
            [obj.data, obj.ref_chnames] = car(obj.data, obj.ch_names);
            obj.history{end + 1} = 'car';
        end

        function bipolar(obj)
            % Perform Bipolar Re-referencing (BR) on the input iEEG data.
            obj.record();
            [obj.data, obj.ref_chnames] = bipolar(obj.data, obj.ch_names);
            inds = strcmp(obj.ref_chnames,'-');
            obj.data(:, inds) = [];
            obj.ch_names(inds) = [];
            obj.ref_chnames(inds) = [];
            obj.history{end + 1} = 'bipolar';
        end

        function load_locs(obj, loc_file)
            p = inputParser;
            addOptional(p, 'loc_file', '', @(x) (isstring(x) || ischar(x)));
            parse(p, loc_file);
            loc_file = p.Results.loc_file;
            if isempty(loc_file)
                loc_file = 'elec_locs.csv';    
                assert(exist(loc_file,'file'),...
                        sprintf(['CNTtools:invalidLocFile\nPlease specify a ' ...
                        'electrode location file for laplacian re-referencing, ' ...
                        'with format | fileID/patientID | electrodeName | x | y | z | \n' ...
                        'For default loading, please save electrode location information' ...
                        'with filename elec_locs.csv and add to MATLAB workpath.\n']))
            else
                assert(exist(loc_file,'file'),'CNTtools:invalidLocFile')
            end
            obj.locs = get_elec_locs(obj.filename, obj.ch_names, loc_file);
        end

        function laplacian(obj, varargin)
            p = inputParser;
            defaults = {'',20};
            for i = 1:length(varargin)
                if isempty(varargin{i})
                    varargin{i} = defaults{i};
                end
            end
            addOptional(p, 'locs', defaults{1}, @(x) (isstring(x) || ischar(x)));
            addOptional(p, 'radius', defaults{2}, @isnumeric);
            parse(p, varargin{:});
            locs = p.Results.locs;
            radius = p.Results.radius;

            obj.load_locs(locs);
            if isempty(obj.locs)
                error(sprintf('CNTtools:Please load electrode locs first.\nLocs can be loaded through: data.load_locs(filename).\n'));
            end

            obj.record();
            [obj.data, obj.ref_chnames] = laplacian(obj.data, obj.ch_names, obj.locs, radius);
            inds = strcmp(obj.ref_chnames,'-');
            obj.data(:, inds) = [];
            obj.ch_names(inds) = [];
            obj.ref_chnames(inds) = [];
            obj.history{end + 1} = 'laplacian';
        end

        function reref(obj, ref, varargin)
            %{
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
            %}
            p = inputParser;
            defaults = {'',20};
            for i = 1:length(varargin)
                if isempty(varargin{i})
                    varargin{i} = defaults{i};
                end
            end
            addRequired(p, 'ref', @(x) isstring(x) || ischar(x));
            addOptional(p, 'locs', defaults{1}, @(x) (isstring(x) || ischar(x)));
            addOptional(p, 'radius', defaults{2}, @isnumeric);
            parse(p, ref, varargin{:});
            ref = p.Results.ref;
            locs = p.Results.locs;
            radius = p.Results.radius;

            assert(ismember(ref,{'car', 'bipolar', 'laplacian'}), 'CNTtools:invalidRerefMethod');

            obj.record();

            switch ref
                case 'car'
                    [obj.data, obj.ref_chnames] = car(obj.data, obj.ch_names);
                case 'bipolar'
                    [obj.data, obj.ref_chnames] = bipolar(obj.data, obj.ch_names);
                    inds = strcmp(obj.ref_chnames,'-');
                    obj.data(:, inds) = [];
                    obj.ch_names(inds) = [];
                    obj.ref_chnames(inds) = [];
                case 'laplacian'
                    obj.load_locs(locs);
                    if isempty(obj.locs)
                        error(sprintf('CNTtools:Please load electrode locs first.\nLocs can be loaded through: data.load_locs(filename).\n'));
                    end
                    [obj.data, obj.ref_chnames] = laplacian(obj.data, obj.ch_names, obj.locs, radius);
                    inds = strcmp(obj.ref_chnames,'-');
                    obj.data(:, inds) = [];
                    obj.ch_names(inds) = [];
                    obj.ref_chnames(inds) = [];
            end
            obj.history{end + 1} = ['reref-', ref];
        end

        function pre_whiten(obj)
            % Perform pre-whitening on iEEG data.
            obj.record();
            obj.data = pre_whiten(obj.data);
            obj.history{end + 1} = 'pre_whiten';
        end

        function bandpower(obj, varargin)
            %{
        Compute the average power of the signal x in a specific frequency band.

        Parameters
        ----------
        band : list
            Lower and upper frequencies of the band of interest. Each row
            represents one band. Default is freqs from default_freqs.
        window : Number
            Length of each window in seconds.
            If None, window_sec = (1 / min(band)) * 2
        relative : boolean
            If True, return the relative power (= divided by the total power of the signal).
            If False (default), return the absolute power.
            %}
            freqs = default_freqs;
            p = inputParser;
            defaults = {freqs,nan,false};
            for i = 1:length(varargin)
                if isempty(varargin{i})
                    varargin{i} = defaults{i};
                end
            end
            addOptional(p, 'band', defaults{1}, @(x) isnumeric(x) && ...
                size(x,2) == 2 && all(x(:,1) < x(:,2)));
            addOptional(p, 'window', defaults{2}, @isnumeric);
            addOptional(p, 'relative', defaults{3}, @(x) ismember(x,[0,1]));
            parse(p, varargin{:});
            band = p.Results.band;
            window = p.Results.window;
            relative = p.Results.relative;
            nbands = size(band,1);
            for i = 1:nbands
                obj.power(i).freq = band(i,:);
                obj.power(i).power = bandpower(obj.data, obj.fs, obj.power(i).freq, window, relative);
            end
            obj.history{end + 1} = 'bandpower';
        end

        function line_length(obj)
            %{
        Calculate the line length of the iEEG data.

        Line length is a measure of the cumulative length of the waveform. It is often used in signal processing to
        quantify the complexity or irregularity of a signal.

        The result is stored in the 'll' attribute of the EEG object.
            %}
            obj.ll = line_length(obj.data);
            obj.history{end + 1} = 'line_length';
        end

        function pearson(obj, varargin)
            %{
        Calculate the Pearson correlation coefficients between channels in the iEEG data.

        Parameters:
        - win (bool, optional): If True, calculate windowed correlations; if False, calculate overall correlations. Default is True.
        - win_size (Number, optional): Size of the time window in seconds for windowed correlation calculation. Default is 2 seconds.

        The result is stored in the 'pearson' key of the 'conn' attribute of the EEG object.
            %}
            p = inputParser;
            defaults = {true,2};
            for i = 1:length(varargin)
                if isempty(varargin{i})
                    varargin{i} = defaults{i};
                end
            end
            addOptional(p, 'win', defaults{1}, @(x) ismember(x,[0,1]));
            addOptional(p, 'win_size', defaults{2}, @isnumeric);
            parse(p, varargin{:});
            win = p.Results.win;
            win_size = p.Results.win_size;
            obj.conn.pearson = pearson(obj.data, obj.fs, win, win_size);
            obj.history{end + 1} = 'pearson';
        end

        function squared_pearson(obj, varargin)
            %{
        Calculate the Squared Pearson correlation coefficients between channels in the iEEG data.

        Parameters:
        - win (bool, optional): If True, calculate windowed correlations; if False, calculate overall correlations. Default is True.
        - win_size (Number, optional): Size of the time window in seconds for windowed correlation calculation. Default is 2 seconds.

        The result is stored in the 'sqaured_pearson' key of the 'conn' attribute of the EEG object.
            %}
            p = inputParser;
            defaults = {true,2};
            for i = 1:length(varargin)
                if isempty(varargin{i})
                    varargin{i} = defaults{i};
                end
            end
            addOptional(p, 'win', defaults{1}, @(x) ismember(x,[0,1]));
            addOptional(p, 'win_size', defaults{2}, @isnumeric);
            parse(p, varargin{:});
            win = p.Results.win;
            win_size = p.Results.win_size;
            obj.conn.squared_pearson = squared_pearson(obj.data, obj.fs, win, win_size);
            obj.history{end + 1} = 'squared_pearson';
        end

        function cross_corr(obj, varargin)
            %{
        Calculate the cross correlation between channels in the iEEG data.

        Parameters:
        - win (bool, optional): If True, calculate windowed correlations; if False, calculate overall correlations. Default is True.
        - win_size (Number, optional): Size of the time window in seconds for windowed correlation calculation. Default is 2 seconds.

        The result is stored in the 'cross_corr' key of the 'conn' attribute of the EEG object.
            %}
            p = inputParser;
            defaults = {true,2};
            for i = 1:length(varargin)
                if isempty(varargin{i})
                    varargin{i} = defaults{i};
                end
            end
            addOptional(p, 'win', defaults{1}, @(x) ismember(x,[0,1]));
            addOptional(p, 'win_size', defaults{2}, @isnumeric);
            parse(p, varargin{:});
            win = p.Results.win;
            win_size = p.Results.win_size;
            [obj.conn.cross_corr, ~] = cross_correlation(obj.data, obj.fs, win, win_size);
        end

        function coherence(obj, varargin)
            %{
        Calculate the coherence between channels in the Electroencephalogram (EEG) data.

        Parameters:
        - win (bool, optional): If True, calculate windowed coherence; if False, calculate overall coherence. Default is True.
        - win_size (Number, optional): Size of the time window in seconds for windowed coherence calculation. Default is 2 seconds.
        - segment (Number, optional): Duration of each segment in seconds for multi-taper spectral estimation. Default is 1 second.
        - overlap (Number, optional): Overlap between segments for multi-taper spectral estimation, in seconds. Default is 0.5 seconds.

        The result is stored in the 'coh' key of the 'conn' attribute of the EEG object.
            %}
            p = inputParser;
            defaults = {true,2,1,0.5};
            for i = 1:length(varargin)
                if isempty(varargin{i})
                    varargin{i} = defaults{i};
                end
            end
            addOptional(p, 'win', defaults{1}, @(x) ismember(x,[0,1]));
            addOptional(p, 'win_size', defaults{2}, @isnumeric);
            addOptional(p, 'segment', defaults{3}, @isnumeric);
            addOptional(p, 'overlap', defaults{4}, @isnumeric);
            parse(p, varargin{:});
            win = p.Results.win;
            win_size = p.Results.win_size;
            segment = p.Results.segment;
            overlap = p.Results.overlap;
            obj.conn.coh = coherence(obj.data, obj.fs, win, win_size, segment, overlap);
        end

        function plv(obj, varargin)
            %{
            Calculate the phase-locking value (PLV) between channels in the iEEG data.
    
            Parameters:
            - win (bool, optional): If True, calculate windowed correlations; if False, calculate overall correlations. Default is True.
            - win_size (Number, optional): Size of the time window in seconds for windowed correlation calculation. Default is 2 seconds.
    
            The result is stored in the 'plv' key of the 'conn' attribute of the EEG object.
            %}
            p = inputParser;
            defaults = {true,2};
            for i = 1:length(varargin)
                if isempty(varargin{i})
                    varargin{i} = defaults{i};
                end
            end
            addOptional(p, 'win', defaults{1}, @(x) ismember(x,[0,1]));
            addOptional(p, 'win_size', defaults{2}, @isnumeric);
            parse(p, varargin{:});
            win = p.Results.win;
            win_size = p.Results.win_size;
            obj.conn.plv = plv(obj.data, obj.fs, win, win_size);
        end

        function rela_entropy(obj, varargin)
            %{
            Calculate the relative entropy between channels in the iEEG data.
    
            Parameters:
            - win (bool, optional): If True, calculate windowed correlations; if False, calculate overall correlations. Default is True.
            - win_size (Number, optional): Size of the time window in seconds for windowed correlation calculation. Default is 2 seconds.
    
            The result is stored in the 'rela_entropy' key of the 'conn' attribute of the EEG object.
            %}
            p = inputParser;
            defaults = {true,2};
            for i = 1:length(varargin)
                if isempty(varargin{i})
                    varargin{i} = defaults{i};
                end
            end
            addOptional(p, 'win', defaults{1}, @(x) ismember(x,[0,1]));
            addOptional(p, 'win_size', defaults{2}, @isnumeric);
            parse(p, varargin{:});
            win = p.Results.win;
            win_size = p.Results.win_size;
            obj.conn.rela_entropy = relative_entropy(obj.data, obj.fs, win, win_size);
        end

        function connectivity(obj, methods, varargin)%win, win_size, segment, overlap)
            %{
            Calculate various connectivity measures between channels in the iEEG data.
    
            Parameters:
            - methods (list): List of connectivity methods to calculate. 
                                Supported methods: ['pearson', 'squared_pearson', 'cross_corr', 'coh', 'plv', 'rela_entropy'].
            - win (bool, optional): If True, calculate windowed connectivity; if False, calculate overall connectivity. Default is True.
            - win_size (Number, optional): Size of the time window in seconds for windowed connectivity calculation. Default is 2 seconds.
            - segment (Number, optional): Duration of each segment in seconds for multi-taper spectral estimation. Default is 1 second.
            - overlap (Number, optional): Overlap between segments for multi-taper spectral estimation, in seconds. Default is 0.5 seconds.
    
            The calculated connectivity measures are stored in the 'conn' attribute of the EEG object.
            %}
            p = inputParser;
            defaults = {true,2,1,0.5};
            for i = 1:length(varargin)
                if isempty(varargin{i})
                    varargin{i} = defaults{i};
                end
            end
            addRequired(p, 'methods', @(x) iscell(x) || ischar(x) || isstring(x));
            addOptional(p, 'win', defaults{1}, @(x) ismember(x,[0,1]));
            addOptional(p, 'win_size', defaults{2}, @isnumeric);
            addOptional(p, 'segment', defaults{3}, @isnumeric);
            addOptional(p, 'overlap', defaults{4}, @isnumeric);
            parse(p, methods, varargin{:});
            methods = p.Results.methods;
            win = p.Results.win;
            win_size = p.Results.win_size;
            segment = p.Results.segment;
            overlap = p.Results.overlap;
            if any(strcmp(methods, 'pearson'))
                obj.conn.pearson = pearson(obj.data, obj.fs, win, win_size);
            end
            if any(strcmp(methods, 'squared_pearson'))
                obj.conn.squared_pearson = squared_pearson(obj.data, obj.fs, win, win_size);
            end
            if any(strcmp(methods, 'cross_corr'))
                obj.conn.cross_corr = cross_correlation(obj.data, obj.fs, win, win_size);
            end
            if any(strcmp(methods, 'coh'))
                obj.conn.coh = coherence(obj.data, obj.fs, win, win_size, segment, overlap);
            end
            if any(strcmp(methods, 'plv'))
                obj.conn.plv = plv(obj.data, obj.fs, win, win_size);
            end
            if any(strcmp(methods, 'rela_entropy'))
                obj.conn.rela_entropy = relative_entropy(obj.data, obj.fs, win, win_size);
            end
        end

        function fig = plot(obj, varargin)%time_range_data, t_axis,select) % update
            % Plot iEEG data for multiple channels over a specified time range.
            p = inputParser;
            addOptional(p, 'time_range_data', [], @isnumeric);
            addOptional(p, 't_axis', [], @isnumeric);
            addOptional(p, 'select', [], @isnumeric);
            parse(p, varargin{:});
            time_range_data = p.Results.time_range_data;
            t_axis = p.Results.t_axis;
            select = p.Results.select;
            if isempty(time_range_data)
                time_range_data = [1,size(obj.data,1)];
            end
            plot_data = obj.data(time_range_data(1):time_range_data(2),:);
            if isempty(t_axis)
                t_axis = [obj.start+time_range_data(1)/obj.fs,obj.start+time_range_data(2)/obj.fs];
            end
            chs = obj.ch_names;
            if ~isempty(select)
                assert(max(select) <= size(plot_data,2),"CNTtools:invalidSelectChannels");
                assert(min(select) > 0,"CNTtools:invalidSelectChannels");
                plot_data = plot_data(:,select);
                chs = chs(select);
            end
            t = linspace(t_axis(1), t_axis(2), numel(plot_data(:, 1)));
            fig = plot_ieeg_data(obj.data, obj.ch_names, t);
        end

        function heatmap_settings(obj,varargin)
            % run this function to assign default heatmap settings, 
            % or apply customized settings
            % customized color could be 1:colormap of size nX3, 
            % 2:cell/string array of color hex codes
            nchs = size(obj.data,2); % add formula here
            
            % default colors
            blue = hex2rgb('#3c5488');red = hex2rgb('#a5474e'); white = [1,1,1]; 
            colors = [white;red];
            % inputs
            p = inputParser;
            addParameter(p, 'ColorLimits', [0,1], @(x) isnumeric(x) && size(x)==[1,2]);
            addParameter(p, 'FontName', 'Helvetica', @(x) isstring(x) || ischar(x));
            addParameter(p, 'FontSize', 10, @(x) isnumeric(x) && x > 0);
            addParameter(p, 'Colormap', colors, @(x) (isnumeric(x) && size(x,2)==3) || (isstring(x) || iscell(x)));
            parse(p,varargin{:})
            h = p.Results;
            h.XDisplayLabels = obj.ch_names;
            h.YDisplayLabels = obj.ch_names;
            h.GridVisible = 'off';
            h.CellLabelColor = 'none';
            % fix figure size
            % Calculate approximate figure size
            figureHeight = nchs * (h.FontSize) / 0.8;
            figureWidth = figureHeight + 50;
            h.Position = [100, 100, figureWidth, figureHeight];
            % fix colormap
            if isstring(h.Colormap)
                h.Colormap = cellstr(h.Colormap);
            end
            if iscell(h.Colormap)
                assert(all(cell2mat(regexp(colors, '^#[0-9A-Fa-f]{6}$', 'once'))),'CNTtools:invalidColorCode')
                h.Colormap = hex2rgb(h.Colormap);
            end
            ncol = size(h.Colormap,1);
            if ncol < 100
                positions = [0:1/(ncol-1):1];
                mycolormap = interp1(positions, h.Colormap, linspace(0, 1, 256), 'pchip');
            end
            h.Colormap = colormap(mycolormap);
            obj.hm_setting = h;
        end

        function fig1 = conn_heatmap(obj, method, varargin)
            % Heatmap plot of connectivity matrix.
            p = inputParser;
            methods = {'pearson','squared_pearson',...
                'cross_corr','coh','plv','rela_entropy'};
            method_names = {'Pearson','Squared Pearson','Cross Correlation',...
                'Coherence','PLV','Relative Entropy'};
            bands = {'delta', 'theta', 'alpha', 'beta', 'gamma', 'ripple', 'broad'};
            addRequired(p, 'method', @(x) (ischar(x) || isstring(x)) && ismember(x, methods));
            addOptional(p, 'band', 'broad', @(x) (ischar(x) || isstring(x)) && ismember(x, bands));
            parse(p, method, varargin{:});
            method = p.Results.method;
            band = p.Results.band;
            assert(isfield(obj.conn,method),'CNTtools: Please calculate connectivity before plotting.')
            if ~strcmp(band,'broad')
                assert(ndims(obj.conn.(method)) > 2,'CNTtools: Band not available for this connectivity measure.');
            end
            % setting
            if isempty(obj.hm_setting)
                obj.heatmap_settings();
            end
            % plotting
            if ndims(obj.conn.(method)) == 3
                figure('Position',obj.hm_setting.Position)
                tmp = rmfield(obj.hm_setting, 'Position');
                fig1 = heatmap(obj.conn.(method)(:,:,strcmp(bands, band)), ...
                    'Title',strcat(method_names{strcmp(methods,method)},'-',band));
                set(fig1,tmp);
            else
                figure('Position',obj.hm_setting.Position)
                tmp = rmfield(obj.hm_setting, 'Position');
                fig1 = heatmap(obj.conn.(method), ...
                    'Title',strcat(method_names{strcmp(methods,method)},'-',band));
                set(fig1,tmp);
            end
        end

        function reverse(obj)
            % Reverse by one processing step.
            obj.data = obj.rev_data;
            obj.ch_names = obj.rev_chs;
            obj.ref_chnames = obj.rev_refchs;
            obj.history{end + 1} = 'reverse';
        end

        function save(obj, varargin)
            p = inputParser;
            defaults = {[obj.filename, '_', num2str(obj.start), '_', num2str(obj.stop), '.mat'],
                true};
            for i = 1:length(varargin)
                if isempty(varargin{i})
                    varargin{i} = defaults{i};
                end
            end
            addOptional(p, 'file', defaults{1}, @(x) isstring(x) || ischar(x));
            addOptional(p, 'default_folder',defaults{2}, @(x) ismember(x,[0,1]));
            parse(p, varargin{:});
            file = p.Results.file;
            default_folder = p.Results.default_folder;
            file = char(file);
            [folder, name, ext] = fileparts(file);
            if isempty(ext)
                file = fullfile(file,defaults{1});
            end
            if default_folder
                file = fullfile(obj.user_data_dir, file);
            end

            save(file,'obj');
        end
    end

    methods (Access = private)
        function obj = record(obj)
            obj.rev_data = obj.data;
            obj.rev_chs = obj.ch_names;
            obj.rev_refchs = obj.ref_chnames;
        end
    end

%     methods (Static)
%         function data = loadobj(s)
%             data = s;
%         end
%     end
end
