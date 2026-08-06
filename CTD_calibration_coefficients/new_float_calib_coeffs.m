function temp_plots = new_float_calib_coeffs(CHK_file_list)
% Lola Pierson - sara.pierson@whoi.edu
% ARGO, WHOI
% Dec 30, 2025

% =========================================================================
% Extract calibration variables from WHOI Checklogs, append to running list
% of calib coeffs, and print out zscores for each checklog.
%
% The function's input, CHK_file_list, should be a list of numbers only, 
% ex: [1234, 2345, 11234]  
%
% This code takes in a singular or list of CHK files of new floats, 
% extracts the calibration coefficients, appends those values to a .mat 
% file database, and calculates zscore for each float with respect to
% CTD type. 
%
% .mat files are found in
% /argus/data1/lab/SOLOII/Checklogs/Calibration_Coeffs
%
% =========================================================================

CHK_file_list = ["CHK" + pad(string(CHK_file_list), 5, 'left', '0')]

%% Set Paths
setargo 
ARGUSCHK = '/argus/data1//lab/SOLO_II/Checklogs/';
ARGUSCALCO = '/argus/data1/lab/SOLO_II/Checklogs/Calibration_Coeffs/';
ARGUSCALCOYR = '/argus/data1/lab/SOLO_II/Checklogs/Calibration_Coeffs/cc_yearly_stats/';
ARGUSCCWEB = '/argus/data1/argo/www/calib';
load(fullfile(ARGOMETA,'/meta_sum'))

outputFolder = '/argus/data1/lab/SOLO_II/Checklogs/Calibration_Coeffs';  % <-- UPDATE THIS IF NEEDED
outputFileName = 'all_calibration_coeffs.xlsx';
outputExcel = fullfile(ARGUSCALCO, outputFileName);

% Load in the .mat file that contains the historical database of
% calibration coefficients for all WHOI floats. 
load('/argus/data1/lab/SOLO_II/Checklogs/Calibration_Coeffs/calibration_coeffs.mat');
ccStruct = ccStruct; %only valid floats
load('/argus/data1/lab/SOLO_II/Checklogs//Calibration_Coeffs/calibration_coeffs_EmptyFiles.mat');
ccEmptyStruct = ccEmptyStruct; %only floats with no calib coeff data
load('/argus/data1/lab/SOLO_II/Checklogs/Calibration_Coeffs/calibration_coeffs_AllFiles.mat');
ccAllStruct = ccAllStruct; %all floats, whether with or w/o data

% CHK_file_list = {ccStruct.Checklog};
% ccNewFloats = ccStruct;

%% Create Struct to hold NEW FLOAT calib coeff info - Initialize with Variable Names of calib coeffs
% note that I tried to make this struct dynamically (in one line)
% and for the life of me I have no idea why it wouldnt work. Please explain
% it to me if you know what went wrong and I would be happy to update.

    % Target variable names = calibration coefficients
    % Note that the "=" are necessary, I have tried this code without them and
    % you end up capturing random/incorrect data because the checklogs contain 
    % too many random letter/number sets that erroneously match  
    targetVars = ["SERIAL NO", "TA0 = ", "TA1 = ", "TA2 = ", "TA3 = ", ...
                  "G = ", "H = ", "I = ", "J = ", "CTCOR = ", "CPCOR = ", ...
                  "WBOTC = ", "PA0 = ", "PA1 = ", "PA2 = ", "PTCA0 = ", ...
                  "PTCA1 = ", "PTCA2 = ", "PTCB0 = ", "PTCB1 = ", ...
                  "PTCB2 = ","PTHA0 = ", "PTHA1 = ", "PTHA2 = ", "POFFSET = "];
%fieldnames for our structure
fNames = matlab.lang.makeValidName(["Checklog" "CTDtype" erase(targetVars, "=")]);

%Creating the structure using the fieldnames, i.e. the calib coeff names
fNames = matlab.lang.makeValidName(["Checklog" "CTDtype" erase(targetVars, "=")]);
ccNewFloats = struct(); %calib coeff struct
for i = 1:numel(fNames);
    ccNewFloats.(fNames(i))=[];     %disp(fNames(i));
end

