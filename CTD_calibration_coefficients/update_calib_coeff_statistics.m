function update_calib_coeff_statistics(year)
% Lola Pierson - sara.pierson@whoi.edu
% ARGO, WHOI
% Jan 5, 2026

%==========================================================================
% This code is to be used approx once a year to update the statistics 
% (mean, median, variance, and standard deviation) used as a baseline 
% comparison for calculating z-score of each new float during the checkout 
% process. 
% 
% Input 'year' should be the number of the year.
% ex: year = 2025
%
%==========================================================================

year = string(year);

%% Set Paths
setargo 
ARGUSCHK = '/argus/data1//lab/SOLO_II/Checklogs/';
ARGUSCALCO = '/argus/data1/lab/SOLO_II/Checklogs/Calibration_Coeffs/';
ARGUSCALCOYR = '/argus/data1/lab/SOLO_II/Checklogs/Calibration_Coeffs/cc_yearly_stats/';


%% Load in .mat files - these are created with calib_coeffs.m 
% Code found in /shared/argo/matlab/lola_tools

load([ARGUSCALCO, 'calibration_coeffs.mat']) %this struct contains all information found in next 6, used as a template. 
load([ARGUSCALCO, 'calibration_coeffs_V725.mat'])
load([ARGUSCALCO, 'calibration_coeffs_V731.mat'])
load([ARGUSCALCO, 'calibration_coeffs_61V502.mat'])
load([ARGUSCALCO, 'calibration_coeffs_61V503.mat'])
load([ARGUSCALCO, 'calibration_coeffs_ALACE3A.mat'])
load([ARGUSCALCO, 'calibration_coeffs_ALACE3C.mat'])


%% Path to output folder containing CHKLOG information
inputFolder = ARGUSCALCO;   
outputFolder = [ARGUSCALCO + "cc_yearly_stats"];  
outputFileName = ["stats_" + year + "_all_cc.xlsx"];
outputExcel = fullfile(outputFolder, outputFileName);


%% Begin calculating statistics for each CTD type. 
fN_num = fieldnames(ccStruct);
fN_num = fN_num(4:end); %only the fields of numeric data, i.e. the fields with calib coeff data
fN_num = [{'label'}; fN_num];

stats = struct('label', {'mean', 'median', 'stddev', 'var'});

%list_mat_files = string([ccStruct_V725(1).CTDtype, ccStruct_V731(1).CTDtype, ccStruct_61V502(1).CTDtype, ccStruct_61V503(1).CTDtype, ccStruct_ALACE3A(1).CTDtype, ccStruct_ALACE3C(1).CTDtype]);
list_mat_files = ["ccStruct_V725", "ccStruct_V731", "ccStruct_61V502", "ccStruct_61V503", "ccStruct_ALACE3A", "ccStruct_ALACE3C"];
for i = 1:length(list_mat_files)
    switch eval( [list_mat_files(i) + '(1).CTDtype'] )
        case "SBE 41CP V 7.2.5"
            tempStruct = ccStruct_V725;
            excel_sheet = 'SBE41CP_V725';
            
        case "SBE 41CP V 7.3.1"
            tempStruct = ccStruct_V731;
            excel_sheet = 'SBE41CP_V731';
            
        case "SBE 61 V 5.0.2"
            tempStruct = ccStruct_61V502;
            excel_sheet = 'SBE61_V502';
            
        case "SBE 61 V 5.0.3"
            tempStruct = ccStruct_61V503;
            excel_sheet = 'SBE61_V503';
            
        case "SBE 41 ALACE-CP V 3.0A"
            tempStruct = ccStruct_ALACE3A;
            excel_sheet = 'SBE41_ALACE3A';
            
        case "SBE 41 ALACE-CP V 3.0C"
            tempStruct = ccStruct_ALACE3C;
            excel_sheet = 'SBE41_ALACE3C';
            
    end

    for m = 2:numel(fN_num)
        col_data = [tempStruct.(fN_num{m})];
        stats(1).(fN_num{m}) = mean(col_data, 'omitnan');
        stats(2).(fN_num{m}) = median(col_data, 'omitnan');
        stats(3).(fN_num{m}) = std(col_data, 1, 'omitnan'); % *stddev
        stats(4).(fN_num{m}) = var(col_data, 1, 'omitnan'); % *var
    end

        %% Save updated .mat files
        matfilename = ["stats_" + year + "_" + excel_sheet + ".mat"];
        loc = fullfile(ARGUSCALCOYR, matfilename);
        save(loc, 'stats');
        
        %% Save updated .mat file to excel sheet/Update excel sheet
        statsTable = struct2table(stats);
        writetable(statsTable, outputExcel, 'Sheet', excel_sheet);
        
        disp("Updated .mat files and accompanying .xlsx file saved, results also written to: " + ARGUSCALCOYR)
end
