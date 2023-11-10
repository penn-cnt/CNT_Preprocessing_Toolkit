function all_plv = plv(values,fs,varargin)
% plv Computes phase-locking value (PLV) for iEEG data.

% Parameters:
%   values (numeric array): iEEG data matrix where each column represents a channel.
%   fs (numeric): Sampling frequency of the iEEG data.
%   do_tw (logical, optional): Boolean indicating whether to use time windows (true) or compute a single PLV (false).
%   tw (numeric, optional): Time window size in seconds.
%   freqs (numeric array, optional): Matrix where each row represents a frequency range. The first column is the lower bound, and the second column is the upper bound.

% Returns:
%   all_plv (numeric array): PLV matrix where each element (i, j, k) represents the PLV between channel i and channel j at frequency range k.

% Example:
%   all_plv = plv(values, fs);
%   all_plv = plv(values, fs, true, 2, [4 8; 8 12]);

%% parse inputs
freqs = default_freqs;
defaults = {false,2,freqs}; % do_tw, tw, freqs, segment, overlap

for i = 1:length(varargin)
    if isempty(varargin{i})
        varargin{i} = defaults{i};
    end
end

p = inputParser;
addRequired(p, 'values', @isnumeric);
addRequired(p, 'fs', @isnumeric);
addOptional(p, 'do_tw', defaults{1}, @(x) ismember(x,[0,1]));
addOptional(p, 'tw', defaults{2}, @isnumeric);
addOptional(p, 'freqs', defaults{3}, @isnumeric);

parse(p, values, fs, varargin{:});

% Access parsed values
values = p.Results.values;
fs = p.Results.fs;
tw = p.Results.tw;
do_tw = p.Results.do_tw;
freqs = p.Results.freqs;

%% Parameters
nchs = size(values,2);
nfreqs = size(freqs,1);

if do_tw && (tw > size(values,1)/fs)
    do_tw = false;
end

for ich = 1:nchs
    curr_values = values(:,ich);
    curr_values(isnan(curr_values)) = mean(curr_values,'omitnan');
    values(:,ich) = curr_values;
end

filtered_data = nan(size(values,1),size(values,2),nfreqs);
for f = 1:nfreqs
    filtered_data(:,:,f) = bandpass_filter(values,fs,freqs(f,1),freqs(f,2));
end
%% Get filtered signal

if do_tw
    % divide into time windows
    iw = round(tw*fs);
    window_start = 1:iw:size(values,1);

    % remove dangling window
    if window_start(end) + iw > size(values,1)
        window_start(end) = [];
    end
    nw = length(window_start);

    all_plv = ones(nchs,nchs,nfreqs,nw);
    for t = 1:nw
        for f = 1:nfreqs
            tmp_data = filtered_data(window_start(t):window_start(t)+iw,:,f);
            % Get phase of each signal
            phase = nan(size(tmp_data));
            for ich = 1:nchs
                phase(:,ich)= angle(hilbert(tmp_data(:,ich)));
            end
            % Get PLV
            plv = ones(nchs,nchs);
            for ich = 1:nchs
                for jch = ich+1:nchs
                    e = exp(1i*(phase(:,ich) - phase(:,jch)));
                    plv(ich,jch) = abs(sum(e,1))/size(phase,1);
                    plv(jch,ich) = abs(sum(e,1))/size(phase,1);
                end
            end
            all_plv(:,:,f,t) = plv;
        end
    end
    all_plv = mean(all_plv,4,'omitnan');
else
    %% initialize output vector
    all_plv = ones(nchs,nchs,nfreqs);
    
    % Do plv for each freq
    for f = 1:nfreqs
        
        tmp_data = filtered_data(:,:,f);
    
        % Get phase of each signal
        phase = ones(size(tmp_data));
        for ich = 1:nchs
            phase(:,ich)= angle(hilbert(tmp_data(:,ich)));
        end
    
        % Get PLV
        plv = ones(nchs,nchs);
        for ich = 1:nchs
            for jch = ich+1:nchs
                e = exp(1i*(phase(:,ich) - phase(:,jch)));
                plv(ich,jch) = abs(sum(e,1))/size(phase,1);
                plv(jch,ich) = abs(sum(e,1))/size(phase,1);
            end
        end
        all_plv(:,:,f) = plv;
    
    end
end
end