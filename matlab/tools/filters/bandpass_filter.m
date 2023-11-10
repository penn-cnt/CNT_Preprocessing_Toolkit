function values = bandpass_filter(values,fs,varargin)
% bandpass_filter Applies bandpass filter to iEEG data.

% Parameters:
%   values (numeric array): iEEG data matrix where each column represents a channel.
%   fs (numeric): Sampling frequency of the iEEG data.
%   low_freq (numeric, optional): Lower cutoff frequency for the bandpass filter (default: 1 Hz).
%   high_freq (numeric, optional): Upper cutoff frequency for the bandpass filter (default: 120 Hz).
%   order (integer, optional): Filter order (default: 4). Order consistent
%   with python version.

% Returns:
%   values (numeric array): Bandpass-filtered iEEG data.

% Example:
%   filtered_values = bandpass_filter(values, fs);
%   filtered_values = bandpass_filter(values, fs, 5, 50, 6);
%   filtered_values = bandpass_filter(values, fs, [], 35);

defaults = {1,120,4};

for i = 1:length(varargin)
    if isempty(varargin{i})
        varargin{i} = defaults{i};
    end
end

p = inputParser;
addRequired(p, 'values', @isnumeric);
addRequired(p, 'fs', @isnumeric);
addOptional(p, 'low_freq', defaults{1}, @isnumeric);
addOptional(p, 'high_freq', defaults{2}, @isnumeric);
addOptional(p, 'order', defaults{3}, @isinteger);

parse(p, values, fs, varargin{:});

% Access parsed values
values = p.Results.values;
fs = p.Results.fs;
low_freq = p.Results.low_freq;
high_freq = p.Results.high_freq;
order = p.Results.order;
order = order * 2;

d = designfilt('bandpassiir','FilterOrder',order, ...
    'HalfPowerFrequency1',max(low_freq,0.5),'HalfPowerFrequency2',min(floor(fs/2)-1,high_freq), ...
    'SampleRate',fs);

for i = 1:size(values,2)
    eeg = values(:,i);
    
    if sum(~isnan(eeg)) == 0
        continue
    end
    
    eeg(isnan(eeg)) = mean(eeg,'omitnan');
    eeg = filtfilt(d,eeg);   
    values(:,i) = eeg;
end


end