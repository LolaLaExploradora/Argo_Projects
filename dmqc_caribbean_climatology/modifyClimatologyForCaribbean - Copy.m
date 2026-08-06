function modifyClimatologyForCaribbean()
%the purpose of this function is to modify the data in WMO boxes that the 
% OWC code uses for data corrections. WMO boxes spanning both the caribbean 
% sea and the pacific need to have the pacific data removed (this will skew
% the OWC correction) 

% *** LOLA 
% here you need to add an automatic functionality for deleting the
% following WMO boxes from both the historical_ctd_coriolis and
% argo_profile folders:
% 7311, 7211, 7111, 7011, 5011-5007
% 7210, 7110, 7010, 7009, 5107-5110
% these are boxes fully in the pacific -- which should not be considered in the
% find25boxes function (which gets called within run_cow_calibration which
% conducts the OWC process) for the caribbean OWC process. 
%wmo_boxes_to_delete_list = [5007, 5008, 5009, 5010, 5011, 5107, 5108, 5109, ...
%    5110, 7009, 7010, 7110, 7210, 7011, 7111, 7211, 7311]; 

ctdFolder = '/shared/argo/dmqc/COW_DATA/climatology_carib/historical_ctd_coriolis';
argoFolder= '/shared/argo/dmqc/COW_DATA/climatology_carib/argo_profiles'


%% ctd folder operations 
cd '/shared/argo/dmqc/COW_DATA/climatology_carib/historical_ctd_coriolis'
%ctd7109 = matfile('ctd_7109.mat', 'Writable', true);
ctd7108 = matfile('ctd_7108.mat', 'Writable', true);
ctd7107 = matfile('ctd_7107.mat', 'Writable', true);
%ctd7008 = matfile('ctd_7008.mat', 'Writable', true);
%ctd7007 = matfile('ctd_7007.mat', 'Writable', true);
ctd7208 = matfile('ctd_7208.mat', 'Writable', true);
ctd7207 = matfile('ctd_7207.mat', 'Writable', true);

% for i = 1:length(wmo_boxes_to_delete_list)
%     ctdmat_delete = sprintf('ctd_%04d.mat', wmo_boxes_to_delete_list(i));
%     argomat_delete = sprintf('argo_%04d.mat', wmo_boxes_to_delete_list(i));
%     fullfile_ctd = fullfile(ctdFolder, ctdmat_delete);
%     fullfile_argo= fullfile(argoFolder, argomat_delete); 
%     if exist(ctdmat_delete, 'file') == 2
%         fprintf(1, 'deleting %s\n.mat', fullfile_ctd);
%         delete(fullfile_ctd);
%     else 
%         fprintf(1, 'File not found: %s\n', fullfile_ctd);
%     end 
% end 

%% argo folder operations
cd '/shared/argo/dmqc/COW_DATA/climatology_carib/argo_profiles'
%argo7109 = matfile('argo_7109.mat', 'Writable', true);
argo7108 = matfile('argo_7108.mat', 'Writable', true);
argo7107 = matfile('argo_7107.mat', 'Writable', true);
%argo7008 = matfile('argo_7008.mat', 'Writable', true);
%argo7007 = matfile('argo_7007.mat', 'Writable', true);
argo7208 = matfile('argo_7007.mat', 'Writable', true);
argo7207 = matfile('argo_7007.mat', 'Writable', true);

% for i = 1:length(wmo_boxes_to_delete_list)
%     if exist(argomat_delete, 'file') == 2
%         fprintf(1, 'deleting %s\n.mat', fullfile_argo);
%         delete(fullfile_argo);
%     else 
%         fprintf(1, 'File not found: %s/n', fullfile_argo);
%     end 
% end 

latlim = [-5 30]; %lat limits are within [-90 90] but for Argo as of 2025 we only have data for [-85 85]
lonlim = [-120 -60]; %lon limits are within [-180 180], note West is negative

%% WMO box 7109
% figure 
% geolimits(latlim, lonlim)
% geobasemap('bluegreen'); hold on
% geoplot([10 20 20 10 10], [-100 -100 -90 -90 -100], 'k-', 'LineWidth', 2); %plot box outline
% title('WMO Box 7109, deleted data for OWC carib calculations below red line')
% geoscatter(ctd7109.lat, ctd7109.long-360, "filled"); hold on
% linelat = [18 18]; linelon = [-100 -90];
% geoplot(linelat, linelon, 'r-', 'LineWidth', 2); hold on
% 
%     %anything below 18N latitude should be eliminated. We will delete that
%     %data below. 
%     ind_ctd=[]; ind_argo=[];
%     ind_ctd = find(ctd7109.lat < 18);
%     ctd7109.lat(ind_ctd) = []; ctd7109.long(ind_ctd) = [];
%     ind_argo = find(argo7109.lat<18);
%     argo7109.lat(ind_argo) = []; argo7109.long(ind_argo) = [];
% 
% geoscatter(ctd7109.lat, ctd7109.long-360, 'g+');
% geoscatter(argo7109.lat, argo7109.long-360, 'g+');

