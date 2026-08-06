function nc_update_PI_NAMES(path, WMO, file_list)
%Lola Pierson
%Argo, WHOI 
%May 1, 2026
%updating PI_NAME in .nc files 

% From when Lola updated metafile PI_NAMES there is a list of all unique PI 
% names and their 'standardized' counterparts. We import those lists as our
% look up table. 
% file & location: /argus/data1/argo/doc/old_cruise_meta_organized_SN3.xlsx

% use netcdf.open ***

lookupTable = readtable('/argus/data1/argo/doc/old_cruise_meta_organized_SN3.xlsx', 'sheet', 'UniquePINames');
oldNames_List = lookupTable{:, 1}; % Column A
oldNames_ListUp = upper(oldNames_List);
newNames_List = lookupTable{:, 2};
%Create a mapping object (old name -> new name)
nameMapUp = containers.Map(oldNames_ListUp, newNames_List);
nameMap = containers.Map(oldNames_List, newNames_List);

var = 'PI_NAME'; %variable to read in from .nc file
counter=1;
num_chars_reqd = 64;

for i = 1:height(file_list) 
    ncid= netcdf.open(fullfile(path, file_list(i,:)), 'WRITE');
    varid=netcdf.inqVarID(ncid,'PI_NAME');
    oldPInames= netcdf.getVar(ncid,varid)';

    if any(deblank(oldPInames(1,:)) == string(newNames_List))
       sprintf('PI_NAME is in NVS R40 format, does not need updating, skipping file %s.', file_list(i,:))
        continue 

    elseif nameMapUp.isKey(deblank(oldPInames(1,:))) || nameMap.isKey(deblank(oldPInames(1,:)))
        if nameMapUp.isKey(deblank(oldPInames(1,:)))
            newNames_ind = nameMapUp(deblank(oldPInames(1,:)));
        elseif nameMap.isKey(deblank(oldPInames(1,:)))
            newNames_ind = nameMap(deblank(oldPInames(1,:)));
        end
            num_chars = numel(newNames_ind);
            [r,~] = size(oldPInames);
        newNames_stnd = [newNames_ind, blanks(num_chars_reqd-num_chars)];
        newNames_stnd(r,:) = newNames_stnd;
        if counter==1 %include an OR statement here to also catch the case when your files dont all 
            %have the same PI name, so that new instances of replacing PI
            %names also require your approval
            sprintf('The PI_NAME field is currently: \n%s', oldPInames(1,:))
            prompt = sprintf('Would you like to replace it with \n%s? \nPlease respond "Y" or hit Enter to conintue, or "N" to exit', newNames_stnd(1,:));
            txt = input(prompt, 's');
            if isempty(txt) | txt=='Y'
                sprintf('%s file PI_NAME replaced with %s', file_list(i,:), newNames_stnd(1,:))
                netcdf.putVar(ncid, varid, newNames_stnd');
                %ncwrite(fullfile(path, file_list(i,:)), var, newNames_stnd);
            else 
                sprintf('bad selection try again')
                continue 
            end 
        else 
            sprintf('%s file PI_NAME replaced with %s', file_list(i,:), newNames_stnd(1,:))
            netcdf.putVar(ncid, varid, newNames_stnd')
            %ncwrite(fullfile(path, file_list(i,:)), var, newNames_stnd);
        end
    else 
        sprintf('PI_NAME for file %s has a format that does not match any in our lookup table: \n%s \nplease update table, found at: \n "/argus/data1/argo/doc/old_cruise_meta_organized_SN3.xlsx" in the "UniquePINames" sheet', file_list(i,:), oldPInames(1,:))
        continue
    end
    netcdf.close(ncid);
    counter=counter+1;
end

end 


    
% %%OLD CODE USED AS AN EXAMPLE 

% PI_names_update_formatted = [PI_names_update, blanks(num_chars_reqd-num_chars)];
% PI_names_update_formatted = [PI_names_update_formatted;PI_names_update_formatted];
% for i=cycles
%     table = profMeas_to_table(WMO, i, path_WMO, 'R'); %ex: profMeas_to_table(2903142, 123, '/shared/argo/dmqc/QC1/2903142', 'R')
%     Rcycle = ["R"+WMO+"_"+ pad(string(i),3,"left",'0') + ".nc"];
%     path_WMO_Rcycle = fullfile(path_WMO,Rcycle)
% 
%     for j=1:length(var)
%     oldPInames = ncread(path_WMO_Rcycle, var)'; %ex: ncread('/shared/argo/dmqc/QC1/1902433/R1902433_000.nc', 'PSAL_QC')
%     %% inupt how to change the var here
%     % ex - for PSAL, if you want to automate the process you need to read in
%     % two variables. You will have to read in the salinity values (two of
%     % them, likely, the PSAL and then the high freq PSAL values. Then you
%     % will have to write a small set of lines that identifies the problem:
%     % which is 
%     % 1. if there is no data in the PSAl (or high freq) then the data in the
%     % QC column should be ' ' 
%     if counter==1
%         sprintf('The variable %s currently contains the following data: \n%s\n%s',var,oldPInames(1,:), oldPInames(2,:))
%         prompt = sprintf('Would you like to replace it with \n%s\n%s? \nPlease respond "Y" or hit Enter to conintue, or "N" to exit', PI_names_update_formatted(1,:),PI_names_update_formatted(2,:));
%         txt = input(prompt, 's');
%         if isempty(txt) | txt=='Y'
%             sprintf('%s file data %s replaced with %s', Rcycle, var, PI_names_update)
%             ncwrite(path_WMO_Rcycle, var, PI_names_update_formatted');
%         else 
%             continue 
%         end 
%     else 
%         sprintf('%s .nc file data %s replaced with %s', Rcycle, var, PI_names_update)
%         ncwrite(path_WMO_Rcycle, var, PI_names_update_formatted');
%     end
% 
%     counter=counter+1;
%     end
% end
% 
% % Some example code to recall how to input the paths
% %ncwrite('/shared/argo/dmqc/QC1/3902237/R3902237_166.nc', 'PSAL_QC', var);
    