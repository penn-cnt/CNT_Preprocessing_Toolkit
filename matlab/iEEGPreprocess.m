classdef iEEGPreprocess < handle
    % A manager platform of iEEG data.
    % Manages login info, and provides login info for data downloading.
    % Manages active data clips.
    properties
        datasets
        meta
        num_data
        users
        user
        user_data_dir
    end

    methods
        function obj = iEEGPreprocess()
            obj.meta = table('Size',[0 5], 'VariableTypes', ...
                {'string','double','double','double','double'}, ...
                'VariableNames',["filename", "start", "stop","dura","fs"]);
%             obj.meta = table2struct(obj.meta);
            obj.num_data = size(obj.meta, 1);
        end

        
        function login_config(obj)
        %{
        Generate login config file and password file, and use as default user.

        Example Usage:
        >>> session = IEEGPreprocess()
        >>> session.login_config()
        %}
            usrname = login_config_base();
            obj.load_user(usrname);
        end
        
        function login(obj, varargin)
        %{
        Log into a specific account or the default account if only one account is available.

        Parameters:
            username (str, optional): The username of the account to log into. If not provided,
                the method will attempt to log into the default account or ask for keyboard prompt.

        Example Usage:
        >>> session = IEEGPreprocess()

        To log into a specific account, use:
        >>> session.login("my_username")

        To log into the default account or choose from multiple accounts:
        >>> session.login()
        %}
            p = inputParser;
            addOptional(p, 'username','', @(x) isstring(x) || ischar(x));
            parse(p, varargin{:});
            username = p.Results.username;
            obj.check_user(); 
            if isempty(username)
                if numel(obj.users) == 1
                    obj.load_user(obj.users{1});
                else
                    disp('Available accounts includes:');
                    disp(obj.users);
                    username = input('Please specify your username:');
                    if ~ismember(username, obj.users)
                        error('CNTtools:InvalidUsername', 'Please retry or set up iEEG login info using session.login_config() before use!');
                    else
                        obj.load_user(username);
                    end
                end
            else
                if ~ismember(username, obj.users)
                    error('CNTtools:InvalidUsername', 'Please retry or set up iEEG login info using session.login_config() before use!');
                else
                    obj.load_user(username);
                end
            end
        end

        function load_data(obj, path, varargin)
        %{
        Load data from a specified directory or a saved file.
        Data can be either an iEEGData instance or iEEGPreprocess instance.
        iEEGData instance would be appended to self.datasets, inputs information would be appended to self.meta.

        Parameters:
        -----------
        path : str
            The directory path or file path from which to load data.
        replace : boolean,optional
            Whether to replace current datasets and metadata. Default is False.
        default_folder: boolean,optional
            Whether to load data from default user data dir. Default is True.

        Raises:
        ------
        AssertionError : "CNTtools:invalidFilenPath"
            Raised when the specified 'dir' does not exist.
        AssertionError : "CNTtools:invalidFileFormat"
            Raised when the specified file is not .mat file.
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
        >>> session.load_data("/path/to/saved_data.mat", replace = True)
        %}
            p = inputParser;
            addRequired(p, 'path', @(x) isstring(x) || ischar(x));
            addOptional(p, 'replace',false, @(x) ismember(x,[0,1]));
            addOptional(p, 'default_folder',true, @(x) ismember(x,[0,1]));
            parse(p, path, varargin{:});
            path = p.Results.path;
            replace = p.Results.replace;
            default_folder = p.Results.default_folder;
            
            if default_folder
                path = fullfile(obj.user_data_dir, path);
            end
            
            assert(exist(path, 'dir') || exist(path, 'file'), 'CNTtools:invalidFilePath', 'Invalid file or directory path.');
            
            if isfolder(path)
                filelist = dir(fullfile(path, '*.mat'));
            elseif isfile(path)
                filelist = dir(path);
            end
            
            assert(any(endsWith({filelist.name}, '.mat')), 'CNTtools:invalidFileFormat', 'Invalid file format.');
            
            for i = 1:numel(filelist)
                f = fullfile(filelist(i).folder, filelist(i).name);
                
                if endsWith(f, '.mat')
                    data = load(f); % update
                    data = data.obj;
                    assert(isa(obj, 'iEEGData') || isa(obj, 'iEEGPreprocess'), 'CNTtools:invalidFileContents', 'Invalid file contents.');
                    
                    if replace
                        obj.datasets = {};
                        obj.meta = table('Size',[0 5], 'VariableTypes',{'string','double','double','double','double'}, 'VariableNames',["filename", "start", "stop","dura","fs"]);
                        obj.num_data = size(obj.meta, 1);
                    end
