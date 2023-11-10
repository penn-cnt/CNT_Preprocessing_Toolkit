function plot_soz_scatter(nodeStrAll,numlabel,folderName)
global paths params
cols = params.lightCols;
cols = brighten(cols,0.2);
labels = unique(numlabel);
leg = {'Left SOZ','Right SOZ','Bilateral SOZ'};
leg = leg(labels);
tmp = strsplit(folderName,'_');
if strcmp(tmp{2},'LR')
    axisLabel = {'Left','Right'};
elseif strcmp(tmp{2},'SOZ')
    axisLabel = {'SOZ','Non-SOZ'};
end
if exist(strcat(paths.figPath,filesep,folderName),'dir') == 0
    mkdir(strcat(paths.figPath,filesep,folderName))
end
f = figure('Position',[0 0 700 500]);
for i = 1:size(nodeStrAll,1)
    for j = 1:length(labels)
        scatter(nodeStrAll(i,numlabel==j,1),nodeStrAll(i,numlabel==j,2),120,cols(j,:),'filled','MarkerFaceAlpha',.7);
        hold on
    end
    hold off
    title(params.shortList{i},'FontName',params.font,'FontSize',params.fontsize)
    legend(leg,'Location','SouthEast','AutoUpdate','off')
    set(gca,'FontName',params.font,'FontSize',params.fontsize-2)
    xlabel(axisLabel{1})
    ylabel(axisLabel{2})
    f.CurrentAxes.XLim(2) = max(f.CurrentAxes.XLim(2),f.CurrentAxes.YLim(2));
    f.CurrentAxes.YLim(2) = max(f.CurrentAxes.XLim(2),f.CurrentAxes.YLim(2));
    f.CurrentAxes.XLim(1) = min(f.CurrentAxes.XLim(1),f.CurrentAxes.YLim(1));
    f.CurrentAxes.YLim(1) = min(f.CurrentAxes.XLim(1),f.CurrentAxes.YLim(1));
    line(f.CurrentAxes.XLim,f.CurrentAxes.YLim,'Color','black','LineStyle','--')
    exportgraphics(gcf, strcat(paths.figPath,filesep,folderName,filesep,num2str(i),'.png'), 'Resolution', 300);
    saveas(gcf,strcat(paths.figPath,filesep,folderName,filesep,num2str(i),'.svg'))
end
close all