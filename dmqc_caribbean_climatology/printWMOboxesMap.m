function WMOboxesMap = printWMOboxesMap()
%NOT CURRENTLY FUNCTIONAL
%Lola found a print out of the WMO boxes, so this was unnecessary

%self explanatory function. Lola needed a way to see where the WMO boxes 
%lie on a global map to be able to adjust OWC
%WMO boxes are 
%the way we will do this is by finding the average lat/long of each of the
%wmo boxes (the wmo boxes each have a number are in the
%/shared/argo/dmqc/COW_DATA/climatology/historical_ctd

addpath /shared/argo/dmqc/COW_DATA/climatology/historical_ctd/
folderPath = '/shared/argo/dmqc/COW_DATA/climatology/historical_ctd/';
filePattern = fullfile(folderPath, '*.mat');
files = dir(filePattern);

wb=[]; avglat=[]; avglon=[];
for i = 1:length(files)
    fileName = files(i).name;
    wmoNum = extractBefore(extractAfter(fileName, '_'), ".mat");
    matObj = matfile(fileName);
    wb = [wb; wmoNum]; 
    avglat = [avglat; mean(matObj.lat)];
    avglon = [avglon; mean(matObj.long)];
    ends

figure
gx = geoaxes; 
geobasemap 
geobasemap('bluegreen'); hold on
textm(avglat, avglon, wb)