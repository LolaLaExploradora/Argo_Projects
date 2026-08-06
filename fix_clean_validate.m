
% This function takes in a wmo number and 
% a list of cyles for which there has been an error
% output/notice from the clean_validate code, and quieries the QC1 folder
% to pull the required information for fixing the levels without data but
% with QC inputs. 

% edits have to be made in QC1 directory
cd /shared/argo/dmqc/QC1

%sudo code below, fix later
cycle_list = pad(cycle_list, 3, "left", '0')

for index = cycle_list 

        R_file_name = ('R'+wmo+cycle(index)+ '.nc');
    pathname = fullfile('/shared/argo/dmqc/QC1/', wmo)
    table = profMeas_to_table( wmo, cycle(index), pathname, 'R')
    
    % we take no. of rows, this tells us how many levels to fix 
    [r,~] = size(table);
    var_select = input("what variable do you need to hcange? options: PSAL_QC etc...")
    qc_side = input("do you need to change QC[1] or QC[2] \n"...
        ..."there are three options" ) %explain "i.e. in full data or high freq data?"
    level = input("at what level does the problem start? hint: see table and look for variable mentioned in clean_validate output", "s" )
    level = str2double(level)
    
    qc_val = input("indicate if there should be a QC value assigned or if NO value should be present")
    
    var = ncread('/shared/argo/dmqc/QC1/1902329/R1902329_017.nc', var); % var == 'PSAL_QC'
    % var length == rows from table size above. 
    % but there will always be 2 columns, the first is the full cycle of data,
    % the second is the high freq data 
    % in our case usually it is the QC data we are looking to change
    
    
    
    %fix the next line of code (with switch/case?) to handle either var 1 or 2
    %depending on the input above
    var(level:end, qc_side) = qc_val; 

    %insert check here so that person doing this can make sure the vector
    %looks okay
    
    %fix ncwrite below 
    ncwrite('/shared/argo/dmqc/QC1/1902329/R1902329_017.nc', 'PSAL_QC', var)

end