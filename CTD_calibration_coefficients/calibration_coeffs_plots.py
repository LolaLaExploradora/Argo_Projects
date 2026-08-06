# Lola Pierson - sara.pierson@whoi.edu
# ARGO, WHOI
# Jan 5, 2025

#% =========================================================================
#% Python script for creating interactive calibration coefficient plots.
#% .mat files are loaded into the script and then used to make plots with
#% respect to the type of CTD. 
#% Historically there are 6 types found in our checklogs, but only 3 are
#% currently used: 
#%
#% 1. SBE 41CP V 7.2.5
#% 2. SBE 61 V 5.0.2
#% 3. SBE 61 V 5.0.3
#%
#% .mat files are found in /argus/data1/lab/SOLOII/Checklogs
#% =========================================================================

# Requirements:
# pip install plotly scipy

import scipy.io
import plotly.express as px

# --- Load .mat file ---
mat_data = scipy.io.loadmat(r'Y:/argus/data1/lab/SOLO_II/Checklogs/all_calibration_coeffs.mat')

# Skip MATLAB metadata
data_keys = [k for k in mat_data.keys() if not k.startswith('__')]