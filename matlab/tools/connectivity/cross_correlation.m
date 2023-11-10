function [mb,lb] = cross_correlation(values,fs,varargin)

%   [mb, lb] = cross_correlation(values, fs, tw, do_tw) 
%   Computes the cross-correlation matrices for the input iEEG data.
%
%   Inputs:
%       values - iEEG data matrix (samples x channels). Default is False.
%       fs - Sampling frequency of the iEEG data.
%       do_tw - optional, Boolean indicating whether to use time windows (true) or
%               compute a single cross-correlation (false). 
%       tw - optional, Time window size in seconds. Default is 2 seconds.
%       max_lag - optional, Specify the maximum lag in milliseconds.
%                           Default is 200 ms.
%
%   Outputs:
%       mb - Mean cross-correlation matrix.
%       lb - Mean lag matrix (in seconds).
%
%   Example:
%       [mb, lb] = cross_correlation(values, fs);
%       [mb, lb] = cross_correlation(values, fs, true);
%       [mb, lb] = cross_correlation(values, fs, true, 1);
%       [mb, lb] = cross_correlation(values, fs, [], [], 300);
%
%   Notes:
%   - The diagonal entries of the cross-correlation matrices represent
%     self-correlation and are set to 1.
%   - If using time windows (do_tw=true), the function returns the mean
%     cross-correlation and lag matrices across all windows.

defaults = {false,2,200};

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
addOptional(p, 'max_lag', defaults{3}, @isnumeric);

parse(p, values, fs, varargin{:});

% Access parsed values
values = p.Results.values;
fs = p.Results.fs;
tw = p.Results.tw;
do_tw = p.Results.do_tw;
max_lag = p.Results.max_lag;

ml_default = size(values,1) - 1;
ml = min(ml_default,round(max_lag * 1e-3 * fs)); % max lag in num samples
nchan = size(values,2);
if do_tw && (tw > size(values,1)/fs)
    do_tw = false;
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
    
    % Prep the variables
    mb_all = nan(nchan,nchan,nw);
    lb_all = nan(nchan,nchan,nw);
    
    for t = 1:nw
    
        % Calculate cross correlation. 'Normalized' normalizes the sequence so that
        % the autocorrelations at zero lag equal 1
        [r,lags] = xcorr(values(window_start(t):window_start(t)+iw,:),ml,'normalized');
        
        % find the maximum xcorr, and its corresponding lag, for each channel pair
        [M,I] = max(r,[],1);
        nlags = lags(I);
        
        % back out what channels are what
        mb = reshape(M,nchan,nchan);
        lb = reshape(nlags,nchan,nchan);
        
        % Make anything that is a nan in mb a nan in lb
        lb(isnan(mb)) = nan;
        
        % make anything at the edge of lags nan in lb
        %lb(lb==ml) = nan;
        %lb(lb==-ml) = nan;
        
        lb = lb/fs;
    
        mb_all(:,:,t) = mb;
        lb_all(:,:,t) = lb;
    
    end
    
    mb = mean(mb_all,3,'omitnan');
    lb = mean(lb_all,3,'omitnan');

else
    % Calculate cross correlation. 'Normalized' normalizes the sequence so that
    % the autocorrelations at zero lag equal 1
    [r,lags] = xcorr(values,ml,'normalized');
    
    % find the maximum xcorr, and its corresponding lag, for each channel pair
    [M,I] = max(r,[],1);
    nlags = lags(I);
    
    % back out what channels are what
    mb = reshape(M,nchan,nchan);
    lb = reshape(nlags,nchan,nchan);
    
    % Make anything that is a nan in mb a nan in lb
    lb(isnan(mb)) = nan;
    
    % make anything at the edge of lags nan in lb
    % lb(lb==ml) = nan;
    % lb(lb==-ml) = nan;
    
    lb = lb/fs;

end

% if 0
%     figure
%     set(gcf,'position',[10 10 1400 400])
%     nexttile
%     turn_nans_gray(mb)
%     nexttile
%     turn_nans_gray(lb)
%     nexttile
%     turn_nans_gray(corr(values))
% end
end