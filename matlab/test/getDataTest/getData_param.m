function output = getData_param(fname)
    addpath(genpath('./../..')); % always add to ensure loading of other files/func

    inputData = table2cell(readtable(fname,'Delimiter',',','Format','auto')); % read test cases
    % format into struct
    output = struct();
    for i = 1:size(inputData,1)
        eval(strcat('output.',string(inputData{i,size(inputData,2)}),'={inputData{',num2str(i),',1:size(inputData,2)-1}};'))
    end
end