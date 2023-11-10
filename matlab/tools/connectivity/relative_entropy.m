function re = relative_entropy(values,fs,varargin)
%% relative_entropy Calculates relative entropy for iEEG data.

% Parameters:
%   values (numeric array): iEEG data matrix where each column represents a channel.
%   fs (numeric): Sampling frequency of the iEEG data.
%   do_tw (logical, optional): Boolean indicating whether to use time windows (true) or compute a single relative entropy (false).
%   tw (numeric, optional): Time window size in seconds.
%   freqs (numeric array, optional): Matrix where each row represents a frequency range. The first column is the lower bound, and the second column is the upper bound.

% Returns:
%   re (numeric array): Relative entropy matrix where each element (i, j, k, t) represents the relative entropy between channel i and channel j at frequency range k and time window t.

% Examples:
%   re = relative_entropy(values, fs);
%   re = relative_entropy(values, fs, true, 2, [4 8; 8 12]);
%   re = relative_entropy(values, fs, [], [], [8 12]);

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

if do_tw
    % divide into time windows
    iw = round(tw*fs);
    window_start = 1:iw:size(values,1);

    % remove dangling window
    if window_start(end) + iw > size(values,1)
        window_start(end) = [];
    end
    nw = length(window_start);
    re = nan(nchs,nchs,nfreqs,nw);
    
    % loop over window_start and frequences
    for t = 1:nw
        for f = 1:nfreqs
        
            tmp_data = filtered_data(window_start(t):window_start(t)+iw,:,f);
        
            for ich = 1:nchs
                for jch = ich:nchs
                    h1 = (steve_histcounts(tmp_data(:,ich),10))'; % faster
                    h2 = (steve_histcounts(tmp_data(:,jch),10))';
                    smooth = 1e-10;
                    h1 = h1 + smooth; h2 = h2 + smooth;
                    h1 = h1/sum(h1); h2 = h2/sum(h2);
                    S1 = sum(h1.*log(h1./h2));
                    S2 = sum(h2.*log(h2./h1));
                    re(ich,jch,f,t) = max([S1,S2]);
                    re(jch,ich,f,t) = re(ich,jch,f,t);
                end
            end
        end
    end
    
    re = mean(re,4,'omitnan');

else
    re = ones(nchs,nchs,nfreqs);
    
    % loop over frequences
    for f = 1:nfreqs
    
        tmp_data = values;%filtered_data(:,:,f);
    
        for ich = 1:nchs
            for jch = ich+1:nchs
                h1 = (steve_histcounts(tmp_data(:,ich),10))';
                h2 = (steve_histcounts(tmp_data(:,jch),10))';
                %h1 = histcounts(tmp_data(:,ich),10);
                %h2 = histcounts(tmp_data(:,jch),10);
                h1 = h1/sum(h1); h2 = h2/sum(h2); % normalize?
                %S1 = sum(h1*log(h1/h2));
                %S2 = sum(h2*log(h2/h1));
                S1 = sum(h1.*log(h1./h2));
                S2 = sum(h2.*log(h2./h1));
                re(ich,jch,f) = max([S1,S2]);
                re(jch,ich,f) = re(ich,jch,f);
            end
        end
    end
end

% if 0
%     figure
%     for i = 1:nfreqs
%     nexttile
%     turn_nans_gray(re(:,:,i))
%     end
% 
% end
%}

end

function c = steve_histcounts(x, n)
    L = min(x);
    U = max(x);
    W = (U-L)/n;
    i = min(n, 1+floor((x-L)/W));
    c = accumarray(i, 1, [n 1]);
end