%% Patterns - what regexp looks for in the CHK files  
pattern1 = '\s*( TA0| TA1| TA2| TA3| G| H| I| J| CTCOR| CPCOR| WBOTC| PA0| PA1| PA2| PTCA0| PTCA1| PTCA2| PTCB0| PTCB1| PTCB2| PTHA0| PTHA1| PTHA2| POFFSET)\s=\s*([+-]?(?:\d+\.?\d*|\.\d+)(?:[eE]\s*[+-]?\s*\d+)?)';
pattern2 = '(SERIAL NO)\.\s*(\d{4,})';

%% Loop through list of new float CHK file(s) 
for j = 1:length(CHK_file_list)
    fileName = CHK_file_list(j); 
    filePath = fullfile(ARGUSCHK, fileName);

    %% if the CHK file is not found, skip it and notify the user. 
    if ~isfile(filePath)
        fprintf('Warning: Checklog %s not found in directory: %s, skipping and moving on.\n', fileName, ARGUSCHK);
        continue; 
    end
    % Create a map for storing variable values for this file
    valueMap = containers.Map(erase(targetVars," = "), repmat({""},size(targetVars)) ); 

    fid = fopen(filePath);
    while ~feof(fid) 
        line = fgetl(fid);
        matchIdx = find(contains(line, targetVars), 1);
        % Search each line only if it contains one of the targetVars/calib coefficients
        if ~isempty(matchIdx)
            % Tokenize, i.e. split at "="
            tokens = regexp(line, pattern1, 'tokens', 'once'); %see index for explanation, *tokens
            tokens_sn = regexp(line, pattern2, 'tokens', 'once'); % see index for expl.
            if ~isempty(tokens_sn)
                varName = strtrim(string(tokens_sn{1}));
                varValue = string(tokens_sn{2});
                valueMap(varName) = varValue;
                    ctdTypeRaw = extractBefore(line, "SERIAL NO");
                    ctdType = strtrim(regexprep(ctdTypeRaw, '^\s*(\[[^\]]*\]|[A-Za-z]{9}\s#)\s*', ''));
            end
            if ~isempty(tokens)
                varName = strtrim(string(tokens{1}));
                varValue = string(tokens{2});
                valueMap(varName) = varValue;
            end
        end
    end

    % Store values in the same order as targetVars
    rowValues = [];
    for k = 1:length(targetVars)
        cleanVar = erase(targetVars(k)," = "); % use erased variable name (without " = ") as key
        rowValues(k) = valueMap(cleanVar);
    end

    %% Append each Checklog's Calibration Coefficient Data to Main Structs
    rowStruct_all = cell2struct( [{fileName} {ctdType} num2cell(rowValues)], fNames, 2 );
    ccAllStruct(end+1)= rowStruct_all;

    if all( isnan(rowValues(2:end)) ) 
        rowStruct_empty = cell2struct( [{fileName} {ctdType} num2cell(rowValues)], fNames, 2 );
        ccEmptyStruct(end+1)= rowStruct_empty; 
    else % Compare current CHK file name to those in ccStruct... 
        existing_CHK_names = [ccStruct.Checklog];
        matchIndCHK = find(strcmp(existing_CHK_names, CHK_file_list(j))); 
        if  ~isempty(matchIndCHK) % ...if there is an old duplicate...
            ccStruct(matchIndCHK)=[]; % ...delete. 
        end
        rowStruct_cc = cell2struct( [{fileName} {ctdType} num2cell(rowValues)], fNames, 2 );
        ccStruct(end+1)= rowStruct_cc; 
        ccNewFloats(j) = rowStruct_cc;
    end
end

% %% Save updated .mat files
% save([ARGUSCALCO + "calibration_coeffs.mat"], 'ccStruct')
% save([ARGUSCALCO + "calibration_coeffs_EmptyFiles.mat"], 'ccEmptyStruct')
% save([ARGUSCALCO + "calibration_coeffs_AllFiles.mat"], 'ccAllStruct')
% 
% %% Save updated .mat file to excel sheet/Update excel sheet
% % resultTab0: Subset of results excluding checklogs with no calibration coefficient
% %             entries (i.e. if all calib coeffs are NaNs - those are not included here). 
% %             Written to sheet "CalibCoeff_Files" 
% % resultTab1: Subset of results which contain only NaNs. Written to sheet "CalibCoeff_Empty_Files"
% % resultTab2: All checklog results. Written to first sheet called "CalibCoeff_All_Files"
% resultTab0 = struct2table(ccStruct);
% resultTab1 = struct2table(ccEmptyStruct);
% resultTab2 = struct2table(ccAllStruct);
% 
% writetable(resultTab0, outputExcel, 'Sheet', 'CalibCoeff_Files');
% writetable(resultTab1, outputExcel, 'Sheet', 'CalibCoeff_Empty_Files');
% writetable(resultTab2, outputExcel, 'Sheet', 'CalibCoeff_All_Files');
% 
% disp("Updated .mat files saved, results also written to: " + outputExcel)

