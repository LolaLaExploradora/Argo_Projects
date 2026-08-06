function get_calib_coeffs(varargin)
% Lola Pierson - sara.pierson@whoi.edu
% ARGO, WHOI
% Mar 3, 2026

% =========================================================================
% Extract calibration variables from WHOI Checklogs (NOT MRV checklogs) 
%
% This code loops through the file list provided, and logs the most
% recent calibration coefficients. 
% if 'new' is specified then the code will also output a temporary
% structure called 'ccNewFloats.mat' CAUTION this file gets overwritten
% with every iteration of get_calib_coeffs. 
%
% The code outputs a .mat file calibration_coeffs.mat and a table which can
% then be used to create an excel document, if desired. 
% /argus/data1/lab/SOLO_II/Checklogs/Calibration_Coeffs
%
% There are 24 calibration coefficients for SBE41CP CTDs.
%
% Index at end of Code for extra information
% *1, *2, *3, etc. Denote parts of code with Indexed information 
%
% =========================================================================