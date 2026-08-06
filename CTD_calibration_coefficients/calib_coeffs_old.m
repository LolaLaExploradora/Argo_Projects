function calib_coeffs(inputFolder)
% Lola Pierson - sara.pierson@whoi.edu
% ARGO, WHOI
% Dec 30, 2025

% =========================================================================
% Extract calibration variables from WHOI Checklogs (NOT MRV checklogs) 
%
% This code loops through the /argus/data1/lab/SOLO_II/Checklogs directory,
% reading in each valid checklog (criteria below) and logging the most
% recent calibration coefficients. 
% This code outputs an excel sheet: all_calibration_coeffs.xlsx 
% with the recently read-in calib coeffs appended to the list. 
% The code also outputs three .mat files: 
% /argus/data1/lab/SOLO_II/Checklogs/calibration_coeffs.mat --> ccStruct
% /argus/data1/lab/SOLO_II/Checklogs/calibration_coeffs_EmptyFiles.mat --> ccEmptyStruct
% /argus/data1/lab/SOLO_II/Checklogs/calibration_coeffs_AllFiles.mat --> ccAllStruct
%
% There are 24 calibration coefficients for SBE41CP CTDs.
%
% There is an Index at end of this code for extra information.
% *1, *2, *3, etc. Denote parts of code with Indexed information 
%
% =========================================================================


% Path to the input folder containing CHK files
inputFolder = '/argus/data1/lab/SOLO_II/Checklogs';   % <-- UPDATE THIS IF NEEDED

% Set output folder for Excel file
outputFolder = '/argus/data1/lab/SOLO_II/Checklogs';  % <-- UPDATE THIS IF NEEDED
outputFileName = 'all_calibration_coeffs.xlsx';
outputExcel = fullfile(outputFolder, outputFileName);

% Get all files (with or without extension) in the folder
allFiles = dir(fullfile(inputFolder, '*'));

%% Filter Checklog directory for valid checklog files/filenames: 
% The pattern has two parts to capture the naming conventions found in the
% directory 
% 1: CHK + 4-7 digits + optional .txt or .log ex: CHK1234.txt or CHK01234
% 2: 4-7 digits + Chklog / Checklog / CheckLog / Check Log 
% 2-2-26 Lola - reduced to just the first pattern, the second was
% unnecessary 
pattern = '^(CHK\d{4,7}(\.(txt|log))?)$';%...                                   % pattern 1
          % '|\d{4,7}_?(Chklog|Checklog|CheckLog|Check Log)(\.(txt|log))?)$'];  % pattern 2

           
% CASE-INSENSITIVE MATCHING
% Creates a mask for identifying valid checklogs 
isMatch = ~[allFiles.isdir] & ...
          cellfun(@(x) ~isempty(regexp(x, pattern, 'once', 'ignorecase')), {allFiles.name});
    
    % MATCHING FILES
    fileList = allFiles(isMatch);
         CHKfile_Properties = struct2table(fileList);
         CHKfile_Properties.name_caseinsen = lower(CHKfile_Properties.name);
         CHKfile_Properties = sortrows(CHKfile_Properties, {'name_caseinsen', 'datenum'}, {'ascend', 'descend'});
         isNewestCHKfile = [true; ~strcmp(CHKfile_Properties.name(2:end), CHKfile_Properties.name(1:end-1))];
    % COLLECT NON-MATCHING FILES 
    nonMatchingList = allFiles(~[allFiles.isdir] & ~isMatch); 
    % REMAINING ENTRIES (directories, system files, etc.)
    otherList = allFiles([allFiles.isdir]);

    % Here code user is notified if files are missed and not organized into
    % one of the three groupings
    sum_match_nonmatch_other = sum(isMatch)+length(nonMatchingList)+length(otherList);
    fprintf(['There are %d files in your original folder, ' ...
        'The sum of matching files, non-matching, and "other" files is %d\n' ...
        'If these do not match, a file has been missed.' ], sum(allfiles), sum_match_nonmatch_other)

