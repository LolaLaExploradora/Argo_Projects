function apply_therm_lag_ViewOnlyInGUI(ncfile, cyc_ii, vel_vec, dt_vec, dt_vec_juld, dpres_vec, dpres_m_vec)
% based on ch_tlag_func.m
% Nov 2010 PER 
% May 2013  Added code to deal with case of real-time corrections to
% Pres put into pres_adjusted (e.g. Apex NPD error)
%
% fb, 2013/11/16: do not use S,T,p with flags > 2
% dw, 2018/2/9: Added code to deal with case of no data and no qc flag
% (' ') to a flag of NaN
% dw, 2018/3/9:  Modified calculation of HISTORY_DATE to avoid possible
% rounding error in seconds (causes 60 seconds)
% dw, 2018/3/19:  Added function copy_to_adjusted to copy values to
% adjusted values when there is insufficient data to run a thermal lag
% calculation
% dw, 2019/2/7: Copies secondary profile data to adjusted fields
% without thermal lag adjustment
% dw, 2019/4/4: Added SCIENTIFIC_CALIB_DATE to correspond to comments
% dw, 2019/10/25: Removed adding FillValue to bad salinity because it
% causes a problem with apply_OW
% dw, 2023/12/18: Taken from ./old/apply_therm_lag_mp.m, removed code
% no longer used and cleaned up the SCIENTIFIC_CALIB eq, coef, and
% comments
epoch = datetime(1950, 1, 1, 'TimeZone', 'UTC');

ncid= netcdf.open(ncfile, 'WRITE'); %LP-ncfile is /shared/argo/dmqc/[WMOnum]/[Rfile_cyclenum]
varid=netcdf.inqVarID(ncid,'WMO_INST_TYPE');
wmo_inst_type= netcdf.getVar(ncid,varid)';

% dw 4/16/2018 - modified to handle more than one profile
if strcmp(deblank(wmo_inst_type(1,:)),'852')
    disp([ncfile,': is not a SBE ctd']) %if the ncid==852 then it is not SBE
    netcdf.close(ncid)
    return
end %LP - how does this piece of code allow us to handle>1 proflie though?

varid=netcdf.inqVarID(ncid,'LATITUDE');
lat =netcdf.getVar(ncid,varid); %LP- why do we need lat?

varid=netcdf.inqVarID(ncid,'CYCLE_NUMBER'); %LP - We operate by cycle in this code. 
% apply_therm_lag called by therm_lag and the latter is cycle-dependent
cycle_number= double(netcdf.getVar(ncid,varid));

varid = netcdf.inqDimID(ncid,'N_PROF');
[~,N_PROF] = netcdf.inqDim(ncid,varid); %tells us if we have both regular & high freq data

% determine if the float has any prssure adjustment
varid = netcdf.inqVarID(ncid,'PARAMETER');
params = netcdf.getVar(ncid,varid);
pres_index = strmatch('PRES',params(:,:,1,1)');
varid=netcdf.inqVarID(ncid,'SCIENTIFIC_CALIB_COMMENT');

calib_comments = netcdf.getVar(ncid,varid);
if strcmp(calib_comments(1:4,pres_index)','none') | isempty(deblank(strcat(calib_comments(:,pres_index)')))   % strcat squeezes out all white space
    pcomments = 0;
else
    pcomments = 1;
end

%also look to see if there is data in PRES_ADJUSTED
% and whether it is different numerically than PRES  % PER Dec 6. 2017
varid=netcdf.inqVarID(ncid,'PRES');
p = netcdf.getVar(ncid,varid);
varid=netcdf.inqVarID(ncid,'PRES_ADJUSTED');
p_adj = netcdf.getVar(ncid,varid);
if all(p_adj== netcdf.getAtt(ncid,varid,'_FillValue'))
    padjust = 0;
else
    if all(p-p_adj ==0)
        padjust = 0;
    else
        padjust = 1;
    end
end

