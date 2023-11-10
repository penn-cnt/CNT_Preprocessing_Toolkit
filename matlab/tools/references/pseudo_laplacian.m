function [values,out_labels] = pseudo_laplacian(values,chLabels,varargin)
% Apply pseudo-laplacian re-referencing to multi-channel iEEG data.
% The output values(:,ich) equals the input values(:,ich) - average of 
% values(:,ich+1) and values(:,ich-1). 
% For example, if ich is RA2, then values(:,RA1) will be the old values(:,RA1)
% - (old values(:,RA1)+old values(:RA3))/2. If the previous/next contact 
% on the electrode is missing, values of the available contact would be used, 
% if none of the previous/next contact is available, the values(:,ich) 
% is defined to be nans, the label is marked as '-'.
% Default allows soft referencing, i.e., subtraction of channels at a distance 
% of the soft threshold. e.g., A soft threshold of 1 allows RA1-RA3.

% Parameters:
% - values (numeric array): Matrix representing iEEG data of shape samples X channels.
% - chLabels (cell array): Cell array containing channel labels corresponding to the columns of the data matrix.
% - soft (logical, optional): Allow for soft bipolar referencing, considering multiple next-numbered contacts. Default is true.
% - softThres (integer, optional): Number of next-numbered contacts to consider in soft referencing. Default is 1.

% Returns:
% - values (numeric array): Pseudo-laplacian-referenced EEG data matrix.
% - labels (cell array): Channel labels for the pseudo-laplacian-referenced data.

% Example:
% values = randn(100, 5);  % Replace with your actual EEG data
% chLabels = {'Fp1', 'Fp2', 'C3', 'C4', 'O1'};
% [values, pseudo_laplacian_labels] = pseudo_laplacian(values, chLabels);
% [values, pseudo_laplacian_labels] = pseudo_laplacian(values, chLabels, [], 2);

defaults = {true,1};

for i = 1:length(varargin)
    if isempty(varargin{i})
        varargin{i} = defaults{i};
    end
end

p = inputParser;
addRequired(p, 'values', @isnumeric);
addRequired(p, 'chLabels', @iscell);
addOptional(p, 'soft', true, @islogical);
addOptional(p, 'softThres', 1, @isinteger);
parse(p, values, chLabels, varargin{:});
values = p.Results.values;
chLabels = p.Results.chLabels;
soft = p.Results.soft;
softThres = p.Results.softThres;

%% Initialize output variables
nchs = size(values,2);
old_values = values;

%% Decompose chLabels
labels = clean_labels(chLabels);
[elecs,numbers] = decompose(labels);
out_labels = labels;

%% Bipolar montage
for ch = 1:nchs
    % Initialize it as nans
    out = nan(size(values,1),1);
    bipolar_label = '-';
    
    % Get the clean label
    label = labels{ch};

    % get the non numerical portion of the electrode contact
    label_non_num = elecs{ch};

    % get numerical portion
    label_num = numbers{ch};

    if ~isnan(label_num)
        % see if there exists one higher
        if soft
            label_nums_high = [label_num + 1:label_num + softThres + 1];
            label_nums_low = [label_num - softThres - 1:label_num - 1];
        else
            label_nums_high = [label_num+1];
            label_nums_low = [label_num-1];
        end
        higher_ch = 0; lower_ch = 0;
        for label_num_i = label_nums_high
            higher_label = [label_non_num,sprintf('%d',label_num_i)];
            if sum(strcmp(labels(:,1),higher_label)) > 0
                higher_ch = find(strcmp(labels(:,1),higher_label),1);
                break
            end
        end
        for label_num_i = label_nums_low(end:-1:1)
            lower_label = [label_non_num,sprintf('%d',label_num_i)];
            if sum(strcmp(labels(:,1),lower_label)) > 0
                lower_ch = find(strcmp(labels(:,1),lower_label),1);
                break
            end
        end
        if higher_ch && lower_ch
            out = old_values(:,ch)-(old_values(:,higher_ch)+old_values(:,lower_ch))/2;
        elseif higher_ch
            out = old_values(:,ch)-old_values(:,higher_ch);
        elseif lower_ch
            out = old_values(:,ch)-old_values(:,lower_ch);
        else
            out_labels{ch} = bipolar_label;
        end
    else
        out_labels{ch} = bipolar_label;
    end
    values(:,ch) = out; 
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