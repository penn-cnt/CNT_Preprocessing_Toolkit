%% Test Class Definition
classdef authTest < matlab.unittest.TestCase
    %% Test Method Block
    methods (Test)
        % includes unit test functions
        function testAuth(testCase)   
            % see https://www.mathworks.com/help/matlab/matlab_prog/types-of-qualifications.html
            % for qualification method
            % addpath(genpath('./../..')); % always add to ensure loading of other files/func
            paths;
            assert(exist(USER_DIR,'dir') == 7);
            if ~isempty(getenv('GITHUB_ACTIONS'))
                % Use GitHub secrets to retrieve credentials
                login.usr = getenv('GITHUB_USERNAME_SECRET');
                login.pwd = getenv('GITHUB_PASSWORD_SECRET');
                login_config_base(login.usr,login.pwd)
            end
            files = dir(fullfile(USER_DIR,'*.json'));
            if isempty(files)
                error('Login info unavailable.')
            else
                for i = 1:length(files)
                    f = fullfile(files(i).folder, files(i).name);
                    login = jsondecode(fileread(f));
                    assert(exist(fullfile(USER_DIR,login.pwd)))
                end
            end
        end
    end
end