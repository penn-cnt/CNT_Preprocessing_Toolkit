import os
from CNTtools import settings


def create_pwd_file(username, password, fname=None):
    if fname is None:
        fname = os.path.join(settings.USER_DIR, "{}_ieeglogin.bin".format(username[:3]))
    with open(fname, "wb") as f:
        f.write(password.encode())
    print("-- -- IEEG password file saved -- --\n")
