% Global settings of the CNT iEEG Pre-processing Toolkit
global ROOT_DIR TEST_DIR DATA_DIR USER_DIR TESTDATA_DIR
% Directories
ROOT_DIR = fileparts(mfilename('fullpath'));
TEST_DIR = fullfile(ROOT_DIR, 'test');
DATA_DIR = fullfile(ROOT_DIR, 'data');
USER_DIR = fullfile(ROOT_DIR, 'users');
TESTDATA_DIR = fullfile(TEST_DIR, 'data');

DIRS = {DATA_DIR, USER_DIR};

for i = 1:numel(DIRS)
    if ~exist(DIRS{i}, 'dir')
        mkdir(DIRS{i});
    end
end

