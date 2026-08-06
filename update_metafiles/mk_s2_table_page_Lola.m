function mk_s2_table_page(fltlist,HTML_FILENAME, tabletype,destdir)
%mk_s2_table_page(fltlist,HTML_FILENAME, tabletype,destdir)

% makes table of plots for list of floats

%fltlist = 7300:7320;
%HTML_FILENAME = 'test_2017.html';
setargo
ARGUSCCWEB = '/argus/data1/argo/www/calib';
%ACCWEBNO = '/argus/data1/argo/www/calib/SBE61_V503';

%HTML_DIR = fullfile(S2WWW,'tables');
HTML_DIR = destdir;

HTML_BASE = 'http://argo.whoi.edu/';
load(fullfile(ARGOMETA,'/meta_sum'))  % we're going to need this

switch tabletype
    case 1
        plot_names = {'Cond', 'Temp', 'Pres', 'N2'}; %maybe re-write code to have POFFSET as its own plot?
        table_name = ['Calibration Coefficient Z scores'];
end

%open file and generate header
html_file = fullfile(HTML_DIR,HTML_FILENAME);
html_title = ['WHOI ARGO Float Summaries: ',strtok(HTML_FILENAME,'.')];
fid = fopen(html_file,'w');
fprintf(fid,'<html>\n<head>\n<title>%s</title>\n</head>\n',html_title);
fprintf(fid,'<body>');
fprintf(fid,'<h2>%s</h2>',html_title);

%start the table
fprintf(fid,'<table border="1" cellpadding="6">\n');
fprintf(fid,'<caption><h2>%s</h2></caption>\n',table_name);
% table Header
fprintf(fid,'<thead>\n');
fprintf(fid,'<tr>\n');
fprintf(fid,'<th>  Info </th>\n');  % first column is always info
for i = 1:length(plot_names) %for you Lola its 'cond' 'temp' 'pres' 'n2'
    fprintf(fid,'<th>  %s </th>\n',char(plot_names(i)));
end
fprintf(fid,'</tr>\n');
fprintf(fid,'</thead>\n');

nflts = length(fltlist);

jcount = 0;  % counter

for iflt = 1:nflts
   fltnum = fltlist(iflt);
   % match in metafile
   ii = [meta_sum.whoi_number] == fltnum;
   %% SOME FLOATS ARE LISTED TWICE IN THE META_SUM 
   % consider putting in a fail safe here so that you proceed if the float
   % has an IMEI number, but not otherwise. 
   if sum(ii) == 1  % add a line to the table
       jcount = jcount+1;
       wmo = meta_sum(ii).wmo_number;
       % left colmun contains some info
       % by doing ../../ we end up in the argus/data1/www directory
       pagelink = sprintf('<a href="../../solo2/%d/index.html">%d</a>',fltnum,fltnum);
       fprintf(fid,'<tr><td align="center"> %s<br>',pagelink);   %info cell
       fprintf(fid, '%d<br>', wmo);
       fprintf(fid, 'CTD SN: %d<br>', str2double(meta_sum(ii).sensor.temp_sn));
       if strcmp(meta_sum(ii).customisation,'n/a')
           fprintf(fid,'%s<br>', 'large piston');
       else
           fprintf(fid,'%s<br>', meta_sum(ii).customisation);
       end
       
       fprintf(fid,'%s<br><br>', meta_sum(ii).rom);

       fprintf(fid,'Deployed: <br>');
       fprintf(fid,'%5d-%2.2d-%2.2d<br>', meta_sum(ii).launch.year,meta_sum(ii).launch.month,meta_sum(ii).launch.day);
       fprintf(fid,'%s<br>',meta_sum(ii).deployment_platform);
       fprintf(fid,'%s<br>',meta_sum(ii).cruise_id);
       fprintf(fid,'</td>');

       for i = 1:length(plot_names)  % loop over plot names
       switch i
           case {1,2,3}
               % set up link
               plotlink = sprintf('%d/%d_%s.png', fltnum, fltnum ,char(plot_names(i))); 
               %LOLA THE ABOVE LINE OUTLINES HOW YOU SHOULD RENAME/STRUCTURE
               %YOUR PRINTED OUT FILES
               fprintf(fid,'<td align="center">  <a href="%s"><img src="%s" width="300" height="200"></a></td>\n',plotlink,plotlink);
           case 4
               plotlink = sprintf('../../sbedrift_wmo/aoml/%s_%d.jpg',char(plot_names(i)), meta_sum(ii).wmo_number); 
               %the above link should be going to 
               % /argus/data1/argo/www/sbedrift_wmo/aoml/[PNG FILE NAME HERE.png]
               fprintf(fid,'<td align="center">  <a href="%s"><img src="%s" width="300" height="200"></a></td>\n',plotlink,plotlink);
       end
       end
       fprintf(fid,'</tr>\n'); %/tr closes the row (each element is a td)
   else
       disp(['Unable to find meta info for float ',num2str(fltnum)])
   end
end


% add totals to bottom row
fprintf(fid,'<tr><th> %i</th>',jcount);
for i = 1:length(plot_names)  % loop over plot names
    fprintf(fid,'<th> - </th>');
end
fprintf(fid,'</tr>\n');

%close the table
fprintf(fid,'</table><br><COLGROUP><COL><COL align="char" char=",">\n');
fprintf(fid,'<a href="http://argo.whoi.edu">WHOI Argo Homepage</a>\n');
fprintf(fid,'Creation Date: %s<br>\n',date);
fprintf(fid,'</body>');
fprintf(fid,'</html>');
fclose(fid);
