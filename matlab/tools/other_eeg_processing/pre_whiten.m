function data = pre_whiten(data)
% Pre-whiten the input data using linear regression.
%
% Parameters:
% - data (numeric array): Matrix representing data in samples X channels.
%
% Returns:
% - data (numeric array): Pre-whitened data matrix.
%
% Example:
% data = randn(100, 5);  % Replace with your actual data
% pre_whitened_data = pre_whiten(data)

p = inputParser;
addRequired(p, 'data', @isnumeric);
parse(p, data);

data = p.Results.data;

for j = 1:size(data,2)
    vals = data(:,j);    
    
    if sum(~isnan(vals)) == 0
        continue
    end

    mdl = fitlm(vals(1:end-1),vals(2:end));
    E = mdl.predict(vals(1:end-1)) - vals(2:end);

    if length(E) < length(vals)
        E = [E;nan(length(vals)-length(E),1)];
    end
    data(:,j) = E;
end
end