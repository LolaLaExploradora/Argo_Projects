function pngs = coreArgo_calib_coeff_plots(all_calibration_coeffs)
% Lola Pierson, Argo WHOI 
% Dec 2026

% =========================================================================
% This function takes in the .mat file of calibration coefficients
% found in /argus/data1/lab/SOLO_II/Checklogs/Calibration_Coeffs
% and creates PNGs that are put into /argus/data1/argo/www/calib/ for  
% printing to the argo website. 
% 
% 
% =========================================================================


%% Set Paths
ARGUSWWWCAL = 'argus/data1/argo/www/calib/';
ARGUSCHK = '/argus/data1/lab/SOLO_II/Checklogs/';
ARGUSCALCO = '/argus/data1/lab/SOLO_II/Checklogs/Calibration_Coeffs/';

load( fullfile(ARGUSCALCO, 'calibration_coeffs_V725.mat') )
load( fullfile(ARGUSCALCO, 'calibration_coeffs_V731.mat') ) %not often used
load( fullfile(ARGUSCALCO, 'calibration_coeffs_61V502.mat') ) %not often used
load( fullfile(ARGUSCALCO, 'calibration_coeffs_61V503.mat') )
load( fullfile(ARGUSCALCO, 'calibration_coeffs_ALACE3A.mat') )
load( fullfile(ARGUSCALCO, 'calibration_coeffs_ALACE3C.mat') )

%% Which float type do you want to update plots for?
var = input("For which CTD would you like to update plots? Input a single number, 1-4 corresponding to your choice \n" + ... 
    "the list is as follows: \n" + ...
    "1. SBE 41CP V7.2.5 - Core Argo floats\n" + ...
    "2. SBE 41CP V 7.3.1 - Core, but this one is anomalous. \n" +...
    "3. SBE 41 ALACE-CP V 3.0A \n" + ...
    "4. SBE 41 ALACE-CP V 3.0C \n" + ...
    "5. SBE 61 V 5.0.2 - Deep Floats, but this one is anomalous.\n" + ... 
    "6. SBE 61 V 5.0.3 - Deep Floats\n")

    switch var
        case 1 %"SBE 41CP V 7.2.5"
            tempStruct = ccStruct_V725; 
            ctdtypename = "SBE41CP_V725";
            ctdtypename_plot = "SBE 41CP V7.2.5";
        case 2 %"SBE 41CP V 7.3.1"
            tempStruct = ccStruct_V731;
            ctdtypename = "SBE41CP_V731";
            ctdtypename_plot = "SBE 41CP V7.3.1";        
        case 3 %"SBE 41 ALACE-CP V 3.0A"
            tempStruct = ccStruct_ALACE3A;
            ctdtypename = "SBE41_ALACE_CP_V3A";
            ctdtypename_plot = "SBE 41 ALACE CP V3A";        
        case 4 %"SBE 41 ALACE-CP V 3.0C"
            tempStruct = ccStruct_ALACE3C;
            ctdtypename = "SBE41_ALACE_CP_V3C";
            ctdtypename_plot = "SBE 41 ALACE CP V3C";        
        case 5 %"SBE 61 V 5.0.2"
            tempStruct = ccStruct_61V502;
            ctdtypename = "SBE61_V502";
            ctdtypename_plot = "SBE 61 V 5.0.2";
        case 6 %"SBE 61 V 5.0.3"
            tempStruct = ccStruct_61V503;
            ctdtypename = "SBE61_V503";
            ctdtypename_plot = "SBE 61 V 5.0.3";
        otherwise 
            warning('Please try again')
    end


%% Calibration Coefficient variables - housekeeping
% This poriton of code sorts the ctd SNs in sequential order (i.e.
% "sorted_ctd_sn_list"). Here we also extract a string of calibratoin
% coefficient variable names for plotting later. 

ctd_sn_list = [tempStruct.SERIALNO];
fN = fieldnames(tempStruct);
    [sorted_ctd_sn_list, sorted_ind] = sort(ctd_sn_list);
ctd_xlabel = string(ctd_sn_list(sorted_ind));
fN = fieldnames(tempStruct);
calib_vars_list = string(fN(4:end));


