# CNT Pre-processing Toolkit
Toolkit for pre-processing of intracranial EEG data, and an interactive pipeline for pre-processing method evaluation.

Toolkit available in Matlab and Python, compatible with iEEG.org

## Python Installation

**pip install**

```
pip install git+https://github.com/penn-cnt/CNT_research_tools.git#subdirectory=python
```

Alternatively, download or clone the toolbox into a local folder via git, switch to folder, and pip install locally:
```
git clone git@github.com:haoershi/CNT_research_tools.git
cd CNT_research_tools/python
pip install .
```

**Set Conda Environment**

An environment could be set through conda to reduce the likelihood of dependency conflicts and making it easier to set up.

Dependencies: 
* [anaconda](https://www.anaconda.com)

Create a conda environment and activate:
```
conda env create -n ieegpy -f ieegpy.yml
conda activate ieegpy
```
If the above command doesn't work, you can manually create an enviornment and install the necessary libraries:
```
conda create -n ieegpy python=3.9
conda activate ieegpy
pip install -r requirements.txt
```

**Testing**

Run pytest to ensure no running issues.
(Getting data may not be tested currently)
(Need update for the new system)

## MATLAB Installation

Dependencies: 
* MATLAB >= R2021b
* Signal Processing Toolbox
* Statistics and Machine Learning Toolbox
Toolboxes could be installed via Adds-Ons > Get Adds-Ons.
* IEEG MATLAB Toolbox (Can be downloaded at https://main.ieeg.org/?q=node/29, or we've provided with our toolkit)

Add folder _matlab_ in MATLAB working directory.
```\matlab
addpath(genpath('path/CNT_research_tools/matlab'));
```

**Testing**

Run unit tests to ensure no running issues:
(Getting data may not be tested currently, need update to the current system)
```
runtests('matlab/test','IncludeSubfolders',true);
```
## Folder Structure

During usage of toolkit, folders users and data would be created under the python/CNTtools or matlab folder to store user login information and data files, respectively.

## Login Congiguration

The toolkit currently depends on ieeg.org.

To access data, please register first on https://www.ieeg.org.

A usr_ieeglogin.bin password file and a usr_config.json file are required in the user folder before data downloading can run correctly.

Files could be automatically generated throught running login configuration and input of username and password.

```
session = iEEGPreprocess()
session.login_config()
# input of user information
```

## Functions

The toolbox includes the following functions:
* Download data from ieeg.org
* Standardize channel labels and identify band channels
* Signal filtering
* Data re-referencing 
    * Common Average Re-referencing (CAR)
    * Bipolar Re-referencing (BR)
    * Laplacian Re-referencing (LR)
* Pre-whitening
* Feature extraction
* Connectivity calculation
* Plotting and connectivity heatmap
<img src="https://github.com/haoershi/CNT_research_tools/assets/116624350/2e28a994-71ef-4b31-b368-df081b367aa4" width=50% height=50%>

## Usage

This toolkit provides a recommended usage pipeline in the form of interactive notebooks in both MATLAB and Python.

For illustration, this toolkit is also used for an systematic evaluation of pre-processing methods, as shown in the demo folder.  
