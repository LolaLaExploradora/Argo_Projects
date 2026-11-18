function    QC1to2(wmonum)
% function move_qc1_qc2(wmonum,cycles)
% wmonum - World Meteorological Organization number [integer]

% Used to move files which don't need to have thermal lag applied from QC1 to
% QC2
% dew - 01/05/2022

setargo

QC1 = [ARGODMQC,'QC1/'];
QC2 = [ARGODMQC,'QC2/'];

qc2path  = [QC2,num2str(wmonum),'/'];
qc1path  = [QC1,num2str(wmonum),'/'];

if exist(qc2path) ~=7
    disp(['Making directory: ',qc2path])
    eval(['!mkdir ',qc2path])
    eval(['!chmod g+s ',qc2path])
    eval(['!chgrp floatgroup ',qc2path])
end

w = dir(qc1path);
tw = strvcat(w.name);
stw = sortrows(tw);
isf = strmatch('R',stw(:,1));
stw = stw(isf,:);

% copying file from QC1 to QC2
for i = 1:length(stw)
    flname = stw(i,:);
    disp([num2str(wmonum),'  Copying: ',flname]);
    ncfile  = deblank(fullfile(qc1path,flname));
    outfile = deblank(fullfile(qc2path,flname));

    [SUCCESS,~,~] = copyfile(ncfile,outfile,'f');
end


% QC2 R-files get PRES, PSAL, & TEMP fields copied to _ADJUSTED fields
% note that associated QC flags also copied to appropriate _ADJ fields. 
w2 = dir(qc2path);
tw2 = strvcat(w2.name);
stw2 = sortrows(tw2);
isf2 = strmatch('R',stw2(:,1));
stw2 = stw2(isf2,:);

for j= 1:length(stw2)
flname = stw2(j,:);
    ncfile  = deblank(fullfile(qc2path,flname));
    ncid= netcdf.open(ncfile, 'WRITE');

    % Look to see if there is data in PRES_ADJUSTED
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

    if padjust == 0
        % copy to profile #1 to adjusted fields, not any other profiles
        % dw - 2/7/2019 : now copies both profiles to adjusted fields
        varid=netcdf.inqVarID(ncid,'PRES');
        pres=netcdf.getVar(ncid,varid); % get all elements of pressure
        varid=netcdf.inqVarID(ncid,'PRES_ADJUSTED');
        netcdf.putVar(ncid,varid,pres);

        varid=netcdf.inqVarID(ncid,'PRES_QC');
        pres_qc=netcdf.getVar(ncid,varid);
        varid=netcdf.inqVarID(ncid,'PRES_ADJUSTED_QC');
        netcdf.putVar(ncid,varid,pres_qc);

        varid=netcdf.inqVarID(ncid,'TEMP');
        temp=netcdf.getVar(ncid,varid);
        varid=netcdf.inqVarID(ncid,'TEMP_ADJUSTED');
        netcdf.putVar(ncid,varid,single(temp));

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
        disp([ncfile,': Detected Data in PRES_ADJUSTED field, P,T,&S data not copied to _ADJUSTED fields'])
    end
netcdf.close(ncid);
end


disp('Done')