% are there sufficient number of levels (>2) to make calculation
thedim=netcdf.inqDimID(ncid,'N_LEVELS'); %thedim - a "zero-based dimension identifier" basically tells the next line where to look for the N_LEVELS variable
[~, nd] = netcdf.inqDim(ncid,thedim);
% N_LEVELS: Max num of pres levels contained in a profile.  
% ex. if your CTD is 2dbar-binned to 2000dbar then N_LEVELS=1000
% https://cdn.ioos.noaa.gov/media/2020/03/argo_user_manual_v3.3a.pdf

if nd < 4 %<4 means there are <2 data points, so no calc can be made
    disp([ncfile,': not enough points to calculate thermal lag'])
    copy_to_adjusted;
    netcdf.close(ncid)
    return
end
    
fprintf(2, ' pcomments=%d, padjust=%d \n', pcomments, padjust);
if (pcomments == 0 & padjust == 1) |  (pcomments == 1 & padjust == 0)
        disp([ncfile,': Unsure about PRES_ADJUSTED field, check files'])
        copy_to_adjusted;
        netcdf.close(ncid)
        return

elseif pcomments == 1 &  padjust ==1   % there exists a pressure adjusted field
    use_adjust = 1;
    disp([ncfile,': Detected Data in PRES_ADJUSTED field, applying thermal lag to adjusted fields'])
   
    varid=netcdf.inqVarID(ncid,'PRES_ADJUSTED');
    pres=netcdf.getVar(ncid,varid); % get all elements of pressure
    f.pres = pres(:,1)';
    badf= f.pres == netcdf.getAtt(ncid,varid,'_FillValue');
    f.pres(badf)=NaN;
    
    varid=netcdf.inqVarID(ncid,'PRES_ADJUSTED_QC');
    pres_qc=netcdf.getVar(ncid,varid);
    f.pres_qc = pres_qc(:,1)';
    
    varid=netcdf.inqVarID(ncid,'TEMP_ADJUSTED');
    temp=netcdf.getVar(ncid,varid);
    f.temp = temp(:,1)';
    badf= f.temp == netcdf.getAtt(ncid,varid,'_FillValue');
    f.temp(badf)=NaN;
    temp_68 = f.temp*1.00024;  %(convert to ITPS-68)
    
    varid=netcdf.inqVarID(ncid,'TEMP_ADJUSTED_QC');
    temp_qc=netcdf.getVar(ncid,varid);
    f.temp_qc = temp_qc(:,1)';
    
    varid=netcdf.inqVarID(ncid,'PSAL_ADJUSTED');
    psal=netcdf.getVar(ncid,varid);
    f.psal = psal(:,1)';
    badf= f.psal == netcdf.getAtt(ncid,varid,'_FillValue');
    f.psal(badf)=NaN;
    
    varid=netcdf.inqVarID(ncid,'PSAL_ADJUSTED_QC');
    psal_qc=netcdf.getVar(ncid,varid);
    f.psal_qc = psal_qc(:,1)';
    
else
    use_adjust = 0;
    varid=netcdf.inqVarID(ncid,'PRES');
    pres=netcdf.getVar(ncid,varid); % get all elements of pressure
    f.pres = pres(:,1)';
    badf= f.pres == netcdf.getAtt(ncid,varid,'_FillValue');
    f.pres(badf)=NaN;
    
    varid=netcdf.inqVarID(ncid,'PRES_QC');
    pres_qc=netcdf.getVar(ncid,varid);
    f.pres_qc = pres_qc(:,1)';
    
    varid=netcdf.inqVarID(ncid,'TEMP');
    temp=netcdf.getVar(ncid,varid);
    f.temp = temp(:,1)';
    badf= f.temp == netcdf.getAtt(ncid,varid,'_FillValue');
    f.temp(badf)=NaN;
    temp_68 = f.temp*1.00024;  %(convert to ITPS-68)
    
    varid=netcdf.inqVarID(ncid,'TEMP_QC');
    temp_qc=netcdf.getVar(ncid,varid);
    f.temp_qc = temp_qc(:,1)';
    
    varid=netcdf.inqVarID(ncid,'PSAL');
    psal=netcdf.getVar(ncid,varid);
    f.psal = psal(:,1)';
    badf= f.psal == netcdf.getAtt(ncid,varid,'_FillValue');
    f.psal(badf)=NaN;
    
    varid=netcdf.inqVarID(ncid,'PSAL_QC');
    psal_qc=netcdf.getVar(ncid,varid);
    f.psal_qc = psal_qc(:,1)';
