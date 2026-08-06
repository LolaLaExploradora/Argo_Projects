%%what I think is a fuzzy logic for reading the excel files and grouping
%%all the names for the platforms and/or cruise IDs together based on their
%%similarity so that we can see how many permutations of the same name we
%%have -- this will help us ultimately decide which one of the permutations
%%to use. 
% Lola - 5/13/2025


% Load names from Excel
addpath /argus/data1/argo/doc/
filename = 'old_cruise_meta_organized_SN2.xlsx';
nameList = readtable(filename);
names = string(nameList.deployment_Platform);  % Replace with actual column name
names = names(1:2024,:);

%% Step 1: Normalize names
normalizedNames = names;

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

%% Step 2: Compute normalized Levenshtein distances
n = numel(normalizedNames);
distanceMatrix = zeros(n);

parpool;  % Start parallel pool (only needs to run once per session)
distanceMatrix = zeros(n, n);  % Preallocate

parfor i = 1:n
    tempRow = zeros(1, n);
    for j = i+1:n
        d = editDistance(normalizedNames(i), normalizedNames(j));
        maxLen = max(strlength(normalizedNames(i)), strlength(normalizedNames(j)));
        similarity = 1 - (d / maxLen);
        tempRow(j) = similarity;
    end
    distanceMatrix(i, :) = tempRow;
end

% Symmetrize the matrix
distanceMatrix = distanceMatrix + distanceMatrix';


%% Step 3: Cluster names by similarity
threshold = 0.8;
linked = linkage(1 - distanceMatrix, 'average');
clusters = cluster(linked, 'Cutoff', 1 - threshold, 'Criterion', 'distance');

%% Step 4.1: Select one representative name per cluster (first one by default)
uniqueNames = strings(max(clusters), 1);
for k = 1:max(clusters)
    idx = find(clusters == k);
    uniqueNames(k) = normalizedNames(idx(1));  % Take first in cluster
end

%% Step 4.2: Sort names ignoring acronyms like "RV", "MV", "SV", "SA"
% Create temporary versions of names with acronyms removed
sortKeys = regexprep(uniqueNames, '^(?i)(RV|MV|SV|SA|CSX|CMA|CGM|TS|RRS|ARA|TMM|CP|NOAA|JPO|SSV|ORV)\s*', '');  % remove acronyms + optional space

% Sort based on cleaned sortKeys, but keep original names
[~, sortIdx] = sort(lower(sortKeys));  % case-insensitive sort
sortedUniqueNames = uniqueNames(sortIdx);

% Optional: Save or display the result
writetable(table(sortedUniqueNames), 'clean_sorted_names.xlsx');
disp(sortedUniqueNames);

%% Step 5: Save results
T = table(names, normalizedNames, clusters);
writetable(T, 'grouped_names.xlsx');
disp('Grouped names saved to grouped_names.xlsx');