%% Create Struct - Initialize with Variable Names
% note that I tried to make this dynamically (1 line)
% and for the life of me I have no idea why it wouldnt work. Please explain
% it to me if you know what went wrong and I would be happy to update.

    % Target variable names = calibration coefficients
    % Note that the "=" are necessary, I have tried this code without them and
    % you end up capturing random/incorrect data because the checklogs contain 
    % too many random letter/number sets that erroneously match  
    targetVars = ["SERIAL NO", "TA0 = ", "TA1 = ", "TA2 = ", "TA3 = ","G = ", ...
                  "H = ", "I = ", "J = ", "CTCOR = ", "CPCOR = ", "WBOTC = ", ...
                  "PA0 = ", "PA1 = ", "PA2 = ", "PTCA0 = ", "PTCA1 = ", "PTCA2 = ", ...
                  "PTCB0 = ", "PTCB1 = ", "PTCB2 = ", "PTHA0 = ", "PTHA1 = ", ...
                  "PTHA2 = ", "POFFSET = ", "CONDUCTIVITY", "TEMPERATURE", "PRESSURE S/N"];

fNames = matlab.lang.makeValidName(["Checklog" "CTDtype" erase(targetVars, "=")]);
ccStruct = struct(); %calib coeff struct
for i = 1:numel(fNames)
    disp(fNames(i))
    ccStruct.(fNames(i))=[];
end

%% Additional Structs 
% ccEmpty Struct - documents Checklogs do not contain Calibration Coefficients
% when no calibration coefficients are found, NaNs are found in the .mat file.
% ccAllStruct - a list of all checklogs and the calibration coefficients
% found, whether NaNs or otherwise. 
ccEmptyStruct = ccStruct;
ccAllStruct = ccStruct;

