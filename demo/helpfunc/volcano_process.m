function volcano_process(filename,ptype)
global paths params
data = table2array(readtable(strcat(paths.MLPath,filesep,filename,'.csv'),'ReadVariableNames',false));
folderName = strrep(filename,'_sozL','');
folderName = strrep(folderName,'_sozR','');
folderName = strrep(folderName,'_sozB','');
subtitle = {};
if contains(filename,'_temp')
    subtitle = [subtitle,'Temporal Lobe SOZ'];
end
if contains(filename,'_nontemp')
    subtitle = [subtitle,'Non-temporal SOZ'];
end
if contains(filename,'_good')
    subtitle = [subtitle,'Good Outcome'];
end
if contains(filename,'_sozL')
    subtitle = [subtitle,'Left SOZ'];
end
if contains(filename,'_sozR')
    subtitle = [subtitle,'Right SOZ'];
end
if contains(filename,'_sozB')
    subtitle = [subtitle,'Bilateral SOZ'];
end
tmp = strsplit(filename,'_');
if strcmp(tmp{2},'LR')
    titleText = {'Left/Right Connectivity Strength Difference',strjoin(subtitle,' - ')};
    data(:,4) = -data(:,4);
elseif strcmp(tmp{2},'SOZ')
    titleText = {'SOZ/non−SOZ Connectivity Strength Difference',strjoin(subtitle,' - ')};
end
switch ptype
    case 'p'
        ind = 5;
    case 'q'
        ind = 6;
    case 'bh'
        ind = 7;
end
plot_volcano(data(:,4),data(:,ind),params.shortList)
title(titleText,'FontName',params.font,'FontSize',params.fontsize)
if exist(strcat(paths.figPath,filesep,folderName),'dir') == 0
    mkdir(strcat(paths.figPath,filesep,folderName))
end
exportgraphics(gcf, strcat(paths.figPath,filesep,folderName,filesep,filename,'_',ptype,'.png'), 'Resolution', 300);
saveas(gcf,strcat(paths.figPath,filesep,folderName,filesep,filename,'_',ptype,'.svg'))
close all