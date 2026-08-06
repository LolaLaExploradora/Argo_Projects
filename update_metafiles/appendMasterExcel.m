% Define paths
excelPath = '/argus/data1/argo/doc/old_cruise_meta_organized_SN2.xlsx';
sheetName = 'Sheet1';  %This is the file that we will read aoml numbers from

% subFolder = input('Enter subfolder name e.g., "active" "archived" "dead" or "malfunction": ', 's');
% basePath = '/argus/data1/argo/metadata/from_aoml_20250501/';
% dataDir = fullfile(basePath, subFolder);
dataDir='/argus/data1/argo/metadata/aoml'
outputFile = '/argus/data1/argo/doc/unmatched_files_log2.xlsx';
%outputSheet = 'Unmatched_Info';

% Read aomlnum column
T = readtable(excelPath);
aomlList = string(T.aomlnum);  % Convert to string array for comparison
aomlList = pad(aomlList, 4, 'left', '0');

% Fields to extract from unmatched files read in from the "dataDir" location
keysOfInterest = ["internal ID number", "float serial number", "WMO ID number", ...
    "deployment type","deployment platform", "deployment cruise id", ...
    "PI     ", "launch time [dd mm yyyy hh mm (Z)]" ];

% Initialize results
logData = {};

% Loop through files
files = dir(fullfile(dataDir, '*.meta'));  % Adjust file extension if needed
files = files(arrayfun(@(f) f.name(1) ~= '.', files)); 
for i = 1:length(files)
    fname = files(i).name;
    fileID = erase(fname, "_"+extractAfter(fname, "_"));
    
    if any(aomlList == fileID)
        continue;  % Match found, do nothing
    end
    
    % Read file lines
    fullPath = fullfile(files(i).folder, fname);
    lines = string(readlines(fullPath));
    
    % Extract info for each key
    row{1}=fname;
    for k = 1:numel(keysOfInterest)
        key = keysOfInterest(k);
        matchIdx = find(contains(lower(lines), lower(key)), 1);
        if ~isempty(matchIdx)
            fullLine = strtrim(lines(matchIdx));  % Clean up the line
            valuePart = strtrim( extractAfter(fullLine, key));
            %valuePart = strtrim(extractAfter(fullLine, key));  % Extract everything after the key
            row{k+1} = valuePart;
        else
            row{k+1} = "N/A";
        end
    end

    
    logData = [logData; row];
end

% Write to Excel if there are unmatched files
if ~isempty(logData)
    colNames = ["Filename", keysOfInterest];
    logTable = cell2table(logData, 'VariableNames', matlab.lang.makeValidName(colNames));
    writetable(logTable, outputFile, 'Sheet', subFolder);
    fprintf('Unmatched file data written to: %s (Sheet: %s)\n', outputFile, subFolder);
else
    fprintf('All files matched with AOML numbers. No log created.\n');
end