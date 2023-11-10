function inds = get_ind(labels)
% this function get the index within 1-36 for a set of labels

[elec, num] = decompose(labels);
inds = [];
for i = 1:length(labels)
    elecName = elec{i};
    elecName = elecName(2:end);
    if strcmp(elecName,'DA')|strcmp(elecName,'AD')|strcmp(elecName,'A')
        inds = [inds num{i}];
    elseif strcmp(elecName,'DH')|strcmp(elecName,'HD')|strcmp(elecName,'B')|strcmp(elecName,'AH')
        inds = [inds 1*12 + num{i}];
    elseif strcmp(elecName,'C')|strcmp(elecName,'PH')
        inds = [inds 2*12 + num{i}];
    end
end
end

function [non_nums,nums] = decompose(labels)
non_nums = {};
nums = {};
for ich = 1:length(labels)
    label = labels{ich};
    %% Get the non-numerical portion
    label_num_idx = regexp(label,'\d');
    label_non_num = label(1:label_num_idx-1);
    non_nums{ich} = label_non_num;
    
    % get numerical portion
    label_num = str2num(label(label_num_idx:end));
    if isempty(label_num), label_num = nan; end
    nums{ich} = label_num;
end
end