%% Standard Deviation and Varience calculation *1
ctdTypes = string({ccStruct.CTDtype});
unique_ctdTypes = unique(ctdTypes)';

% OLD CORE ARGO CTDs: SBE 41 ALACE CP - two types
inds1 = find( string({ccStruct.CTDtype}) == unique_ctdTypes(1) );
inds3 = find( string({ccStruct.CTDtype}) == unique_ctdTypes(3) );
    ccStruct_ALACE3A = ccStruct([inds1 inds3]);
inds2 = find( string({ccStruct.CTDtype}) == unique_ctdTypes(2) );
inds4 = find( string({ccStruct.CTDtype}) == unique_ctdTypes(4) );
    ccStruct_ALACE3C = ccStruct([inds2 inds4]);
% CURRENT CORE ARGO CTD: SBE41CP V725
inds5 = find( string({ccStruct.CTDtype}) == unique_ctdTypes(5) );
    ccStruct_V725 = ccStruct(inds5);
% AN ODDITY: SBE41CP V731
inds6 = find( string({ccStruct.CTDtype}) == unique_ctdTypes(6) );
    ccStruct_V731 = ccStruct(inds6);
% DEEP ARGO CTDS: SBE61 - two types
inds7 = find( string({ccStruct.CTDtype}) == unique_ctdTypes(7) );
    ccStruct_61V502 = ccStruct(inds7);
inds8 = find( string({ccStruct.CTDtype}) == unique_ctdTypes(8) );
    ccStruct_61V503 = ccStruct(inds8);

save([ARGUSCALCO + "calib_coeffs_ALACE3A.mat"], 'ccStruct_ALACE3A')
save([ARGUSCALCO + "calib_coeffs_ALACE3C.mat"], 'ccStruct_ALACE3C')
save([ARGUSCALCO + "calib_coeffs_V725.mat"], 'ccStruct_V725')
save([ARGUSCALCO + "calib_coeffs_V731.mat"], 'ccStruct_V731')
save([ARGUSCALCO + "calib_coeffs_61V502.mat"], 'ccStruct_61V502')
save([ARGUSCALCO + "calib_coeffs_61V503.mat"], 'ccStruct_61V503')


%% Calculate mean, median, stddev, and variance of dataset wrt CTD type
% Z score calculated for each calibration coefficient for each new float in list
% Each CTD type will have its own statistics and we compare new floats to
% those particular statistics. 

fN_num = fieldnames(ccStruct);
fN_num = fN_num(4:end); %only the fields of numeric data, i.e. the fields with calib coeff data
fN_num = [{'label'}; fN_num];

