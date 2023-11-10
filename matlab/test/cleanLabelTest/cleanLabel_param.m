function output = decompLabel_param(fname)
    addpath(genpath('./../..')); % always add to ensure loading of other files/func

    inputData = table2cell(readtable(fname,'Delimiter',',')); % read test cases
    % format into structs
    output = struct();
    for i = 1:size(inputData,1)
        eval(strcat('output.',inputData{i,2},'=inputData(',num2str(i),',:);'))
    end
end