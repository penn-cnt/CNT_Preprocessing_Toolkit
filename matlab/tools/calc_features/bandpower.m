function bp = bandpower(data, fs, band, varargin)
% Adapted from https://raphaelvallat.com/bandpower.html
% Compute the average power of the signal x in a specific frequency band.
%
%     Parameters
%     ----------
%     data : matrix
%         Input signal in the time-domain. (time by channels)
%     fs : float
%         Sampling frequency of the data.
%     band : list
%         Lower and upper frequencies of the band of interest. 
%     win : float
%         Length of each window in seconds.
%         If None, win = (1 / min(band)) * 2
%     relative : boolean
%         If True, return the relative power (= divided by the total power of the signal).
%         If False (default), return the absolute power.
%
%     Return
%     ------
%     bp : matrix, channels X bands
%         Absolute or relative band power.

defaults = {nan,false};

for i = 1:length(varargin)
    if isempty(varargin{i})
        varargin{i} = defaults{i};
    end
end

p = inputParser;
addRequired(p, 'data', @isnumeric);
addRequired(p, 'fs',  @isnumeric);
addRequired(p, 'band', @isnumeric);
addOptional(p, 'win', defaults{1}, @isnumeric);
addOptional(p, 'relative', defaults{2}, @islogical);
parse(p, data, fs, band, varargin{:});

% Access parsed values
data = p.Results.data;
fs = p.Results.fs;
band = p.Results.band;
win = p.Results.win;
relative = p.Results.relative;

low = band(1); high = band(2);
if ~isnan(win)
    nperseg = win * fs;
else
    nperseg = (2 / low) * fs;
end

% Compute the modified periodogram (Welch)
[pxx, f] = pwelch(data, nperseg, [], [low high], fs);
% Frequency resolution
freq_res = f(2) - f(1);

% Find closest indices of band in frequency vector
idx_band = find(f >= low & f <= high);

% Integral approximation of the spectrum using Simpson's rule.
if ismatrix(pxx)
    bp = simpson(freq_res,pxx(idx_band,:));
else
    bp = simpson(freq_res,pxx(idx_band));
end

if relative
    bp = bp/simpson(freq_res,pxx);
end
