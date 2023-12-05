"""
A simple test script to check if config file works properly
"""

import os, json
import pandas as pd
from ieeg.auth import Session
from CNTtools import settings
from CNTtools.tools import create_pwd_file

#current_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

def test_auth():
    assert os.path.exists(settings.USER_DIR)
    config = {}
    if os.getenv('GITHUB_ACTIONS'):
        config['usr'] = os.getenv('IEEG_USERNAME')
        config['pwd'] = os.getenv('IEEG_PASSWORD')
        fname = os.path.join(settings.USER_DIR, "{}_ieeglogin.bin".format(config['usr'][:3]))
        with open(fname, "wb") as f:
            f.write(config['pwd'].encode())
        print("-- -- IEEG password file saved -- --\n")
        config["pwd"] = "{}_ieeglogin.bin".format(config["usr"][:3])
        file_name = os.path.join(settings.USER_DIR, config["usr"][:3] + "_config.json")
        with open(file_name, "w") as f:
            json.dump(config, f)
        print("-- -- IEEG user config file saved -- --\n")
    files = os.listdir(os.path.join(settings.USER_DIR))    
    if len(files) == 0:
        raise('Login info unavailable.')
    else:
        for i in files:
            if i.endswith('.json'):
                with open(os.path.join(settings.USER_DIR, i), "rb") as f:
                    config = pd.read_json(f, typ="series")
            assert os.path.exists(os.path.join(settings.USER_DIR, config.pwd))
            pwd = open(os.path.join(settings.USER_DIR, config.pwd), "r").read()
            s = Session(config.usr, pwd)
