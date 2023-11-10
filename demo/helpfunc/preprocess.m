function [full_data,keep,times] = preprocess(session,Info)
global params
% read in a meta info item correspond to a file
% return the preprocessed data, labels, fs, new electrode Ind file, if keep
% this file, and other sample info
%% Add path to this codebase
% mname = mfilename('fullpath');
% [filedir, ~, ~] = fileparts(fileparts(mname));
% addpath(genpath(filedir))
% if ~exist('IEEGToolbox','dir')==7 || ~exist('tools','dir')==7
%     try
%         addpath(genpath(strcat(fileparts(filedir),'/matlab')))
%     catch ME
%         assert(exist('IEEGToolbox','dir')==7,'CNTtools:dependencyUnavailable','IEEGToolbox not imported.')
%         assert(exist('tools','dir')==7,'CNTtools:dependencyUnavailable','Tools not imported.')
%     end
% end
% %% Read json login info
% login = read_json(which('config.json'));
% %% Get patient name
file_name = Info.filename;
%% Download data from ieeg.org
% rand time
init_2pm = 14*3600-Info.startTime;
ind_2pms = init_2pm:24*3600:Info.duration;
ind_2pms(find(ind_2pms<1)) = [];
if isempty(ind_2pms)
    ind_2pms = randi([3601,floor(Info.duration)-3601],1);
end
ranges = [max(1,ind_2pms'-3600),min(ind_2pms'+3600,floor(Info.duration)-120)]; % 1-3 pm index
nSession = size(ranges,1);
% get chans
selecElecs = eval(['Info.chan_',params.chans_to_use]);
% fetch data
full_data = {};
% full_labels = {};
keep = [];
for i = 1:params.nSeg
    time = randi(ranges(randi(min(nSession,3)),:),1);
    time = [time,time+120]; % 2min clip
    data = session.download_data(file_name, time(1), time(2), selecElecs);
    data.find_bad_chs();
    percent = sum(data.bad)/size(data.data,2);
    count = 0;
    while percent >= 0.2 && count < 10
        tmp_time = randi(ranges(randi(min(nSession,3)),:),1);
        tmp_time = [tmp_time,tmp_time+120];
        % time for different 2pm
        tmp = session.download_data(file_name, tmp_time(1), tmp_time(2),selecElecs);
        tmp.find_bad_chs();
%         tmpBad = identify_bad_chs(tmp.values,tmp.fs);
        percentBad = sum(tmp.bad)/size(data.data,2);
        if percentBad < percent
            data = tmp;
            percent = percentBad;
            time = tmp_time;
        end
        count = count + 1;
    end
    if strcmp(params.chans_to_use,'LR')
        % find bad channels, set the ind in elecInd to 0
        num_chan = length(data.ch_names);
        % update labels
        badLeft = data.bad(1:num_chan/2);
        badRight = data.bad(num_chan/2+1:end);
        badFull = badLeft | badRight;
        badFull = [badFull;badFull];
        data.ch_names = data.ch_names(~badFull);
        data.data = data.data(:,~badFull);
    else
        data.reject_artifact();
    end
    data.notch_filter();
    keep(i) = 1;
    if isempty(data.ch_names)
        keep(i) = 0;
    end
    full_data{i} = data;
    times(i,:) = time;
end
keep = any(keep);