%% WMO box 7108
figure 
geolimits(latlim, lonlim)
geobasemap('bluegreen'); hold on
geoplot([10 20 20 10 10], [-90 -90 -80 -80 -90], 'k-', 'LineWidth', 2); %plot box outline
title('WMO Box 7108, deleted data for OWC carib calculations below & left of red line')
geoscatter(ctd7108.lat, ctd7108.long-360, "filled"); hold on
linelat = [15 15 15 10]; linelon = [-90 -85 -85 -85];
geoplot(linelat, linelon, 'r-', 'LineWidth', 2); hold on

    ind_ctd=[]; ind_argo=[];
    ind_ctd = find(ctd7108.lat < 15 & ctd7108.long < 285);
    ctd7108.lat(ind_ctd) = []; ctd7108.long(ind_ctd) = [];
    ind_argo = find(argo7108.lat < 15 & argo7108.long < 285);
    argo7108.lat(ind_argo) = []; argo7108.long(ind_argo) = [];

%% WMO box 7107
figure 
geolimits(latlim, lonlim)
geobasemap('bluegreen'); hold on
geoplot([10 20 20 10 10], [-90 -90 -80 -80 -90], 'k-', 'LineWidth', 2); %plot box outline
title('WMO Box 7108, deleted data for OWC carib calculations below & left of red line')
geoscatter(ctd7108.lat, ctd7108.long-360, "filled"); hold on
linelat = [15 15 15 10]; linelon = [-90 -85 -85 -85];
geoplot(linelat, linelon, 'r-', 'LineWidth', 2); hold on

    ind_ctd=[]; ind_argo=[];
    ind_ctd = find(ctd7108.lat < 15 & ctd7108.long < 285);
    ctd7108.lat(ind_ctd) = []; ctd7108.long(ind_ctd) = [];
    ind_argo = find(argo7108.lat < 15 & argo7108.long < 285);
    argo7108.lat(ind_argo) = []; argo7108.long(ind_argo) = [];

% %% WMO box 7008
% figure 
% geolimits(latlim, lonlim)
% geobasemap('bluegreen'); hold on
% geoplot([0 10 10 0 0], [-90 -90 -80 -80 -90], 'k-', 'LineWidth', 2); %plot box outline
% title('WMO Box 7008, deleted data for OWC carib calculations below & left of red line')
% geoscatter(ctd7008.lat, ctd7008.long-360, "filled"); hold on
% linelat = [10 10 9.5 9.5 9 9 8.5 8.5]; linelon = [-90 -83.5 -83.5 -83 -83 -82.5 -82.5 -80]; %red line 
% geoplot(linelat, linelon, 'r-', 'LineWidth', 2); 
% 
%     ind_ctd=[]; ind_argo=[];
%     ind_ctd = find(ctd7008.lat < 8.5 | (ctd7008.lat<9 & ctd7008.long< 277.5) | (ctd7008.lat<9.5 & ctd7008.long< 277) | (ctd7008.lat<10 & ctd7008.long< 276.5));
%     ctd7008.lat(ind_ctd) = []; ctd7008.long(ind_ctd) = [];
%     ind_argo = find(argo7008.lat < 8.5 | (argo7008.lat<9 & argo7008.long< 277.5) | (argo7008.lat<9.5 & argo7008.long< 277) | (argo7008.lat<10 & argo7008.long< 276.5));
%     argo7008.lat(ind_argo) = []; argo7008.long(ind_argo) = [];

%% WMO box 7007
% figure 
% geolimits(latlim, lonlim)
% geobasemap('bluegreen'); hold on
% geoplot([0 10 10 0 0], [-80 -80 -70 -70 -80], 'k-', 'LineWidth', 2); %plot box outline
% title('WMO Box 7007, deleted data for OWC carib calculations below & left of red line')
% geoscatter(ctd7007.lat, ctd7007.long-360, "filled"); hold on
% linelat = [9.2 9.2 7.5 7.5]; linelon = [-80 -78 -78 -70]; %red line 
% geoplot(linelat, linelon, 'r-', 'LineWidth', 2); 
% 
%     ind_ctd=[]; ind_argo=[];
%     ind_ctd = find(ctd7007.lat <7.5 | (ctd7007.lat<9.2 & ctd7007.long<282));
%     ctd7007.lat(ind_ctd) = []; ctd7007.long(ind_ctd) = [];
%     ind_argo = find(argo7007.lat <7.5 | (argo7007.lat<9.2 & argo7007.long<282));
%     argo7007.lat(ind_argo) = []; argo7007.long(ind_argo) = [];

