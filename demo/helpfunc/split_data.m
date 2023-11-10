function [leftData,rightData] = split_data(data)

labels = data.ch_names;

% Extract 'L' and 'R'
letters = cellfun(@(x) x(1), labels, 'UniformOutput', false);
numbers = cellfun(@(x) x(2:end), labels, 'UniformOutput', false);

left_inds = find(strcmp(letters,'L'));
right_inds = find(strcmp(letters,'R'));

left = numbers(left_inds);
right = numbers(right_inds);

inds_left = ismember(left,right);
inds_right = ismember(right,left);

leftData = copy(data);
rightData = copy(data);
leftData.data = data.data(:,left_inds(inds_left));
leftData.ch_names = data.ch_names(left_inds(inds_left));
leftData.ref_chnames = data.ref_chnames(left_inds(inds_left));
rightData.data = data.data(:,right_inds(inds_right));
rightData.ch_names = data.ch_names(right_inds(inds_right));
rightData.ref_chnames = data.ref_chnames(right_inds(inds_right));

