%% Test Class Definition
classdef getIEEGDataTest < matlab.unittest.TestCase
    % This is a test class defined for the get_ieeg_data function
    % Import test cases from test_getData.csv file, which include filename,
    % start time, stop time and notes describes the test scenairo of the
    % case, the notes would be used as test case names and the other three
    % would be used to run the get_ieeg_data function. Login usrname
    % and password file would be imported from the config.json file.
    %
    % From this website to learn how to incorporate outside data
    % https://www.mathworks.com/help/matlab/matlab_prog/use-external-parameters-in-parameterized-test.html
    % Define parameters below
    properties (TestParameter)
        Data
    end
    methods (TestClassSetup)
        function auth(testCase)
            runtests("authTest")
        end
    end
    methods (TestParameterDefinition, Static)
        function Data = getData()            
            addpath(genpath(pwd));
            addpath(genpath([pwd '/..']));
            Data = mat2cell(table2cell(readtable('getIEEGData_testInput.csv','Delimiter',',')), ...
                ones(size(readtable('getIEEGData_testInput.csv','Delimiter',','),1), 1));
        end
    end
    %% Test Method Block
    methods (Test)
        % includes unit test functions
        function testGetData(testCase,Data)
            % This part test for wrong input types
            % see https://www.mathworks.com/help/matlab/matlab_prog/types-of-qualifications.html
            % for qualification method
            addpath(genpath('./..'));% always add to ensure loading of other files/func
            paths;
            files = dir(fullfile(USER_DIR,'*.json'));
            f = fullfile(files(1).folder, files(1).name);
            login = jsondecode(fileread(f));
            selecElecs = {};
            ignoreElecs = {};
            if ~isempty(Data{4});eval(['selecElecs = ',Data{4},';']);end
            if ~isempty(Data{5});eval(['ignoreElecs = ',Data{5},';']);end
            f = @() get_ieeg_data(login.usr, login.pwd, 'I001_P034_D01', Data{1},Data{2},selecElecs,ignoreElecs);
            if strcmp(Data{3},'/')
                testCase.verifyWarningFree(f)
            else
                testCase.verifyError(f,Data{3})
            end
        end

    end
end