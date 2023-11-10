function extractMLData(nodeStrAll,path)
pairT_LR = zeros(size(nodeStrAll,1),7); 
for i = 1:size(nodeStrAll,1)
    pairT_LR(i,1:2) = squeeze(mean(nodeStrAll(i,:,:),2,'omitnan'));
    pairT_LR(i,3) = mean(nodeStrAll(i,:,1)-nodeStrAll(i,:,2),'omitnan');
    pairT_LR(i,4) = mean((nodeStrAll(i,:,1)-nodeStrAll(i,:,2))./nodeStrAll(i,:,2),'omitnan');
    [~, pairT_LR(i,5),~,stats] = ttest(nodeStrAll(i,:,1), nodeStrAll(i,:,2));
    pairT_LR(i,8) = stats.tstat / sqrt(stats.df);
end
[~,pairT_LR(:,6)] = mafdr(pairT_LR(:,5));
pairT_LR(:,7) = mafdr(pairT_LR(:,5),'BHFDR',true);
writematrix(pairT_LR,path)
end