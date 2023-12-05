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
                config.usr = getenv('IEEG_USERNAME'); 
                config.pwd = getenv('IEEG_PASSWORD');
                pwd_path = fullfile(USER_DIR, strcat(config.usr(1:3), '_ieeglogin.bin'));
                PATH = IEEGSession.createPwdFile(config.usr, config.pwd, pwd_path);
                config.pwd = strcat(config.usr(1:3), '_ieeglogin.bin');
                file_name = fullfile(USER_DIR, strcat(config.usr(1:3), '_config.json'));
                jsonStr = jsonencode(config);
                fid = fopen(file_name, 'w');
                fprintf(fid, '%s', jsonStr);
                fclose(fid);
                fprintf('-- -- IEEG user config file saved -- --\n');
                user_data_dir = fullfile(DATA_DIR, config.usr(1:3));
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