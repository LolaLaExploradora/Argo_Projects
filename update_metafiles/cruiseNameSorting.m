%%fuzzy logic for reading the excel files and grouping
%%all the names for the platforms and/or cruise IDs together based on their
%%similarity so that we can see how many permutations of the same name we
%%have -- this will help us ultimately decide which one of the permutations
%%to use. 
% Lola - 5/13/2025


% Load names from Excel
addpath /argus/data1/argo/doc/
filename = 'old_cruise_meta_organized_SN2.xlsx';
names1 = readtable(filename);
cruiseID = string(names1.correctedDeployment_CruiseID);
platName = string(names1.deployment_Platform);  % Replace with actual column name

%% Step 1: Normalize names
normalizedNames = platName(1:2024);

% Remove periods and extra spaces in acronyms, but preserve slashes
normalizedNames = regexprep(normalizedNames, '\.', '');         % Remove periods
normalizedNames = regexprep(normalizedNames, '\s+', ' ');       % Collapse multiple spaces
normalizedNames = strtrim(normalizedNames);                     % Trim leading/trailing spaces
normalizedNames = regexprep(normalizedNames, '(?i)(?<!\w)(?!n/a\b)([A-Z])/([A-Z])(?!\w)', '$1$2', 'ignorecase');

% Normalize acronym formatting at beginning only (title-case, clean spacing)
normalizedNames = regexprep(normalizedNames, '^(?i)rv\b', 'RV');   % replaces rv (case insensitive - rv, rV, etc) with RV
normalizedNames = regexprep(normalizedNames, '^(?i)mv\b', 'MV');   % same as above for MV
normalizedNames = regexprep(normalizedNames, '^(?i)sv\b', 'SV');   % same as above for SV
normalizedNames = regexprep(normalizedNames, '^(?i)sa\b', 'SA');   % same as above for SA
normalizedNames = regexprep(normalizedNames, '^(?i)s\s+a', 'SA');
    % (?i) makes it case-insensitive
    % ^ anchors the match to the start of the string 
    % \b makes sure that the condition only matches if it is a full-word (ex. rvl would not be caught in RV line) 

originalNames = platName(1:2024);
data = [originalNames, normalizedNames, cruiseID(1:2024)];

% Define acronyms to ignore 
acronyms = ["CP", "MV", "SA", "SV", "RV", "TS", ... 
            "APL", "ARA", "CGA", "CGM", "CMA", "CMV", "CMA CGM", ... 
            "CMA CGN", "CSX", "FRS", "JPO", "ORV", "NOAA", "RRS", "RSS", ... 
            "SSV", "TMM", "SSV" "USCG", "USCGC", "USS"];

% Build a regex pattern to match leading acronyms followed by a space --
% case-insensitive
pattern = "^(?i)(" + strjoin(acronyms, '|') + ")\s*";

% Create sort keys by stripping acronyms (only for sorting purposes)
sortKeys = regexprep(normalizedNames, pattern, '', 'ignorecase');

% Sort based on the cleaned names
[~, sortIdx] = sort(lower(sortKeys));  % case-insensitive sort

% Apply sorting to the original table
sortedData = data(sortIdx, :);

% Remove duplicate rows from a 2-column string array
[~, uniqueIdx] = unique(sortedData, 'rows', 'stable');
dedupedData = sortedData(uniqueIdx, :);

% Optional: write to file
outputFolder = '/argus/data1/argo/doc';  % Change this to your desired folder
outputFile = fullfile(outputFolder, 'sorted_unique_by_name_ignore_acronyms2.xlsx');

writetable(array2table(dedupedData, 'VariableNames', {'OriginalName', 'NormalizedName', 'CruiseID'}), outputFile);
fprintf('Saved to: %s\n', outputFile);
% Display top 10 rows
disp(dedupedData(1:10, :));

