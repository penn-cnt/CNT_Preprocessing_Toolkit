function plot_volcano(pc, pval, names)
global params
% calculate negative log10 of p-values
sigThres = 0.05;
pcThres = 0.4;
logThres = -log10(sigThres);
logPval = -log10(pval);
sigJudge = pval<sigThres;
pcJudge = abs(pc)>=pcThres & abs(pc)<1;
nlabel = length(find(sigJudge | pcJudge));

blue = params.darkCols(1,:);red =params.darkCols(2,:); 
col{1} = blue;
col{2} = red;
cols = cell2mat(col(sigJudge+1)');
% % find significantly differentially expressed genes
% sigGenes = pval < sigLevel;

% plot volcano plot
figure('Position',[0,0,700,500])
hold on
xlim([-1,1]);
ylim([0,3]);
line([-1, 1],[logThres,logThres],'Color','k','LineStyle','--','LineWidth',1)
line([0,0],[0,3],'Color','k','LineStyle','--','LineWidth',1)
scatter(pc, logPval, 400, cols, 'filled');
xlabel('Percent Change');
ylabel('-Log_{10} P');
set(gca,'FontName',params.font,'FontSize',params.fontsize-2)
a = scatter(nan,nan,400,col{1},'filled');
b = scatter(nan,nan,400,col{2},'filled');
alpha(0.5)
legend([a,b],{'Non-Sig','Sig'},'FontSize',params.fontsize-1);
if nlabel > 0
    pos = get(gca, 'Position');
    % stop = max(logPval)+0.15;
    stop = 2.5;
    space = 0.1;
    ypos = stop:-space:stop-space*(nlabel-1);
    ypos = ypos/3;
    ypos = ypos*pos(4)+pos(2);
    % label points with gene names
    pcSig = (pc(sigJudge | pcJudge)+1)*0.5;
    pcSig = pcSig*pos(3)+pos(1);
    pvalSig = logPval(sigJudge | pcJudge)/3;
    pvalSig = pvalSig*pos(4)+pos(2);
    namesLabel = names(sigJudge | pcJudge);
    [pcSig,I] = sort(pcSig);
    pvalSig = pvalSig(I);
    namesLabel = namesLabel(I);
    add = 0.03;
    addh = -0.05:0.1/(nlabel-1):0.05;
    annotation('textarrow',[pcSig(1)+addh(1),pcSig(1)],[pvalSig(1)+add,pvalSig(1)],'String',namesLabel(1), ...
            'FontSize', params.fontsize-4, 'FontName',params.font,'HeadStyle','plain','HorizontalAlignment','center');
    for i = 2:nlabel
        diff = pvalSig(i) - pvalSig(1:i-1);
        n = length(find(abs(diff) < 0.005));
        if addh(i) - (pos(2)+pos(4)) < 0.005
            addh(i) = -0.5*addh(i);
        end
        annotation('textarrow',[pcSig(i)+addh(i),pcSig(i)],[pvalSig(i)+add+n*0.035,pvalSig(i)],'String',namesLabel(i), ...
                'FontSize', params.fontsize-4, 'FontName',params.font,'HeadStyle','plain','HorizontalAlignment','center');
    end

end
