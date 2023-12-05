classdef bandPowerTest < matlab.unittest.TestCase

    methods (Test)
        function testBandPowerAbsolute(tc)
            addpath(genpath('./..')); 
            % Generate example data with known band power in the alpha range
            fs = 250;
            duration = 10; % seconds
            time = [0:1/fs:duration-1/fs]';
            alpha_band = [8, 12];
            alpha_power = 0.5; % Known alpha band power

            data = zeros(length(time), 1);
            data = data + sin(2*pi*10*time) + 0.1 * randn(size(time)); % Alpha band (10 Hz)

            % Call the function under test
            bp = band_power(data, fs, alpha_band);

            % Assertions
            tc.verifyEqual(bp, alpha_power, 'Alpha band power mismatch', 'AbsTol', 0.1); % Allow some tolerance

            % Generate example data
            data = randn(100, 5);
            fs = 250;
            band = [1, 30];

            % Call the function under test
            bp = band_power(data, fs, band);

            % Assertions
            tc.verifyEqual(size(bp), [1, size(data, 2)], 'Band power size mismatch');
            tc.verifyGreaterThan(bp, 0, 'Band power should be greater than zero');
        end

        function testBandPowerRelative(tc)
            addpath(genpath('./..')); 
            % Generate example data with known band power in the alpha range
            fs = 250;
            duration = 10; % seconds
            time = [0:1/fs:duration-1/fs]';
            
            % Simulate data with power in two frequency bands
            alpha_band = [8, 12];
            beta_band = [15, 30];
            alpha_power = 0.6; % Known power ratio
            beta_power = 0.4;  % Known power ratio

            data_alpha = sin(2*pi*10*time); % Alpha band (10 Hz)
            data_beta = sin(2*pi*20*time);  % Beta band (20 Hz)

            data = alpha_power * data_alpha + beta_power * data_beta + 0.1 *randn(size(time));
            % Call the function under test with relative power
            bp = band_power(data, fs, alpha_band, [], true);

            % Assertions
            tc.verifyEqual(bp, alpha_power, 'Relative alpha band power mismatch', 'AbsTol', 0.1); % Allow some tolerance


            % Generate example data
            data = randn(100, 5);
            fs = 250;
            band = [1, 30];

            % Call the function under test with relative power
            bp = band_power(data, fs, band, [], true);

            % Assertions
            tc.verifyEqual(size(bp), [1, size(data, 2)], 'Relative band power size mismatch');
            tc.verifyGreaterThanOrEqual(bp, 0, 'Relative band power should be greater than or equal to zero');
            tc.verifyLessThanOrEqual(bp, 1, 'Relative band power should be less than or equal to one');
        end
    end

end
