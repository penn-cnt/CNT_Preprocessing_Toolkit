function [out_values,car_labels] = car(values,labels)
% Common Average Referencing (CAR) for iEEG data.
%
% Parameters:
% - values (numeric array): Matrix representing EEG data. Each column is a channel, and each row is a time point.
% - labels (cell array): Cell array containing channel labels corresponding to the columns of the data matrix.
%
% Returns:
% - out_values (numeric array): CAR-referenced iEEG data matrix.
% - car_labels (cell array): Channel labels for the CAR-referenced data.
%
% Example:
% values = randn(100, 5);  % Replace with your actual EEG data
% labels = {'Fp1', 'Fp2', 'C3', 'C4', 'O1'};
% [out_values, car_labels] = car(values, labels);
p = inputParser;
addRequired(p, 'values', @isnumeric);
addRequired(p, 'labels', @iscell);
parse(p, values, labels);
values = p.Results.values;
labels = p.Results.labels;

out_values = values - mean(values,2,'omitnan'); 
car_labels = strcat(labels,'-CAR');
end