function output = findNonIEEG_param(fname)
    addpath(genpath('./../..')); % always add to ensure loading of other files/func

    inputData = table2cell(readtable(fname,'Delimiter',',')); % read test cases
    % format into structs
    output = struct();
    countNonIEEG = 0;countIEEG = 0;
    for i = 1:size(inputData,1)
        if inputData{i,2} == 1
            countNonIEEG = countNonIEEG+1;
            eval(strcat('output.NonIEEG',num2str(countNonIEEG),'=inputData(',num2str(i),',:);'))
        else
            countIEEG = countIEEG+1;
            eval(strcat('output.IEEG',num2str(countIEEG),'=inputData(',num2str(i),',:);'))
        end
    end
end