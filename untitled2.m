% Finding float over land around 30*N and 60*E in the meta_sum 
% 
setargo
load(fullfile(ARGOMETA,'/meta_sum'))
launch_data0 = [meta_sum.launch];% == 2025
%mask for lat >30N & <40N
    lat_30plus = [launch_data0.latitude] > 30;
    lat_40minus = [launch_data0.latitude] < 40;
    inds_lat30to40 = lat_30plus & lat_40minus;
meta_sum_lat = meta_sum(inds_lat30to40);
%mask the updated metasum for long >60E and <90E
launch_data1 = [meta_sum_lat.launch];
    long_60plus = [launch_data1.longitude] >60;
    %long_90minus = [launch_data1.longitude] >90;
    %inds_long60to90 = long_60plus & long_90minus;
meta_sum_lat_long = meta_sum_lat(long_60plus);