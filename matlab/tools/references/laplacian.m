function [out_values,laplacian_labels] = laplacian(values,labels,locs,radius)
% Apply Laplacian re-referencing to multi-channel iEEG data.
%
% Parameters:
% - values (numeric array): Matrix representing iEEG data of shape samples X channels.
% - labels (cell array): Cell array containing channel labels corresponding to the columns of the data matrix.
% - locs (numeric array): Matrix representing the locations of electrodes.
% - radius (numeric): Radius defining the neighborhood for Laplacian re-referencing.
%
% Returns:
% - out_values (numeric array): Laplacian-referenced EEG data matrix.
% - laplacian_labels (cell array): Channel labels for the Laplacian-referenced data.
%
% Example:
% values = randn(100, 5);  % Replace with your actual EEG data
% labels = {'Fp1', 'Fp2', 'C3', 'C4', 'O1'};
% locs = randn(5, 3);  % Replace with your electrode locations
% radius = 20;  % Replace with your desired radius
% [out_values, laplacian_labels] = laplacian(values, labels, locs, radius);
%
p = inputParser;
addRequired(p, 'values', @isnumeric);
addRequired(p, 'labels', @iscell);
addRequired(p, 'locs', @isnumeric);
addRequired(p, 'radius', @isnumeric);
parse(p, values, labels, locs, radius);
values = p.Results.values;
labels = p.Results.labels;
locs = p.Results.locs;
radius = p.Results.radius;

nchs = size(values,2);
out_values = nan(size(values));
laplacian_labels = cell(nchs,1);
close_chs = cell(nchs,1);
% do pseudo-laplacian if no locs info available
nan_elecs = any(isnan(locs),2);
[pseudo_values, pseudo_labels] = pseudo_laplacian(values,labels);
out_values(:,nan_elecs) = pseudo_values(:,nan_elecs);
laplacian_labels(nan_elecs) = pseudo_labels(nan_elecs);
% calculate distance
D = pdist2(locs,locs); 
close = D < radius;
close(logical(eye(size(close)))) = 0;

for i = 1:nchs
    if ~nan_elecs(i)
        close_elecs = close(i,:);
        if ~isempty(find(close_elecs))
            out_values(:,i) = values(:,i) - mean(values(:,close_elecs),2,'omitnan');
            laplacian_labels(i) = labels(i);
            close_chs{i} = find(close(i,:));
        else
            out_values(:,i) = pseudo_values(:,i);
            laplacian_labels(i) = pseudo_labels(i);
            close_chs{i} = 0;
        end
    else
        close_chs{i} = 0;
    end
end

end