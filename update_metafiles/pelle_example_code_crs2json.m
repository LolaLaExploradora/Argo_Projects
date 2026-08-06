%crs2json
% converts old archive of cruise meta data (set_s2_cruises.m) to a json
% file.  Uses meta data sin meta_sum.mat to convert from SOLO serial number
% to wmo number.  

setargo
load(fullfile(ARGOMETA,'meta_sum'))

set_s2_cruises

Ncruise = length(crsstr);

for i = 1:Ncruise
    Nflt(i) = length(crsstr(i).fltnums);
    % carry over desired fields to new structure ncruise
    ncruise(i).name = crsstr(i).name;
    ncruise(i).year = crsstr(i).year;
    for j = 1:Nflt(i)
        %look up wmo
        im = crsstr(i).fltnums(j) == [meta_sum.whoi_number];
        switch sum(im)
            case 0
                disp(['Unable to match s/n ',num2str(crsstr(i).fltnums(j))])
            case 1
                %disp(['MATCH s/n ',num2str(crsstr(i).fltnums(j))])
            ncruise(i).wmo(j) = int32(meta_sum(im).wmo_number);
            otherwise
                disp(['Multiple matches s/n ',num2str(crsstr(i).fltnums(j))])
        end
    end
end

cruise = jsonencode(ncruise,'PrettyPrint',true);

%write that string out to a json file
outfile = fullfile(ARGOMETA,'solo_cruise_meta.json');
fid = fopen(outfile,'w')
fprintf(fid,'%s',cruise);
fclose(fid)