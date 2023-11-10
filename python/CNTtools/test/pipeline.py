#%%
"""
This function provides a test case of pulling iEEG data
"""
# pylint: disable-msg=C0103
# pylint: disable-msg=C0301
#%%
# Imports
import pandas as pd
import numpy as np
import pytest
import os
import sys

work_path = os.getcwd()  # get current path
test_path = os.path.join(work_path, "python/test")
file_path = os.path.join(work_path, "python")
# print(os.getcwd())
# os.chdir(work_path)
# par_folder = os.path.dirname(work_path)
sys.path.append(file_path)

import tools

# %%
# open config file at the work_path
with open("python/config.json", "rb") as f:
    config = pd.read_json(f, typ="series")

# data info
iEEG_filename = "HUP172_phaseII"
start_time = 402580
stop_time = 402600
electrodes = ["LE10", "LE11", "LH01", "LH02", "LH03", "LH04"]
# %%
data, fs = tools.get_iEEG_data(
    config.usr, config.pwd, iEEG_filename, start_time, stop_time
)
t_sec = np.linspace(
    start_time, stop_time, num=data.shape[0]
)  # set a time array for later use
# %%
# for test, plot sample data
fig, ax = tools.plot_iEEG_data(data, t_sec)
fig.set_size_inches(18.5, 10.5)
ax.set_title(iEEG_filename)
# %%
# clean channel labels
clean_channels = np.array(tools.clean_labels(data.columns))
# show cleaned and original labels
if np.all(clean_channels == data.columns):
    print("No channels changed.")
else:
    comp_chan = np.vstack([data.columns, np.array(clean_channels)]).T
    print(comp_chan[np.where(clean_channels != data.columns)[0], :])
#%%
# find and return a boolean mask for non ieeg channels
non_ieeg_channels = tools.find_non_ieeg(clean_channels)
# test:print non-ieeg-channels
print(clean_channels[non_ieeg_channels])
#%%
data.columns = clean_channels
data = data.iloc[:, ~non_ieeg_channels]
# test
print(data.columns)
# %%
# sync localization
# locs = tools.pull_patient_localization('file_path')
# %%
# Identify bad channels
# No func yet

# %%
# Notch Filter

# %%
# Rereference
# function unavailable
data, data.columns = tools.automatic_bipolar_montage(data, data.columns)
# %%
# other tests
# tools.pull_sz_starts(patient, metadata)
# tools.pull_sz_ends(patient, metadata)
abs_power = tools.bandpower(data, fs, [4, 8])
rela_power = tools.bandpower(data, fs, [4, 8], relative=True)
# %%
