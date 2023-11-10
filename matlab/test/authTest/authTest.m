%% Test Class Definition
classdef authTest < matlab.unittest.TestCase
    %% Test Method Block
    methods (Test)
        % includes unit test functions
        function testAuth(testCase,username)   
            % see https://www.mathworks.com/help/matlab/matlab_prog/types-of-qualifications.html
            % for qualification method
            % addpath(genpath('./../..')); % always add to ensure loading of other files/func
            paths;
            config_path = fullfile(USER_DIR, strcat(username(1:3), '_config.json'));
    
            login = read_json(config_path);
            pwd_path = strcat('matlab',filesep,login.pwd);
            assert(exist(config_path,'file')==2,'CNTtools:Login','Login info unavailable.')
            assert(exist(pwd_path,'file')==2,'CNTtools:Login','Login info unavailable.')
        end
    end
end