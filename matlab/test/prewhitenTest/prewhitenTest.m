%% Test Class Definition
classdef prewhitenTest < matlab.unittest.TestCase
    % This is a test class defined for the decompose_labels function
    % Import test cases from decompLabel_testInput.csv file, which include 
    % input, expected output, and notes describes the test scenairo of the
    % case, the notes would be used as test case names and the other three
    % would be used to run the download_ieeg_data function. 

    %% Test Method Block
    methods (Test)
        % includes unit test functions
        function testnotch(testCase)   
            % This part test for wrong input types
            % see https://www.mathworks.com/help/matlab/matlab_prog/types-of-qualifications.html
            % for qualification method
            addpath(genpath('./../..')); % always add to ensure loading of other files/func
            load prewhiten_testInput.mat;
            f = @() pre_whiten(old_values);
            testCase.verifyWarningFree(f)
        end
    end
end