stats = struct('label', {'mean', 'median', 'stddev', 'var'});
sp_count = 2;
list_not_found = [];
for ooo = 1:length(CHK_file_list)
    %If CHK file was not found, it will not be in the ccNewFloats
    %structure, therefore we need to skip it in our production of plots.
    if ~ismember(CHK_file_list(ooo), [ccNewFloats.Checklog])
        fprintf('Checklog %s not found, therefore its calibration coefficients cannot be found nor plotted, skipping this file.\n', CHK_file_list(ooo))
    continue; 
    end 

    newFloat_CTD = upper(string(ccNewFloats(ooo).CTDtype));
    CHK_name_sanitiz = regexprep(CHK_file_list{ooo},"\.txt$","");
    %CHK_name_sanitiz = regexprep(ccNewFloats(ooo),"\.txt$","");
    fltnum = strip(extractAfter(CHK_name_sanitiz, 'CHK'), 'left','0');
    switch newFloat_CTD
        case "SBE 41CP V 7.2.5"
            load([ARGUSCALCOYR + "stats_2025_SBE41CP_V725.mat"])
            tempStruct = ccStruct_V725;
            tempStructStats = stats;
            ctdtypename = "SBE41CP_V725"; %folder in argus/data1/argo/www/calib
            excel_doc = 'calib_coeffs_V725';
        
        case "SBE 41CP V 7.3.1"
            load([ARGUSCALCOYR + "stats_2025_SBE41CP_V731.mat"])
            tempStruct = ccStruct_V731;
            tempStructStats = stats;
            ctdtypename = "SBE41CP_V731";
            excel_doc = 'calib_coeffs_V731';
        
        case "SBE 61 V 5.0.2"
            load([ARGUSCALCOYR + "stats_2025_SBE61_V502.mat"])
            tempStruct = ccStruct_61V502;
            tempStructStats = stats;
            ctdtypename = "SBE61_V502";
            excel_doc = 'calib_coeffs_61V502';
        
        case "SBE 61 V 5.0.3"
            load([ARGUSCALCOYR + "stats_2025_SBE61_V503.mat"])
            tempStruct = ccStruct_61V503;
            tempStructStats = stats;
            ctdtypename = "SBE61_V503";
            excel_doc = 'calib_coeffs_61V503';
        
        case "SBE 41 ALACE-CP V 3.0A"
            load([ARGUSCALCOYR + "stats_2025_SBE41_ALACE3A.mat"])
            tempStruct = ccStruct_ALACE3A;
            tempStructStats = stats;
            ctdtypename = "SBE41_ALACE_CP_V3A";
            excel_doc = 'calib_coeffs_ALACE3A';
        
        case "SBE 41 ALACE-CP V 3.0C"
            load([ARGUSCALCOYR + "stats_2025_SBE41_ALACE3C.mat"])
            tempStruct = ccStruct_ALACE3C;
            tempStructStats = stats;
            ctdtypename = "SBE41_ALACE_CP_V3C";
            excel_doc = 'calib_coeffs_ALACE3C';
        
        otherwise 
            %warning('Unknown CTD type %s found in %s', newFloat_CTD, CHK_file_list(ooo))
                        warning('Unknown CTD type %s found in %s', newFloat_CTD, CHK_file_list{ooo})
            continue
    end

    plotDir = sprintf('%s/%s/%s', ARGUSCCWEB, ctdtypename, fltnum);
    if isdir(plotDir) == 0
       mkdir(plotDir)
    end
    
    %Find nearest 50 CTD Serial Numbers for plotting superimposed line on
    %calib coeff histograms 
    [~,indss] = sortrows([tempStruct.SERIALNO].');
    tempStruct_sortedSN = tempStruct(indss);
    idx = find([tempStruct_sortedSN.Checklog]==CHK_file_list(ooo))
        %Define range - we are doing +/- 25 
        startIdx = max(1,idx-25);
        endIdx = min(length(tempStruct_sortedSN), startIdx+49);
        startCTDSN_comparison = tempStruct_sortedSN(startIdx).SERIALNO;
        currentCTDSN = tempStruct_sortedSN(idx).SERIALNO;
        endCTDSN_comparison = tempStruct_sortedSN(endIdx).SERIALNO;

    for m = 2:numel(fN_num)
            cc_data_point = ccNewFloats(ooo).(fN_num{m});
            cc_dataset_mean = tempStructStats(1).(fN_num{m});
            cc_dataset_std = tempStructStats(3).(fN_num{m});
        z_score_classic = (cc_data_point - cc_dataset_mean)/cc_dataset_std ;
        %zscore(ooo).Checklog = CHK_file_list(ooo);
        zscore(ooo).Checklog = CHK_file_list{ooo};
        zscore(ooo).CTDtype = ccNewFloats(ooo).CTDtype;
        zscore(ooo).SERIALNO = ccNewFloats(ooo).SERIALNO;
        zscore(ooo).(fN_num{m}) = z_score_classic;
        
        % Make histogram plots for subsets of calibration coefficient
        % variables. i.e. Temperature, Conductivity, and Pressure 
        switch m
            % Temp i.e. if fN_num == TA0, TA1, TA2, or TA3
            case {2,3,4,5} 
                % Write histograms to subplots (i.e. using nexttile)
                cc_dataset_hist = [tempStruct.(fN_num{m})];
                cc_dataset_hist_50nearest = [tempStruct_sortedSN(startIdx:1:endIdx).(fN_num{m})];
                hT=nexttile(sp_count); %hT - handle for Temp calib coeffs plot
                    title(sprintf('%s\n z score = %.4f', fN_num{m}, z_score_classic)); hold on
                    h1 = histogram(cc_dataset_hist, 'Normalization', 'probability'); hold on
                    abw = h1.BinWidth;
                    histogram(cc_dataset_hist_50nearest,'Normalization', 'probability','BinWidth',abw);
                    xline(cc_data_point,'r', 'LineWidth',2); 
                    % Shade plot background based on z score
                    if z_score_classic > 3 || z_score_classic < -3 
                        set(hT, 'Color', [1 0.8 0.8]);
                    elseif z_score_classic<3 && z_score_classic>2 || z_score_classic<-2 && z_score_classic>-3
                        set(hT, 'Color', [1 0.8 0.6]);
                    elseif z_score_classic<-1 && z_score_classic>-2 || z_score_classic>1 && z_score_classic<2
                        set(hT, 'Color', [1 0.8 0.4]);
                    end
                    %hold off 
                % If last number in category, title figure and save
                if m == 5 
                    %sgtitle(sprintf('%s', CHK_file_list(ooo)));
                    legStr = sprintf('50 Nearest CTDs\n%i-%i',startCTDSN_comparison, endCTDSN_comparison);
                    legStr1 = sprintf('current CTD %i',currentCTDSN);
                    legend('All CTDs', legStr,legStr1)
                    sgtitle(sprintf('%s', CHK_file_list{ooo}));
                    hT = axes('Position', [0, 0, 1, 1], 'Visible', 'off'); hold on
                        uistack(hT, 'bottom'); hold on % Move shared axis to bottom layer
                        text(0.5, 0.02, 'Calibration Coeff Value', 'HorizontalAlignment', 'center', 'Parent', hT); % x & y labels on axes object
                        text(0.02, 0.5, 'Bin Counts', 'HorizontalAlignment', 'center', 'Rotation', 90, 'Parent', hT);
                    % Save and export the finalized subplot    
                    hT=gcf; 
                    hT.Position(3:4)=[1700 850];
                    var = 'Temp';
                    plotLink = sprintf('%s/%s_%s.png', plotDir, fltnum, var);
                    exportgraphics(hT, plotLink);
                    sp_count=1; % reset count for next case statement
                end
                sp_count = sp_count+1;

            case {6,7,8,9,10,11,12} %Cond i.e. if fN_num == G,H,I,J, CPcor, CTcor, WBOTC
                cc_dataset_hist = [tempStruct.(fN_num{m})]; 
                cc_dataset_hist_50nearest = [tempStruct_sortedSN(startIdx:1:endIdx).(fN_num{m})];
                hC = nexttile(sp_count); 
                    title(sprintf('%s, z score = %.4f', fN_num{m}, z_score_classic)); hold on
                    h1 = histogram(cc_dataset_hist, 'Normalization', 'probability'); hold on
                    abw = h1.BinWidth;
                    histogram(cc_dataset_hist_50nearest,'Normalization', 'probability','BinWidth',abw);
                    xline(cc_data_point,'r', 'LineWidth',2); 
                    if z_score_classic > 3|| z_score_classic < -3
                        set(hC, 'Color', [1 0.8 0.8]);
                    elseif z_score_classic<3 && z_score_classic>2 || z_score_classic<-2 && z_score_classic>-3
                        set(hC, 'Color', [1 0.8 0.6]);
                    elseif z_score_classic<-1 && z_score_classic>-2 || z_score_classic>1 && z_score_classic<2
                        set(hC, 'Color', [1 0.8 0.4]);
                    end
                    hold off 
                
                if m == 12
                    legend('All CTDs', legStr,legStr1, 'Location','best')
                    %sgtitle(sprintf('%s', CHK_file_list(ooo)));
                    sgtitle(sprintf('%s', CHK_file_list{ooo}));
                    hC = axes('Position', [0, 0, 1, 1], 'Visible', 'off'); hold on
                        uistack(hC, 'bottom'); hold on
                        text(0.5, 0.02, 'Calibration Coeff Value', 'HorizontalAlignment', 'center', 'Parent', hC);
                        text(0.02, 0.5, 'Bin Counts', 'HorizontalAlignment', 'center', 'Rotation', 90, 'Parent', hC);
                    % Save and export the finalized subplot    
                    hC = gcf;
                    hC.Position(3:4)=[1700 850];
                    var = 'Cond';
                    plotLink = sprintf('%s/%s_%s.png', plotDir, fltnum, var);
                    exportgraphics(hC, plotLink);
                    sp_count=1;
                end
                sp_count = sp_count+1;

            case {13,14,15,16,17,18,19,20,21,22,23,24,25} %Pres i.e. fN_num == PA0, PA1, PA2, PTHA0,... etc and all remaining variables that start with "P"
                cc_dataset_hist = [tempStruct.(fN_num{m})]; 
                cc_dataset_hist_50nearest = [tempStruct_sortedSN(startIdx:1:endIdx).(fN_num{m})];
                hP = nexttile(sp_count); 
                    title(sprintf('%s, z score = %.4f', fN_num{m}, z_score_classic)); hold on
                    h1 = histogram(cc_dataset_hist, 'Normalization', 'probability'); hold on
                    abw = h1.BinWidth;
                    histogram(cc_dataset_hist_50nearest,'Normalization', 'probability','BinWidth',abw);
                    xline(cc_data_point,'r', 'LineWidth',4); 
                    if z_score_classic > 3 || z_score_classic < -3
                        set(hP, 'Color', [1 0.8 0.8]);
                    elseif z_score_classic<3 && z_score_classic>2 || z_score_classic<-2 && z_score_classic>-3
                        set(hP, 'Color', [1 0.8 0.6]);
                    elseif z_score_classic<-1 && z_score_classic>-2 || z_score_classic>1 && z_score_classic<2
                        set(hP, 'Color', [1 0.8 0.4]);
                    end
                    hold off 
                
                if m == 25
                    legend('All CTDs', legStr,legStr1)
                    %sgtitle(sprintf('%s', CHK_file_list(ooo)));
                    sgtitle(sprintf('%s', CHK_file_list{ooo}));
                    hP = axes('Position', [0, 0, 1, 1], 'Visible', 'off'); hold on
                        uistack(hP, 'bottom'); hold on
                        text(0.5, 0.02, 'Calibration Coeff Value', 'HorizontalAlignment', 'center', 'Parent', hP);
                        text(0.02, 0.5, 'Bin Counts', 'HorizontalAlignment', 'center', 'Rotation', 90, 'Parent', hP);
                    % Save and export the finalized subplot    
                    hP=gcf;
                    hP.Position(3:4)=[2000 1200];
                    var = 'Pres';
                    plotLink = sprintf('%s/%s_%s.png', plotDir, fltnum, var);
                    exportgraphics(hP, plotLink);
                    sp_count=1;
                end
                sp_count = sp_count+1;
        end
    end

    %%DEL lines below after done printing zscores
    %zscore_T = struct2table(zscore);
    ppp = [meta_sum.whoi_number] == str2double(extractAfter(CHK_name_sanitiz,3)); 
        if sum(ppp)>1 %compare meta_sum.(ppp).launch.jday and see which is newest. pick that one
            ind_ppp = find(ppp==1)
            ppp = input('type in the index you determined was the right one, hint: check IMEI nubmers: \n')
        elseif sum(ppp)==0
            disp('%s is not on the meta_sum list')
            list_not_found = [list_not_found; CHK_name_sanitiz]
            continue 
        end
    sheet_cruisename = meta_sum(ppp).cruise_id; 
    year = meta_sum(ppp).launch.year;
    zscore_destin_dir = sprintf('%s/z_scores/%s', ARGUSCALCO, ctdtypename);
    zscore_destin_file = sprintf('%s/z_scores/%s/%d_zscores.xlsx', ARGUSCALCO, ctdtypename,year);
    newData = struct2table(zscore(end));%(1:end, :);
    if exist(zscore_destin_file, 'file') == 2
        sheets = sheetnames(zscore_destin_file);
        if ismember(sheet_cruisename, sheets)
            existingData = readtable(zscore_destin_file, 'Sheet', sheet_cruisename);
            combinedData = [existingData; newData];
            writetable(combinedData, zscore_destin_file, 'Sheet', sheet_cruisename);
        else 
            z_score_newData_T = struct2table(zscore(end));
            writetable(z_score_newData_T, zscore_destin_file, 'Sheet', sheet_cruisename);
        end 
    else 
        if ~exist(zscore_destin_dir, 'dir')
            mkdir(zscore_destin_dir)
        end
        z_score_newData_T = struct2table(zscore(end));
        writetable(z_score_newData_T, zscore_destin_file, 'Sheet', sheet_cruisename);
    end
end

missing_destin = sprintf('%s/z_scores/%s', ARGUSCALCO, 'missing_CHKs_from_meta_sum.xlsx');
list_not_found = table(list_not_found);
writetable(list_not_found, missing_destin)
list_floats = [];

sprintf('all done, thank you! \nCalibration Coefficient z-score plots by category (Temp, Cond, Pres) can be found in \n%s \ncategorized by CTD type and WHOI float number', ARGUSCCWEB)


%% Create figure 
% stats_T  = rows2vars( struct2table(stats));
% zscore_T = rows2vars( struct2table(zscore));
% stats_T  = struct2table(stats);
% zscore_T = struct2table(zscore);
% fig = figure('Units', 'inches', 'Position',[0 0 8.5 11], 'Color','w')
%     ax = axes(fig); axis(ax,'off'); ax.Position = [0 0 1 1];
% pageTitle = 'Z score values for new float list';
%     text(0.5, 0.98, pageTitle,'FontSize', 14,'FontWeight', 'bold', ...
%         'HorizontalAlignment', 'center', 'Units', 'normalized'); % Adds title at the top
% subTitle = {'z-score is a measure of standard deviation.'
%             '0-1 is within one stddev'
%             '1-2 is within 2 stddevs'
%             '2-3 is over 2 stddevs away from the mean of the data'
%             'anything over 2 should be looked at more closely.'}
%     text(0.5, 0.925, subTitle,'FontSize', 10,'FontAngle', 'italic', ...
%         'HorizontalAlignment', 'center', 'Units', 'normalized');
% table_txt = evalc('disp(zscore_T)');
%     table_txt = regexprep(table_txt,'<[^>]*>',''); % removes the html tags
%     table_txt = regexprep(table_txt,'[\{\}''"]',''); % removes {}, '', ""
%     t = text(0.05,0.865, table_txt,'FontName','Courier','FontSize', 10, 'VerticalAlignment','top', ...
%     'Interpreter','none', 'Units','normalized');
% set(fig,'PaperUnits','inches')
% set(fig,'PaperPosition',[0 0 8.5 11])
% set(fig,'PaperOrientation','portrait')


%% Save Table and Figure
% exportgraphics(fig, [ARGUSCALCO + "/z_scores/" + "zscores_output" + ".pdf"] ,'ContentType','vector');
%     fprintf('\n zscore figure saved to %sz_scores as pdf.\n WARNING: this figure will be overwritten. \n See the xlsx sheet in %s for saved values.\n', ARGUSCALCO, outputFolder,year)
% writetable(zscore_T, [ARGUSCALCO + "/z_scores/" + year + "_zscores.xlsx"], 'Sheet', cruisename);



%==========================================================================
% INDEX
%==========================================================================
%% *token - regexp pattern & tokenizing
% In this line of code, the regularized expression is searching the current 
% line for the pattern specified in the pattern1 variable, which is:
% pattern1 = (calib coeff name) + "=" + (pattern of numeric digits)
% By using the "token" option, the regexp function recognizes name on the 
% left hand side of the "=" as one token and a numeric value on the right 
% hand side as another token. 
% it is an extremely efficient way to search the line while capturing and
% isolating our variables of interest all at once. 
%
% pattern2 does the same as pattern1, but specifically for the Serial Number 
% of the CTD. This pattern was sufficiently different from the
% calib coeff variable pattern such that they could not be combined. 
% Dont try to do it. It will only bring you **strife**. 
%
%% *1 Stand Dev & Variance calculation 
% both of these are done with a population calc. This is different than a 
% calc done for a sample relative to a dataset. 
% 
% *stddev
% population calculation:
%   stddev = sqrt( (1/N) * sum( abs( data(1:end) .- mean)^2 ) )
% sample calculation:
% stddev = sqrt( (1/(N-1)) * sum( abs( datapoint -mean)^2 ) )
%   
% *var:
%   the "1" flag here divides by N for a population calculation, as opposed
%   to calculation for a particular sample. 
%   population calculation:
%       var = (1/N) * sum( abs(data(1:end) .- mean)^2 )
%   sample calculation:
%       var = (1/N-1) * sum( abs( datapoint - mean)^2 )


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % col_data = [tempStruct.(fN_num{m})];
        % stats(1).(fN_num{m}) = mean(col_data, 'omitnan');
        % stats(2).(fN_num{m}) = median(col_data, 'omitnan');
        % stats(3).(fN_num{m}) = std(col_data, 1, 'omitnan'); % *stddev
        % stats(4).(fN_num{m}) = var(col_data, 1, 'omitnan'); % *var