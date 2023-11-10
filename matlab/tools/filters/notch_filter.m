function values = notch_filter(values,fs,varargin)
% Apply a notch filter to iEEG data to remove interference at a specified frequency.
%
% Parameters:
% - values (numeric array): Matrix representing EEG data. Each column is a channel, and each row is a time point.
% - fs (numeric): Sampling frequency of the EEG data.
% - notch_freq (numeric, optional): Frequency to notch filter (default is 60 Hz).
% - order (numeric, optional): Order of the notch filter (default is 4).
%
% Returns:
% - values (numeric array): Matrix with notch-filtered EEG data.
%
% Example:
% values = randn(100, 5);  % Replace with your actual iEEG data
% fs = 250;
% notch_filtered_values = notch_filter(values, fs);
% notch_filtered_values = notch_filter(values, fs, [], 8);
% notch_filtered_values = notch_filter(values, fs, 120);

defaults = {60,4};

for i = 1:length(varargin)
    if isempty(varargin{i})
        varargin{i} = defaults{i};
    end
end

p = inputParser;
addRequired(p, 'values', @isnumeric);
addRequired(p, 'fs', @isnumeric);
addOptional(p, 'notch_freq', defaults{1}, @isnumeric);
addOptional(p, 'order', defaults{2}, @isinteger);

parse(p, values, fs, varargin{:});

values = p.Results.values;
fs = p.Results.fs;
notch_freq = p.Results.notch_freq;
order = p.Results.order;
order = order * 2;

f = designfilt('bandstopiir','FilterOrder',order, ...
   'HalfPowerFrequency1',notch_freq-1,'HalfPowerFrequency2',notch_freq+1, ...
   'DesignMethod','butter','SampleRate',fs);
%fvtool(f)

for i = 1:size(values,2) 
    eeg = values(:,i);
    if sum(~isnan(eeg)) == 0
        continue
    end
    eeg(isnan(eeg)) = mean(eeg,'omitnan');
    eeg = filtfilt(f,eeg);   
    values(:,i) = eeg;
end


end

