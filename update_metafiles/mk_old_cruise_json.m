% uses metadata to create json structure of older (pre-2012) cruises 
% specifying which wmo numbers are associate with each cruise

if exist('ARGODMQC') ~=1;        setargo; end;  % set defualt paths

load([ARGOMETA,'meta_sum']);  % load in matlab structure or meta data summary
for i = 1:length(meta_sum);  % rearrange year field
    meta_sum(i).year = meta_sum(i).launch.year;  % to make things easier later
end

jname = fullfile(ARGOMETA,'argo_cruise_meta.json');
foo = fileread(jname);
cruiseA = jsondecode(foo);

%gather all the wmos already identified in cruiseA
WMO_NEW = [];
for i = 1:length(cruiseA);
    WMO_NEW = union(WMO_NEW, cruiseA{i}.wmo);
end

WMO_ALL = [meta_sum.wmo_number];   % wmo numbers from all whoi floats;
WMO_OLD = setdiff(WMO_ALL, WMO_NEW);  % list of WMO numbers not yet accounted for

% a litte processing of the meta stucture
k = 0;
for i = 1:length(meta_sum);
    % check one by one if the record is in WMO_OLD;, if so retain
    if any([meta_sum(i).wmo_number == WMO_OLD])
        k = k+1;
        meta_old(k) = meta_sum(i);
    end
end

k = 0;
for yr = 2001:2024
    imatch = [meta_old.year] == yr;
    meta_yr = meta_old(imatch);  % just the meta file records for that year
    cruise_strs = unique({meta_yr.cruise_id});
    Ncruise = length(cruise_strs);
    for icruise = 1:Ncruise
        cmatch = strmatch(cruise_strs{icruise}, {meta_yr.cruise_id});
        wmos = int32([meta_yr(cmatch).wmo_number]);
    
        % print out cruise name and associated wmos 
        fprintf(1,'%d  %s \n',yr,cruise_strs{icruise})
        for iwmo = 1:length(wmos); fprintf(1,' %d',wmos(iwmo)); end; fprintf(1,'\n');

        %setup structure to output to json
        k = k+1;
        ocruise(k).name = cruise_strs{icruise};
        ocruise(k).year = yr;
        ocruise(k).wmo = wmos;
    end
end

cruise = jsonencode(ocruise,'PrettyPrint',true);
%write that string out to a json file
outfile = fullfile(ARGOMETA,'old_cruise_meta.json');
fid = fopen(outfile,'w')
fprintf(fid,'%s',cruise);
fclose(fid)


