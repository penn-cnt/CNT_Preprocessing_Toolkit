function data = get_ieeg_data(login_name, pwfile, fname, start, stop, varargin)

% This function download data from ieeg portal with filename, time range,
% and user information provided
% Inputs:
%       login_name: user name of ieeg portal account
%       pwfile: password file of ieeg portal account
%       fname: name of to be downloaded file
%       start: start time of to be pulled data within file, in seconds
%       stop: stop time of to be pulled data within file, in seconds
%       selecElecs: cell array of electrode list of channel lables
%       or array of int channel indices to be included
%       ignoreElecs: cell array of electrode list of channel lables
%       or array of int channel indices to be ignored
%       outputfile: path to save downloaded data
% Output:
%       data: a struct of field 'fs', 'values', 'file_name', 'chLabels',
%       'duration', and 'ann'

%% Added 1/22/23, Haoer

defaults = {{},{},''};

for i = 1:length(varargin)
    if isempty(varargin{i})
        varargin{i} = defaults{i};
    end
end

p = inputParser;
addRequired(p, 'login_name', @(x) isstring(x) || ischar(x));
addRequired(p, 'pwfile', @(x) isstring(x) || ischar(x));
addRequired(p, 'fname', @(x) isstring(x) || ischar(x));
addRequired(p, 'start', @isnumeric);
addRequired(p, 'stop', @isnumeric);
addOptional(p, 'selecElecs', defaults{1}, @(x) iscell(x) || isnumeric(x) || isstring(x) || ischar(x));
addOptional(p, 'ignoreElecs', defaults{2}, @(x) iscell(x) || isnumeric(x) || isstring(x) || ischar(x));
addOptional(p, 'outputfile', defaults{3}, @(x) isstring(x) || ischar(x));
parse(p, login_name, pwfile, fname, start, stop, varargin{:});

% Access parsed values
login_name = p.Results.login_name;
pwfile = p.Results.pwfile;
fname = p.Results.fname;
start = p.Results.start;
stop = p.Results.stop;
selecElecs = p.Results.selecElecs;
ignoreElecs = p.Results.ignoreElecs;
outputfile = p.Results.outputfile;
% remove potential blanks/quotes
fname = strip(fname);
fname = strip(fname,'"');
fname = strip(fname,"'");

attempt = 1;

