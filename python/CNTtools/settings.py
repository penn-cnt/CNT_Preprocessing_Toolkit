"""
Global settings of the CNT iEEG Pre-processing Toolkit
"""

import sys, os

#####################
#    DIRECTORIES    #
#####################
ROOT_DIR = os.path.dirname(os.path.abspath(__file__))
TEST_DIR = os.path.join(ROOT_DIR, "test")
DATA_DIR = os.path.join(ROOT_DIR, "data")
USER_DIR = os.path.join(ROOT_DIR, "users")
TESTDATA_DIR = os.path.join(TEST_DIR, "data")

DIRS = [DATA_DIR, USER_DIR]

for d in DIRS:
    if not os.path.exists(d):
        os.mkdir(d)
