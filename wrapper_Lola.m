%% Wrapper code to call mk_s2_table_page_Lola
% Lola Pierson & Pelle Robbins
% WHOI, Argo
% 2026
% sara.pierson@whoi.edu
%
% Original code, s2_table_wrapper.m, written by Pelle Robbins.
% Code was copied/modifed by Lola Pierson with consent from Dr. Robbins. 
% 
% This code calls mk_s2_table_page_Lola to create webpages like those seen
% at https://argo.whoi.edu/solo2/tables/deployed_2025_1.html for
% calibration coefficient z-scores. 

setargo
ARGUSCCWEB = '/argus/data1/argo/www/calib';
ARGUSCALCO = '/argus/data1/lab/SOLO_II/Checklogs/Calibration_Coeffs/';
years = 2012:2026;
tabletypes = 1:7;
tabletypes = 1;
etctables = [8:11];  % tables for etc pages
etcdir = '/data1/www/etcetc/solo2/plot/tables/';

load(fullfile(ARGOMETA,'/meta_sum'))
%load(fullfile(ARGUSCALCO,'calibration_coeffs.mat'));%only valid floats

nflts = length(meta_sum);
% loop over all floats in meta_sum struct and extract launch date
% % % for i = 1:nflts
% % %     jday(i) = meta_sum(i).launch.jday;
% % %     year(i) = meta_sum(i).launch.year;
% % %     fltnum(i) = meta_sum(i).whoi_number;
% % % end
% % % 
% % % iss2 = fltnum > 7000;  % just do the S2 flots
% % % fltnum = fltnum(iss2); %list of S2 fltnums
% % % year  = year(iss2); %list of launch years for fltnums above
% % % jday = jday(iss2); %list of julday for fltnums above
% % % 
% % % %% HTML pages made for floats, by year
% % % for iy = years; %index of years, starting at first in list above
% % %    ii = year == iy;%mask - only floats of a partic year 
% % % 
% % %    fltlist = fltnum(ii); %only floats of said yr
% % %    jlist = jday(ii);
% % %    [foo,I] = sort(jlist); %sort jday list of said yr
% % %    fltlist = fltlist(I); %sort float nums of partic yr by jul day deployment
% % % 
% % %    for itable = tabletypes
% % %        filename = sprintf('deployed_%d_%d.html',iy,itable);
% % %        mk_s2_table_page(fltlist,filename,itable) %for all flts of partic year, fill html page
% % %    end
% % % 
% % %    % etc tables
% % %     for itable = etctables
% % %        filename = sprintf('deployed_%d_%d.html',iy,itable);
% % %        mk_s2_table_page(fltlist,filename,itable,etcdir)
% % %    end
% % % end
% % % 
% % % 
% % % %% now repeat by FY: fiscal year. 
% % % 
% % % fy(1).fltlist = [7066 7067 7068 7071:7082 7084 7087 7088 7094 7102 7110:7160 7162 7163 7164];
% % % fy(1).year = 2012;
% % % 
% % % fy(2).fltlist = [7161 7168:7198 7202:7241 7243:7249];
% % % fy(2).year = 2013;
% % % 
% % % fy(3).fltlist = [7200 7201 7250 7255:7263 7280:7284 7286:7379];
% % % fy(3).year = 2014;
% % % 
% % % fy(4).fltlist = [7380:7427 7298 10083:10095 10107:10116];
% % % fy(4).year = 2015;
% % % 
% % % fy(5).fltlist = [7341 7400 7430:7479 11010:11034];
% % % fy(5).year = 2016;
% % % 
% % % fy(6).fltlist = [7480:7545 11040:11059];
% % % fy(6).year = 2017;
% % % 
% % % for ify = 1:length(fy)
% % %     for itable = tabletypes
% % %         filename = sprintf('FY_%d_%d.html',fy(ify).year,itable);
% % %         mk_s2_table_page(fy(ify).fltlist,filename,itable)
% % %     end 
% % %      % etc tables
% % %     for itable = etctables
% % %        filename = sprintf('FY_%d_%d.html',fy(ify).year,itable);
% % %        mk_s2_table_page(fy(ify).fltlist,filename,itable,etcdir)
% % %    end
% % % end
% % % 
% % % %% do the sio floats
% % % % wrapper program to call mk_s2_table_page
% % % load(fullfile(ARGOMETA,'/sio_meta'))
% % % 
% % % nflts = length(sio_meta);
% % % % loop over all and extract launch date
% % % for i = 1:nflts
% % %     jday(i) = sio_meta(i).launch.jday;
% % %     year(i) = sio_meta(i).launch.year;
% % %     fltnum(i) = sio_meta(i).whoi_number;
% % % end
% % % 
% % % iss2 = fltnum >= 6000;  % 
% % % fltnum = fltnum(iss2);
% % % year  = year(iss2);
% % % jday = jday(iss2);
% % % 
% % % for iy = years;
% % %    ii = year == iy;
% % % 
% % %    fltlist = fltnum(ii);
% % %    jlist = jday(ii);
% % %    [foo,I] = sort(jlist);
% % %    fltlist = fltlist(I);
% % % 
% % %    for itable = tabletypes
% % %        filename = sprintf('sio_%d_%d.html',iy,itable);
% % %        mk_sio_table_page(fltlist,filename,itable)
% % %    end
% % %     % etc tables
% % %     for itable = etctables
% % %        filename = sprintf('sio_%d_%d.html',iy,itable);
% % %        mk_sio_table_page(fltlist,filename,itable,etcdir)
% % %    end
% % % end

%% Floats by CTD type, plotting calibration coeff zscores 
% 
% load(fullfile(ARGUSCALCO, '/ccStruct_ALACE3A')) %old floats
% load(fullfile(ARGUSCALCO, '/ccStruct_ALACE3C')) %old floats
% load(fullfile(ARGUSCALCO, '/ccStruct_V725')) %most common, current floats
% load(fullfile(ARGUSCALCO, '/ccStruct_V731')) %an anomaly, only like 3 floats
% load(fullfile(ARGUSCALCO, '/ccStruct_61V502')) %deep floats
% load(fullfile(ARGUSCALCO, '/ccStruct_61V503')) %deep floats

ctd_List = ["ALACE3A", "ALACE3C", "V725", "V731", "61V502",  "61V503"];
ctd_List_dir_name = ["SBE41_ALACE_CP_V3A", "SBE41_ALACE_CP_V3C", "SBE41CP_V725", "SBE41CP_V731", "SBE61_V502", "SBE61_V503"];
itable=1;
for i=1:length(ctd_List) %ctd_type=ctd_List %loops through ctd_List (v clever)
    ctd_List_i = ctd_List(i);
    ctd_List_dir_name_i = ctd_List_dir_name(i);
    load([ARGUSCALCO+"calib_coeffs_"+ctd_List_i])

    %sort struct by CTD serial no. (so that the floats get printed on the
    %html page in this order)
    [~, order] = sort([tempStruct.SERIALNO]);
    tempStruct = tempStruct(order);
    cc_chk = regexprep( {tempStruct.Checklog} ,"\.txt$","");
    fltlist = extractAfter(cc_chk, 3);
    fltlist = str2double(fltlist);

    for itable=tabletypes
        filename = sprintf('deployed_%s.html',ctd_List_i);
        cc_dir = fullfile(ARGUSCCWEB,ctd_List_dir_name_i);
        mk_s2_table_page_Lola(fltlist,filename,itable,cc_dir)
    end
end
