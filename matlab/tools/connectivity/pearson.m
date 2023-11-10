function avg_pc = pearson(values,fs,varargin)
% Calculate the Pearson correlation coefficients between channels in iEEG data.
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
% correlations = pearson(values, fs);
% correlations = pearson(values, fs, true);
% correlations = pearson(values, fs, true, 3);

defaults = {false,2};

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

parse(p, values, fs, varargin{:});

% Access parsed values
values = p.Results.values;
fs = p.Results.fs;
tw = p.Results.tw;
do_tw = p.Results.do_tw;

nchs = size(values,2);

if ~do_tw
    avg_pc = corrcoef(values);
else
    % Define time windows
    iw = round(tw*fs);
    window_start = 1:iw:size(values,1);

    % remove dangling window
    if window_start(end) + iw > size(values,1)
        window_start(end) = [];
    end
    nw = length(window_start);

    % initialize output vector
    all_pc = nan(nchs,nchs,nw);

    % Calculate pc for each window
    for i = 1:nw

        % Define the time clip
        clip = values(window_start:window_start+iw,:);


        pc = corrcoef(clip);
        %pc(logical(eye(size(pc)))) = 0;

        % unwrap the pc matrix into a one dimensional vector for storage
        all_pc(:,:,i) = pc;

    end

    % Average the network over all time windows
    avg_pc = mean(all_pc,3,'omitnan');

end
end