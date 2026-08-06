function rename_oldCruiseMetaFiles_OXY()
% This code modifies the oxygen data line in NAVIS float meta files. 
% Previously this was one line, now it is three. 
% The meta files to be changed exist in argus/data1/argo/metadata/from_aoml_20250501
% The excel file, old_cruise_meta_organized_SN2.xlsx, contains a sheet called
% 'NAVIS_OXYdata located in /argus/data1/argo/doc, which tells the matlab
% code which meta files contain the NAVIS float information, and therefore, 
% which ones for which to modify the oxygen lines
%%
addpath /argus/data1/argo/doc
excelFile = 'old_cruise_meta_organized_SN3.xlsx'; 
sheetName = 'NAVIS_OXYdata';  % Adjust if needed

%% Step 0: Read Excel
T = readtable(excelFile, 'Sheet', sheetName);
T.aomlnum = string(T.aomlnum);  % ensure string type for matching
T.aomlnum = string(compose('%04d', double(T.aomlnum)));


%% Step 1: List all files starting with 4 or 5 digit aoml number 
% Define paths
addpath /argus/data1/argo/metadata/from_aoml_20250501/
subFolder = input('Enter subfolder name e.g., "active" "archived" "dead" or "malfunction": ', 's');
basePath = '/argus/data1/argo/metadata/from_aoml_20250501/';
folderPath = fullfile(basePath, subFolder);
allFiles = dir(fullfile(folderPath, '*.meta'));  % Adjust extension if needed
fileNames = {allFiles.name};
pat = '^\d{4,5}_';  % regex for 4 or 5 digits followed by underscore

% basePath = '/argus/data1/argo/metadata/kat_files_for_aoml';
% folderPath = fullfile(basePath);
% allFiles = dir(fullfile(folderPath, '*.meta'));  % Adjust extension if needed
% fileNames = {allFiles.name};
% pat = '^\d{4,5}_';  % regex for 4 or 5 digits followed by underscore

