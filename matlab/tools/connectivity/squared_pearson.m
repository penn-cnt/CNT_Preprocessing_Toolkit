function avg_pc = squared_pearson(values,fs,varargin)
% Calculate the Squared Pearson correlation coefficients between channels in iEEG data.
%
% Parameters:
% - values (matrix): Matrix representing iEEG data. Each column is a channel, and each row is a time point.
% - fs (float): Sampling frequency of the iEEG data.
% - do_tw (logical, optional): If true, calculate windowed correlations; if false, calculate overall correlations.
% - tw (float, optional): Size of the time window in seconds for windowed correlation calculation.
%
% Returns:
% - avg_pc (matrix): Pearson correlation coefficients between channels. If windowed, returns an average over time windows.
%
% Example:
% values = randn(100, 5);  % Replace with your actual data
% fs = 250;
% correlations = squared_pearson(values, fs);
% correlations = squared_pearson(values, fs, true);
% correlations = squared_pearson(values, fs, true, 3);

avg_pc = pearson(values,fs,varargin{:});
avg_pc = avg_pc.^2;

