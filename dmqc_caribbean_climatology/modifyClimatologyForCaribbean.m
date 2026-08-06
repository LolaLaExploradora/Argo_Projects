function modifyClimatologyForCaribbean()
%the purpose of this function is to modify the data in WMO boxes that the 
% OWC code uses for data corrections. WMO boxes spanning both the caribbean 
% sea and the pacific need to have the pacific data removed (this will skew
% the OWC correction) 

ctdCoriolisFolder = '/shared/argo/dmqc/COW_DATA/climatology_carib/historical_ctd_coriolis';
ctdFolder = '/shared/argo/dmqc/COW_DATA/climatology_carib/historical_ctd';
botFolder = '/shared/argo/dmqc/COW_DATA/climatology_carib/historical_bot';
argoFolder= '/shared/argo/dmqc/COW_DATA/climatology_carib/argo_profiles'


%% ctd coriolis folder operations 
cd '/shared/argo/dmqc/COW_DATA/climatology_carib/historical_ctd_coriolis_orig'
ctdCor7108 = matfile('ctd_7108.mat', 'Writable', true);
ctdCor7107 = matfile('ctd_7107.mat', 'Writable', true);
ctdCor7208 = matfile('ctd_7208.mat', 'Writable', true);
ctdCor7207 = matfile('ctd_7207.mat', 'Writable', true);

%% ctd folder operations 
cd '/shared/argo/dmqc/COW_DATA/climatology_carib/historical_ctd_orig'
ctd7107 = matfile('ctd_7107.mat', 'Writable', true);
ctd7207 = matfile('ctd_7207.mat', 'Writable', true); %7108, 7208 not in database

%% bot folder operations 
cd '/shared/argo/dmqc/COW_DATA/climatology_carib/historical_bot_orig'
bot7208 = matfile('bot_7208.mat', 'Writable', true); 

%% argo folder operations
cd '/shared/argo/dmqc/COW_DATA/climatology_carib/argo_profiles_orig'
argo7108 = matfile('argo_7108.mat', 'Writable', true);
argo7107 = matfile('argo_7107.mat', 'Writable', true);
argo7208 = matfile('argo_7208.mat', 'Writable', true);
argo7207 = matfile('argo_7207.mat', 'Writable', true);

%% Lat/long limits for plotting
latlim = [-5 30]; %lat limits are within [-90 90] but for Argo as of 2025 we only have data for [-85 85]
lonlim = [-120 -60]; %lon limits are within [-180 180], note West is negative

%% WMO box 7108
figure 
geolimits(latlim, lonlim)
geobasemap('bluegreen'); hold on
geoplot([10 20 20 10 10], [-90 -90 -80 -80 -90], 'k-', 'LineWidth', 2); %plot box outline
title('WMO Box 7108, deleted data for OWC carib calculations below & left of red line')
geoscatter(ctd7108.lat, ctd7108.long-360, "filled"); hold on
linelat = [15 15 15 10]; linelon = [-90 -85 -85 -85];
geoplot(linelat, linelon, 'r-', 'LineWidth', 2); hold on

        ind_ctdCor=[]; ind_ctd=[]; ind_bot=[]; ind_argo=[]; 
    ind_ctd = find(ctd7108.lat < 15 & ctd7108.long < 285);
    ctd7108.lat(ind_ctd) = []; ctd7108.long(ind_ctd) = [];
        ind_ctdCor = find(ctdCor7108.lat < 15 & ctdCor7108.long < 285);
        ctdCor7108.lat(ind_ctdCor) = []; ctdCor7108.long(ind_ctdCor) = [];
    ind_bot = find(bot7108.lat < 15 & bot7108.long < 285);
    bot7108.lat(ind_bot) = []; bot7108.long(ind_bot) = [];
        ind_argo = find(argo7108.lat < 15 & argo7108.long < 285);
        argo7108.lat(ind_argo) = []; argo7108.long(ind_argo) = [];

%% WMO box 7107
figure 
geolimits(latlim, lonlim)
geobasemap('bluegreen'); hold on
geoplot([10 20 20 10 10], [-80 -80 -70 -70 -80], 'k-', 'LineWidth', 2); %plot box outline
title('WMO Box 7107, deleted data for OWC carib calculations below & left of red line')
geoscatter(ctd7107.lat, ctd7107.long-360, "filled"); hold on
linelat = [15 15 15 10]; linelon = [-90 -85 -85 -85];
geoplot(linelat, linelon, 'r-', 'LineWidth', 2); hold on
    % We do not actually have to remove any data from WMO box 7107 :) 
    %         ind_ctdCor=[]; ind_ctd=[]; ind_bot=[]; ind_argo=[]; 
    % ind_ctd = find(ctd7108.lat < 15 & ctd7108.long < 285);
    % ctd7108.lat(ind_ctd) = []; ctd7108.long(ind_ctd) = [];
    %     ind_ctdCor = find(ctdCor7108.lat < 15 & ctdCor7108.long < 285);
    %     ctdCor7108.lat(ind_ctdCor) = []; ctdCor7108.long(ind_ctdCor) = [];
    % ind_bot = find(bot7108.lat < 15 & bot7108.long < 285);
    % bot7108.lat(ind_bot) = []; bot7108.long(ind_bot) = [];
    %     ind_argo = find(argo7108.lat < 15 & argo7108.long < 285);
    %     argo7108.lat(ind_argo) = []; argo7108.long(ind_argo) = [];


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

    ind_ctdCor=[]; ind_ctd=[]; ind_bot=[]; ind_argo=[];
    ind_ctdCor = find(ctdCor7208.lat > 22.75 | (ctdCor7208.lat>22.5 & ctdCor7208.long<277) | (ctdCor7208.lat>22 & ctdCor7208.long< 276) | (ctdCor7208.lat>20 & ctdCor7208.long< 272));
    ctdCor7208.lat(ind_ctdCor) = []; ctdCor7208.long(ind_ctdCor) = [];
    
    ind_ctd = find(ctd7208.lat > 22.75 | (ctd7208.lat>22.5 & ctd7208.long<277) | (ctd7208.lat>22 & ctd7208.long< 276) | (ctd7208.lat>20 & ctd7208.long< 272));
    ctd7208.lat(ind_ctd) = []; ctd7208.long(ind_ctd) = [];

    ind_bot = find(bot7208.lat > 22.75 | (bot7208.lat>22.5 & bot7208.long<277) | (bot7208.lat>22 & bot7208.long< 276) | (bot7208.lat>20 & bot7208.long< 272));
    bot7208.lat(ind_bot) = []; bot7208.long(ind_bot) = [];

    ind_argo = find(argo7208.lat > 22.75 | (argo7208.lat>22.5 & argo7208.long<277) | (argo7208.lat>22 & argo7208.long< 276) | (argo7208.lat>20 & argo7208.long< 272));
    argo7208.lat(ind_argo) = []; argo7208.long(ind_argo) = [];

