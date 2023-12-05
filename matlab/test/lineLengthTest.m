classdef lineLengthTest < matlab.unittest.TestCase

    methods (Test)
        function testLineLength(tc)
            addpath(genpath('./..')); 
            % Generate example data with known line lengths
            x = [1 2 3 4 5; 2 3 nan 5 6; 4 3 2 1 0]'; % Example data
            expected_ll = [1 1 1]; % Known line lengths

            % Call the function under test
            ll = line_length(x);

            % Assertions
            tc.verifyEqual(size(ll), [1, size(x, 2)], 'Output size mismatch');
            tc.verifyEqual(ll, expected_ll, 'Line lengths mismatch');
        end
    end

end
