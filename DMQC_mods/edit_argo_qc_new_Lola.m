function edit_argo_qc_new_Lola(wmonum, np, windowOption, cycleRangeStart, cycleRangeEnd)
% GUI for editting argo data
% wmonum - WMO Number
% np - profile number (optional - default is 1)
% windowOption - custom window size (dw 12/xx/2024)
% cycleRangeStart -
% cycleRangeEnd - self explanatory, allows user to edit a specific cycle 
%                 range. NOTE with this update, wmonum,
%                 np, and windowOption are MANDATORY inputs. (Lola Feb 2025) 

% modified to handle multiple profiles dw 4/11/2018
% modified to use plot_nearby with all 3 plots - temp, psal, T-S dew
% 6/15/2021
% dwest@whoi.edu 12/1/2022 to allow both ascending and descending profiles
% dwest@whoi.edu 5/10/2024 using sigma-1 instead of sigma-0 in plots
if ispc
    setargo_pc
else
    setargo
end

if ispc
    QC1 = [ARGODMQC,'\QC1\'];   % path to read in netcdf file
    QC2 = [ARGODMQC,'\QC2\'];   % path to write out netcdf files

    GDAC = [ARGOGDAC,'\dac\aoml\'];
else
    QC1 = [ARGODMQC,'/QC1/'];   % path to read in netcdf file
    QC2 = [ARGODMQC,'/QC2/'];   % path to write out netcdf files

    GDAC = [ARGOGDAC,'/dac/aoml/'];
end

fetch_from_gdac(wmonum,GDAC,QC1)  % move files from GDAC mirror to QC1
%overwrite=[];
%fetch_from_gdac(wmonum,GDAC,QC1,overwrite, cycleRangeStart, cycleRangeEnd)  % move files from GDAC mirror to QC1



% moved to cleanup_for_aoml.m as needed dw 4/11/2018
%prepare_Rfiles(wmonum,QC1) %adds qc flags for missing data dw 3/21/2018

%% Section within "%%" added by Lola, finalized 02/17/2025 
%allows for user to either input a cycle range or have the gui show all
%cycles. 
if exist("cycleRangeStart")
    sourceAll = [QC1,num2str(wmonum)] 
        %sourceAll is where the full range of cycle files are held
    destination = [QC1, num2str(wmonum), '/', 'temp']; 
        %destination is a temporary file that will hold only the range of
        %cycles you want to work on at the time, it will be deleted when
        %the gui is closed.
        %did not use "fullfile" command bc that only makes files, not folders
    mkdir(destination) 
        %note that you have to use "function syntax" not command syntax here
        %command syntax (ex: "mkdir destination") will create a directory with the name of the variable
        %it will not read the path passed in by the varaible
    allFiles = dir(sourceAll);
    fileNames = extractfield(allFiles, 'name');
        %the following piece of code ensures that the total number of
        %cycles in the input cycle range actually matches the number of
        %files available for review. Ex. sometimes you can be missing an R
        %file from the DAC, and when that happens the cycle range will need
        %to be reduced by 1, otherwise the for loop (below) will not
        %function. 

    
    for j=[cycleRangeStart:1:cycleRangeEnd]
        fileN = fileNames{j+3};
        source = fullfile(sourceAll, fileN);
        [status, msg, msgID] = copyfile(source, destination, 'f')
    end

    Config.inpath= [destination];
    Config.outpath=[QC1,num2str(wmonum)];
else 
    Config.inpath= [QC1,num2str(wmonum)]; %this and the following line previously existed outside of the code block added by Lola
    Config.outpath=[QC1,num2str(wmonum)]; %if code block deleted & these lines added back in, the code would work as it previously did
end 
%%


% functions for read/write of data files
%Config.read_func = 'rd_flt_gdac';
%testing for solo2 floats
%Config.read_func = 'rd_flt_gdac2';
Config.read_func = 'rd_flt_gdac3';

if nargin < 2
    np = 1;
end
Config.np = np;

%Config.write_func = 'wrt_flt_gdac';
Config.write_func = 'wrt_flt_gdac2';

if ispc
    Config.logfile = [ARGOLOG,'\dmqc\',num2str(wmonum),'_qceditlog.txt'];
    Config.hist_ctd_dir = [ARGODMQC,'\CAL_DATA\climatology\historical_ctd_coriolis'];
    Config.hist_ctd_wmo = [ARGODMQC,'\CAL_DATA\constants\wmo_boxes_ctd'];
    Config.hist_argo_dir = [ARGODMQC,'\CAL_DATA\climatology\argo_profiles\'];
    Config.hist_argo_wmo = [ARGODMQC,'\CAL_DATA\constants\wmo_boxes_argo.mat'];
else
    Config.logfile = [ARGOLOG,'/dmqc/',num2str(wmonum),'_qceditlog.txt'];
    Config.hist_ctd_dir = [ARGODMQC,'/CAL_DATA/climatology/historical_ctd_coriolis'];
    Config.hist_ctd_wmo = [ARGODMQC,'/CAL_DATA/constants/wmo_boxes_ctd'];
    Config.hist_argo_dir = [ARGODMQC,'/CAL_DATA/climatology/argo_profiles/'];
    Config.hist_argo_wmo = [ARGODMQC,'/CAL_DATA/constants/wmo_boxes_argo.mat'];
end

%HISTORY_INSTITUTION [Optional]
Config.HISTORY_INSTITUTION='WHOI'; %[Default='    ']

%Climatology [Optional]
%Config.CLIFile='/Users/pvb/Data/Climatologias/WOA05/WOA05.mat';
if ispc
    Config.CLIFile='\Volumes\U1\WOA\WOA05.mat';
else
    Config.CLIFile='/Volumes/U1/WOA/WOA05.mat';
end

Config.CLIBorder=5; %size of the box for the climatology, in degrees [Default=10]

%Extrem values for axes [Optional]
%Config.maxP=2000;   %[Default=automatic]
%Config.maxT=30;     %[Default=automatic]
%Config.minT=2;      %[Default=automatic]
%Config.maxS=38.8;   %[Default=automatic]
%Config.minS=34;     %[Default=automatic]
%Config.maxO=200;     %[Default=automatic]
%Config.minO=20;     %[Default=automatic]

Config.QCms = 6;  % markersize for que QC plots [Default=5]
Config.POSBorder = 5;  %Size of the box for the climatology, in degrees [Default=10]

if exist("windowOption")
switch windowOption
    case 'Deb'
        disp('Deb display')
        Config.windowOption = 'Deb';
    case 'Sachiko'
        disp('Sachiko display')
        Config.windowOption = 'Sachiko';
    case 'Lola'
        disp('Lola display')
        Config.windowOption = 'Lola';
end

end
qc_gui_new(Config)

rmdir(destination, 's') %added by Lola to remove temp directory created by code block specified above in "%%" section. 
    %added 02/07/2025 