%% WMO box 7207
figure 
geolimits(latlim, lonlim)
geobasemap('bluegreen'); hold on
geoplot([20 30 30 20 20], [-80 -80 -70 -70 -80], 'k-', 'LineWidth', 2); %plot box outline
title('WMO Box 7207, deleted data for OWC carib calculations above red line')
geoscatter(ctdCor7207.lat, ctdCor7207.long,'g', "filled"); hold on
geoscatter(ctd7207.lat, ctd7207.long, "filled"); hold on
geoscatter(argo7207.lat, argo7207.long, "filled"); hold on
linelat = [22 22 21 21 20 20]; linelon = [-80 -78 -78 -76 -76 -70];
geoplot(linelat, linelon, 'r-', 'LineWidth', 2); hold on

    ind_ctdCor=[]; ind_ctd=[]; ind_argo=[];
    %Historical Coriolis data in WMO box 7207
    ind_ctdCor = find(ctdCor7207.lat > 22 | (ctdCor7207.lat>21 & ctdCor7207.long >-78) | (ctdCor7207.lat>20 & ctdCor7207.long>-76));
    rmvd_lat =  [ctdCor7207.lat];
    rmvd_lat = rmvd_lat(ind_ctdCor);
    rmvd_long = [ctdCor7207.long];
    rmvd_long = rmvd_long(ind_ctdCor);
    geoscatter(rmvd_lat, rmvd_long, 'r', "filled")
    ctdCor7207.lat(ind_ctdCor) = []; ctdCor7207.long(ind_ctdCor) = [];
    
    %ctd data in WMO box 7207 -- NONE 
    ind_ctd = find(ctd7207.lat > 22 | ctd7207.long >284 | (ctd7207.lat>21 & ctd7207.long>282));
    rmvd_lat =  [ctd7207.lat];
    rmvd_lat = rmvd_lat(ind_ctd);
    rmvd_long = [ctd7207.long];
    rmvd_long = rmvd_long(ind_ctd);
    geoscatter(rmvd_lat, rmvd_long, 'r', "filled")
    ctd7207.lat(ind_ctd) = []; ctd7207.long(ind_ctd) = [];
    
    % argo data in WMO box 7207 -- NONE???
    ind_argo = find(argo7207.lat > 22 | argo7207.long >284 | (argo7207.lat>21 & argo7207.long>282));
    argo7207.lat(ind_argo) = []; argo7207.long(ind_argo) = [];

    %no bottle data 7207

disp('Double check proper data has been deleted by verifying that the data KEPT is overlaid with a green plus')


%% The following portion of code will update the wmo_boxes.mat file
% deleting the pacific boxes necessary, and saving the updated list of wmo
% boxes with data in them with the name wmo_boxes_carib.mat

wmo_boxes = load('/shared/argo/dmqc/CAL_DATA/constants/wmo_boxes.mat'); %the mat file is loaded in as a structure
wmovec = [wmo_boxes.la_wmo_boxes(:,1)]; %this line pulls a vector of WMO box numbers out of the structure - this makes indexing in the next line easier
    % numbers of the WMO boxes which we have removed above. These are boxes 
    % that lie entirely in the pacific. we do not need this data. Above we
    % have deleted it. Here, we will set the logical values for
    % ctd_historical data, argo data, and bottle data (columns 2, 3, and 4
    % respectively in the wmo_boxes struct) equal to 0. OWC uses this
    % struct to skip over empty boxes, which is what we want to do for the
    % Caribbean owc procedure. 
wb_data = [7107, 7108, 7207, 7208];
w_ind = find(~ismember(wmovec, wb_data)); %indicies for which we need to make sure columns all read "0"
wmo_boxes_carib = wmo_boxes; %initialize new .mat file
wmo_boxes_carib.la_wmo_boxes(w_ind, 2:end) = [0]; %clever mask to set all columns of wmo boxes we specify equal to 0

save /shared/argo/dmqc/CAL_DATA/constants/wmo_boxes_carib.mat wmo_boxes_carib
save /shared/argo/dmqc/COW_DATA/constants/wmo_boxes_carib.mat wmo_boxes_carib