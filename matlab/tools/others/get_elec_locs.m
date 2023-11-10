function output = get_elec_locs(fileID, chLabels,filename)
% Get electrode locations for specified channel labels from a file.

% Parameters:
% - fileID (string, char): iEEG data filename in iEEG.org, should contain
% patient info, should match to filename in first column of the elec locs file
% - chLabels (cell array): Channel labels for which to retrieve electrode locations.
% - filename (string, char): Path to the file containing electrode locations.

% Returns:
% - output (matrix): Matrix containing electrode locations corresponds to channel labels.
%                        Unavailable channel locations filled with nan.

% Example:
% chLabels = {'Fp1', 'Fp2', 'C3', 'C4'};
% filename = 'electrode_locations.csv';
% output = get_elec_locs(chLabels, filename);

p = inputParser;
addRequired(p, 'fileID', @(x) isstring(x) || ischar(x));
addRequired(p, 'chLabels', @(x) iscell(x) || isstring(x) || ischar(x));
addRequired(p, 'filename', @(x) (isstring(x) || ischar(x)) && exist(x,'file') == 2);
parse(p, fileID, chLabels, filename);
fileID = p.Results.fileID;
chLabels = p.Results.chLabels;
filename = p.Results.filename;

if ~iscell(chLabels)
    try
        chLabels = cellstr(chLabels); 
    catch ME
        throw(MException('CNTtools:invalidInputType','Electrode labels should be a cell array.'))
    end
end


elec_locs = table2cell(readtable(filename));
available_pts = unique(elec_locs(:,1));
match = cellfun(@(x) contains(fileID,x) && ~isempty(x),available_pts);
output = nan(size(chLabels,1),3);
try
    fullFileID = available_pts{match};
    % clean both
    elec_locs = elec_locs(cellfun(@(x) strcmp(x,fullFileID), elec_locs(:,1)),:);
    labels = elec_locs(:,2);
    labels = clean_labels(labels);
    chLabels = clean_labels(chLabels);
    [Lia,locb] = ismember(chLabels,labels);
    output(Lia,:) = cell2mat(elec_locs(locb(Lia),3:5));
catch
    warning(['No match electrode location info were indentified, pseudo-laplacian ' ...
        're-referencing where Channel i is referenced to the average signal of Channel ' ...
        'i-1 and Channel i+1 would be done.'])
end
