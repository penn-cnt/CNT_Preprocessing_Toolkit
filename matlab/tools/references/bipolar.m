function [values,bipolar_labels] = bipolar(values,chLabels,varargin)
% Create a bipolar montage from multi-channel iEEG data.
% The output values(:,ich) equals the input values(:,ich) - values(:,jch), 
% where jch is the next numbered contact on the same electrode as ich. 
% For example. if ich is RA1, then jch is RA2 and values(:,RA1) will be 
% the old values(:,RA1) - old values(:,RA2). If ich is the last contact 
% on the electrode, or adjacent channel does not exist, then values(:,ich) 
% is defined to be nans. the label is marked as '-'.
% Default allows soft referencing, i.e. substraction of channels at distance 
% of soft threshold. e.g. A soft threshold of 1 allows RA1-RA3.
% 
% Parameters:
% - values (numeric array): Matrix representing iEEG data of shape samples X channels.
% - chLabels (cell array): Cell array containing channel labels corresponding to the columns of the data matrix.
% - soft (logical, optional): Allow for soft bipolar referencing, considering multiple next-numbered contacts. Default is true.
% - softThres (integer, optional): Number of next-numbered contacts to consider in soft referencing. Default is 1.
%
% Returns:
% - values (numeric array): Bipolar-referenced EEG data matrix.
% - bipolar_labels (cell array): Channel labels for the bipolar-referenced data.
%
% Example:
% values = randn(100, 5);  % Replace with your actual EEG data
% chLabels = {'Fp1', 'Fp2', 'C3', 'C4', 'O1'};
% [values, bipolar_labels] = bipolar(values, chLabels);
% [values, bipolar_labels] = bipolar(values, chLabels, [], 2);

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

% locs = {};
% anatomy = {};

%% Initialize output variables
nchs = size(values,2);
chs_in_bipolar = nan(nchs,2);
old_values = values;

%% Decompose chLabels
labels = clean_labels(chLabels);
[elecs,numbers] = decompose(labels);
bipolar_labels = cell(nchs,1);

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
    label_num = numbers(ch);
    if ~isnan(label_num)
        % see if there exists one higher
        if soft
            label_nums = [label_num + 1:label_num + softThres + 1];
        else
            label_nums = [label_num+1];
        end
    
        for label_num_i = label_nums
            higher_label = [label_non_num,sprintf('%d',label_num_i)];
            if sum(strcmp(labels(:,1),higher_label)) > 0
                higher_ch = find(strcmp(labels(:,1),higher_label),1);
                out = old_values(:,ch)-old_values(:,higher_ch);
                bipolar_label = [label,'-',higher_label];
                chs_in_bipolar(ch,:) = [ch,higher_ch];
                break
            end
        end
        if strcmp(label,'FZ') % exception for FZ and CZ
            if sum(strcmp(labels(:,1),'CZ')) > 0
                higher_ch = find(strcmp(labels(:,1),'CZ'));
                out = old_values(:,ch)-old_values(:,higher_ch);
                bipolar_label = [label,'-','CZ'];
                chs_in_bipolar(ch,:) = [ch,higher_ch];
            end
        end
    end
    values(:,ch) = out;
    bipolar_labels{ch} = bipolar_label;
    
end

% %% Get location of midpoint between the bipolar channels
% if ~isempty(locs)
%     mid_locs = nan(length(bipolar_labels),3);
%     mid_anatomy = cell(length(bipolar_labels),1);
%     for i = 1:length(bipolar_labels)
% 
%         % Get the pair
%         ch1 = chs_in_bipolar(i,1);
%         ch2 = chs_in_bipolar(i,2);
% 
%         if isnan(ch1) || isnan(ch2)
%             continue
%         end
% 
%         % get the locs
%         loc1 = locs(ch1,:);
%         loc2 = locs(ch2,:);
% 
%         % get midpoint
%         midpoint = (loc1 + loc2)/2;
%         mid_locs(i,:) = midpoint;
% 
% 
%     end
% else
%     mid_locs = [];
% end
% 
% %% Get anatomy
% if ~isempty(anatomy)
%     mid_anatomy = cell(length(bipolar_labels),1);
%     for i = 1:length(bipolar_labels)
% 
%         % Get the pair
%         ch1 = chs_in_bipolar(i,1);
%         ch2 = chs_in_bipolar(i,2);
% 
%         if isnan(ch1) || isnan(ch2)
%             continue
%         end
% 
%         
%         % get anatomy of each
%         anat1 = anatomy{ch1};
%         anat2 = anatomy{ch2};
%         midanat = [anat1,'-',anat2];
%         mid_anatomy{i} = midanat;
% 
%     end
% else
%     mid_anatomy = [];
% end

end

function [non_nums,nums] = decompose(labels)
non_nums = {};
nums = [];
for ich = 1:length(labels)
    label = labels{ich};
    %% Get the non-numerical portion
    label_num_idx = regexp(label,'\d');
    label_non_num = label(1:label_num_idx-1);
    non_nums{ich} = label_non_num;
    
    % get numerical portion
    label_num = str2num(label(label_num_idx:end));
    if isempty(label_num), label_num = nan; end
    nums(ich) = label_num;
end
end