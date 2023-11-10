function plot_paired_line(data)
global params
col1 = params.ref(1).col;col2 = params.ref(2).col;
% Get the number of groups
ngroups = length(data);
assert(ngroups ==2, 'This functions is only for paired comparison.')
ncomp = size(data{1},2);
nsample = size(data{1},1);
% Plot the pre/post data for each group
pre = data{1};
post = data{2};
groupCenters = @(nGroups,nMembers,interGroupSpace) ...
    nGroups/2+.5 : nGroups+interGroupSpace : (nGroups+interGroupSpace)*nMembers-1;
xpos = groupCenters(ngroups, ncomp, 1);
width = 0.7;
figure('Position',[0,0,800,400]);
hold on
for i = 1:ncomp
    for j = 1:nsample
        plot([xpos(i)-width, xpos(i)+width], [pre(j,i), post(j,i)], 'Color', 'black');
    end
    % Plot the pre/post data with lines connecting the pre/post dots
    h1 = plot((xpos(i)-width).*ones(nsample,1), pre(:,i), 'o', 'Color', col1,'MarkerFaceColor',[1,1,1],'LineWidth',1,'MarkerSize',8);
    h2 = plot((xpos(i)+width).*ones(nsample,1), post(:,i), 'o', 'Color', col2,'MarkerFaceColor',[1,1,1],'LineWidth',1,'MarkerSize',8);
end
legend([h1,h2],{params.ref.name});
% Add a legend and axis labels
ylabel('Reliability')
xlabel('% Electrode Removed')
set(gca,'FontName','Avenir','FontSize',14)
labels = cellstr(num2str(params.perc'*100,'%.0f%%'))';
set(gca,'XTick',xpos,'XTickLabels',labels)
end