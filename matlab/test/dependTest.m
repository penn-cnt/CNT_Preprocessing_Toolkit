%% Test Class Definition
classdef dependTest < matlab.unittest.TestCase
    %% Test Method Block
    methods (Test)
        % includes unit test functions
        function testDepends(testCase)   
            % see https://www.mathworks.com/help/matlab/matlab_prog/types-of-qualifications.html
            % for qualification method
            % addpath(genpath('./../..')); % always add to ensure loading of other files/func
            assert(exist('IEEGToolbox','dir')==7,'CNTtools:dependencyUnavailable','IEEGToolbox not imported.')
            assert(exist('tools','dir')==7,'CNTtools:dependencyUnavailable','Tools not imported.')
        end
    end
end