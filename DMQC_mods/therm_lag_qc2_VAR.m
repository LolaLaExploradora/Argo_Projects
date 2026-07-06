function therm_lag_qc2_mp(wmonum)
%function therm_lag_qc2(wmonum)
% np - profile number (optional)
% dw 4/10/2018: modified to add potential for multiple profiles
% dw 2/7/2019: modified to copy/transfer secondary profile data without
% applying thermal lag

setargo

QC1 = [ARGODMQC,'/QC1/'];
QC2 = [ARGODMQC,'/QC2/'];

qc2path  = [QC2,num2str(wmonum),'/'];
qc1path  = [QC1,num2str(wmonum),'/'];

if exist(qc2path) ~=7
    disp(['Making directory: ',qc2path])
    eval(['!mkdir ',qc2path])
    eval(['!chmod g+s ',qc2path])

    eval(['!chgrp floatgroup ',qc2path])

end
%eval(['!cp ',qc1path,'/*.nc ' ,qc2path])
%eval(['!rsync -rl ',qc1path,'/*.nc ' ,qc2path]);   % to deal with samba
eval(['!rsync -pr ',qc1path,' ' ,qc2path]);   % to deal with samba


w=dir(qc2path);
% sort names because matlab doesn't understand english
tw=strvcat(w.name); 
wqc=sortrows(tw); 
nqc = length(strmatch('R',wqc(:,1)));
iqc = strmatch('R',wqc(:,1));
for ii = 1:nqc 
    flname = wqc(iqc(ii),:);
    fprintf(1, ' working on %s ', flname);
    ncfile  = deblank(fullfile(qc2path,flname));
   % apply_therm_lag_bck(ncfile)
   apply_therm_lag_mp(ncfile)
end
