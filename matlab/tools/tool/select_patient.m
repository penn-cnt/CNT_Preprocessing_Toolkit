for i = 1:length(metaData)
    [chans,~,~] = decompose_labels(metaData(i).channels);
    chanstr = strjoin(chans);
    judge = [];
    judgemat = zeros(3,12);
    elecInd = char(65:67);
    for ind = 1:3
        for j = 1:12
            if ismember(strcat('L',elecInd(ind),num2str(j)),chans) && ismember(strcat('R',elecInd(ind),num2str(j)),chans) 
                judgemat(ind,j) = 1;
            end
        end
    end

    if any(any(judgemat))
        metaData(i).LR = 1;
        metaData(i).elecInd = judgemat;
    else
        metaData(i).LR = 0;
        metaData(i).elecInd = judgemat;
    end
end

subMeta = metaData;
count = 1;
while count <= length(subMeta)
    if subMeta(count).LR == 0
        subMeta(count) = [];
    else
        count = count + 1;
    end
end

for i = 1:length(subMeta)
    subMeta(i).count = length(find(subMeta(i).elecInd));
    ABC = 'ABC';
    subMeta(i).ABC = [];
    for j = 1:3
        if length(find(subMeta(i).elecInd(j,:))) == 12
            subMeta(i).ABC = [subMeta(i).ABC, ABC(j)];
        end
    end
end
soz = readtable('soz.csv');
soz = table2cell(soz);
soz(:,2) = cellfun(@(x) lower(x),soz(:,2),'UniformOutput',false);
for i = 1:length(subMeta)
    tmp = strsplit(subMeta(i).filename,'_'); 
    name = tmp{1};
    [~,ind] = ismember(name,soz(:,1));
    if ind > 0
        subMeta(i).soz = soz{ind,2};
    end
end

subSubMeta = subMeta;
count = 1;
while count <= length(subSubMeta)
    if ~strcmp(subSubMeta(count).ABC,'ABC')
        subSubMeta(count) = [];
    else
        count = count + 1;
    end
end
