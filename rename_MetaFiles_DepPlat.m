function rename_MetaFiles_DepPlat()
% This code reads in cruise names and deployement platforms from meta_sum,
% specifically for floats deployed in 2025. 
% First it standardizes the platform names across all 2025 deployments,
% then it standardizes the cruise names. 
addpath /shared/argo/matab
addpath_for_argo_owc
addpath_for_dmqc
setargo
load(fullfile(ARGOMETA,'/meta_sum'))

vec = arrayfun(@(x) x.launch.year, meta_sum);
mask0 = vec == 2025;
mask00 = vec == 2026;
mask = mask0+mask00;
meta_deplyd_2025 = meta_sum(mask0);
%meta_deplyd_2025_26 = meta_sum(mask);
meta_2025_fns = {meta_sum(mask0).file_name};
%dep_plat = unique({meta_deplyd_2025.deployment_platform}');
%cruise_id = unique({meta_deplyd_2025.cruise_id}');

filename = '/shared/argo/matlab/lola_tools/2025_metadata.xlsx'
 
% writecell(dep_plat,filename,'Sheet','deployment_platform');
% writecell(dep_plat_new,filename,'Sheet','deployment_platform', 'Range', 'B1')
% 
% writecell(cruise_id, filename, 'Sheet', 'cruise_id');
% writecell(cruise_id_new, filename, 'Sheet', 'cruise_id', 'Range', 'B1');
data_dp = readtable(filename, 'sheet', 'deployment_platform');
data_cid = readtable(filename, 'sheet', 'cruise_id');
dep_plat = string(data_dp{:,1});
dep_plat_new = string(data_dp{:,2});
cruise_id = string(data_cid{:,1});
cruise_id_new = string(data_cid{:,2});

modifiedLog = [];
logPermissionErr = [];
folderPath= '/argus/data1/argo/metadata/aoml/';
for i=1:length(meta_2025_fns)
    fN = meta_2025_fns{i};
    filePath = fullfile(folderPath,fN);
    lines = readlines(filePath);
    %mask_dp = contains(lower(lines), "deployment platform");
    mask_dp = contains(lower(lines), "deployment cruise id");
    if any(mask_dp) && sum(mask_dp)==2
        inds = find(mask_dp==1);
        inds2 = inds(2);
        mask_dp(inds2) = 0;
        oldLine = lines(mask_dp);
        %oldName = strtrim(extractAfter(oldLine, "deployment platform"));
        oldName = strtrim(extractAfter(oldLine, "deployment cruise id"));
        %matchIdx = find(dep_plat == oldName,1);
        %matchIdx = find(cruise_id == oldName,1);
        %newName = dep_plat_new(matchIdx);
        %newName = cruise_id_new(matchIdx);
        newName = oldName;
        newLine = "deployment platform                     " + newName; 
        %newLine = "deployment cruise id                    " + newName; 
        if oldLine ~= newLine
            [fid, message] = fopen(filePath, 'w');
            if fid == -1
                fprintf('Error: Cannot open file %s for writing, saved to naughty log', filePath);
                logPermissionErr = [logPermissionErr; {fN, message}];
            else
                fclose(fid);  % Close immediately since writelines will write later
                lines(mask_dp) = newLine;
                writelines(lines, filePath);  % Overwrite original
                %fprintf('Updated deployment platform entry in %s from %s to %s\n' , fN, oldName, newName);
                fprintf('Updated deployment cruise id entry in %s from %s to %s\n' , fN, oldName, newName);
                modifiedLog = [modifiedLog; {fN}];
            end
        end
    end


end

fprintf('P')