end

   % fb, 2013/11/16:
% apply QC flag edits before filtering
% following Pelle's lead used for f.pres_qc
n_qc = length(f.pres_qc);
pqc = ones(1, n_qc);
tqc = ones(1, n_qc);
sqc = ones(1, n_qc);

for ii = 1:n_qc
    if isempty(str2num(f.pres_qc(ii)))
        pqc(ii)=NaN;
    else
        pqc(ii) = str2num(f.pres_qc(ii));
    end
    if isempty(str2num(f.temp_qc(ii)))
        tqc(ii) = NaN;
    else
        tqc(ii) = str2num(f.temp_qc(ii));
    end
    if isempty(str2num(f.psal_qc(ii)))
        sqc(ii) = NaN;
    else
        sqc(ii) = str2num(f.psal_qc(ii));
    end
end

% if the float is a NAVIS float apply thermal lag to the binned data
% only
if str2num(wmo_inst_type(1,:))==869
    lastPres = 985;
    disp('NAVIS')
else
    lastPres = max(f.pres);
end

% calculate the salinity corrected for thermal lag
% for WHOI SOLOs, vel = 10 cm/s
vel = 0.1 ; % 10 cm/sec = 0.1 m/s
% SBE 41CP new numbers as of 10/10/06
alph=0.141;
tau=6.68;
% ok = find(isfinite(f.pres) & isfinite(temp_68) & isfinite(f.psal) & f.pres > 0 & pqc < 4 & tqc < 4 & sqc < 4);
% dwest@whoi.edu 6/12/2025 - added last pressure bin 
% The next line compares several logical vectors
ok = find(isfinite(f.pres) & isfinite(temp_68) & isfinite(f.psal) & f.pres>=0 & f.pres<=lastPres & pqc < 4 & tqc < 4 & sqc < 4);
    %ok : number of pressure levels 
nok = length(ok);
ref = max(ok); 

if isempty(ref) || nok <2;
    disp(['Unable to find valid pressure (or T, S) data: ',ncfile])
    copy_to_adjusted; %this copies temp and pres 
    netcdf.close(ncid)
    return
end

% ------------------------------------------------------------
%% Lola's code changes to include VAR start here

