function rename_oldCruiseMetaFiles_PIs()
% This code takes in corrected PI names from an excel file and applies
% them back into the metadata files -- the meta files came from AOML in a 
% tarball that exists in argus/data1/argo/metadata/from_aoml_20250501
% The excel file is called old_cruise_meta_organized_SN2.xlsx and is
% located in /argus/data1/argo/doc
% the corrected PI names are in Sheet2 - "UniquePINames' of this excel file
% and those corrected names get applied to each metafile number in sheet1.
% They do this through matching. All unique names were gathered from Sheet1
% and written down in the "UniquePINames" sheet. If there is a match
% between the original names, then the corrected name is what gets pulled
% into sheet 1 for the 'updated PI Name' field. 
%%
addpath /argus/data1/argo/doc
excelFile = 'old_cruise_meta_organized_SN3.xlsx'; 
sheetName = 'UniquePINames';  % Adjust if needed

%% Step 1: Read Excel
T = readtable(excelFile, 'Sheet', 'Sheet1');
T.aomlnum = string(T.aomlnum);  % ensure string type for matching
T.aomlnum = string(compose('%04d', double(T.aomlnum)));
T.correctedPI = string(T.correctedPI);

%% Step 2: List all files starting with 4 or 5 digit aoml number 
% Define paths
addpath /argus/data1/argo/metadata/from_aoml_20250501/
subFolder = input('Enter subfolder name e.g., "active" "archived" "dead" or "malfunction": ', 's');
basePath = '/argus/data1/argo/metadata/from_aoml_20250501/';
folderPath = fullfile(basePath, subFolder);
allFiles = dir(fullfile(folderPath, '*.meta'));  % Adjust extension if needed
fileNames = {allFiles.name};
pat = '^\d{4,5}_';  % regex for 4 or 5 digits followed by underscore

logMultiAOML=[]; logMissingPI=[]; logPermissionErr=[]; logMaskError=[]; modifiedLog=[];
%% Step 3: Loop over files
for i = 1:length(fileNames) 
    fname = fileNames{i};
    match = regexp(fname, pat, 'match');
    if isempty(match), continue; end         
    fileID = extractBefore(match{1}, '_');         
    
    % Look for matching row in Excel
    rowIdx = find(T.aomlnum == fileID);
    if isempty(rowIdx), continue; end
    newPIName = T.correctedPI(rowIdx);
        
    %Check if you have multiple entries for the aomlnum
        if numel(newPIName) > 1
            fprintf('Multiple entries detected for %s\n :\n', fname);
            for  j = 1:numel(newPIName)
                fprintf('  [%d] %s\n', j, string(newPIName(j))); end
                idx = input('Select the index of the entry you want to use: ');
                logMultiAOML = [logMultiAOML; {fname, [T.aomlnum(rowIdx(1)), T.aomlnum(rowIdx(2))]}];
                fprintf('File %s has multiple aoml-entries, saved to naughty log.\n', fname);
            if idx >= 1 && idx <= numel(newPIName)
                newPIName = newPIName(idx);
            else
                error('Invalid selection. Exiting.'); end
        end

    %% Step 4: Read metafile
    filePath = fullfile(folderPath, fname);
    lines = readlines(filePath);
    
    %% Step 5: Modify "PI" line
    mask = ~cellfun('isempty', regexp(lower(lines), '^pi\s+'));
    if any(mask) && sum(mask)==1
        oldLine = lines(mask);
        % Extract just the value portion after "PI"
        piContent = strtrim(extractAfter(oldLine, "PI"));
        % % Check if it's empty, just spaces, "n/a", "unknown", or "0"
        % if isempty(piContent) | all(piContent == ' ') | ...
        %    strcmpi(piContent, "n/a") | strcmpi(piContent, "unknown") | strcmpi(piContent, "0")
        %    logMissingPI = [logMissingPI; {fname, piContent}];
        %    fprintf('File %s has non-standard or missing PI entry "%s", saved to naughty log.\n', fname, piContent);
        %    continue;
        % end

        newLine = "PI                                      " + newPIName;
        %how many spaces?
        %only update if needed
        if oldLine ~= newLine
            %Try opening the file to check write access
            [fid, message] = fopen(filePath, 'w');
            if fid == -1
                fprintf('Error: Cannot open file %s for writing, saved to naughty log', filePath);
                logPermissionErr = [logPermissionErr; {fname, message}]
            else
                fclose(fid);  % Close immediately since writelines will write later
                lines(mask) = newLine;
                writelines(lines, filePath);  % Overwrite original
                fprintf('Updated PI field in %s from %s to %s\n', fname, piContent, newPIName);
                modifiedLog = [modifiedLog; {fname}];
            end
        end

    else 
        matchIdxs = find(mask);
        logMaskError=[logMaskError; {fname, maskIdxs}];
        fprintf('Error: ''PI'' mask matched to more than one line in %s\n',fname)
    end

end

% Save all log to Excel if any problematic PI values were found
logFile = fullfile(basePath, ['PIupdate_logs.xlsx']);  % Unified log file

if exist('logMissingPI', 'var') && ~isempty(logMissingPI)
    logTable = cell2table(logMissingPI, 'VariableNames', {'Filename', 'Invalid_PI_Value'});
    sName=strcat('Missing_or_Invalid_PI_',subFolder);
    writetable(logTable, logFile, 'Sheet', sName);
    fprintf('Missing/non-standard PI log written to sheet %s in: %s\n',sName, logFile);
end

if exist('logMultiAOML', 'var') && ~isempty(logMultiAOML)
    logTable1 = cell2table(logMultiAOML, 'VariableNames', {'Filename', 'Multi_AOML_Value'});
    sName1=strcat('Multi_AOML_',subFolder);
    writetable(logTable1, logFile, 'Sheet',sName1 );
    fprintf('Multi-AOML log written to sheet %s in: %s\n',sName1, logFile);
end

if exist('logPermissionErr', 'var') && ~isempty(logPermissionErr)
    logTable2 = cell2table(logPermissionErr, 'VariableNames', {'Filename', 'Error_Message'});
    sName2=strcat('Permission_Errors_',subFolder);
    writetable(logTable2, logFile, 'Sheet', sName2);
    fprintf('Permission error log written to sheet %s in: %s\n',sName2, logFile);
end

if exist('logMaskError', 'var') && ~isempty(logMaskError)
    logTable3 = cell2table(logMaskError, 'VariableNames', {'Filename', 'Matched_Lines'});
    sName3=strcat('Mask_Errors_',subFolder);
    writetable(logTable3, logFile, 'Sheet',sName3 );
    fprintf('Mask Errros log written to sheet %s in: %s\n',sName3, logFile);
end

%% Log what you changed
if exist('modifiedLog', 'var') && ~isempty(modifiedLog)
    logTable3 = cell2table(modifiedLog, 'VariableNames', {'Filename'});
    sName3 = strcat('Updated_ID_Meta_',subFolder);
    writetable(logTable3, logFile, 'Sheet', sName3);
    fprintf('Metadata files with updated PI fields logged in sheet %s in: %s\n',sName3, logFile);
end

fprintf('done \n')
%% 