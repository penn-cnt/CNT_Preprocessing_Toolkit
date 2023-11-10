% login_config.m
function usr = login_config_base()
    % Generates user .json config file using keyboard username and password inputs.
    paths;

    config = struct();
    config.usr = input('Please input your username: \n', 's');
    config.pwd = input('Please input your password: \n', 's');

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
    
    if ~exist(user_data_dir, 'dir')
        mkdir(user_data_dir);
    end
    
    usr = config.usr;
end
