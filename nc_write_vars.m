function nc_write_vars(WMO, cycles, var)
%Lola Pierson
%Argo, WHOI 
%April 29, 2026

%updating .nc files 
%the cycles should be a range, if applicable, and the variable (var) should
%be a string that matches the variable that needs to be changed in the .nc
%file. Mind the spelling, otherwise it wont work. 

path_WMO = fullfile('shared/argo/dmqc/QC1/', string(WMO));
counter=1;
PI_names_update = 'Breck OWENS, Steven JAYNE, Pelle ROBBINS';
num_chars = numel(PI_names_update);
num_chars_reqd = 64;
PI_names_update_formatted = [PI_names_update, blanks(num_chars_reqd-num_chars)];
    PI_names_update_formatted = [PI_names_update_formatted;PI_names_update_formatted];

for i=cycles
    table = profMeas_to_table(WMO, i, path_WMO, 'R'); %ex: profMeas_to_table(2903142, 123, '/shared/argo/dmqc/QC1/2903142', 'R')
    Rcycle = ["R"+WMO+"_"+ pad(string(i),3,"left",'0') + ".nc"];
    path_WMO_Rcycle = fullfile(path_WMO,Rcycle)

    for j=1:length(var)
    var_disp = ncread(path_WMO_Rcycle, var)'; %ex: ncread('/shared/argo/dmqc/QC1/1902433/R1902433_000.nc', 'PSAL_QC')
    %% inupt how to change the var here
    % ex - for PSAL, if you want to automate the process you need to read in
    % two variables. You will have to read in the salinity values (two of
    % them, likely, the PSAL and then the high freq PSAL values. Then you
    % will have to write a small set of lines that identifies the problem:
    % which is 
    % 1. if there is no data in the PSAl (or high freq) then the data in the
    % QC column should be ' ' 
    if counter==1
        sprintf('The variable %s currently contains the following data: \n%s\n%s',var,var_disp(1,:), var_disp(2,:))
        prompt = sprintf('Would you like to replace it with \n%s\n%s? \nPlease respond "Y" or hit Enter to conintue, or "N" to exit', PI_names_update_formatted(1,:),PI_names_update_formatted(2,:));
        txt = input(prompt, 's');
        if isempty(txt) | txt=='Y'
            sprintf('%s file data %s replaced with %s', Rcycle, var, PI_names_update)
            ncwrite(path_WMO_Rcycle, var, PI_names_update_formatted');
        else 
            continue 
        end 
    else 
        sprintf('%s .nc file data %s replaced with %s', Rcycle, var, PI_names_update)
        ncwrite(path_WMO_Rcycle, var, PI_names_update_formatted');
    end
    
    counter=counter+1;
    end
end
        


% Some example code to recall how to input the paths
%ncwrite('/shared/argo/dmqc/QC1/3902237/R3902237_166.nc', 'PSAL_QC', var);
    