logNAV_NotOnList=[]; logMissing_OXYdata=[]; logMaskErr=[]; log_all_NS_data=[]; logPermissionErr=[]; logModifiedOxyMetaFiles=[];
%% Step 2: Loop over files
for i = 1:length(fileNames)
    fname = fileNames{i};

 %% Step 3: Read file
    filePath = fullfile(folderPath, fname);
    lines_orig = readlines(filePath, 'WhitespaceRule', 'preserve');
    lines_orig = cellstr(lines_orig);  % Convert to cell array of char vectors

    %% Step 4: Modify line of interest
    oxy_data_line = 'calib coef for oxygen';
    mask = contains(lower(lines_orig), oxy_data_line);
        NAVIS_line = 'navisir_';
        NAVmask = contains(lower(lines_orig), NAVIS_line);
        % % NAV_idx = find(NAVmask,1)
        

    if any(mask) && any(NAVmask) && sum(mask+NAVmask)==2 %if the file is both a NAVIS && has the 'calib coef for oxygen' line
    
        %this part matches the file name to a file in the excel sheet 
        match = regexp(fname, pat, 'match');    %parses aoml# of file name
        if isempty(match), continue; end        %if aoml doesnt match our standard we continue. i.e. only 4-5 digit aoml numbers valid
        fileID = extractBefore(match{1}, '_');  %we extract just the aoml#, no underscore
        % Look for matching row in Excel
        rowIdx = find(T.aomlnum == fileID);
        if isempty(rowIdx)
            logNAV_NotOnList=[logNAV_NotOnList; {fname}];
        continue; end
    
        idx = find(mask,1);
        old_oxy_line = lines_orig(idx);
        oldline_nums = strtrim(extractAfter(old_oxy_line,oxy_data_line));
          
            % Extract key=value pairs using regular expressions
            old_oxy_line{1} = [old_oxy_line{1} ';']; %makes sure the line ends with a semicolon, otherwise the regex wont work
            tokens = regexp(old_oxy_line{1}, '([A-Z]+[0-9]*)=([-+.\deE]+);','tokens') ;

            tokens1 = vertcat(tokens{:});
            tokens2 = sortrows(tokens1, 1); %this sorts the tokens before continuing so that they get grouped in alphabetical order 
            % Initialize containers
            groupAB = {};
            groupCE = {};
            groupTA = {};
            groupCatchAll = {};
            % Categorize and reformat
            for j = 1:size(tokens2,1)
                key = tokens2{j,1};  % Get key directly
                val = tokens2{j,2};  % Get value directly
                    %keep track of if there was any empty oxygen variable 
                    switch strtrim(val)
                        case {'', 'n/a', ' '}
                        valStatus=1;
                        logMissing_OXYdata=[logMissing_OXYdata; {'key''=''val'';'}]
                        otherwise 
                        valStatus=0;end
            
                if startsWith(key, 'TA')
                    groupTA{end+1} = sprintf('%s=%s;', key, val);
                elseif startsWith(key, 'C') || startsWith(key, 'E')
                    if startsWith(key, 'C')
                        key = lower(key);
                    end
                    groupCE{end+1} = sprintf('%s=%s;', key, val);
                elseif startsWith(key, 'A') || startsWith(key, 'B')
                    key = lower(key);
                    groupAB{end+1} = sprintf('%s=%s;', key, val);
                else 
                    key=lower(key)
                    groupCatchAll{end+1} = sprintf('%s=%s;', key, val)
                end
            end
    
    
            % Save log to Excel if any problematic OXY values were found
            if exist(logMissing_OXYdata,'var') && ~isempty(logMissing_OXYdata) || exist(groupCatchAll, 'var') && ~isempty(groupCatchAll)
                log_all_NS_data = [log_all_NS_data; {fname}, {logMissing_OXYdata; groupCatchAll}]
            end
    
            % Create final grouped strings
            lineAB = ['calib coef for O2                       ', strjoin(groupAB, '')];
            lineCE = ['calib coef for O2                       ', strjoin(groupCE, '')];
            lineTA = ['calib coef for TEMP_DOXY                ', strjoin(groupTA, '')]; %DO NOT REMOVE SPACES. 
                    %On the off chance you have deleted the spaces, lines AB & CE have 23 spaces. line TA has 16 spaces. -_- 
            
            % Replace the original line with new grouped lines
            lines_mod = lines_orig; %creating a copy of the original lines called modified lines
            lines_mod(idx) = [];  % Remove the 'calib coef for oxygen' line, located at index or "idx"
            % Insert the new lines at the same index
            lines_new = [lines_mod(1:idx-1); lineAB; lineCE; lineTA; lines_mod(idx:end)];
            
            % Write the modified lines back to the file, but only if necessary
            [fid,message] = fopen(filePath, 'w');
            if fid < 0
                error('Failed to open meta file %s because: %s\n', fname, message);
                logPermissionErr=[logPermissionErr; {fname, message}];
            end

                %below we check if the new lines already match the lines in the
                %file, if so we leave them alone (though note this shouldnt
                %happen anyway because the code is based on a mask of the
                %original line 'calib coef for oxygen' line which should be
                %missing if it has already been replaced. But we love redundancy <3
                if isequal(lines_orig{idx:idx+2}, lines_new{idx:idx+2})
                    fprintf('file %s has already been modified for OXY data, moving on, like your ex\n', fname)
                else
                    writelines(lines_new,filePath)
                    fprintf('Updated ''calib coef for oxygen'' field for %s\n', fname);
                    %Log the meta file numbers we have modified to be in the new format
                    logModifiedOxyMetaFiles = [logModifiedOxyMetaFiles; {fname}];
                end

            fclose(fid);
    elseif sum(mask)+sum(NAVmask)>2 
        errorSheetName = 'mask_error_'+subFolder;
        idx = find(mask,1);
        idxNav = find(NAVmask,1);
        logMaskErr = [logMaskErr; {fname, [idx, idxNav]}];
        fprintf('this file produced an error when trying to find the ''calib coef for oxygen'' line, saved to the %s log', errorSheetName)
    end
end

% Define unified log file path
logFile = fullfile(basePath, ['OXYlogs.xlsx']);  % Single Excel file

% Log 1: Missing or Invalid PI
if exist('logNAV_NotOnList', 'var') && ~isempty(logNAV_NotOnList)
    logTable = cell2table(logNAV_NotOnList, 'VariableNames', {'Filename'});
    sheetName = strcat('Invalid_PI_', subFolder);
    writetable(logTable, logFile, 'Sheet', sheetName);
    fprintf('Missing/non-standard PI log written to sheet %s in: %s\n',sheetName, logFile);
end

% Log 2: Log Non standard data
if exist('log_all_NS_data', 'var') && ~isempty(log_all_NS_data)
    logTable1 = cell2table(log_all_NS_data, 'VariableNames', {'Filename', 'NonStandardData'});
    sheetName1 = strcat('NS_Data_',subFolder);
    writetable(logTable1, logFile, 'Sheet', sheetName1);
    fprintf('Non-standard data log written to sheet %s in: %s\n',sheetName1, logFile);
end

% Log 3: Permission Errors
if exist('logPermissionErr', 'var') && ~isempty(logPermissionErr)
    logTable2 = cell2table(logPermissionErr, 'VariableNames', {'Filename', 'Error_Message'});
    sheetName2 = strcat('Perm_Err_',subFolder);
    writetable(logTable2, logFile, 'Sheet', sheetName2);
    fprintf('Permission error log written to sheet %s in: %s\n',sheetName2, logFile);
end

% Log 4: Mask Errors
if exist('logMaskErr', 'var') && ~isempty(logMaskErr)
    logTable3 = cell2table(logPermissionErr, 'VariableNames', {'Filename', 'indicies of errors'});
    sheetName3 = strcat('Mask_Errs_',subFolder);
    writetable(logTable3, logFile, 'Sheet', sheetName3);
    fprintf('Permission error log written to sheet %s in: %s\n',sheetName3, logFile);
end

%% LOG WHAT YOU CHANGED
if exist('logModifiedOxyMetaFiles', 'var') && ~isempty(logModifiedOxyMetaFiles)
    logTable4 = cell2table(logModifiedOxyMetaFiles, 'VariableNames', {'Filename'});
    sheetName4 = strcat('Mod_OXY_Meta_',subFolder);
    writetable(logTable4, logFile, 'Sheet', sheetName4);
    fprintf('Modified metafiles log written to sheet %s in: %s\n',sheetName4, logFile);
end

fprintf('done \n')
%% 