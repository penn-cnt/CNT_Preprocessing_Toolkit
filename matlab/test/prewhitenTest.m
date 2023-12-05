classdef prewhitenTest < matlab.unittest.TestCase

    methods (Test)
        function test_Prewhiten(tc)
            % Test with default parameters
            addpath(genpath('./..')); % always add to ensure loading of other files/func
            paths;
            load(fullfile(TESTDATA_DIR,'sampleData.mat'));
            
            values = pre_whiten(old_values);
            tc.verifyEqual(size(values), size(old_values), 'Output size mismatch');
        end
    end

end
