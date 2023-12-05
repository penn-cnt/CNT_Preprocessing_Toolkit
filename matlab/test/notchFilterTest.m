classdef notchFilterTest < matlab.unittest.TestCase

    methods (Test)
        function test_NotchFilter(tc)
            % Test with default parameters
            addpath(genpath('./..')); % always add to ensure loading of other files/func
            paths;
            load(fullfile(TESTDATA_DIR,'sampleData.mat'));
            
            values = notch_filter(old_values, fs);
            tc.verifyEqual(size(values), size(old_values), 'Output size mismatch');
            values = notch_filter(old_values, fs, 50, 6);
            tc.verifyEqual(size(values), size(old_values), 'Output size mismatch');
        end
    end

end