%% WMO box 7208
figure 
geolimits(latlim, lonlim)
geobasemap('bluegreen'); hold on
geoplot([20 30 30 20 20], [-90 -90 -80 -80 -90], 'k-', 'LineWidth', 2); %plot box outline
title('WMO Box 7208, deleted data for OWC carib calculations above red line')
geoscatter(ctd7208.lat, ctd7208.long-360, "filled"); hold on
geoscatter(argo7208.lat, argo7208.long-360, "filled"); hold on
linelat = [20 22 22 22.5 22.5 22.75 22.75]; linelon = [-88 -88 -84 -84 -83 -83 -80];
geoplot(linelat, linelon, 'r-', 'LineWidth', 2); hold on

    ind_ctd=[]; ind_argo=[];
    ind_ctd = find(ctd7208.lat > 22.75 | (ctd7208.lat>22.5 & ctd7208.long<277) | (ctd7208.lat>22 & ctd7208.long< 276) | (ctd7208.lat>20 & ctd7208.long< 272));
    ctd7208.lat(ind_ctd) = []; ctd7208.long(ind_ctd) = [];
    ind_argo = find(argo7208.lat > 22.75 | (argo7208.lat>22.5 & argo7208.long<277) | (argo7208.lat>22 & argo7208.long< 276) | (argo7208.lat>20 & argo7208.long< 272));
    argo7208.lat(ind_argo) = []; argo7208.long(ind_argo) = [];

%% WMO box 7207
figure 
geolimits(latlim, lonlim)
geobasemap('bluegreen'); hold on
geoplot([20 30 30 20 20], [-80 -80 -70 -70 -80], 'k-', 'LineWidth', 2); %plot box outline
title('WMO Box 7207, deleted data for OWC carib calculations above red line')
geoscatter(ctd7207.lat, ctd7207.long-360, "filled"); hold on
geoscatter(argo7207.lat, argo7207.long-360, "filled"); hold on
linelat = [22 22 21 21 20 20]; linelon = [-80 -78 -78 -76 -76 -70];
geoplot(linelat, linelon, 'r-', 'LineWidth', 2); hold on

    ind_ctd=[]; ind_argo=[];
    ind_ctd = find(ctd7207.lat > 22 | ctd7207.long >284 | (ctd7207.lat>21 & ctd7207.long>282));
    ctd7207.lat(ind_ctd) = []; ctd7207.long(ind_ctd) = [];
    ind_argo = find(argo7207.lat > 22 | argo7207.long >284 | (argo7207.lat>21 & argo7207.long>282));
    argo7207.lat(ind_argo) = []; argo7207.long(ind_argo) = [];
    %you need to do the hist data down here as well 
    ind_argo = find(argo7207.lat > 22 | argo7207.long >284 | (argo7207.lat>21 & argo7207.long>282));
    argo7207.lat(ind_argo) = []; argo7207.long(ind_argo) = [];

disp('Double check proper data has been deleted by verifying that the data KEPT is overlaid with a green plus')

%note to self, Lola should you delete all data that is outside of the
%lat/long points that are kept? The reason it is being done as it currently
%is is because I assuem that keeping the rest of the data will not matter
%since the select_WMO_box code just looks for lat/long data (from what I
%understand). 

%% The following portion of code will update the wmo_boxes.mat file
% deleting the pacific boxes necessary, and saving the updated list of wmo
% boxes with data in them with the name wmo_boxes_carib.mat

wmo_boxes = load('/shared/argo/dmqc/CAL_DATA/constants/wmo_boxes.mat'); %the mat file is loaded in as a structure
wmovec = [wmo_boxes.la_wmo_boxes(:,1)]; %this line pulls a vector of WMO box numbers out of the structure - this makes indexing in the next line easier
wb_no_data = wmo_boxes_to_delete_list;
    % numbers of the WMO boxes which we have removed above. These are boxes 
    % that lie entirely in the pacific. we do not need this data. Above we
    % have deleted it. Here, we will set the logical values for
    % ctd_historical data, argo data, and bottle data (columns 2, 3, and 4
    % respectively in the wmo_boxes struct) equal to 0. OWC uses this
    % struct to skip over empty boxes, which is what we want to do for the
    % Caribbean owc procedure. 
w_ind = find(ismember(wmovec, wb_no_data)); %indicies for which we need to make sure columns all read "0"
wmo_boxes_carib = wmo_boxes; %initialize new .mat file
wmo_boxes_carib.la_wmo_boxes(w_ind, 2:end) = [0]; %clever mask to set all columns of wmo boxes we specify equal to 0

save /shared/argo/dmqc/CAL_DATA/constants/wmo_boxes_carib.mat wmo_boxes_carib
save /shared/argo/dmqc/COW_DATA/constants/wmo_boxes_carib.mat wmo_boxes_carib