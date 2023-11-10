function select_chan(dataset)

load(which(strcat(dataset,'_metaDataFull.mat')))
load(which(strcat(dataset,'_graywhite.mat')))

% for every file
for i = 1:length(metaData)
    
    % clean channels
    [chans,~,~] = clean_labels(metaData(i).channels);

    if data(i).has_atropos
        metaData(i).gw = data(i).gm_wm;
        judge = cellfun(@(x) strcmp(x,'gray matter')|strcmp(x,'white matter'),data(i).gm_wm);
        metaData(i).chan_gw = chans(judge);
        metaData(i).gray = cellfun(@(x) strcmp(x,'gray matter'),data(i).gm_wm(judge));
        metaData(i).chan_gray = metaData(i).chan_gw(metaData(i).gray);
        metaData(i).chan_white = metaData(i).chan_gw(~metaData(i).gray);
    end

    % join to a string
    chanstr = strjoin(chans);

    tofind = {metaData(i).tofindA, metaData(i).tofindB, metaData(i).tofindC};
    tmp = {};
    for ind = 1:3
        for j = 1:12
            if ismember(strcat('L',tofind{ind},num2str(j)),chans) && ismember(strcat('R',tofind{ind},num2str(j)),chans) 
                tmp = [tmp,{strcat('L',tofind{ind},num2str(j));strcat('R',tofind{ind},num2str(j))}];
            end
        end
    end
    metaData(i).chan_LR = reshape(tmp',[],1);
    
    if ~isempty(metaData(i).chan_LR)
        metaData(i).LR = 1;
    else
        metaData(i).LR = 0;
    end
end
% 
% % remove files without LR paired chans
% subMeta = metaData;
% count = 1;
% while count <= length(subMeta)
%     if subMeta(count).LR == 0
%         subMeta(count) = [];
%     else
%         count = count + 1;
%     end
% end

patientList = metaData;
save(strcat('meta',filesep,dataset,'_subMeta.mat'),'patientList')

