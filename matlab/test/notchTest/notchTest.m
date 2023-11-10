%% Test Class Definition
classdef notchTest < matlab.unittest.TestCase

    %% Test Method Block
    methods (Test)
        % includes unit test functions
        function testnotch(testCase)   
            % This part test for wrong input types
            % see https://www.mathworks.com/help/matlab/matlab_prog/types-of-qualifications.html
            % for qualification method
            addpath(genpath('./../..')); % always add to ensure loading of other files/func
            load notch_testInput.mat;
            test_values = notch_filter(old_values,fs);
            testCase.verifyEqual(test_values,filtered_values,'AbsTol',10);
        end
    end
end