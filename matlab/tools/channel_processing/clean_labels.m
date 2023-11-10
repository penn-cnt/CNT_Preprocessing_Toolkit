function clean_chs = clean_labels(chLabels)
% Clean and standardize electrode labels.

% Parameters:
% - chLabels (cell, string, or char): Cell array, string, or char array containing electrode labels.

% Returns:
% - clean_chs (cell): Cell array of cleaned and standardized electrode labels.

p = inputParser;
addRequired(p, 'chLabels', @(x) iscell(x) || isstring(x) || ischar(x));
parse(p, chLabels);
chLabels = p.Results.chLabels;

% assume cell format of channel labels
if ~iscell(chLabels)
    try
        chLabels = cellstr(chLabels); 
    catch ME
        throw(MException('CNTtools:invalidInputType','Electrode labels should be a cell array.'))
    end
end
% end of added part

clean_chs = cell(length(chLabels),1);
% elecs = cell(length(chLabels),1);
% numbers = nan(length(chLabels),1);

for ich = 1:length(chLabels)
    label = chLabels{ich};
    %% if it's a string, convert it to a char
    if isa(label,'string')
        label = convertStringsToChars(label);
    end
    %% Remove leading zero
    % get the non numerical portion
    label_num_idx = regexp(label,'\d');
    if ~isempty(label_num_idx)
        label_non_num = label(1:label_num_idx-1);
        label_num = label(label_num_idx:end);
        % Remove leading zero
        if strcmp(label_num(1),'0')
            label_num(1) = [];
        end
        label = [label_non_num,label_num];
    end
    
    %% Remove 'EEG '
    eeg_text = 'EEG ';
    if contains(label,eeg_text)
        eeg_pos = regexp(label,eeg_text);
        label(eeg_pos:eeg_pos+length(eeg_text)-1) = [];
    end
    
    %% Remove '-Ref'
    ref_text = '-Ref';
    if contains(label,ref_text)
        ref_pos = regexp(label,ref_text);
        label(ref_pos:ref_pos+length(ref_text)-1) = [];
    end
    
    %% Remove spaces
    if contains(label,' ')
        space_pos = regexp(label,' ');
        label(space_pos) = [];
    end
    
    %% Remove '-'
    label = strrep(label,'-','');
    
    %% Remove CAR
    label = strrep(label,'CAR','');
    
    %% Switch HIPP to DH, AMY to DA
    % this may come back to bite me
    label = strrep(label,'HIPP','DH');
    label = strrep(label,'AMY','DA');

    %% Fill the clean label
    clean_chs{ich} = label;
%     
    if contains(label,'Fp1','ignorecase',true) && ~contains(label,'LFP1','ignorecase',true)
        clean_chs{ich} = 'Fp1';
    end
    
    if contains(label,'Fp2','ignorecase',true)  && ~contains(label,'LFP2','ignorecase',true)
        clean_chs{ich} = 'Fp2';
    end
    
end
end