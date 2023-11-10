function bar_error_plot(full_data,full_error,cols,xlabels)
global params
nbars = size(full_data,2);
ngroups = size(full_data,1);

fig = figure('Position',[0 0 1400 500]);
% b = bar(full_data,'grouped','EdgeColor','none', 'FaceColor','flat','FaceAlpha',0.7);
% for i = 1:nbars
%     b(i).CData = repmat(flipud([0.9-0.1*i]'),6,3);
% end
% l = legend(freqBands,'Location','northwest');
% l.AutoUpdate = 'off';
% hold all;
b = bar(full_data,'grouped','EdgeColor','none', 'FaceColor','flat','FaceAlpha',0.7);
for i = 1:nbars
    b(i).BarWidth = 0.95;
    b(i).CData = reshape(cols(:,i,:),[ngroups,3]);
end
hold on
xticklabels(xlabels);
ylabel('Correlation','FontSize',params.fontsize,'FontWeight','bold');
set(gca,'FontName',params.font,'FontSize',params.fontsize);
x = nan(nbars, ngroups);
for i = 1:nbars
    x(i,:) = b(i).XEndPoints;
    for j = 1:ngroups
        errorbar(x(i,j),full_data(j,i), [],full_error(j,i), '-','Color','k','LineWidth',0.75);%cols(j,i,:));
    end
end