classdef plotTest < matlab.unittest.TestCase

    methods (Test)
        function test_BandpassFilter(tc)
            % Test with default parameters
            addpath(genpath('./..')); % always add to ensure loading of other files/func
            load reref_testInput.mat;
            f = @() plot_ieeg_data(old_values(1:10000,:),labels,[1:10000]);
            tc.verifyWarningFree(f);
            close all
        end
    end

end
