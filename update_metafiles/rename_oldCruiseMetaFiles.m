function rename_oldCruiseMetaFiles_CruiseID()
% This code takes in corrected cruise names from an excel file and applies
% them back into the metadata files -- the meta files came from AOML in a 
% tarball that exists in argus/data1/argo/metadata/from_aoml_20250501
% The excel file is called old_cruise_meta_organized_SN2.xlsx and is
% located in /argus/data1/argo/doc
%%
addpath /argus/data1/argo/doc
excelFile = 'old_cruise_meta_organized_SN2.xlsx'; 
sheetName = 'Sheet1';  % Adjust if needed

% Step 1: Read Excel
T = readtable(excelFile, 'Sheet', sheetName);
T.aomlnum = string(T.aomlnum);  % ensure string type for matching
T.aomlnum = string(compose('%04d', double(T.aomlnum)));
T.New_CruiseID = string(T.New_CruiseID);

% Step 2: List all files starting with 4 or 5 digit aoml number in tarball
% directory. Define paths
addpath /argus/data1/argo/metadata/from_aoml_20250501
subFolder = input('Enter subfolder name e.g., "active" "archive" "dead" or "malfunction": ', 's');
basePath = '/argus/data1/argo/metadata/from_aoml_20250501';
folderPath = fullfile(basePath, subFolder);
allFiles = dir(fullfile(folderPath, '*.meta'));  % Adjust extension if needed
fileNames = {allFiles.name};
pat = '^\d{4,5}_';  % regex for 4 or 5 digits followed by underscore

logMultiAOML=[]; logPermissionErr=[];
% Step 3: Loop over files
for i = 1:length(fileNames)
    fname = fileNames{i};
    match = regexp(fname, pat, 'match');
    if isempty(match), continue; end
    fileID = extractBefore(match{1}, '_');
    
    % Look for matching row in Excel
    rowIdx = find(T.aomlnum == fileID);
    if isempty(rowIdx), continue; end
    newCruiseID = T.New_CruiseID(rowIdx);
        
    %Check if you have multiple entries for the aomlnum
        if numel(newCruiseID) > 1
            fprintf('Multiple entries detected:\n');
            for  j = 1:numel(newCruiseID)
                fprintf('  [%d] %s\n', j, string(newCruiseID(j))); end
                idx = input('Select the index of the entry you want to use: ');
                logMultiAOML = [logMultiAOML; {fname, [T.aomlnum(rowIdx(1)), T.aomlnum(rowIdx(2))]}];
                % Validate input
                if idx >= 1 && idx <= numel(newCruiseID)
                    newCruiseID = newCruiseID(idx);
                else
                    error('Invalid selection. Exiting.'); end
        end
    
    % Step 4: Read file
    filePath = fullfile(folderPath, fname);
    lines = readlines(filePath);

    % Step 5: Modify "deployment cruise ID" line
    mask = contains(lower(lines), "deployment cruise id");
    if any(mask)
        oldLine = lines(mask);
        newLine = "deployment cruise ID                    " + newCruiseID; 
        %there are twenty spaces in the original meta file between these two things so I kept it that way

        % Only update if needed
        if oldLine ~= newLine
            %Try opening the file to check write access
            [fid, message] = fopen(filePath, 'w');
            if fid == -1
                fprintf('Error: Cannot open file %s\n for writing, saved to naughty log', filePath);
                logPermissionErr = [logPermissionErr; {fname, message}]
            else
                fclose(fid);  % Close immediately since writelines will write later
                lines(mask) = newLine;
                writelines(lines, filePath);  % Overwrite original
                fprintf('Updated: %s\n', fname);
            end
        end
    end
end

% Save all log to Excel if any problematic PI values were found
logFile = fullfile(basePath, ['CruiseIDupdate_logs_' subFolder '.xlsx']);  % Unified log file

if exist('logMultiAOML', 'var') && ~isempty(logMultiAOML)
    logTable1 = cell2table(logMultiAOML, 'VariableNames', {'Filename', 'Multi_AOML_Value'});
    writetable(logTable1, logFile, 'Sheet', 'Multi_AOML');
    fprintf('Multi-AOML log written to sheet "Multi_AOML" in: %s\n', logFile);
end

if exist('logPermissionErr', 'var') && ~isempty(logPermissionErr)
    logTable2 = cell2table(logPermissionErr, 'VariableNames', {'Filename', 'Error_Message'});
    writetable(logTable2, logFile, 'Sheet', 'Permission_Errors');
    fprintf('Permission error log written to sheet "Permission_Errors" in: %s\n', logFile);
end
%% 