while attempt < 100
    try
        session = IEEGSession(fname, login_name, pwfile); % check if can fetch this file
        channelLabels = session.data.channelLabels; % get channel info

        % check file is not empty
        assert(~isempty(channelLabels),'CNTtools:emptyFile','No channels.');
        dura = session.data.rawChannels(1).get_tsdetails.getDuration/1e6;  % get duration info
        % test if time range valid
        assert(stop > start,'CNTtools:invalidTimeRange','Stop before start.')
        assert(start >= 0 && stop <= dura, 'CNTtools:invalidTimeRange', 'Time outrange.')
        channelLabels = clean_labels(channelLabels);
        allChannelLabels = channelLabels;
        nchs = length(allChannelLabels);
        allChanInds = [1:nchs];
        chanInds = allChanInds;
        if ~isempty(selecElecs)
            if ~iscell(selecElecs)
                try
                    if isstring(selecElecs) || ischar(selecElecs)
                        selecElecs = cellstr(selecElecs);
                    elseif isa(selecElecs,'numeric')
                        selecElecs = num2cell(selecElecs);
                    end
                catch ME
                    throw(MException('CNTtools:invalidInputType','Electrode labels should be a cell array.'))
                end
            end
            if isa(selecElecs{1},'numeric')
                chanInds = selecElecs(cellfun(@(x) x >= 1 & x <= nchs, selecElecs));
                if length(chanInds) < length(selecElecs)
                    warning("CNTtools:invalidChannelID, invalid channels ignored.");
                end
                channelLabels = allChannelLabels(cellfun(@(x) x, chanInds));
                chanInds = cell2mat(chanInds);
            elseif isstring(selecElecs{1}) || ischar(selecElecs{1})
                selecElecs = clean_labels(selecElecs);
                [~, chanInds] = ismember(selecElecs, allChannelLabels);
                allChanInds(chanInds == 0) = [];
                channelLabels = allChannelLabels(chanInds);
                %channelIDs = num2cell(channelIDs);
                if length(chanInds) < length(selecElecs)
                    warning("CNTtools:invalidChannelID, invalid channels ignored.");
                end
            end
        end
        if ~isempty(ignoreElecs)
            if ~iscell(ignoreElecs)
                try
                    if isstring(selecElecs) || ischar(ignoreElecs)
                        ignoreElecs = cellstr(ignoreElecs);
                    elseif isa(ignoreElecs,'numeric')
                        ignoreElecs = num2cell(ignoreElecs);
                    end
                catch ME
                    throw(MException('CNTtools:invalidInputType','Electrode labels should be a cell array.'))
                end
            end
            if isa(ignoreElecs{1},'numeric')
                chanInds = allChanInds;
                chanInds(cellfun(@(x) x >= 1 & x <= nchs, ignoreElecs)) = [];
                %channelIDs = num2cell(channelIDs);
                if length(chanInds) > nchs - length(ignoreElecs)
                    warning("CNTtools:invalidChannelID, invalid channels ignored.");
                end
                channelLabels = allChannelLabels(chanInds);
            elseif isstring(ignoreElecs{1}) || ischar(ignoreElecs{1})
                ignoreElecs = clean_labels(ignoreElecs);
                channelLabels = allChannelLabels(cellfun(@(x) ~ismember(x,ignoreElecs), allChannelLabels));
                [~, chanInds] = ismember(channelLabels, allChannelLabels);
                %channelIDs = num2cell(channelIDs);
                if length(chanInds) > nchs - length(ignoreElecs)
                    warning("CNTtools:invalidChannelID, invalid channels ignored.");
                end
            end
        end

        nchs = size(channelLabels,1);
        % get fs
        data.fs = session.data.sampleRate;
        % Convert times to indices
        run_idx = round(start*data.fs):round(stop*data.fs);
        if ~isempty(run_idx)
            try
                values = session.data.getvalues(run_idx,chanInds);
            catch ME
                % Break the number of channels in half to avoid wacky server errors
                values1 = session.data.getvalues(run_idx,chanInds(1:floor(nchs/4)));
                values2 = session.data.getvalues(run_idx,chanInds(floor(nchs/4)+1:floor(2*nchs/4)));
                values3 = session.data.getvalues(run_idx,chanInds(floor(2*nchs/4)+1:floor(3*nchs/4)));
                values4 = session.data.getvalues(run_idx,chanInds(floor(3*nchs/4)+1:nchs));
                values = [values1,values2,values3,values4];
            end
        else
            values = [];
        end

        data.values = values;

        % get file name
        data.file_name = session.data.snapName;

        % Get ch labels
        data.chLabels = channelLabels;

        % get duration (convert to seconds)
        data.duration = stop-start;

        % Get annotations
        n_layers = length(session.data.annLayer);

        for ai = 1:n_layers
            a = session.data.annLayer(ai).getEvents(0);
            n_ann = length(a);
            for i = 1:n_ann
                event(i).start = a(i).start/(1e6);
                event(i).stop = a(i).stop/(1e6); % convert from microseconds
                event(i).type = a(i).type;
                event(i).description = a(i).description;
            end
            ann.event = event;
            ann.name = session.data.annLayer(ai).name;
            data.ann(ai) = ann;
        end
        % break out of while loop
        break

        % If server error, try again (this is because there are frequent random
        % server errors).
    catch ME
        if contains(ME.message,'Authentication')
            throw(MException('CNTtools:invalidLoginInfo','Invalid login info.'));
        elseif contains(ME.message,'No snapshot with name')
            throw(MException('CNTtools:invalidFileName','Invalid filename.'));
        elseif contains(ME.message,'positive integers or logical values')
            throw(MException('CNTtools:emptyFile','No channels.'));
        elseif contains(ME.message,'503') || contains(ME.message,'504') || ...
                contains(ME.message,'502') || contains(ME.message,'500')
            attempt = attempt + 1;
            fprintf('Failed to retrieve ieeg.org data, trying again (attempt %d)\n',attempt);
        else
            throw(ME);
        end
    end

end

%% Delete session
session.delete;
clearvars -except data outputfile
if ~isempty(outputfile)
    save(outputfile,'data');
end