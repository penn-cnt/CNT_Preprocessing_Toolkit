function all_coherence = coherence(values,fs,varargin)
% coherence Calculates coherence for iEEG data with multiple channels.

% Parameters:
%   values (numeric array): iEEG data matrix where each column represents a channel.
%   fs (numeric): Sampling frequency of the iEEG data.
%   do_tw (logical, optional): Boolean indicating whether to use time windows (true) or compute a single coherence (false).
%   tw (numeric, optional): Time window size in seconds.
%   freqs (numeric array, optional): Matrix where each row represents a frequency range. The first column is the lower bound, and the second column is the upper bound.
%   segment (numeric, optional): Duration of each segment in seconds for multi-taper spectral estimation.
%   overlap (numeric): Overlap between segments for multi-taper spectral estimation, in seconds.

% Output:
%   all_coherence (numeric array): Coherence matrix where each element (i, j, k) represents the coherence between channel i and channel j at frequency range k.

% Examples:
%   all_coherence = coherence(values, fs);
%   all_coherence = coherence(values, fs, [], [], [], 2, 1);
%   all_coherence = coherence(values, fs, true, 2, [4 8], 1, 0.5);


%% parse inputs
freqs = default_freqs;
defaults = {false,2,freqs,1,0.5}; % do_tw, tw, freqs, segment, overlap

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
addOptional(p, 'segment', defaults{4}, @isnumeric);
addOptional(p, 'overlap', defaults{5}, @isnumeric);
addOptional(p, 'freqs', defaults{3}, @isnumeric);

parse(p, values, fs, varargin{:});

% Access parsed values
values = p.Results.values;
fs = p.Results.fs;
tw = p.Results.tw;
do_tw = p.Results.do_tw;
freqs = p.Results.freqs;
segment = p.Results.segment;
overlap = p.Results.overlap;
assert(segment > overlap, "overlap should be smaller than segment.")

%% Parameters
nchs = size(values,2);
nfreqs = size(freqs,1);
nperseg = round(fs * segment);
noverlap = round(fs * overlap);
window = round(fs * tw);

if window > size(values,1)
    do_tw = false;
end

%% initialize output vector
all_coherence = nan(nchs,nchs,nfreqs);

for ich = 1:nchs
    curr_values = values(:,ich);
    curr_values(isnan(curr_values)) = mean(curr_values,'omitnan');
    values(:,ich) = curr_values;
end

if do_tw
    % divide into time windows
    window_start = 1:window:size(values,1);

    % remove dangling window
    if window_start(end) + window > size(values,1)
        window_start(end) = [];
    end
    nw = length(window_start);

    temp_coherence = nan(nchs,nchs,nfreqs,nw);
    for t = 1:nw
        for ich = 1:nchs
            [cxy,f] = mscohere(values(window_start(t):window_start(t)+window,ich),values(window_start(t):window_start(t)+window,:),nperseg,noverlap,[],fs);
            for i_f = 1:nfreqs
                temp_coherence(:,ich,i_f,t) = ...
                    mean(cxy(f >= freqs(i_f,1) & f <= freqs(i_f,2),:),1,'omitnan');
            end
        end

    end
    temp_coherence = mean(temp_coherence,4,'omitnan');
else
    temp_coherence = nan(nchs,nchs,nfreqs);
    for ich = 1:nchs
        % Do MS cohere on full thing
        [cxy,f] = mscohere(values(:,ich),values,nperseg,noverlap,[],fs);
    
        % Average coherence in frequency bins of interest
        for i_f = 1:nfreqs
            temp_coherence(:,ich,i_f) = ...
                mean(cxy(f >= freqs(i_f,1) & f <= freqs(i_f,2),:),1,'omitnan');
        end
    end
end

%% Put the non-nans back
all_coherence = temp_coherence;
% all_coherence(logical(repmat(eye(nchs,nchs),1,1,nfreqs))) = nan;


end
