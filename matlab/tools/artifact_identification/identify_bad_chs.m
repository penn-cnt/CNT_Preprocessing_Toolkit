function [bad,details] = identify_bad_chs(values,fs)
% Identifies bad channels based on various criteria.
%
% Parameters:
% - values (numeric array): Matrix representing EEG data. Each column is a channel, and each row is a time point.
% - fs (numeric): Sampling frequency of the EEG data.
%
% Returns:
% - bad (logical array): Boolean array indicating bad channels.
% - details (struct): Details of bad channels categorized by specific criteria.
%
% Criteria:
% - Channels with more than half NaNs are marked as bad.
% - Channels with more than half zeros are marked as bad.
% - Channels with a significant number of values above an absolute threshold are marked as bad.
% - Channels with rare cases of super high variance above baseline are marked as bad.
% - Channels with a significant amount of 60 Hz noise are marked as bad.
% - Channels with standard deviation much higher than the median are marked as bad.
%
% Example:
% values = randn(100, 5);  % Replace with your actual EEG data
% fs = 250;
% [bad, details] = identify_bad_chs(values, fs);

p = inputParser;
addRequired(p, 'values', @isnumeric);
addRequired(p, 'fs', @isnumeric);
parse(p, values, fs);
values = p.Results.values;
fs = p.Results.fs;

%% Parameters to reject super high variance
tile = 99;
mult = 10;
num_above = 1;
abs_thresh = 5e3;

%% Parameter to reject high 60 Hz
percent_60_hz = 0.7;

%% Parameter to reject electrodes with much higher std than most electrodes
mult_std = 10;

nchs = size(values,2);
chs = 1:nchs;
bad = [];
high_ch = [];
nan_ch = [];
zero_ch = [];
high_var_ch = [];
noisy_ch = [];
all_std = nan(nchs,1);


for i = 1:nchs
    
    bad_ch = 0;
    
    ich = i;
    eeg = values(:,ich);
    bl = median(eeg,'omitnan');
    
    %% Get channel standard deviation
    all_std(i) = std(eeg,'omitnan');
    
    %% Remove channels with nans in more than half
    if sum(isnan(eeg)) > 0.5*length(eeg)
        bad = [bad;ich];
        nan_ch = [nan_ch;ich];
        continue;
    end
    
    %% Remove channels with zeros in more than half
    if sum(eeg == 0) > 0.5 * length(eeg)
        bad = [bad;ich];
        zero_ch = [zero_ch;ich];
        continue;
    end
    
    %% Remove channels with too many above absolute thresh
    
    if sum(abs(eeg - bl) > abs_thresh) > 10
        bad = [bad;ich];
        bad_ch = 1;
        high_ch = [high_ch;ich];
    end
    
    if bad_ch == 1
        continue;
    end
    
    
    %% Remove channels if there are rare cases of super high variance above baseline (disconnection, moving, popping)
    pct = prctile(eeg,[100-tile tile]);
    thresh = [bl - mult*(bl-pct(1)), bl + mult*(pct(2)-bl)];
    sum_outside = sum(eeg > thresh(2) | eeg < thresh(1));
    if sum_outside >= num_above
        bad_ch = 1;
    end
    
    if bad_ch == 1
        bad = [bad;ich];
        high_var_ch = [high_var_ch;ich];
        continue;
    end
    
    %% Remove channels with a lot of 60 Hz noise, suggesting poor impedance
    
    % Calculate fft
    %orig_eeg = orig_values(:,ich);
    %Y = fft(orig_eeg-mean(orig_eeg));
    Y = fft(eeg-mean(eeg,'omitnan'));
    
    % Get power
    P = abs(Y).^2;
    freqs = linspace(0,fs,length(P)+1);
    freqs = freqs(1:end-1);
    
    % Take first half
    P = P(1:ceil(length(P)/2));
    freqs = freqs(1:ceil(length(freqs)/2));
    
    P_60Hz = sum(P(freqs > 58 & freqs < 62))/sum(P);
    if P_60Hz > percent_60_hz
        bad_ch = 1;
    end
    
end

%% Remove channels for whom the std is much larger than the baseline
median_std = median(all_std,'omitnan');
higher_std = chs(all_std > mult_std * median_std);
bad_std = higher_std';
bad_std(ismember(bad_std,bad)) = [];
bad = ([bad;bad_std]);
bad_bin = zeros(nchs,1);
bad_bin(bad) = 1;
bad = logical(bad_bin);

details.noisy = noisy_ch;
details.nans = nan_ch;
details.zeros = zero_ch;
details.var = high_var_ch;
details.higher_std = bad_std;
details.high_voltage = high_ch;

end