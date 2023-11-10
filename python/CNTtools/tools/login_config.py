import os, json
from .create_pwd_file import create_pwd_file
from CNTtools import settings


def login_config():
    """Generates user .json config file using keyboard username and password inputs."""
    config = {}
    config["usr"] = input("Please input your username: \n")
    config["pwd"] = input("Please input your password: \n")
    create_pwd_file(config["usr"], config["pwd"])
    config["pwd"] = "{}_ieeglogin.bin".format(config["usr"][:3])
    file_name = os.path.join(settings.USER_DIR, config["usr"][:3] + "_config.json")
    with open(file_name, "w") as f:
        json.dump(config, f)
    print("-- -- IEEG user config file saved -- --\n")
    user_data_dir = os.path.join(settings.DATA_DIR, config["usr"][:3])
    if not os.path.exists(user_data_dir):
        os.mkdir(user_data_dir)
    return config["usr"]