%                     disp(class(data))
                    if isa(data, 'iEEGData')
                        obj.add_data_instance(data);
                    elseif isa(data, 'iEEGPreprocess')
                        obj.merge_datasets(data); 
                    end
                end
            end
        end
        
        function data = download_data(obj, filename, start, stop, varargin)
        %{
        Download iEEG data from ieeg.org with the specified parameters.

        Parameters:
        -----------
        filename : str
            The name of the iEEG data file to download from ieeg.org.
        start : numeric
            The start time (in seconds) of the data segment to download.
        stop : numeric
            The stop time (in seconds) of the data segment to download.
        select_elecs : cell of str or int, optional
            A list of electrode names or indices to select for download. Default is None.
        ignore_elecs : cell of str or int, optional
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
        %}  
            defaults = {{},{},''};

            for i = 1:length(varargin)
                if isempty(varargin{i})
                    varargin{i} = defaults{i};
                end
            end

            p = inputParser;
            addOptional(p, 'select_elecs',defaults{1}, @(x) iscell(x) || isstring(x) || ischar(x));
            addOptional(p, 'ignore_elecs',defaults{2}, @(x) iscell(x) || isstring(x) || ischar(x));
            addOptional(p, 'username',defaults{3}, @(x) isstring(x) || ischar(x));
            parse(p, varargin{:});
            select_elecs = p.Results.select_elecs;
            ignore_elecs = p.Results.ignore_elecs;
            username = p.Results.username;

            if isempty(obj.user)
                obj.login('username', username);
            end
            data = iEEGData(filename, start, stop, select_elecs, ignore_elecs);
            data.download(obj.user); 
            obj.add_data_instance(data); 
        end
        
        function list_data(obj)
        %{
        List all datasets as a table with necessary information, 
        including filename from ieeg.org and start/stop time
        %}
            disp(obj.meta);
        end

        function remove_data(obj, dataIndex)
            % Remove data instance from current session.
            obj.meta(dataIndex, :) = [];
            obj.datasets(dataIndex) = [];
        end
        
        function save(obj, filename, varargin) 
        %{
        Save the iEEGPreprocess instance in .mat format. Defaultly save to data/user.

        Args:
            filename (str): filename to save file. Can be either a path, or a name without path specified.
        %}
            p = inputParser;
            addRequired(p, 'filename', @(x) isstring(x) || ischar(x));
            addOptional(p, 'default_folder',true, @(x) ismember(x,[0,1]));
            parse(p, filename, varargin{:});
            filename = p.Results.filename;
            default_folder = p.Results.default_folder;
            filename = char(filename);
            if default_folder
                filename = fullfile(obj.user_data_dir, filename);
            end
            
            if ~endsWith(filename, '.mat')
                filename = strcat([filename,'.mat']);
            end
            save(filename,'obj');
        end
%     end
% 
% 
%     methods (Access = private)

        function load_user(obj, varargin)
            % Load user info into current session.
            paths;
            p = inputParser;
            addOptional(p, 'username','', @(x) isstring(x) || ischar(x));
            parse(p, varargin{:});
            username = p.Results.username;

            config_file = fullfile(USER_DIR, [username(1:3) '_config.json']);
            data = jsondecode(fileread(config_file));
            obj.user = data;
            disp(['Login as : ', obj.user.usr]);
            obj.user_data_dir = fullfile(DATA_DIR, obj.user.usr(1:3));
        end

        function load_all_users(obj)
            % Load all usernames in the user folder
            paths;
            obj.users = {};
            files = dir(fullfile(USER_DIR, '*.json'));
            for i = 1:numel(files)
                f = fullfile(files(i).folder, files(i).name);
                data = jsondecode(fileread(f));
                obj.users = [obj.users, data.usr];
            end
        end
        
        function check_user(obj)
            % Verify that at least 1 user exists
            obj.load_all_users();
            if isempty(obj.users)
                disp('Please set up iEEG login info before downloading data.');
                obj.login_config();
            end
        end

        function add_data_instance(obj, data)
            obj.datasets{end + 1} = data; % data should be iEEGData instance
            data.index = obj.num_data + 1;
            add_data = struct('filename', data.filename, 'start', data.start, 'stop', data.stop, 'dura', data.dura, 'fs', data.fs);
            obj.meta = [obj.meta; struct2table(add_data)];
            obj.num_data = size(obj.meta, 1);
        end
        
        function merge_datasets(obj, data)
            for k = 1:length(data.datasets)
                obj.add_data_instance(data.datasets{k});
            end
        end

    end
    
end


