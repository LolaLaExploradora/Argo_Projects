%function file = old_cruise_metadata_corrected_jsonOutput(excelFile)
clear
clc 

% MATLAB code to read data from an xlsx file and output as a JSON file
% Specify the path of the input .xlsx file
parentFolder = ['/argus/data1/argo/doc/']
cd(parentFolder) 
inputFile = 'old_cruise_meta_organized_SN3.xlsx';  % Replace with your file path

% Specify the rows and columns to select (e.g., rows 2 to 5 and columns 1 to 3)
startRow = input('Enter starting row for your year range: ')-1;
endRow = input('Enter ending row for your year range: ');
startColumn = [1]; %3, 7, 9
endColumn = [20];

% Read the selected range from the Excel file
data = readtable(inputFile, 'Range', [startRow, startColumn, endRow, endColumn]);
    %for quickness right now I am just deleting the columns i dont need
    %after I import them, in the future I might consider making an entirely
    %new excel file so that it runs faster. 

%Retain only the columns that you need
data1 = data([1:end], [10,14,3]); %hard coded for now, but again, can change
%right now this code is grabbing the new cruise ID, year, and wmo number
%(in that order)
%data1 = renamevars(data1,["NewCruiseID", "year", "WMOnum"], ["name", "year", "wmo"]);

%For unique name-year pairs (called 'keys' for which we identify key indicies) 
%collect WMO numbers as an int32 list
keys = strcat(string(data1.New_CruiseID),"__",string(data1.year));
[uniqueKeys, ~, keyIdx] = unique(keys);

%% Group WMO numbers by CruiseID-Year
%groupedData = cell(length(uniqueKeys), 1); %NEW LINE
for i = 1:length(uniqueKeys)
    wmo_nums = data1.WMOnum(keyIdx == i);
    groupedData{i} = int32(str2double(wmo_nums));
end

%% Turn the data collected above back into a table, this time with unique
%name and years listed once, but with all corresponding wmos in a list next
%to the name-year pair. 
splitKeys = split(uniqueKeys, "__");
data2 = table(splitKeys(:,1), str2double(splitKeys(:,2)), groupedData', 'VariableNames', {'name', 'year', 'wmo'});

% Initialize consolidated structure array
allDataStruct = table2struct(data2);

%% Group by year and write separate JSON files
years = unique(data2.year);
for i = 1:length(years)
    yearsData = data2(data2.year == years(i), :);
    dataStruct = table2struct(yearsData);
    jsonData = jsonencode(dataStruct, 'PrettyPrint', true);

    outputFile = ['argo_cruises_' num2str(years(i)) '.json'];
    fid = fopen(outputFile, 'w');
    if fid == -1
        error('Cannot open file for writing %s', outputFile);
    end
    fwrite(fid, jsonData, 'char');
    fclose(fid);
    fprintf('JSON file for year %d has been created successfully!\n', years(i));
end

%% Write consolidated JSON for all years
jsonAllData = jsonencode(allDataStruct, 'PrettyPrint', true);
fidAll = fopen('argo_cruises_all_years.json', 'w');
if fidAll == -1
    error('Cannot open consolidated file for writing\n');
end
fwrite(fidAll, jsonAllData, 'char');
fclose(fidAll);

disp('All yearly and consolidated JSON files have been created successfully!');

