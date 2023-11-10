% metaData = table2struct(readtable('MUSC_filelist.csv','Delimiter',',','Format','auto'));
load('meta/MUSC_metaData.mat')
login = read_json(which('config.json'));
for i = 1:length(metaData)
    if isempty(metaData(i).duration)
        data = fetch_ieeg_info(metaData(i).filename, login.usr, login.pwd);
        metaData(i).duration = data.duration;
        metaData(i).channels = data.chLabels;
        metaData(i).fs = data.fs;
        metaData(i).chanstr = strjoin(metaData(i).channels');
    end
end
save('meta/MUSC_metaData.mat','metaData');

function data = fetch_ieeg_info(fname, login_name, pwfile)

try
    session = IEEGSession(fname, login_name, pwfile);
    channelLabels = session.data.channelLabels(:,1);
    % get fs
    data.fs = session.data.sampleRate;

    % Get ch labels
    data.chLabels = channelLabels;
    if size(channelLabels,1)>0
        % get duration (convert to seconds)
        data.duration = session.data.rawChannels(1).get_tsdetails.getDuration/1e6;
    else
        data.duration = nan;
    end
    session.delete;
    clearvars -except data
catch ME
    data.fs = [];
    data.chLabels = {};
    data.duration = [];
end
end
