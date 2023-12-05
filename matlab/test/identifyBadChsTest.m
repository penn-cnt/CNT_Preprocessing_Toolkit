%% Test Class Definition
classdef identifyBadChsTest < matlab.unittest.TestCase
    % This is a test class defined for the identify_bad_chs function 
    %% Test Method Block
    methods (Test)
        % includes unit test functions
        function test_identifyBadChs(testCase)   
            % This part test for wrong input types
            % see https://www.mathworks.com/help/matlab/matlab_prog/types-of-qualifications.html
            % for qualification method
            addpath(genpath('./..')); % always add to ensure loading of other files/func
            paths;
            load(fullfile(TESTDATA_DIR,'sampleData.mat'));
            f = @() identify_bad_chs(old_values,fs);
            testCase.verifyWarningFree(f)
        end
    end
end