%% Loop through all valid Checklogs in Checklog directory
pattern1 = '\s*( TA0| TA1| TA2| TA3| G| H| I| J| CTCOR| CPCOR| WBOTC| PA0| PA1| PA2| PTCA0| PTCA1| PTCA2| PTCB0| PTCB1| PTCB2| PTHA0| PTHA1| PTHA2| POFFSET)\s=\s*([+-]?(?:\d+\.?\d*|\.\d+)(?:[eE]\s*[+-]?\s*\d+)?)';
pattern2 = '(SERIAL NO)\.\s*(\d{4,})';
pattern3 = '(CONDUCTIVITY | TEMPERATURE| PRESSURE S/N).*:\s*(\d{2}-[A-Za-z]{3}-\d{2})$'; 
% Loop through matching files
for j = 1:length(fileList)
    fileName = fileList(j).name
    filePath = fullfile(fileList(j).folder, fileName);

    % Create a map for storing calibration coefficient values to their respective names for this file 
    valueMap = containers.Map(erase(targetVars," = "), repmat({""}, size(targetVars)) );
    ctdType = NaN; %this gets overwritten if a CTD serial number is found

    % Search each line only if it contains one of the targetVars (i.e. if it contains the calibration coefficient
    fid = fopen(filePath);
    while ~feof(fid) 
        line = fgetl(fid);
        matchIdx = find(contains(line, targetVars), 1);
        if ~isempty(matchIdx)
            % Tokenize (split at "=")
            tokens = regexp(line, pattern1, 'tokens', 'once');
            tokens_sn = regexp(line, pattern2, 'tokens', 'once');
            tokens_caldate = regexp(line, pattern3, 'tokens', 'once');
            if ~isempty(tokens)
                varName = strtrim(string(tokens{1}));
                varValue = string(tokens{2});
                valueMap(varName) = varValue;
            end
            if ~isempty(tokens_sn)
                varName = strtrim(string(tokens_sn{1}));
                varValue = string(tokens_sn{2}); 
                valueMap(varName) = varValue; 
                    % Lines containing "SERIAL NO" should always be Preceeded by the CTD type, hence we extract before
                    % the key iff (iff: if and only if) the key is found to identify the CTD Serial No
                    ctdTypeRaw = extractBefore(line, "SERIAL NO");
                    %ctdType = strtrim(regexprep(ctdTypeRaw, '(\[[^\]]*\]\s*', ''))
                    ctdType = strtrim(regexprep(ctdTypeRaw, '^\s*(\[[^\]]*\]|[A-Za-z]{9}\s#)\s*', ''));
            end
            if ~isempty(tokens_caldate)
                varName = strtrim(string(tokens_caldate{1}));
                varValue = string(tokens_caldate{2})
                valueMap(varName) = varValue;
            end
        end
    end

    % Store calibration coeffs and other variables into the struct column
    % with a matching name 
    rowValues = [];
    for k = 1:length(targetVars)
        % use erased variable name (without " = ") as key
        cleanVar = erase(targetVars(k)," = ");
        rowValues(k) = valueMap(cleanVar); 
    end

    %% Append each Checklog's Calibration Coefficient Data to Main Struct
    % Add checklog name to cell array (rowValues) containing this checklog's specific calib coeff data
    % and convert this cell array to a 1-row, temporary struct with
    % matching fieldnames to the structs we initialized - the "main" structs. The temporary structs
    % with each checklog's specific calib coeff info get appended to the end of the main structs. 
    rowStruct_all = cell2struct( [{fileName} {ctdType} num2cell(rowValues)], fNames, 2 );
    ccAllStruct(j)= rowStruct_all;
    
    if all( isnan(rowValues(2:end)) ) 
        rowStruct_empty = cell2struct( [{fileName} {ctdType} num2cell(rowValues)], fNames, 2 );
        ccEmptyStruct(end+1)= rowStruct_empty; 
    else 
        %% LOLA -- here is where to make if statement 
        % to take care of duplicate CHK logs. we can keep the duplicates in
        % the "allFiles" .mat file to understand changes/updates to
        % hardware, but here we want just the "working" calib coeffs in
        % deployed floats. 
        rowCell_cc = cell2struct( [{fileName} {ctdType} num2cell(rowValues)], fNames, 2 );
        ccStruct(end+1)= rowCell_cc; 
    end
end

%% Save structs as .mat files
ccStruct(1)=[];
ccEmptyStruct(1)=[];

save('/argus/data1/lab/SOLO_II/Checklogs/calibration_coeffs.mat', 'ccStruct')
save('/argus/data1/lab/SOLO_II/Checklogs/calibration_coeffs_EmptyFiles.mat', 'ccEmptyStruct')
save('/argus/data1/lab/SOLO_II/Checklogs/calibration_coeffs_AllFiles.mat', 'ccAllStruct')

%% Write Data to Excel sheet 
% Ensure output folder exists
if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end

%% Save structs 
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
    % Write non-matching files to second sheet
    if ~isempty(nonMatchingList)
        nonMatchTable = table({nonMatchingList.name}', 'VariableNames', {'NonMatchingFiles'});
        writetable(nonMatchTable, outputExcel, 'Sheet', 'Skipped_Files');
    % If no skipped files, still create sheet with note
    else
        nonMatchTable = table("No skipped files", 'VariableNames', {'NonMatchingFiles'});
        writetable(nonMatchTable, outputExcel, 'Sheet', 'Skipped_Files');
    end
    % Write 'other' files to a sheet in the excel file.  
    if ~isempty(otherList)
        otherTable = table({otherList.name}', 'VariableNames', {'OtherEntries'});
        writetable(otherTable, outputExcel, 'Sheet', 'Other_Items');
    end

%% 

disp("Done! Results written to: " + outputExcel);
disp("Note that SERIAL NO in your excel output refers to CTD serial number \n ..." + ...
    "use coreArgo_calib_coeff_plots.m to plot calibration coefficients \n ..." + ...
    "and use new_float_calib_coeff_plots.m to process new checklogs into the database")