%if we do not have sufficient mc code data, use the old velocity calc code:
vel_static = .1;
e_time00 = sw_dpth(f.pres',lat(1))/vel_static;
e_time11 = e_time00(ref)-e_time00'; % rise time


%% Rtraj data - dpres and dt
% pressure
dpres_m = sw_dpth(dpres_vec{cycle_number(1)+1}, lat(1));
% time
dt = dt_vec_juld{cyc_ii,1};
int_day = floor(dt(1));
dt_fracDay = dt-int_day;
dt_sec = dt_fracDay*86400; %relative time wrt day, in sec

%% Profile data - pressure
fpres_m = sw_dpth(flip(f.pres(ok)'), lat(1)); %flip pres so deep-->shallow
%using the "ok" logical mask here to reject any data points that correspond
%to pressure, temp, or salinity having QC=4. 

%% Interpolate profile pressure using Rtraj data
%  Rtraj data (dpres and dt_sec) is coarse -- as in, there are few points. 
%  Profile data (fpres) is fine -- many points. 
%  output of interpolation is relative time [sec] for fine Profile fpres data
%
% Pelle's method/solution : restrict pres to only increasing points
%  where internal waves cause pressure to not strictly increase, we turn
%  these values into NaNs and notify the user of the number of NaNs in the
%  final dataset and the pressure differences

%% Pressure and Time Vectors
% Here we make sure there are no pressure inversions or duplicate numbers
% (otherwise interp1 wont work)

both_p_vecs{1} = fpres_m;
both_p_vecs{2} = dpres_m;
for idx = 1:length(both_p_vecs)
    pres = both_p_vecs{idx};
    % Mask - restricts for strictly ascentding values (deep-->shallow)
    mask_strct_incr = logical([0; (diff(pres)>=0)]); 
    track_masks{idx,1} = mask_strct_incr;
    pres = pres(~mask_strct_incr);
    % Mask - removes dulplicates
    [~, mask_rmv_dupl] = unique(pres, "stable");
    updated_p_vecs{idx} = pres(mask_rmv_dupl);
    
    %update rmv_dupl mask to a logical sequence (for use later)
    full_list = 1:1:length(pres);
    missing_inds = setdiff(full_list, mask_rmv_dupl);
    mask_rmv_dupl_lgc = false(size(pres));
    mask_rmv_dupl_lgc(missing_inds) = true;
    track_masks{idx, 2} = mask_rmv_dupl_lgc;
    
    % IF - idx 2 will always be Rtraj pres data, only Rtraj data has accompanying 
    % time data (dt_sec) that should be masked to remove the same indices of values
    % removed from dpres_m
    if idx == 2  
        dt_sec = dt_sec(~mask_strct_incr);
        dt_sec = dt_sec(mask_rmv_dupl);
    end
end
fpres_m_maskd = updated_p_vecs{1};
dpres_m_maskd = updated_p_vecs{2};

%% Plot P vs T for both Rtraj and Profile 
% figure
% plot(dt_sec, dpres_m_maskd, 'b+', vt_sec, fpres_m_maskd, 'm.')
%% Print out pressure inversions being removed and their distances 
fpres_m_inv = find(track_masks{1,1}==1);
if ~isempty(fpres_m_inv)
    %take ind locations of inversions, pull the index immediate before, and
    %use those two pres values to calculate pressure discrepancy to print
    %in the statement.
    b4_inv = fpres_m_inv-1;
    presb4inv = fpres_m(b4_inv);
    presatinv = fpres_m(fpres_m_inv);
    rela_depth_shift = presb4inv-presatinv;
    fprintf("Pressure inversion found at index/indices %d of %d (where pres vec is ascending)/n ..." + ...
       "with relative depth shift(s): %d", fpres_m_inv, length(fpres_m), rela_depth_shift)
end


% we also track if fpres is out of bounds of dpres. All values removed from
% fpres due to pres invs, duplicates, or being out of bounds of dpres will
% result in NaNs for psal due to lack of sufficient information for
% calculation of thermal lag.
mask_max_lgc = false(size(fpres_m));
inds_max = find(fpres_m>max(dpres_m));
mask_max_lgc(inds_max) = true;
track_masks{1,3} = mask_max_lgc;
%should I also track where fpres is less than the minimum of dpres?
salt_cor_mask = track_masks{1,1}|track_masks{1,2}|track_masks{1,3};

%% Interpolate relative time (seconds) for Profile pressure
vt_sec = interp1(dpres_m_maskd, dt_sec, fpres_m_maskd, 'linear');

%% Recreate Pelle's rise time plot
vert_vel = diff(dpres_m_maskd)./diff(dt_sec);
figure
plot([vert_vel;0]*-1, dpres_m_maskd, 'b-')
set(gca,'ydir','rev'); hold on
ylabel('pressure [m]')
xlabel('w [m/s]')
xlim([-.1 .2])

%% Velocity     
%it is possible for velocity to have nans if fpres_m_maskd has values out
%of bounds of dpres_m_maskd
v_mpers1 = diff(fpres_m_maskd)./diff(vt_sec);

%% Elapsed time 
intermed = diff(fpres_m_maskd)./(v_mpers1);
nanmask1 = find(isnan(intermed));
e_time0 = cumsum(diff(fpres_m_maskd)./(v_mpers1), 'omitnan');
    %cant leave NaNs in cumsum, so we omit them, they turn to zeros
e_time0(nanmask1) = NaN;
    %add them back in here so that we keep our calculations sound
e_time0 = [0; e_time0]; 
    %add zero here for first index we lost to diff() in etime0 above
e_time1 = e_time0(end)-e_time0'; % rise time

nanmask2 = find(isnan(e_time1));
e_time1(nanmask2) = [];
    %now we turn all the NaNs to [] to pass into celltm_sbe

%Call G. Johnson's thermal mass function.  Note vectors must be ordered
%from bottom of cast up.
salt_cor0=fliplr(celltm_sbe41(f.psal(ok(nok:-1:1)), temp_68(ok(nok:-1:1)), ...
    f.pres(ok(nok:-1:1)), e_time11(ok(nok:-1:1)), ...
    alph,tau));

ok_VAR = 1:1:length(e_time1);
nok_VAR = max(ok_VAR);
%adjust fpres_m, temp --> inputs without NaN values 
fpres_VAR = f.pres(~salt_cor_mask);
temp_68_VAR = temp_68(~salt_cor_mask);
fpsal_VAR = f.psal(~salt_cor_mask);
salt_cor11=fliplr(celltm_sbe41(fpsal_VAR(ok_VAR(nok_VAR:-1:1)), temp_68_VAR(ok_VAR(nok_VAR:-1:1)), ...
    fpres_VAR(ok_VAR(nok_VAR:-1:1)), e_time1(ok_VAR(nok_VAR:-1:1)), ...
    alph,tau));

%Here we filter the salinity correction back into the appropriate indicies
nanvec = nan(1,length(fpres_m));
nanvec(~salt_cor_mask) = salt_cor11;
salt_cor1 = nanvec;
if sum(~salt_cor_mask) ~= length(salt_cor11) || length(ok) ~= length(salt_cor1)
    disp("Error, discrepancy between levels of salinity omitted from thermal lag calculation and levels calculated")
end

%% PLOT NO THERM LAG ADJ, ORIG ADJ, UPDATED ADJ
% fpres_VAR_plot = nanvec(~salt_cor_mask);
% figure
% title(string(ncfile(end-14:end)), 'Interpreter', 'none'); hold on
% subtitle('Thermal lag adjustment comparison'); hold on
% xlabel('salinity [psu]'); hold on;
% ylabel('pressure [dbar]'); set(gca,'ydir','rev'); hold on;
% plot(f.psal, f.pres, 'k.', salt_cor0, f.pres, 'b+', salt_cor1, f.pres, 'm*')
% legend('No TL adj', 'Orig TL adj vel=0.1m/s', 'VAR TL adj')
% 
% dtdp = gradient(temp_68(ok), f.pres(ok));
% figure
% title(string(ncfile(end-14:end)), 'Interpreter', 'none'); hold on
% subtitle('Difference btwn original psal data and TL adjusted data'); hold on
% ylabel('salinty [psu]')
% plot(fpres_VAR, fpsal_VAR-salt_cor11, 'm*'); hold on;
% plot(f.pres(ok), f.psal(ok)-salt_cor0, 'b.')
% ylabel('salinity [psu]')
% xlabel('pressure [dbar]');
% hold on
% yyaxis right;
% ylabel('temperature gradient')
% plot(f.pres(ok), dtdp, 'y-')
% legend('orig - VARTL', 'orig - stndTL', 'temp gradient')

if use_adjust == 0  
    varid=netcdf.inqVarID(ncid,'PRES');
    foo=netcdf.getVar(ncid,varid); % get all elements of pressure
    pres = foo(:,1);
    varid=netcdf.inqVarID(ncid,'PRES_ADJUSTED');
    netcdf.putVar(ncid,varid,foo);
    
    varid=netcdf.inqVarID(ncid,'PRES_QC');
    foo=netcdf.getVar(ncid,varid);
    pres_qc = foo(:,1);
    varid=netcdf.inqVarID(ncid,'PRES_ADJUSTED_QC');
    netcdf.putVar(ncid,varid,foo);
    
    varid=netcdf.inqVarID(ncid,'TEMP');
    foo=netcdf.getVar(ncid,varid);
    temp = foo(:,1);
    varid=netcdf.inqVarID(ncid,'TEMP_ADJUSTED');
    netcdf.putVar(ncid,varid,foo);
    
    varid=netcdf.inqVarID(ncid,'TEMP_QC');
    foo=netcdf.getVar(ncid,varid);
    temp_qc=foo(:,1);
    varid=netcdf.inqVarID(ncid,'TEMP_ADJUSTED_QC');
    netcdf.putVar(ncid,varid,foo);
end

if use_adjust == 0 
    varid=netcdf.inqVarID(ncid,'PSAL');
    psal=netcdf.getVar(ncid,varid);
    psal(ok,1) = salt_cor1;
    
    varid=netcdf.inqVarID(ncid,'PSAL_QC');
    psal_qc=netcdf.getVar(ncid,varid);
    
else
    varid=netcdf.inqVarID(ncid,'PSAL_ADJUSTED');
    psal=netcdf.getVar(ncid,varid);
    psal(ok,1) = salt_cor1;
    
    varid=netcdf.inqVarID(ncid,'PSAL_ADJUSTED_QC');
    psal_qc=netcdf.getVar(ncid,varid);
    
end

varid=netcdf.inqVarID(ncid,'PSAL_ADJUSTED');
netcdf.putVar(ncid,varid,psal);

varid=netcdf.inqVarID(ncid,'PSAL_ADJUSTED_QC');
netcdf.putVar(ncid,varid,psal_qc);

varid=netcdf.inqVarID(ncid,'PSAL_ADJUSTED_ERROR'); 
foo=netcdf.getVar(ncid,varid);
error = abs(f.psal(ok)-salt_cor1);
psal_err = zeros(size(foo));
psal_err(ok,1) = error;
netcdf.putVar(ncid,varid,psal_err);
 

%% write out calibration and history comment
%first figure out what 'Param' is psal
varid = netcdf.inqVarID(ncid,'PARAMETER');
params = netcdf.getVar(ncid,varid);
psal_index = strmatch('PSAL',params(:,:,1,1)');
% profile #1
if all(ismember(psal_qc(:,1),[' ','4','9']))
    equation = pad('None',256);
    coeff = pad('None',256);
    comment = pad('Bad PSAL',256);
else
    equation= pad('PSAL_ADJ = CTM_ADJ_PSAL ',256);
    %coeff=pad('CTM: alpha=0.141C, tau=6.89s, rise rate = 10 cm/s with error equal to the adjustment;',256);
    coeff=pad('CTM: alpha=0.141C, tau=6.89s, rise rate = variable with error equal to the adjustment;',256);
    comment= pad('PSAL_ADJ corrects Conductivity Thermal Mass (CTM) with variable ascent, Johnson et al., 2007, JAOT. only applied to binned data',256);
end
% profile #2 if exists
if N_PROF > 1
    if all(ismember(psal_qc(:,2),[' ','4','9']))
        equation2 = pad('None',256);
        coeff2 = pad('None',256);
        comment2 = pad('Bad PSAL',256);
    else
        equation2=pad('PSAL_ADJ = PSAL ',256);
        coeff2 = pad('None',256);
        comment2=pad('No thermal mass adjustment on non-primary profiles.;',256);
    end
end
caldate = datestr(now,'yyyymmddHHMMSS');

varid=netcdf.inqVarID(ncid,'SCIENTIFIC_CALIB_EQUATION');
netcdf.putVar(ncid,varid,[0 psal_index-1 0 0],[length(equation) 1 1 1],equation);
for np = 2:N_PROF
    netcdf.putVar(ncid,varid,[0 psal_index-1 0 np-1],[length(equation2) 1 1 1],equation2)
end
varid=netcdf.inqVarID(ncid,'SCIENTIFIC_CALIB_COEFFICIENT');
netcdf.putVar(ncid,varid,[0 psal_index-1 0 0],[length(coeff) 1 1 1],coeff)
for np = 2:N_PROF
    netcdf.putVar(ncid,varid,[0 psal_index-1 0 np-1],[length(coeff2) 1 1 1],coeff2)
end
varid=netcdf.inqVarID(ncid,'SCIENTIFIC_CALIB_COMMENT');
netcdf.putVar(ncid,varid,[0 psal_index-1 0 0],[length(comment) 1 1 1],comment)
for np = 2:N_PROF
    netcdf.putVar(ncid,varid,[0 psal_index-1 0 np-1],[length(comment2) 1 1 1],comment2)
end
varid=netcdf.inqVarID(ncid,'SCIENTIFIC_CALIB_DATE');
%varid=netcdf.inqVarID(ncid,'CALIBRATION_DATE'); %LP (Lola) 04/23/26 - use this when SCIENTIFIC_CALIB_DATE is not found in older floats
netcdf.putVar(ncid,varid,[0 psal_index-1 0 0],[14 1 1 1],caldate)
for np = 2:N_PROF
    netcdf.putVar(ncid,varid,[0 psal_index-1 0 np-1],[14 1 1 1],caldate)
end

% write out history statement
histdate = datestr(now,'yyyymmddHHMMSS');

nhistory_id =  netcdf.inqDimID(ncid,'N_HISTORY');
[foo, N_HISTORY] = netcdf.inqDim(ncid,nhistory_id);

% note we are increminting history count by one, but netcdf indexing starts at
% zero instead of one.
for np = 1:N_PROF  % primary profile
    varid = netcdf.inqVarID(ncid,'HISTORY_INSTITUTION');
    netcdf.putVar(ncid,varid,[0 np-1 N_HISTORY],[4 1 1],'WHOI')
    varid = netcdf.inqVarID(ncid,'HISTORY_STEP');
    netcdf.putVar(ncid,varid,[0 np-1 N_HISTORY],[4 1 1],'ARSQ')

    varid = netcdf.inqVarID(ncid,'HISTORY_SOFTWARE');
    netcdf.putVar(ncid,varid,[0 np-1 N_HISTORY],[4 1 1],'CTM ')
    varid = netcdf.inqVarID(ncid,'HISTORY_SOFTWARE_RELEASE');
    netcdf.putVar(ncid,varid,[0 np-1 N_HISTORY],[4 1 1],'V1.0')

    varid = netcdf.inqVarID(ncid,'HISTORY_DATE');
    netcdf.putVar(ncid,varid,[0 np-1 N_HISTORY],[14 1 1],histdate)
    varid = netcdf.inqVarID(ncid,'HISTORY_ACTION');
    netcdf.putVar(ncid,varid,[0 np-1 N_HISTORY],[2 1 1],'IP')
end

netcdf.close(ncid);

%% function to copy values to adjusted values
function copy_to_adjusted

    % is all the psal data bad?
    varid=netcdf.inqVarID(ncid,'PRES_QC');
    pres_qc=netcdf.getVar(ncid,varid);


    if padjust == 0
        % copy to profile #1 to adjusted fields, not any other profiles
        % dw - 2/7/2019 : now copies both profiles to adjusted fields
        varid=netcdf.inqVarID(ncid,'PRES');
        pres=netcdf.getVar(ncid,varid); % get all elements of pressure
        varid=netcdf.inqVarID(ncid,'PRES_ADJUSTED');
        netcdf.putVar(ncid,varid,pres);

%             varid=netcdf.inqVarID(ncid,'PRES_QC');
%             pres_qc=netcdf.getVar(ncid,varid);
        varid=netcdf.inqVarID(ncid,'PRES_ADJUSTED_QC');
        netcdf.putVar(ncid,varid,pres_qc);

        varid=netcdf.inqVarID(ncid,'TEMP');
        temp=netcdf.getVar(ncid,varid);
        varid=netcdf.inqVarID(ncid,'TEMP_ADJUSTED');
        netcdf.putVar(ncid,varid,temp);

        varid=netcdf.inqVarID(ncid,'TEMP_QC');
        temp_qc=netcdf.getVar(ncid,varid);
        varid=netcdf.inqVarID(ncid,'TEMP_ADJUSTED_QC');
        netcdf.putVar(ncid,varid,temp_qc);
        
        varid=netcdf.inqVarID(ncid,'PSAL');
        psal=netcdf.getVar(ncid,varid);
        varid=netcdf.inqVarID(ncid,'PSAL_ADJUSTED');
        netcdf.putVar(ncid,varid,psal);

        varid=netcdf.inqVarID(ncid,'PSAL_QC');
        psal_qc=netcdf.getVar(ncid,varid);
        varid=netcdf.inqVarID(ncid,'PSAL_ADJUSTED_QC');
        netcdf.putVar(ncid,varid,psal_qc);
    else
        disp([ncfile,': Detected Data in PRES_ADJUSTED field, no thermal lag applied insufficient data'])
    end

  