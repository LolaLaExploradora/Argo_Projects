function [vel_vec, dt_vec, dt_vec_juld, dpres_vec, dpres_m_vec, cycles_incmpl_mc] = calc_VAR_MC(wmonum, Rtrajpath, nqc)
%nqc = number of cycles

% since the traj file contains info for all cycles, we call it here and
% apply the velocites that we calculate by cycle in the next code
% (apply_therm...) by passing in a vector of those velocities
Rtraj_fn = [num2str(wmonum), '_Rtraj.nc']; %filename
Rtraj_fp = fullfile(Rtrajpath, Rtraj_fn); %filepath, getting Rtraj from AOML
    %this was discussed with Deb 7/17/26

%% MC Code Option
mc = ncread(Rtraj_fp, 'MEASUREMENT_CODE');%
mc_mask_combo = find(mc==500 | mc==600); %indicies where mc is AST or AET (ascent start/end time, respectively)
mc_combo = mc(mc_mask_combo);

pres = ncread(Rtraj_fp, 'PRES');
 pres_mc_combo = pres(mc_mask_combo);

lat0 = ncread(Rtraj_fp, "LATITUDE");
  mc_mask_703 = find(mc==703);
  %lat_mask = mc_mask_703+2;
lat = lat0(mc_mask_703);

juld = ncread(Rtraj_fp, 'JULD');
 juld_mc_combo = juld(mc_mask_combo);


%% Check for alternating 500-600 pattern
% Assign velocity = 10cm/s (0.1m/s) for cycles tat do not have both mc=500
% and 600 codes. For cycles with both, calculate velocity. 
epoch = datetime(1950, 1, 1, 'TimeZone', 'UTC');
timeStamps_mc = [epoch + days(juld_mc_combo)];
timeStamps_all = [epoch + days(juld)];
vel_vec=[]; cycles_incmplt_mc=[]; dpres_vec={};
dt_vec={}; dpres_m_vec={}; vel_vec={}; dt_vec_juld={};

skip_next = false;

for i = 1:length(mc_combo)
    
    if skip_next
        skip_next=false; continue
    end

    if mc_combo(i)==mc_combo(i+1) || mc_combo(i)>=mc_combo(i+1)
        vel_vec(end+1,:) = {0.1}; %0.1m/s rise time
        cycles_incmplt_mc = [cycles_incmplt_mc, i-1]; %starting at cycle 0 (i.e. i-1) 
            if mc_combo(i)==500
                dt_vec(end+1,:) = {juld(mc_mask_combo(i)), 0};
                dpres_vec(end+1,:) = {pres_mc_combo(i), 0};

                dt_vec_juld(end+1,:) = {timeStamps_all(mc_mask_combo(i)), 0};
            elseif mc_combo(i)==600
                dt_vec(end+1,:) = {0, timeStamps_all(mc_mask_combo(i))};
                dpres_vec(end+1,:) = {0, pres_mc_combo(i)};

                dt_vec_juld(end+1,:) = {0, juld(mc_mask_combo(i))};
                %include here just the deepest pressure found between this
                %reading of mc=600's pressure and the last 600 reading? we
                %can put in exceptions for not going back in time to drift
            end
    elseif mc_combo(i) < mc_combo(i+1)
        %Velocity along entire ascent path
        dt = timeStamps_all(mc_mask_combo(i):1:mc_mask_combo(i+1)); 
        dt_juld = juld(mc_mask_combo(i):1:mc_mask_combo(i+1)); 
          dt_vec(end+1,:) = {dt}; %datetime
          dt_vec_juld(end+1,:) = {dt_juld}; %juld
        dpres = pres(mc_mask_combo(i):1:mc_mask_combo(i+1)); %in dbar
        dpres_vec(end+1,:) = {dpres};
        %insert here an if statement that does not let the velocity calc
        %occur if there is not a sufficient/matching number of latitudes
        %dpres_m = sw_dpth(dpres, lat(i+1)); %in METERS
          %dpres_m_vec(end+1,:) = {dpres_m};
        %vel_vec(end+1,:) = {diff(dpres_m)./seconds(diff(dt))}; %pres[m]/time[s]
        skip_next=true;
    end
    
end

%next make sure you have calculated as many velocities as there are cycles.
% cyc2_pres = dpres_vec{3,1};
% cyc2_time = dt_vec{3,1};
% time_diff = seconds(diff(cyc2_time));

%plotcyc2_pres, );
% %% Calculate Velocity Option
% pres = ncread(Rtraj_fp, 'PRES');
% pres_qc = ncread(Rtraj_fp, 'PRES_QC');
% juld = ncread(Rtraj_fp, 'JULD');
% juld_qc = ncread(Rtraj_fp, 'JULD_QC');
% % eventually pull in pres adj and juld adj as well -- creating checks to
% % use those values if needed. 

% %  pres_mc_500 = pres(mc_mask_500);
% %  pres_mc_600 = pres(mc_mask_600);
% %  mc_500 = mc(mc_mask_500);
% % mc_600 = mc(mc_mask_600);
% %     mc_mask_500 = find(mc==500);
% %     mc_mask_600 = find(mc==600);

% %Just velocity from two points AET and AST
% dt = seconds(timeStamps_mc(i+1)-timeStamps_mc(i));
%     dt_vec(end+1,:) = {timeStamps_mc(i), timeStamps_mc(i+1)};
% dpres = pres_mc_combo(i+1)-pres_mc_combo(i);
%     dpres_vec = [dpres_vec; pres_mc_combo(i), pres_mc_combo(i+1)];
% vel_vec = [vel_vec, dpres/dt];