%% Break-out plots - details 
% Here is where we set the number of points per plot, and calculate number
% of plots. We do not always run the portion of code that prints 10 plots
% per full plot (for ease of picking out serial numbers with calib coefs 
% of interest), but when we do this portion is needed. Just leave this in
% all the time. 
pts_per_plot= 101;
n_plots= ceil(numel(ctd_sn_list)/pts_per_plot);


%% Full plots - Set colors, plot parameters and labels  
% Note that the number of colors that are plotted on each full plot should
% be the sae as the number of plots that the fUll plot gets split into. 
[rows, cols] = size(tempStruct);
n_colors=10;
colors = hsv(10); %note that points per plot == the number of points per color 
color_vec = zeros(numel(ctd_sn_list),3);
for k = 1:n_plots
    start_ind = (k-1)*pts_per_plot+1;
    end_ind = min(k*pts_per_plot,numel(ctd_sn_list));
    color_vec(start_ind:end_ind,:)= ones(numel(start_ind:end_ind),3).*colors(k,:);
end

xtick_pos = 1:pts_per_plot:(pts_per_plot*(n_plots+1)); %you need the plus one because we have an extra position taken up by the first indexing number
xtick_pos(end) = cols;
xtick_labels_full_plot = string(sorted_ctd_sn_list(xtick_pos));


%% Print Plots 
for i = 4:length(fN)
    variable2plot = [tempStruct.(fN{i})]; %all calibration coeff values in your current column
    v2p = variable2plot(sorted_ind); %the calib coeffs sorted by ctdsn number
    var_name_str = string(fN{i});
    
    % HISTOGRAMS
    fig = figure('Visible', 'on', 'Position', [195 1350 2200 450]);
    h = histogram(v2p,10);
    numBins = h.NumBins;
    xlabel(sprintf('%s Calibration Coeff value', ctdtypename_plot));
    ylabel('Count');
    title(sprintf('%s Histogram', var_name_str));
    legendText = sprintf('%d Bins', numBins);
    h.DisplayName = legendText;
    legend('show');
    fileName = sprintf('%s_fullplot_histogram.png', var_name_str);
    exportgraphics(gcf, fullfile( [ARGUSWWWCAL +ctdtypename] , fileName))

    % FULL PLOTS
    fig = figure('Visible', 'on', 'Position', [195 1350 2200 450]);
    scatter(1:numel(v2p), v2p, 20, color_vec, 'filled'); grid on;
    xlabel(sprintf('%s CTD Serial Number', ctdtypename_plot) );
    ylabel('Calibration Coefficient value');
    title(sprintf('%s Plot', var_name_str))
    xticks(xtick_pos)
    xticklabels(xtick_labels_full_plot);
        % Optional: rotate for readability
        xtickangle(45);
    fileName = sprintf('%s_fullplot.png', var_name_str);
    exportgraphics(gcf, fullfile( [ARGUSWWWCAL + ctdtypename] , fileName))
    
    % BREAK-OUT PLOTS
    for j = 1:n_plots
        ind_start = (j-1)*pts_per_plot+1;
        ind_end = min(j*pts_per_plot, numel(ctd_sn_list));

        seg_xvals = sorted_ctd_sn_list(ind_start:ind_end);
        seg_yvals = v2p(ind_start:ind_end);

        fig = figure('Visible', 'on', 'Position', [195 1350 2200 450])
        scatter(1:numel(seg_xvals), seg_yvals, 'o', 'filled'); grid on
        xlabel(sprintf('%s CTD Serial number', ctdtypename_plot));
        ylabel('calibration coefficient value');
        title(sprintf('%s Plot %d of %d, Serial numbers %d-%d', var_name_str, j, n_plots, seg_xvals(1), seg_xvals(end)))
        xticks(1:numel(seg_xvals))
        xticklabels(string(seg_xvals))
        xtickangle(45)

        fileName = sprintf('%s_plot_part%d.png', var_name_str, j);
        exportgraphics(gcf, fullfile( [ARGUSWWWCAL + ctdtypename], fileName))
    end
end 

