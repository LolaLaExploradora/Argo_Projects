function rename_oldCruiseMetaFiles_CruiseID()
% This code takes in corrected cruise names from an excel file and applies
% them back into the metadata files -- the meta files came from AOML in a 
% tarball that exists in argus/data1/argo/metadata/from_aoml_20250501
% The excel file is called old_cruise_meta_organized_SN3.xlsx and is
% located in /argus/data1/argo/doc
%%
addpath /argus/data1/argo/doc
excelFile = 'old_cruise_meta_organized_SN3.xlsx'; 
sheetName = 'Sheet1';  % Adjust if needed

%% Step 1: Read Excel
T = readtable(excelFile, 'Sheet', sheetName);
T.aomlnum = string(T.aomlnum);  % ensure string type for matching
T.aomlnum = string(compose('%04d', double(T.aomlnum)));
T.New_CruiseID = string(T.New_CruiseID);

%% Step 2: List all files starting with 4 or 5 digit aoml number in tarball
% directory. Define paths
addpath /argus/data1/argo/metadata/from_aoml_20250501/
subFolder = input('Enter subfolder name e.g., "active" "archived" "dead" or "malfunction": ', 's');
basePath = '/argus/data1/argo/metadata/from_aoml_20250501/';
folderPath = fullfile(basePath, subFolder);
allFiles = dir(fullfile(folderPath, '*.meta'));  % Adjust extension if needed
fileNames = {allFiles.name};
pat = '^\d{4,5}_';  % regex for 4 or 5 digits followed by underscore

logMultiAOML=[]; logPermissionErr=[]; logMaskError=[]; modifiedLog=[];
%% Step 3: Loop over files
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
            fprintf('Multiple entries detected for %s\n :\n', fname);
            for  j = 1:numel(newCruiseID)
                fprintf('  [%d] %s\n', j, string(newCruiseID(j))); end
                idx = input('Select the index of the entry you want to use: ');
                logMultiAOML = [logMultiAOML; {fname}];
                % Validate input
                if idx >= 1 && idx <= numel(newCruiseID)
                    newCruiseID = newCruiseID(idx);
                else
                    error('Invalid selection. Exiting.'); end
        end
    
    %% Step 4: Read file
    filePath = fullfile(folderPath, fname);
    lines = readlines(filePath);

    %% Step 5: Modify "deployment cruise ID" line
    mask = contains(lower(lines), "deployment cruise id");
    if any(mask) && sum(mask)==1
        
        oldLine = lines(mask);
        newLine = "deployment cruise ID                    " + newCruiseID; 
        %there are twenty spaces in the original meta file between these two things so I kept it that way
        
        %cruiseIDContent = strtrim(extractAfter(lower(oldLine), "deployment cruise id"));
        cruiseIDContent = strtrim(regexprep(oldLine, '.*deployment cruise id\s*', '', 'ignorecase'));
        % Only update if needed
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
                fprintf('Updated Cruise ID in %s from %s to %s\n', fname, cruiseIDContent, newCruiseID);
                modifiedLog = [modifiedLog; {fname}];
            end
        end
    else
        matchIdxs = find(mask);
        logMaskError=[logMaskError; {fname, maskIdxs}];
        fprintf('Error: ''deployment platform'' mask matched to more than one line in %s\n',fname)
    end
end

% Save all log to Excel if any problematic PI values were found
logFile = fullfile(basePath, ['CruiseIDupdate_logs.xlsx']);  % Unified log file

%log multi aoml
if exist('logMultiAOML', 'var') && ~isempty(logMultiAOML)
    logTable = cell2table(logMultiAOML, 'VariableNames', {'Filename'});
    sName = strcat('Multi_AOML_', subFolder);
    if isfile(logFile) && any(strcmp(sheetnames(logFile), sName))
        existingTable = readtable(logFile, 'Sheet', sName);
        combinedTable = unique([existingTable; logTable], 'rows');
    else
        combinedTable = logTable;
    end
    writetable(combinedTable, logFile, 'Sheet', sName);
    fprintf('Multi-AOML log written to sheet %s in: %s\n',sName, logFile);
