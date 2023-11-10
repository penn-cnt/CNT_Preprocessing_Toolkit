function result = movingmean(x, k)
% Apply a moving average filter to the input data along each channel.
%
% Parameters:
% - x (numeric array): Matrix representing iEEG data of size samples X
% channels
% - k (int): Size of the moving average window.
%
% Returns:
% - numeric array: Data after applying the moving average filter along each channel.
%
% Example:
% x = randn(100, 5);  % Replace with your actual EEG data
% window_size = 3;
% smoothed_data = movingmean(x, window_size);
p = inputParser;
addRequired(p, 'x', @isnumeric);
addRequired(p, 'k', @isinteger);
parse(p, x, k);
% Access parsed values
x = p.Results.x;
k = p.Results.k;

if ndims(x) == 1
    result = smoothdata(x, 'movmean', k);
else
    result = zeros(size(x));
    for i = 1:size(x,2)
        result(:, i) = smoothdata(x(:,i), 'movmean', k);
    end
end
