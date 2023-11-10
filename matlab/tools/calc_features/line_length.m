function ll = line_length(x)
% Calculate the line length of each channel in the input data matrix.
%
% Parameters:
% - x (numeric array): Matrix representing EEG data. Each column is a channel,
%                      and each row is a time point.
%
% Returns:
% - ll (numeric array): Line length values for each channel, averaged by the
%                       number of data points in x.
%
% Example:
% x = randn(100, 5);  % Replace with your actual EEG data
% ll = line_length(x);
%
p = inputParser;
addRequired(p, 'x', @isnumeric);
parse(p, x);
% Access parsed values
x = p.Results.x;

% calculate the line length averaged by number of data points in x
y = x(1:end-1,:);
z = x(2:end,:);

ll = mean(abs(z-y),1);

end