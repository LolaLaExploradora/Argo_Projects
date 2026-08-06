function temp_plots = new_float_calib_coeff(CHK_file_list, cruisename, year)
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
% cruisename should be input as a string,
% ex: "A16S-RR2602-2026"
%
% Cruisename can be found in the Deployment google sheet and as of 2025 has 
% a standardized format, please reach out to Lola if you are unsure of this 
% name (but in emergencies use what makes sense, the reason to use the 
% standardized/"official" name is to keep our own book-keeping organized 
% and easily searchable but can be adjusted after the fact if necessary. 
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


% Path to the input folder containing CHKLOG files
inputFolder = '/argus/data1/lab/SOLO_II/Checklogs';   % <-- UPDATE THIS IF NEEDED
outputFolder = '/argus/data1/lab/SOLO_II/Checklogs/Calibration_Coeffs';  % <-- UPDATE THIS IF NEEDED
outputFileName = 'all_calibration_coeffs.xlsx';
outputExcel = fullfile(outputFolder, outputFileName);

% Load in the .mat file that contains the historical database of
% calibration coefficients for all WHOI floats. 
load('/argus/data1/lab/SOLO_II/Checklogs/Calibration_Coeffs/calibration_coeffs.mat');
ccStruct = ccStruct;
load('/argus/data1/lab/SOLO_II/Checklogs//Calibration_Coeffs/calibration_coeffs_EmptyFiles.mat');
ccEmptyStruct = ccEmptyStruct;
load('/argus/data1/lab/SOLO_II/Checklogs/Calibration_Coeffs/calibration_coeffs_AllFiles.mat');
ccAllStruct = ccAllStruct;


%% Create Struct - Initialize with Variable Names
% %note that I tried to make this dynamically (in one line)
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

fNames = matlab.lang.makeValidName(["Checklog" "CTDtype" erase(targetVars, "=")]);

pattern1 = '\s*( TA0| TA1| TA2| TA3| G| H| I| J| CTCOR| CPCOR| WBOTC| PA0| PA1| PA2| PTCA0| PTCA1| PTCA2| PTCB0| PTCB1| PTCB2| PTHA0| PTHA1| PTHA2| POFFSET)\s=\s*([+-]?(?:\d+\.?\d*|\.\d+)(?:[eE]\s*[+-]?\s*\d+)?)';
pattern2 = '(SERIAL NO)\.\s*(\d{4,})';
 
fNames = matlab.lang.makeValidName(["Checklog" "CTDtype" erase(targetVars, "=")]);
ccNewFloats = struct(); %calib coeff struct
for i = 1:numel(fNames);
    disp(fNames(i));
    ccNewFloats.(fNames(i))=[];
end

%% Loop through CHK file(s) 
for j = 1:length(CHK_file_list)
    fileName = CHK_file_list(j); %make a failsafe here for if the checklog is not found. Just an output statement is fine. 
    filePath = fullfile(inputFolder, fileName);
    
    %% if the CHK file is not found, skip it and notify the user. 
    if ~isfile(filePath)
        fprintf('Warning: Checklog %s not found in directory: %s', fileName, ARGUSCHK);
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
    else 
        %% LOLA -- here is where to make if statement 
        % to take care of duplicate CHK logs. we can keep the duplicates in
        % the "allFiles" .mat file to understand changes/updates to
        % hardware, but here we want just the "working" calib coeffs in
        % deployed floats. 
        rowStruct_cc = cell2struct( [{fileName} {ctdType} num2cell(rowValues)], fNames, 2 );
        ccStruct(end+1)= rowStruct_cc; 
        ccNewFloats(j) = rowStruct_cc;
    end
end

%% Save updated .mat files
save('/argus/data1/lab/SOLO_II/Checklogs/calibration_coeffs.mat', 'ccStruct')
save('/argus/data1/lab/SOLO_II/Checklogs/calibration_coeffs_EmptyFiles.mat', 'ccEmptyStruct')
save('/argus/data1/lab/SOLO_II/Checklogs/calibration_coeffs_AllFiles.mat', 'ccAllStruct')

%% Save updated .mat file to excel sheet/Update excel sheet
% resultTab0: Subset of results excluding checklogs with no calibration coefficient
%             entries (i.e. if all calib coeffs are NaNs - those are not included here). 
%             Written to sheet "CalibCoeff_Files" 
% resultTab1: Subset of results which contain only NaNs. Written to sheet "CalibCoeff_Empty_Files"
% resultTab2: All checklog results. Written to first sheet called "CalibCoeff_All_Files"
resultTab0 = struct2table(ccStruct);
resultTab1 = struct2table(ccEmptyStruct);
resultTab2 = struct2table(ccAllStruct);

writetable(resultTab0, outputExcel, 'Sheet', 'CalibCoeff_Files');
writetable(resultTab1, outputExcel, 'Sheet', 'CalibCoeff_Empty_Files');
writetable(resultTab2, outputExcel, 'Sheet', 'CalibCoeff_All_Files');

disp("Updated .mat files saved, results also written to: " + outputExcel)

%==========================================================================
%% Call funciton to update figures
% in the works
%==========================================================================

%% Standard Deviation and Varience calculation *1
ctdTypes = string({ccStruct.CTDtype});
unique_ctdTypes = unique(upper(ctdTypes))';

% OLD CORE ARGO SBE 41 ALACE CP CTDS
inds1 = find( string({ccStruct.CTDtype}) == unique_ctdTypes(1) );
    ccStruct_ALACE3A = ccStruct(inds1);
inds2 = find( string({ccStruct.CTDtype}) == unique_ctdTypes(2) );
    ccStruct_ALACE3C = ccStruct(inds2);
% CORE ARGO SBE41CP CTDS
inds3 = find( string({ccStruct.CTDtype}) == unique_ctdTypes(3) );
    ccStruct_V725 = ccStruct(inds3);
inds4 = find( string({ccStruct.CTDtype}) == unique_ctdTypes(4) );
    ccStruct_V731 = ccStruct(inds4);
% DEEP ARGO SBE61 CTDS
inds5 = find( string({ccStruct.CTDtype}) == unique_ctdTypes(5) );
    ccStruct_61V502 = ccStruct(inds5);
inds6 = find( string({ccStruct.CTDtype}) == unique_ctdTypes(6) );
    ccStruct_61V503 = ccStruct(inds6);

save('/argus/data1/lab/SOLO_II/Checklogs/calibration_coeffs_ALACE3A.mat', "ccStruct_ALACE3A")
save('/argus/data1/lab/SOLO_II/Checklogs/calibration_coeffs_ALACE3C.mat', "ccStruct_ALACE3C")
save('/argus/data1/lab/SOLO_II/Checklogs/calibration_coeffs_V725.mat', "ccStruct_V725")
save('/argus/data1/lab/SOLO_II/Checklogs/calibration_coeffs_V731.mat', "ccStruct_V731")
save('/argus/data1/lab/SOLO_II/Checklogs/calibration_coeffs_61V502.mat', "ccStruct_61V502")
save('/argus/data1/lab/SOLO_II/Checklogs/calibration_coeffs_61V503.mat', "ccStruct_61V503")


%% Calculate mean, median, stddev, and variance of dataset wrt CTD type
%% Z score calculated for each calibration coefficient for each new float in list
% Each CTD type will have its own statistics and we compare new floats to
% those particular statistics. 

fN_num = fieldnames(ccStruct);
fN_num = fN_num(4:end); %only the fields of numeric data, i.e. the fields with calib coeff data
fN_num = [{'label'}; fN_num];

stats = struct('label', {'mean', 'median', 'stddev', 'var'});

for ooo = 1:length(CHK_file_list)
    newFloat_CTD = upper(string(ccNewFloats(ooo).CTDtype));
    switch newFloat_CTD
        case "SBE 41CP V 7.2.5"
            load([ARGUSCALCOYR + "stats_2025_SBE41CP_V725.mat"])
            %tempStruct = ccStruct_V725;
            tempStruct = stats;
            excel_doc = 'calibration_coeffs_V725';
        case "SBE 41CP V 7.3.1"
            load([ARGUSCALCOYR + "stats_2025_SBE41CP_V731.mat"])
            %tempStruct = ccStruct_V731;
            tempStruct = stats;
            excel_doc = 'calibration_coeffs_V731';
        case "SBE 61 V 5.0.2"
            load([ARGUSCALCOYR + "stats_2025_SBE61_V502.mat"])
            %tempStruct = ccStruct_61V502;
            tempStruct = stats;
            excel_doc = 'calibration_coeffs_61V502';
        case "SBE 61 V 5.0.3"
            load([ARGUSCALCOYR + "stats_2025_SBE61_V503.mat"])
            %tempStruct = ccStruct_61V503;
            tempStruct = stats;
            excel_doc = 'calibration_coeffs_61V503';
        case "SBE 41 ALACE-CP V 3.0A"
            load([ARGUSCALCOYR + "stats_2025_SBE41_ALACE3A.mat"])
            %tempStruct = ccStruct_ALACE3A;
            tempStruct = stats;
            excel_doc = 'calibration_coeffs_ALACE3A';
        case "SBE 41 ALACE-CP V 3.0C"
            load([ARGUSCALCOYR + "stats_2025_SBE41_ALACE3C.mat"])
            %tempStruct = ccStruct_ALACE3C;
            tempStruct = stats;
            excel_doc = 'calibration_coeffs_ALACE3C';
        otherwise 
            warning('Unknown CTD type %s found in %s', newFloat_CTD, CHK_file_list(ooo))
            continue
    end

    for m = 2:numel(fN_num)
        % col_data = [tempStruct.(fN_num{m})];
        % stats(1).(fN_num{m}) = mean(col_data, 'omitnan');
        % stats(2).(fN_num{m}) = median(col_data, 'omitnan');
        % stats(3).(fN_num{m}) = std(col_data, 1, 'omitnan'); % *stddev
        % stats(4).(fN_num{m}) = var(col_data, 1, 'omitnan'); % *var
            cc_data_point = ccNewFloats(ooo).(fN_num{m});
            cc_dataset_mean = tempStruct(1).(fN_num{m});
            cc_dataset_std = tempStruct(3).(fN_num{m});
        z_score_classic = (cc_data_point - cc_dataset_mean)/cc_dataset_std ;
        zscore(ooo).Checklog = CHK_file_list(ooo);
        zscore(ooo).CTDtype = ccNewFloats(ooo).CTDtype;
        zscore(ooo).SERIALNO = ccNewFloats(ooo).SERIALNO;
        zscore(ooo).(fN_num{m}) = z_score_classic;
        % Make histogram plots for subsets of calibration coefficient
        % variables. i.e. Temperature, Conductivity, and Pressure 
        switch m
            case {2,3,4,5} %i.e. if fN_num == TA0, TA1, TA2, or TA3
                cc_dataset_hist = [tempStruct.(fN_num{m})];
                subplot(2,2,m-1); histogram(cc_dataset_hist)
            
            case {6,7,8,9,10,11,12}

            case {13,14,15,16,17,18,19,20,21,22,23,24,25}

        end

        %title each plot wrt main figure handle & save to webpage 
        % THE TWO LINES BELOW ARE EXS FROM OTHER CODE FOR EASE 
        % you need three sets of these lines. one for each figure 
        % fileName = sprintf('%s_fullplot_histogram.png', var_name_str);
        % exportgraphics(gcf, fullfile( ['/argus/data1/argo/www/calib/'+ctdtypename] , fileName))
    end
end


% stats_T  = rows2vars( struct2table(stats));
% zscore_T = rows2vars( struct2table(zscore));
stats_T  = struct2table(stats);
zscore_T = struct2table(zscore);

fig = figure('Units', 'inches', 'Position',[0 0 8.5 11], 'Color','w')
    ax = axes(fig); axis(ax,'off'); ax.Position = [0 0 1 1];
pageTitle = 'Z score values for new float list';
    text(0.5, 0.98, pageTitle,'FontSize', 14,'FontWeight', 'bold', ...
        'HorizontalAlignment', 'center', 'Units', 'normalized'); % Adds title at the top
subTitle = {'z-score is a measure of standard deviation.'
            '0-1 is within one stddev'
            '1-2 is within 2 stddevs'
            '2-3 is over 2 stddevs away from the mean of the data'
            'anything over 2 should be looked at more closely.'}
    text(0.5, 0.925, subTitle,'FontSize', 10,'FontAngle', 'italic', ...
        'HorizontalAlignment', 'center', 'Units', 'normalized');

table_txt = evalc('disp(zscore_T)');
    table_txt = regexprep(table_txt,'<[^>]*>',''); % removes the html tags
    table_txt = regexprep(table_txt,'[\{\}''"]',''); % removes {}, '', ""
    t = text(0.05,0.865, table_txt,'FontName','Courier','FontSize', 10, 'VerticalAlignment','top', ...
    'Interpreter','none', 'Units','normalized');

set(fig,'PaperUnits','inches')
set(fig,'PaperPosition',[0 0 8.5 11])
set(fig,'PaperOrientation','portrait')

exportgraphics(fig, [ARGUSCALCO + "/z_scores/" + "zscores_output" + ".pdf"] ,'ContentType','vector');
fprintf('\n zscore figure saved to %sz_scores as pdf.\n WARNING: this figure will be overwritten. \n See the xlsx sheet in %s for saved values.\n', ARGUSCALCO, outputFolder,year)

writetable(zscore_T, [outputFolder + "/z_scores/" + year + "_zscores.xlsx"], 'Sheet', cruisename);

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