%% Test Class Definition
classdef carTest < matlab.unittest.TestCase
    % This is a test class defined for the decompose_labels function
    % Import test cases from decompLabel_testInput.csv file, which include 
    % input, expected output, and notes describes the test scenairo of the
    % case, the notes would be used as test case names and the other three
    % would be used to run the download_ieeg_data function. 

    %% Test Method Block
    methods (Test)
        % includes unit test functions
        function testCAR(testCase)   
            % This part test for wrong input types
            % see https://www.mathworks.com/help/matlab/matlab_prog/types-of-qualifications.html
            % for qualification method
            addpath(genpath('./..')); % always add to ensure loading of other files/func
            paths;
            load(fullfile(TESTDATA_DIR,'reref_testInput.mat'));
            f = @() car(old_values,labels);
            testCase.verifyWarningFree(f)
            sim_data = [1,3,5;4,7,10;15,20,25];
            sim_result = [-2,0,2;-3,0,3;-5,0,5];
            sim_labels = {'CAR-1','CAR-2','CAR-3'};
            out = car(sim_data,sim_labels);
            testCase.verifyEqual(out,sim_result);
            
        end
    end
end