end

%log permission errors
if exist('logPermissionErr', 'var') && ~isempty(logPermissionErr)
    logTable1 = cell2table(logPermissionErr, 'VariableNames', {'Filename', 'Error_Message'});
    sName1 = strcat('Permission_Errors_',subFolder);
    if isfile(logFile) && any(strcmp(sheetnames(logFile), sName1))
        existingTable1 = readtable(logFile, 'Sheet', sName1);
        combinedTable1 = unique([existingTable1; logTable1], 'rows');
    else
        combinedTable1 = logTable1;
    end
    writetable(combinedTable1, logFile, 'Sheet', sName1);
    fprintf('Permission error log written to sheet %s in: %s\n',sName1, logFile);
end

%log mask errors
if exist('logMaskError', 'var') && ~isempty(logMaskError)
    logTable2 = cell2table(logMaskError, 'VariableNames', {'Filename', 'Matched_Lines'});
    sName2 = strcat('Mask_Errors_',subFolder);
    if isfile(logFile) && any(strcmp(sheetnames(logFile), sName2))
        existingTable2 = readtable(logFile, 'Sheet', sName2);
        combinedTable2 = unique([existingTable2; logTable2], 'rows');
    else
        combinedTable2 = logTable2;
    end
    writetable(combinedTable2, logFile, 'Sheet', sName2);
    fprintf('Mask Errors log written to sheet %s in: %s\n',sName2, logFile);
end

%log updated cruise id meta
if exist('modifiedLog', 'var') && ~isempty(modifiedLog)
    logTable3 = cell2table(modifiedLog, 'VariableNames', {'Filename'});
    sName3 = strcat('Updated_ID_Meta_',subFolder);
    if isfile(logFile) && any(strcmp(sheetnames(logFile), sName3))
        existingTable3 = readtable(logFile, 'Sheet', sName3);
        combinedTable3 = unique([existingTable3; logTable3], 'rows');
    else
        combinedTable3 = logTable3;
    end
    writetable(combinedTable3, logFile, 'Sheet', sName3);
    fprintf('Metafiles with updated CruiseID fields logged in sheet %s in: %s\n',sName3, logFile);
end



% if exist('logMultiAOML', 'var') && ~isempty(logMultiAOML)
%     logTable = cell2table(logMultiAOML, 'VariableNames', {'Filename', 'Multi_AOML_Value'});
%     sName = strcat('Multi_AOML_', subFolder);
%     writetable(logTable, logFile, 'Sheet', sName);
%     fprintf('Multi-AOML log written to sheet %s in: %s\n',sName, logFile);
% end
% 
% if exist('logPermissionErr', 'var') && ~isempty(logPermissionErr)
%     logTable1 = cell2table(logPermissionErr, 'VariableNames', {'Filename', 'Error_Message'});
%     sName1 = strcat('Permission_Errors_',subFolder);
%     writetable(logTable1, logFile, 'Sheet', sName1);
%     fprintf('Permission error log written to sheet %s in: %s\n',sName1, logFile);
% end
% 
% if exist('logMaskError', 'var') && ~isempty(logMaskError)
%     logTable2 = cell2table(logMaskError, 'VariableNames', {'Filename', 'Matched_Lines'});
%     sName2 = strcat('Mask_Errors_',subFolder);
%     writetable(logTable2, logFile, 'Sheet', sName2);
%     fprintf('Mask Errros log written to sheet %s in: %s\n',sName2, logFile);
% end
% 
% %% Log what you changed
% if exist('modifiedLog', 'var') && ~isempty(modifiedLog)
%     logTable3 = cell2table(modifiedLog, 'VariableNames', {'Filename'});
%     sName3 = strcat('Updated_ID_Meta_',subFolder);
%     writetable(logTable3, logFile, 'Sheet', sName3);
%     fprintf('Metafiles with updated CruiseID fields logged in sheet %s in: %s\n',sName3, logFile);
% end

fprintf('done \n')
%% 

