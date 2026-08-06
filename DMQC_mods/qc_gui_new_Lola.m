function varargout = qc_gui_new_Lola(varargin)
    % qc_gui M-file for qc_gui.fig
    % varargout = qc_gui(config)
    %
    % Config.inpath  - inpath for data profiles
    %   Data should be in indivuadual profiles
    % Config.outpath - outpath for data profiles
    
    %
    % Config.HISTORY_INSTITUTION - Institution [Default='    ']
    %
    % Climatology [Optional]
    %
    % Config.CLIFile  - name of the climatological file [Default= No climatology]
    %	if the climatological filed is provided, it should have:
    %       lat (J), lon(I), pre(K)
    %       sal (I,J,K), tem(I,J,K)
    %       name
    % Config.CLIBorder  - size of the box for the climatology, in degrees [Default=10]
    %
    % Extrem values for axes [Optional]
    % Config.maxP  - Maximum pressure    [Default=automatic]
    % Config.maxT  - Maximum temperature [Default=automatic]
    % Config.minT  - Minimun temperature [Default=automatic]
    % Config.maxS  - Maximum salinity    [Default=automatic]
    % Config.minS  - Minimum salinity    [Default=automatic]
    %
    % Config.QCms  - Markersize for que QC plots [Default=5]
    % Config.POSBorder - Size of the box for the climatology, in degrees [Default=10]
    
    
    %      qc_gui, by itself, creates a new qc_gui or raises the existing
    %      singleton*.
    %
    %      H = qc_gui returns the handle to a new qc_gui or the handle to
    %      the existing singleton*.
    %
    %      qc_gui('CALLBACK',hObject,eventData,handles,...) calls the local
    %      function named CALLBACK in qc_gui.M with the given input arguments.
    %
    %      qc_gui('Property','Value',...) creates a new qc_gui or
    %      raises the
    %      existing singleton*.  Starting from the left, property value pairs are
    %      applied to the GUI before qc_gui_OpeningFcn gets called.
    %      An
    %      unrecognized property name or invalid value makes property application
    %      stop.  All inputs are passed to qc_gui_OpeningFcn via varargin.
    %
    %      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only
    %      one
    %      instance to run (singleton)".
    %
    % See also: GUIDE, GUIDATA, GUIHANDLES
    
    % Edit the above text to modify the response to help qc_gui
    
    % Last Modified by GUIDE v2.5 15-Jun-2021 16:28:03
    
    % Begin initialization code - DO NOT EDIT
    gui_Singleton = 1;
    gui_State = struct('gui_Name', mfilename, ...
        'gui_Singleton',  gui_Singleton, ...
        'gui_OpeningFcn', @qc_gui_OpeningFcn, ...
        'gui_OutputFcn',  @qc_gui_OutputFcn, ...
        'gui_LayoutFcn',  [] , ...
        'gui_Callback',   []);
    if nargin && ischar(varargin{1})
        gui_State.gui_Callback = str2func(varargin{1});
    end
    
    if nargout
        [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
    else
        gui_mainfcn(gui_State, varargin{:});
    end
    % End initialization code - DO NOT EDIT
    
    % --- Executes just before qc_gui is made visible.
function qc_gui_OpeningFcn(hObject, eventdata, handles, varargin)
    % This function has no output args, see OutputFcn.
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    % varargin   command line arguments to qc_gui (see VARARGIN)
    Config=varargin{1};
    
    warning off MATLAB:legend:IgnoringExtraEntries
    flt = feval(Config.read_func,Config.inpath,Config.np);  % load data into flt structure
    %flt = feval(Config.read_func,Config.inpath);  % load data into flt structure    
    %    flt = rd_flt_gdac(Config.inpath);

    flt(1).write_func = Config.write_func;
    for i = 1:length(flt)
        flt(i).current = 0;
        flt(i).editted = 0;
    end
    flt(1).np = Config.np;
   
    %Add some data to the flt structure that will be used later
    if isfield(Config,'HISTORY_INSTITUTION')
        flt(1).HISTORY_INSTITUTION=Config.HISTORY_INSTITUTION;
    else
        flt(1).HISTORY_INSTITUTION='    ';
    end
    
    %Extrem values for axes
    if isfield(Config,'maxP')
        flt(1).maxP=Config.maxP;
    end
    if isfield(Config,'maxT')
        flt(1).maxT=Config.maxT;
    end
    if isfield(Config,'minT')
        flt(1).minT=Config.minT;
    end
    if isfield(Config,'maxS')
        flt(1).maxS=Config.maxS;
    end
    if isfield(Config,'minS')
        flt(1).minS=Config.minS;
    end
    if isfield(Config,'minO')
        flt(1).minO=Config.minO;
    end
     if isfield(Config,'maxO')
        flt(1).maxO=Config.maxO;
     end
    
     if (isfield(Config,'hist_ctd_dir'))
         flt(1).hist_ctd_dir = Config.hist_ctd_dir;
         flt(1).hist_ctd_wmo = Config.hist_ctd_wmo;
         
         flt(1).hist_argo_dir = Config.hist_argo_dir;
         flt(1).hist_argo_wmo = Config.hist_argo_wmo;

     end
    
    %Markers size for the QC Flags
    if isfield(Config,'QCms')
        flt(1).QCms=Config.QCms;
    else
        flt(1).QCms=3;
    end
    
    %Border size for the position plots
    if isfield(Config,'POSBorder')
        flt(1).POSBorder=Config.POSBorder;
    else
        flt(1).POSBorder=10;
    end
    
    %Paths
    flt(1).inpath = Config.inpath;
    flt(1).outpath = Config.outpath;
    
    if isfield(Config,'logfile')
        diary( Config.logfile)
        disp(['Logging QC edits to logfile:',Config.logfile,'  ',date])
        flt(1).logfile = Config.logfile;
    end
    
    % looking for adjusted pressure values
     if sum(~isnan(flt(1).pres_adjusted))
         set(handles.adjusted_menu,'ForegroundColor','red')
     end
        

    
    %Argo reference julian day
    flt(1).jref= 2433283;  %argo reference julian day
    
    %load the climatology field.
    if isfield(Config,'CLIFile')
        if exist(Config.CLIFile,'file')
            Cli=load(Config.CLIFile);
            lat = [flt.lat];
            lon = [flt.lon];
            maxlon = max(lon);    minlon = min(lon);
            maxlat = max(lat);    minlat = min(lat);
            if isfield(Config,'CLIBorder')
                flt(1).CLIBorder=Config.CLIBorder;
            else
                flt(1).CLIBorder=10;
            end
            minlat=minlat-flt(1).CLIBorder;
            maxlat=maxlat+flt(1).CLIBorder;
            minlon=minlon-flt(1).CLIBorder;
            maxlon=maxlon+flt(1).CLIBorder;
            if minlat <-90  ;minlat = -90;end
            if maxlat > 90  ;maxlat = 90;end
            if minlon <-180 ;minlon = -180;end
            if maxlon > 180 ;maxlon = 180;end
            I=find(Cli.lon>minlon & Cli.lon<maxlon);
            J=find(Cli.lat>minlat & Cli.lat<maxlat);
            if isfield(flt(1),'maxP')
                K=find(Cli.pre>0 & Cli.pre<(flt(1).maxP+50));
            else
                K=find(Cli.pre>0 & Cli.pre<2050);
            end
            if isempty(I)==0 && isempty(J)==0 && isempty(K)==0
                flt(1).CLIis=1;
                flt(1).CLIlat=Cli.lat(J);
                flt(1).CLIlon=Cli.lon(I);
                flt(1).CLIpre=Cli.pre(K);
                flt(1).CLIsal=Cli.sal(I,J,K);
                flt(1).CLItem=Cli.tem(I,J,K);
                flt(1).CLIname=Cli.name;
            end
            
        end
    end
    % Choose default command line output for qc_gui
    handles.output = hObject;
    
    % Update handles structure
    guidata(hObject, handles);
    
    % Save float data and configurations in mydata
    setappdata(handles.figure1,'mydata',flt);
    
     %counter to keep track of current profile
    %first_profile = min([flt.cycle_number])
    first_profile = flt(1).cycle_number;
    set(handles.text3,'string',num2str(first_profile))
    
    
    %counter to keep track of current pressure bin
    set(handles.text4,'string',num2str(1))
    
    % This sets up the initial plot - only do when we are invisible
    % so window can get raised using qc_gui.
    if strcmp(get(hObject,'Visible'),'off')
        gui_plot_ts(hObject, eventdata, handles,4)
        gui_plot_flags(hObject,eventdata,handles,5,'temp')
    end
    
    date1 = gregorian(flt(1).jref+flt(1).juld);
    date2 = gregorian(flt(1).jref+flt(end).juld);
    
    set(handles.text2,'string',[sprintf('Float: %d ',str2num(flt(1).wmo_num)), char(10),...
        sprintf('# of Profiles: %d',length(flt)),char(10),...
        sprintf('Dates: %d-%d-%d to %d-%d-%d',date1(1:3),date2(1:3)),char(10),...
        sprintf('Path: %s',flt(1).inpath)],'fontsize',13)
    
   
    % plot the first profile in the main axes
    gui_plot_profile(hObject, eventdata, handles,1)
    
    %plot trajectory in axes 2
    gui_plot_pos(hObject, eventdata, handles,2,0)
    
    %Add extra menus to the plot popup
    Spopupmenu=get(handles.popupmenu7,'string');
    Spopupmenu(8)={'Temperature Section'};
    Spopupmenu(9)={'Salinity Section'};
    if isfield(flt(1),'CLIis')
        if  flt(1).CLIis==1
            Spopupmenu(10)={'T-S Climatology'};
        end
    end
    if isfield(flt(1),'doxy')
        Spopupmenu(11)={'Oxygen Section'};     
    end
    
    set(handles.popupmenu7,'string',Spopupmenu);
    
    if isfield(flt(1),'doxy')
            set(handles.axes1_menu,'string',{'Temperature', 'Salinity','Oxygen'});
    end
    
    if isfield(Config,'windowOption')
        switch Config.windowOption
            case 'Deb'
                hObject.Position = [4.71 25.56 197.29 50];
            case 'Sachiko'
                hObject.Position = [13.1429 1.9375 164.1429 45.4375];
            case 'Lola'
                hObject.Position = [4.71 25.56 197.29 50];
        end
    end
    % UIWAIT makes qc_gui wait for user response (see UIRESUME)
    % uiwait(handles.figure1);
    
    % --- Outputs from this function are returned to the command line.
function varargout = qc_gui_OutputFcn(hObject, eventdata, handles)
    % varargout  cell array for returning output args (see VARARGOUT);
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Get default command line output from handles structure
    varargout{1} = handles.output;
    % --- Executes on button press in quit_no_save.
function quit_no_save_Callback(hObject, eventdata, handles)
    % hObject    handle to quit_no_save (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % quit the GUI
    flt = getappdata(handles.figure1,'mydata');
    unsaved_changes = any([flt.editted]);
    if unsaved_changes
        user_response = quitsave('Title','Unsaved Edits');
  
        switch user_response
            case 'Save'
                if ~strcmp(flt(1).inpath,flt(1).outpath)
                    eval(['!cp ',flt(1).inpath,'/* ',flt(1).outpath])
                end
                disp(['Backing up current changes to files in ',flt(1).outpath])
                %wrt_flt_gdac(flt);
                
                flt = feval(flt(1).write_func,flt);
        end
    end
    
    
    
    disp(['Quitting QC editor ',date])
    if isfield(flt,'logfile')
        disp(['Closing QC edit logfile: ',flt(1).logfile])
        diary off
    end
    delete(handles.figure1)
    
    
    % --------------------------------------------------------------------
function FileMenu_Callback(hObject, eventdata, handles)
    % hObject    handle to FileMenu (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    
    % --------------------------------------------------------------------
function OpenMenuItem_Callback(hObject, eventdata, handles)
    % hObject    handle to OpenMenuItem (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    file = uigetfile('*.fig');
    if ~isequal(file, 0)
        open(file);
    end
    
    % --------------------------------------------------------------------
function PrintMenuItem_Callback(hObject, eventdata, handles)
    % hObject    handle to PrintMenuItem (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    printdlg(handles.figure1)
    
    % --------------------------------------------------------------------
function CloseMenuItem_Callback(hObject, eventdata, handles)
    % hObject    handle to CloseMenuItem (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    selection = questdlg(['Close ' get(handles.figure1,'Name') '?'],...
        ['Close ' get(handles.figure1,'Name') '...'],...
        'Yes','No','Yes');
    if strcmp(selection,'No')
        return;
    end
    if isfield(flt,'logfile')
        disp(['Closing QC edit logfile: ',flt(1).logfile])
        diary off
    end
    delete(handles.figure1)
    
    
    % --- Executes on selection change in axes1_menu.
function axes1_menu_Callback(hObject, eventdata, handles)
    % hObject    handle to axes1_menu (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Hints: contents = get(hObject,'String') returns axes1_menu contents as cell array
    %        contents{get(hObject,'Value')} returns selected item from axes1_menu
    
    %zoom out
    flt = getappdata(handles.figure1,'mydata');
    if isfield(flt,'xlim')
        flt = rmfield(flt,'xlim');
        flt = rmfield(flt,'ylim');
        setappdata(handles.figure1,'mydata',flt);
    end
    
    popup_sel_index = get(handles.axes1_menu, 'Value');
    switch popup_sel_index
        case 1
            %            gui_plot_temperature(hObject, eventdata, handles,4)
            gui_plot_flags(hObject, eventdata, handles,5,'temp')
        case 2
            %            gui_plot_salt(hObject, eventdata, handles,4)
            gui_plot_flags(hObject, eventdata, handles,5,'psal')
        case 3
            %            gui_plot_doxy(hObject, eventdata, handles,4)
            gui_plot_flags(hObject, eventdata, handles,5,'doxy')
    end
    gui_plot_ts(hObject, eventdata, handles,4)
    gui_plot_profile(hObject, eventdata, handles,1)
    
    
    % --- Executes during object creation, after setting all properties.
function axes1_menu_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to axes1_menu (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called
    
    % Hint: popupmenu controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    set(hObject, 'String', {'Temperature', 'Salinity'});

    
function edit1_Callback(hObject, eventdata, handles)
    % hObject    handle to edit1 (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Hints: get(hObject,'String') returns contents of edit1 as text
    %        str2double(get(hObject,'String')) returns contents of edit1 as a double
    
    
    % --- Executes during object creation, after setting all properties.
function edit1_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to edit1 (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called
    
    % Hint: edit controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    
    
    %--- function to plot cascade salt profiles
function gui_plot_salt(hObject, eventdata, handles,axs)
    eval(['axes(handles.axes',num2str(axs),');'])
    cla reset;
    flt = getappdata(handles.figure1,'mydata');

    popup_sel_index = get(handles.adjusted_menu, 'Value');
    switch popup_sel_index
        case 1
            prop = 'psal';
        case 2
            prop = 'psal_adjusted';
    end
    
    mean_salt = nanmean([getfield(flt,prop)]);
    current_profile = str2num(get(handles.text3,'string'));
    ii = find([flt.cycle_number] == current_profile);
    for i = 1:length(flt)
        if i == ii
            %     plot((flt(i).psal-mean_salt)*10+flt(i).cycle_number,flt(i).pres,'b-')
            hsalt(i) = plot((getfield(flt,{i},prop)-mean_salt)*10+flt(i).cycle_number,flt(i).pres,'b-');
        elseif i == ii-1 | (ii == 1 & i ==2)
            %       plot((flt(i).psal-mean_salt)*10+flt(i).cycle_number,flt(i).pres,'m-')
            hsalt(i) = plot((getfield(flt,{i},prop)-mean_salt)*10+flt(i).cycle_number,flt(i).pres,'m-');
        else
            %        plot((flt(i).psal-mean_salt)*10+flt(i).cycle_number,flt(i).pres,'c-')
            hsalt(i) = plot((getfield(flt,{i},prop)-mean_salt)*10+flt(i).cycle_number,flt(i).pres,'c-');         
        end
        hold on
    end
    if isfield(flt(1),'maxP')
        M1=nanmax(flt(ii).pres);if M1>flt(1).maxP;M1=flt(1).maxP;end
        set(gca,'ylim',[0 M1])
    end
    
    set(gca,'ydir','rev')
    set(gca,'fontsize',10)
    hold off
    
    if axs == 4
        for i = 1:length(flt)
            set(hsalt(i),'hittest','off');
        end
%        set(handles.axes4,'ButtonDownFcn', @(hObject,eventdata)qc_gui('axes4_ButtonDownFcn',hObject,eventdata,guidata(hObject)))
        set(handles.axes4,'ButtonDownFcn', @(hObject,eventdata)qc_gui_new_Lola('axes4_ButtonDownFcn',hObject,eventdata,guidata(hObject)))
    end
        %--- function to plot cascade oxygen profiles
function gui_plot_doxy(hObject, eventdata, handles,axs)
    eval(['axes(handles.axes',num2str(axs),');'])
    cla reset;
    flt = getappdata(handles.figure1,'mydata');
    
    popup_sel_index = get(handles.adjusted_menu, 'Value');
    switch popup_sel_index
        case 1
            prop = 'doxy';
        case 2
            prop = 'doxy_adjusted';
    end
    
    mean_doxy = nanmean([getfield(flt,prop)]);
    
    current_profile = str2num(get(handles.text3,'string'));
    ii = find([flt.cycle_number] == current_profile);
    for i = 1:length(flt)
        if i == ii
            hsalt(i) = plot((getfield(flt,{i},prop)-mean_doxy)*.1+flt(i).cycle_number,flt(i).pres,'b-');
        elseif i == ii-1 | (ii == 1 & i ==2)
            hsalt(i) = plot((getfield(flt,{i},prop)-mean_doxy)*.1+flt(i).cycle_number,flt(i).pres,'m-');
        else
            hsalt(i) = plot((getfield(flt,{i},prop)-mean_doxy)*.1+flt(i).cycle_number,flt(i).pres,'c-');
            
        end
        hold on
    end
    if isfield(flt(1),'maxP')
        M1=nanmax(flt(ii).pres);if M1>flt(1).maxP;M1=flt(1).maxP;end
        set(gca,'ylim',[0 M1])
    end
    
    set(gca,'ydir','rev')
    set(gca,'fontsize',10)
    hold off
    
    if axs == 4
        for i = 1:length(flt)
            set(hsalt(i),'hittest','off');
        end
%        set(handles.axes4,'ButtonDownFcn', @(hObject,eventdata)qc_gui('axes4_ButtonDownFcn',hObject,eventdata,guidata(hObject)))
        set(handles.axes4,'ButtonDownFcn', @(hObject,eventdata)qc_gui_new_Lola('axes4_ButtonDownFcn',hObject,eventdata,guidata(hObject)))
    end

    %--- function to plot cascade temperature profiles
function gui_plot_temperature(hObject, eventdata, handles,axs)
    %axes(handles.axes1);
    eval(['axes(handles.axes',num2str(axs),');'])
    cla reset;
    flt = getappdata(handles.figure1,'mydata');
    popup_sel_index = get(handles.adjusted_menu, 'Value');
    switch popup_sel_index
        case 1
            prop = 'temp';
        case 2
            prop = 'temp_adjusted';
    end
    
    current_profile = str2num(get(handles.text3,'string'));
    ii = find([flt.cycle_number] == current_profile);
    for i = 1:length(flt)
        if i == ii
            %     plot(flt(i).temp+flt(i).cycle_number,flt(i).pres,'b-')
            htemp(i) =  plot(getfield(flt,{i},prop)+flt(i).cycle_number,flt(i).pres,'b-','linewidth',2);
        elseif i == ii-1 | (ii == 1 & i ==2)
            % plot(flt(i).temp+flt(i).cycle_number,flt(i).pres,'m-')
            htemp(i) = plot(getfield(flt,{i},prop)+flt(i).cycle_number,flt(i).pres,'m-');
        else
            %    plot(flt(i).temp+flt(i).cycle_number,flt(i).pres,'c-')
            htemp(i) = plot(getfield(flt,{i},prop)+flt(i).cycle_number,flt(i).pres,'c-');
        end
        hold on
    end
    hold off
    
    if isfield(flt(1),'maxP')
        M1=nanmax(flt(i).pres);
        if M1>flt(1).maxP || M1==0 ||isnan(M1)==1;M1=flt(1).maxP;end
        set(gca,'ylim',[0 M1])
    end
    set(gca,'ydir','rev')
    set(gca,'fontsize',10)
    if axs == 4
        for i = 1:length(flt)
            set(htemp(i),'hittest','off');
        end
%        set(handles.axes4,'ButtonDownFcn', @(hObject,eventdata)qc_gui('axes4_ButtonDownFcn',hObject,eventdata,guidata(hObject)))
        set(handles.axes4,'ButtonDownFcn', @(hObject,eventdata)qc_gui_new_Lola('axes4_ButtonDownFcn',hObject,eventdata,guidata(hObject)))
    end
    
    %--- function to plot sections
function gui_plot_section(hObject, eventdata, handles,axs,prop,refresh)
    eval(['axes(handles.axes',num2str(axs),');'])
    flt = getappdata(handles.figure1,'mydata');
    
    propY='pres';
    current_profile = str2num(get(handles.text3,'string'));
    ii = find([flt.cycle_number] == current_profile);
    
    if refresh==0
        cla reset;
        Z=double(getfield(flt,{1},prop)');
        Y=double(getfield(flt,{1},propY)');
        X=flt(1).cycle_number*ones(1,size(flt(1).pres,2))';
        for i = 2:length(flt)
            Zt=double(getfield(flt,{i},prop));
            iQC = (getfield(flt(ii),[prop,'_qc']) == '4');Zt(iQC)=NaN;
            iQC = (getfield(flt(ii),[prop,'_qc']) == '3');Zt(iQC)=NaN;
            iQC = (getfield(flt(ii),[prop,'_qc']) == '2');Zt(iQC)=NaN;
            iQC = (getfield(flt(ii),[prop,'_qc']) == '0');Zt(iQC)=NaN;
            iQC = (getfield(flt(ii),[prop,'_qc']) == '9');Zt(iQC)=NaN;

            Z=merge(Z,Zt');
            Yt=double(flt(i).pres);
            iQC = (getfield(flt(ii),[propY,'_qc']) == '4');Yt(iQC)=NaN;
            iQC = (getfield(flt(ii),[propY,'_qc']) == '3');Yt(iQC)=NaN;
            iQC = (getfield(flt(ii),[propY,'_qc']) == '2');Yt(iQC)=NaN;
            iQC = (getfield(flt(ii),[propY,'_qc']) == '0');Yt(iQC)=NaN;
            iQC = (getfield(flt(ii),[propY,'_qc']) == '9');Yt(iQC)=NaN;

            Y=merge(Y,Yt');
            X=merge(X,flt(i).cycle_number*ones(1,size(flt(i).pres,2))');
        end
        flt(1).X=X;
        flt(1).Y=Y;
        switch prop
            %if  strncmp(prop,'temp',4);
            case {'temp'}
                MZ=round(nanmax(Z(:)));
                if isfield(flt(1),'maxT')
                    if MZ>flt(1).maxT;M1=flt(1).maxT;end
                end
                mZ=round(nanmin(Z(:)));
                if isfield(flt(1),'minT')
                    if mZ<flt(1).minT;mZ=flt(1).minT;end
                end
                dZ=1;
                % elseif strncmp(prop,'psal',4);
            case {'psal'}
                MZ=round(nanmax(Z(:))*10)/10;
                if isfield(flt(1),'maxS')
                    if MZ>flt(1).maxS;MZ=flt(1).maxS;end
                end
                mZ=round(nanmin(Z(:))*10)/10;
                if isfield(flt(1),'minS')
                    if mZ<flt(1).minS;mZ=flt(1).minS;end
                end
                dZ=0.1;
            case {'doxy'}
                %elseif strncmp(prop,'doxy',4);
                MZ=round(nanmax(Z(:))*10)/10;
                if isfield(flt(1),'maxO')
                    if MZ>flt(1).maxO;MZ=flt(1).maxO;end
                end
                mZ=round(nanmin(Z(:))*10)/10;
                if isfield(flt(1),'minO')
                    if mZ<flt(1).minO;mZ=flt(1).minO;end
                end
                dZ=0.1;
        end
        

        pcolor(X,Y,Z);hold on;shading interp;
        caxis([mZ MZ])
         % PANTONE BLUE 299-1: 100%  75%  50%  25%   % WOCE ATLAS COLORMAP
        blue=[1,146,191; 65,171,206; 127,198,222; 191,226,238]/256;
        % PANTONE RED 97-1: 100%  75%  50%  25%
        red =  [251,0,38; 250,66,75; 250,128,124; 252,192,184]/256;
        %PANTONE ORANGE 32-1: 100%  75%  50%  25%
        orange=[255,158,15; 254,182,64; 254,207,122; 254,231,186]/256;
        tmap = [blue; flipud(red)];        
        smap = [blue; flipud(orange)];
        switch prop
            case {'temp'}
                colormap(tmap);
            case {'psal'}
                colormap(smap);
        end
        contour(X,Y,Z,[mZ:dZ:MZ],'k')
        [c,h]=contour(X,Y,Z,[mZ:2*dZ:MZ],'k');
        clabel(c,h,'fontsize',07,'color','k','rotation',0,'background','w')
        if isfield(flt(1),'maxP')
            MY=nanmax(Y(:));
            if MY>flt(1).maxP || MY==0 ;MY=flt(1).maxP;end
            set(gca,'ylim',[0 MY])
        end
        
        set(gca,'ydir','rev')
        set(gca,'fontsize',10)
        
        handles.hLineContour=plot(flt(1).X(:,ii),flt(1).Y(:,ii),'y','linewidth',2);
        guidata(hObject, handles);
        setappdata(handles.figure1,'mydata',flt);
    else
        if ishandle(handles.hLineContour)
            delete(handles.hLineContour)
        end
        handles.hLineContour=plot(flt(1).X(:,ii),flt(1).Y(:,ii),'y','linewidth',2);
        guidata(hObject, handles);
    end
    
    %--- function to plot T-S
function gui_plot_ts(hObject, eventdata, handles,axs)
    %axes(handles.axes1);
    eval(['axes(handles.axes',num2str(axs),');'])
    cla reset;
    flt = getappdata(handles.figure1,'mydata');

    popup_sel_index = get(handles.adjusted_menu, 'Value');
    switch popup_sel_index
        case 1
            prop1 = 'temp';
            prop1_qc = 'temp_qc';
            prop2 = 'psal';
            prop2_qc = 'psal_qc';
        case 2
            prop1 = 'temp_adjusted';
            prop1_qc = 'temp_qc_adjusted';
            prop2 = 'psal_adjusted';
            prop2_qc = 'psal_adjusted_qc';
    end
    
    current_profile = str2num(get(handles.text3,'string'));
    ii = find([flt.cycle_number] == current_profile);
   
    hts = 0*ones(length(flt),1);
    for i = 1:length(flt)
        i1 = getfield(flt(i),['temp_qc']) == '1' & getfield(flt(i),[prop2_qc]) == '1';
        if any(i1)
            if i == ii-1 | (ii == 1 & i ==2)
                hts(i) = plot(getfield(flt,{i},prop2,{i1}),getfield(flt,{i},prop1,{i1}),'m-');
            else
                hts(i) = plot(getfield(flt,{i},prop2,{i1}),getfield(flt,{i},prop1,{i1}),'c-');
            end
            hold on
        end
    end
    if ii == 1
        i1 = getfield(flt(2),['temp_qc']) == '1' & getfield(flt(2),[prop2_qc]) == '1';
        plot(getfield(flt,{2},prop2,{i1}),getfield(flt,{2},prop1,{i1}),'m-')
    else
        i1 =  getfield(flt(ii-1),['temp_qc']) == '1' & getfield(flt(ii-1),[prop2_qc]) == '1';
        %plot(getfield(flt,{ii-1},prop2),getfield(flt,{ii-1},prop1),'m-')
        plot(getfield(flt,{ii-1},prop2,{i1}),getfield(flt,{ii-1},prop1,{i1}),'m-')

    end
    i1 =  getfield(flt(ii),['temp_qc']) == '1' & getfield(flt(ii),[prop2_qc]) == '1';

    plot(getfield(flt,{ii},prop2,{i1}),getfield(flt,{ii},prop1,{i1}),'b.-','linewidth',2)
    
    if isfield(flt(1),'maxT') && isfield(flt(1),'minT')
        M1=nanmax(getfield(flt,{ii},prop1));if M1>flt(1).maxT;M1=flt(1).maxT;end
        m1=nanmin(getfield(flt,{ii},prop1));if m1<flt(1).minT;m1=flt(1).minT;end
        set(gca,'ylim',[m1 M1])
    end
    if isfield(flt(1),'maxS') && isfield(flt(1),'minS')
        M2=nanmax(getfield(flt,{ii},prop2));if M2>flt(1).maxS;M2=flt(1).maxS;end
        m2=nanmin(getfield(flt,{ii},prop2));if m2<flt(1).minS;m2=flt(1).minS;end
        set(gca,'xlim',[m2 M2])
    end  
    grid on
    hold off
    set(gca,'fontsize',10)
    if axs == 4
        for i = 1:length(flt)
            if (hts(i) ~= 0)
                set(hts(i),'hittest','off');
            end
        end
%        set(handles.axes4,'ButtonDownFcn', @(hObject,eventdata)qc_gui('axes4_ButtonDownFcn',hObject,eventdata,guidata(hObject)))
        set(handles.axes4,'ButtonDownFcn', @(hObject,eventdata)qc_gui_new_Lola('axes4_ButtonDownFcn',hObject,eventdata,guidata(hObject)))
    end
    
    %--- function to plot T-S together with the Climatology
function gui_plot_ts_climatology(hObject, eventdata, handles,axs)
    eval(['axes(handles.axes',num2str(axs),');'])
    cla reset;
    flt = getappdata(handles.figure1,'mydata');
  
    popup_sel_index = get(handles.adjusted_menu, 'Value');
    switch popup_sel_index
        case 1
            prop1 = 'temp';
            prop2 = 'psal';
        case 2
            prop1 = 'temp_adjusted';
            prop2 = 'psal_adjusted';
    end
    
    current_profile = str2num(get(handles.text3,'string'));
    ii = find([flt.cycle_number] == current_profile);
    maxlon = max(flt(ii).lon);    minlon = min(flt(ii).lon);
    maxlat = max(flt(ii).lat);    minlat = min(flt(ii).lat);
    minlat=minlat-flt(1).CLIBorder;
    maxlat=maxlat+flt(1).CLIBorder;
    minlon=minlon-flt(1).CLIBorder;
    maxlon=maxlon+flt(1).CLIBorder;
    if minlat < -90 ; minlat = -90;end
    if maxlat > 90 ; maxlat = 90;end
    if minlon < -180 ; minlon = -180;end
    if maxlon > 180 ; maxlon = 180;end
    
    I=find(flt(1).CLIlon>minlon & flt(1).CLIlon<maxlon);
    J=find(flt(1).CLIlat>minlat & flt(1).CLIlat<maxlat);
    if isfield(flt(1),'maxP');
        MP=nanmax(flt(ii).pres);if (MP>flt(1).maxP | MP==0 | isnan(MP)==0);MP=flt(1).maxP;end
        K=find(flt(1).CLIpre>0 & flt(1).CLIpre<(MP+50));
    else
        MP=nanmax(flt(ii).pres);
        K=find(flt(1).CLIpre>0 & flt(1).CLIpre<(MP+50));
    end
    if isempty(I)==0 && isempty(J)==0 && isempty(K)==0
        CLIsal=flt(1).CLIsal(I,J,K);
        CLItem=flt(1).CLItem(I,J,K);
        plot(CLIsal(:),CLItem(:),'o','markersize',4,'markeredge',[0.65 0.65 0.65],'markerfacecolor',[0.65 0.65 0.65]);hold on
        plot(getfield(flt,{ii},prop2),getfield(flt,{ii},prop1),'b.-','linewidth',2)
        if ii>1
            i=ii-1;plot(getfield(flt,{i},prop2),getfield(flt,{i},prop1),'m-')
        end
        if ii<length(flt)
            i=ii+1;plot(getfield(flt,{i},prop2),getfield(flt,{i},prop1),'m-')
        end
        %Find axis limits automatically
        if isfield(flt(1),'maxT') && isfield(flt(1),'minT')
            M1=nanmax(getfield(flt,{ii},prop1));if M1>flt(1).maxT;M1=flt(1).maxT;end
            m1=nanmin(getfield(flt,{ii},prop1));if m1<flt(1).minT;m1=flt(1).minT;end
            set(gca,'ylim',[m1 M1])
        end
        if isfield(flt(1),'maxS') && isfield(flt(1),'minS')
            M2=nanmax(getfield(flt,{ii},prop2));if M2>flt(1).maxS;M2=flt(1).maxS;end
            m2=nanmin(getfield(flt,{ii},prop2));if m2<flt(1).minS;m2=flt(1).minS;end
            set(gca,'xlim',[m2 M2])
        end
        
        grid on
        hold off
        set(gca,'fontsize',10)
    end
    
    %--- function to plot  profiles
function gui_plot_profile(hObject, eventdata, handles,axs)
    eval(['axes(handles.axes',num2str(axs),');'])
    %set(gca,'Nextplot','Replacechildren')
    cla reset;
    flt = getappdata(handles.figure1,'mydata');
    
    popup_sel_index = get(handles.axes1_menu, 'Value');
    
    switch popup_sel_index
        case 1
            prop = 'temp';
        case 2
            prop = 'psal';
        case 3
            prop = 'doxy';
    end
    
    popup_sel_adj = get(handles.adjusted_menu, 'Value');
    switch popup_sel_adj
        case 1
          %do nothing
        case 2
          prop = [prop,'_adjusted'];             
    end
    
    
    current_profile = str2num(get(handles.text3,'string'));
    ii = find([flt.cycle_number] == current_profile);
    if ii > 1
        nbr = ii-1;
    else
        nbr = 2;
    end
    
    current_bin = str2num(get(handles.text4,'string'));
    
    i0 = getfield(flt(ii),[prop,'_qc']) == '0';
    i1 = getfield(flt(ii),[prop,'_qc']) == '1';
    i2 = getfield(flt(ii),[prop,'_qc']) == '2';
    i3 = getfield(flt(ii),[prop,'_qc']) == '3';
    i4 = getfield(flt(ii),[prop,'_qc']) == '4';
    % 8/13/2021 dew - adding code to plot only qc = '1' or '2' for previous profiles
    i1nbr = (getfield(flt(nbr),[prop,'_qc']) == '1') | (getfield(flt(nbr),[prop,'_qc']) == '2');
    
%    h3 = plot(getfield(flt(nbr),prop),flt(nbr).pres,'m-');hold on  % neighboring profile
    h3 = plot(getfield(flt(nbr),prop,{i1nbr}),flt(nbr).pres(i1nbr),'m-');hold on  % neighboring profile
    h1a = plot(getfield(flt(ii),prop,{i4}),flt(ii).pres(i4),'rx','markersize',5);
    h2a = plot(getfield(flt(ii),prop,{i2}),flt(ii).pres(i2),'x','markersize',5,'color',[1 .5 0]);
    h3a = plot(getfield(flt(ii),prop,{i3}),flt(ii).pres(i3),'x','markersize',5,'color',[1 .4 .1]);
    h0 = plot(getfield(flt(ii),prop,{i0}),flt(ii).pres(i0),'x','markersize',5,'color',[.4 .4 .4]);

    h1 = plot(getfield(flt(ii),prop,{i1}),flt(ii).pres(i1),'b.-','linewidth',2); %Actual profile
    h2 = plot(getfield(flt(ii),prop,{current_bin}),flt(ii).pres(current_bin),'k','marker','o','markersize',8,'markerfacecolor','c');
    
    %plot profile of other variable
    xlim = get(gca,'xlim');
    switch popup_sel_index
        case 1
            if isfield(flt(1),'minT') && isfield(flt(1),'maxT')
                M2=nanmax(getfield(flt(ii),prop,{i1}));if (M2>flt(1).maxT || M2==0 || isnan(M2)==0);M2=flt(1).maxT;end
                m2=nanmin(getfield(flt(ii),prop,{i1}));if m2<flt(1).minT || m2==0 || isnan(m2)==0;m2=flt(1).minT;end
                set(gca,'xlim',[m2 M2])
            end
        case 2
            if isfield(flt(1),'minS') && isfield(flt(1),'maxS')
                M2=nanmax(getfield(flt(ii),prop,{i1}));if M2>flt(1).maxS || M2==0 || isnan(M2)==0;M2=flt(1).maxS;end
                m2=nanmin(getfield(flt(ii),prop,{i1}));if m2<flt(1).minS || m2==0 || isnan(m2)==0;m2=flt(1).minS;end
                set(gca,'xlim',[m2 M2])
            end
        case 3
    end
    
    switch popup_sel_index
        case 1
            otherprop = 'psal';
        case 2
            otherprop = 'temp';
        case 3
            otherprop = 'doxy';
    end
    switch popup_sel_adj
        case 1
            %do nothing
        case 2
            otherprop = [otherprop,'_adjusted'];
    end
    switch popup_sel_adj
        case 1
            tqc = 'temp_qc';
            sqc = 'psal_qc';
        case 2
            tqc = 'temp_adjusted_qc';
            sqc = 'psal_adjusted_qc';
    end
    
    
    % plot other property
        h4 = []; h5 = [];  % initialize in case no good data

    
    i1 = getfield(flt(ii),[otherprop,'_qc']) == '1';
    oprop_data =getfield(flt(ii),otherprop,{i1});
    if ~isempty(oprop_data)
        h4 = add_plot(oprop_data,flt(ii).pres(i1),'g-',2);
    end
    
    % if seawater routines are available, plot density
    if exist('sw_pden') == 2
        i1 = getfield(flt(ii),['pres_qc']) == '1' & getfield(flt(ii),[tqc]) == '1' & getfield(flt(ii),[sqc]) == '1';
% 8/13/2021 dew - density of bad data
%        ibad = ismember(getfield(flt(ii),['pres_qc']),['3','4']) | ismember(getfield(flt(ii),[tqc]),['3','4']) | ismember(getfield(flt(ii),[sqc]),['3','4']);

        switch popup_sel_adj
            case 1
                f_pres =getfield(flt(ii),'pres',{i1});
                f_psal =getfield(flt(ii),'psal',{i1});
                f_temp = getfield(flt(ii),'temp',{i1});
                fa_pres = getfield(flt(ii),'pres');
                fa_psal = getfield(flt(ii),'psal');
                fa_temp = getfield(flt(ii),'temp');
            case 2
                f_pres =getfield(flt(ii),'pres_adjusted',{i1});
                f_psal =getfield(flt(ii),'psal_adjusted',{i1});
                f_temp = getfield(flt(ii),'temp_adjusted',{i1});
                fa_pres = getfield(flt(ii),'pres_adjusted');
                fa_psal = getfield(flt(ii),'psal_adjusted');
                fa_temp = getfield(flt(ii),'temp_adjusted');
        end

        % 5/10/2024 DEW - started using sigma-1 instead of sigma-0
%         f_dens = sw_pden(f_psal,f_temp,f_pres,0);
%         fa_dens = sw_pden(fa_psal,fa_temp,fa_pres,0);
         f_dens = sw_pden(f_psal,f_temp,f_pres,1000);
         fa_dens = sw_pden(fa_psal,fa_temp,fa_pres,1000);

       
        % 8/16/2021 dew - plot all of the density
        if any(~isnan(fa_dens))
            % add 0.03 kg/m^3 potential density error line
            densa_low = fa_dens-0.03;
             keepX.min = min([densa_low fliplr(fa_dens)]);
             keepX.max = max([densa_low fliplr(fa_dens)]);
            h6 =  add_plot([densa_low fliplr(fa_dens)],[fa_pres fliplr(fa_pres)],'c.-',1,keepX);
        end
        
        if any(~isnan(f_dens)) 
            % add 0.03 kg/m^3 potential density error line
            dens_low = f_dens-0.03;
            h5 =  add_plot([dens_low fliplr(f_dens)],[f_pres fliplr(f_pres)],'k-',1,keepX);
%            dens_low = f_dens(1:end-1)-0.03;
%            dens_pres = f_pres(2:end);
            % add sigma-1 line
%            h7 = add_plot(fliplr(f1_dens),[fliplr(f_pres)],'r-');
        end

      
    end
    %add legend
%     if exist('sw_pden') == 2
%         legend([h1 h4 h5 h3], prop,otherprop,'density','neighbor','location','best');
%     else
%         legend([h1 h4 h3],prop,otherprop,'neighbor','location','best');
%     end
% handlestring = '[';
% 
% if ~isempty(h1)
%     handlestring = [handlestring,'h1 '];
%     legendstring = ', prop';
% end
% if ~isempty(h4)
%     handlestring = [handlestring, 'h4 '];
%     legendstring = [legendstring,', otherprop'];
% end
% if ~isempty(h5)
%     handlestring = [handlestring, 'h5 '];
%     legenstring = [legendstring,', ''density'''];
% end
% if ~isempty(h3)
%     handlestring = [handlestring, 'h3'];
%     legendstring = [legendstring,' ,''neighbor'''];
% end
% handlestring = strcat(handlestring,']');
% if ~strcmp(handlestring,'[]')
%     legendstring = ['legend(',handlestring,legendstring,',''location'',''best'');']
%     eval(legendstring)
% end

    uistack(h1,'top');
    uistack(h2,'top');

    set(h0,'hittest','off');
    set(h1,'hittest','off');
    set(h2,'hittest','off');
    set(h3,'hittest','off');
    set(h1a,'hittest','off');
    set(h2a,'hittest','off');
    set(h3a,'hittest','off');
    set(h4,'hittest','off');
    set(h5,'hittest','off');

    if isfield(flt(1),'maxP')
        M1=nanmax(flt(ii).pres);if (M1>flt(1).maxP | M1==0 | isnan(M1)==0);M1=flt(1).maxP;end
        set(gca,'ylim',[0 M1])
    end
    
    set(gca,'ydir','rev')
    set(gca,'fontsize',10)
    grid
    
    %Display info about this profile/bin
    dd = gregorian(flt(ii).juld + flt(1).jref);
    popup_sel_adj = get(handles.adjusted_menu, 'Value');
    switch popup_sel_adj
        case 1
            if isfield(flt(1),'doxy')
                set(handles.text5,'string',[sprintf('Cycle #: %d, Bin #: %d',current_profile, current_bin),char(10),...
                    sprintf('Lat: %6.3f, Lon: %7.3f',flt(ii).lat,flt(ii).lon),char(10),...
                    sprintf('Date: %4d-%2d-%2d',dd(1:3)),char(10),...
                    sprintf('P: %7.1f    %c',flt(ii).pres(current_bin),flt(ii).pres_qc(current_bin)),char(10),...
                    sprintf('T: %7.2f    %c',flt(ii).temp(current_bin),flt(ii).temp_qc(current_bin)),char(10),...
                    sprintf('S: %7.2f    %c',flt(ii).psal(current_bin),flt(ii).psal_qc(current_bin)),char(10),...
                    sprintf('O2: %6.2f    %c',flt(ii).doxy(current_bin),flt(ii).doxy_qc(current_bin)),char(10),...
                    ],'fontsize',11)
                
            else
                set(handles.text5,'string',[sprintf('Cycle #: %d, Bin #: %d',current_profile, current_bin),char(10),...
                    sprintf('Lat: %6.3f, Lon: %7.3f',flt(ii).lat,flt(ii).lon),char(10),...
                    sprintf('Date: %4d-%2d-%2d',dd(1:3)),char(10),...
                    sprintf('P: %7.1f    %c',flt(ii).pres(current_bin),flt(ii).pres_qc(current_bin)),char(10),...
                    sprintf('T: %7.2f    %c',flt(ii).temp(current_bin),flt(ii).temp_qc(current_bin)),char(10),...
                    sprintf('S: %7.2f    %c',flt(ii).psal(current_bin),flt(ii).psal_qc(current_bin)),char(10),...
                    ],'fontsize',11)
            end
            
        case 2
            if isfield(flt(1),'doxy')
                set(handles.text5,'string',[sprintf('Cycle #: %d, Bin #: %d',current_profile, current_bin),char(10),...
                    sprintf('Lat: %6.3f, Lon: %7.3f',flt(ii).lat,flt(ii).lon),char(10),...
                    sprintf('Date: %4d-%2d-%2d',dd(1:3)),char(10),...
                    sprintf('P: %7.1f    %c',flt(ii).pres_adjusted(current_bin),flt(ii).pres_adjusted_qc(current_bin)),char(10),...
                    sprintf('T: %7.2f    %c',flt(ii).temp_adjusted(current_bin),flt(ii).temp_adjusted_qc(current_bin)),char(10),...
                    sprintf('S: %7.2f    %c',flt(ii).psal_adjusted(current_bin),flt(ii).psal_adjusted_qc(current_bin)),char(10),...
                    sprintf('O2: %6.2f    %c',flt(ii).doxy_adjusted(current_bin),flt(ii).doxy_adjusted_qc(current_bin)),char(10),...
                    ],'fontsize',11)
                
            else
                set(handles.text5,'string',[sprintf('Cycle #: %d, Bin #: %d',current_profile, current_bin),char(10),...
                    sprintf('Lat: %6.3f, Lon: %7.3f',flt(ii).lat,flt(ii).lon),char(10),...
                    sprintf('Date: %4d-%2d-%2d',dd(1:3)),char(10),...
                    sprintf('P: %7.1f    %c',flt(ii).pres_adjusted(current_bin),flt(ii).pres_adjusted_qc(current_bin)),char(10),...
                    sprintf('T: %7.2f    %c',flt(ii).temp_adjusted(current_bin),flt(ii).temp_adjusted_qc(current_bin)),char(10),...
                    sprintf('S: %7.2f    %c',flt(ii).psal_adjusted(current_bin),flt(ii).psal_adjusted_qc(current_bin)),char(10),...
                    ],'fontsize',11)
            end
            
    end
    
    
    
    if isfield(flt(1),'xlim')
        %disp('trying to retain zoom')
        set(gca,'xlim',flt(1).xlim);
        set(gca,'ylim',flt(1).ylim);
    end
    %set(handles.axes1,'ButtonDownFcn', @axes1_ButtonDownFcn);
    %set(handles.axes1,'ButtonDownFcn', {@axes1_ButtonDownFcn, hObject, eventdata, handles});
%    set(handles.axes1,'ButtonDownFcn', @(hObject,eventdata)qc_gui('axes1_ButtonDownFcn',hObject,eventdata,guidata(hObject)))
%    set(handles.axes2,'ButtonDownFcn', @(hObject,eventdata)qc_gui('axes2_ButtonDownFcn',hObject,eventdata,guidata(hObject)))
%    set(handles.axes5,'ButtonDownFcn', @(hObject,eventdata)qc_gui('axes5_ButtonDownFcn',hObject,eventdata,guidata(hObject)))
    set(handles.axes1,'ButtonDownFcn', @(hObject,eventdata)qc_gui_new_Lola('axes1_ButtonDownFcn',hObject,eventdata,guidata(hObject)))
    set(handles.axes2,'ButtonDownFcn', @(hObject,eventdata)qc_gui_new_Lola('axes2_ButtonDownFcn',hObject,eventdata,guidata(hObject)))
    set(handles.axes5,'ButtonDownFcn', @(hObject,eventdata)qc_gui_new_Lola('axes5_ButtonDownFcn',hObject,eventdata,guidata(hObject)))

    hold off
    
    
function gui_plot_flags(hObject, eventdata, handles,axs,prop)
    %function gui_plot_flags(hObject, eventdata, handles,axs,prop)
    %   axs:  axes number to plot in
    %  prop:  either 'pres','temp','psal',...
    eval(['axes(handles.axes',num2str(axs),');'])
    cla reset;
    flt = getappdata(handles.figure1,'mydata');
    
    popup_sel_index = get(handles.adjusted_menu, 'Value');
    switch popup_sel_index
        case 1
            %do nothing
        case 2
            prop = [prop,'_adjusted'];
    end
    
    fldname = [prop,'_qc'];
     
    if isfield(flt,fldname)
        ncy = length(flt);
        for i = 1:ncy
            qc = getfield(flt(i),fldname);
            type = flt(i).type;
            pres = flt(i).pres;
            f0 = findstr('0',qc);
            f1 = findstr('1',qc);
            f2 = findstr('2',qc);
            f3 = findstr('3',qc);
            f4 = findstr('4',qc);
            f9 = findstr('9',qc);
            if strmatch(type,'R')
                if any(f0)
                    hrf0 = plot(flt(i).cycle_number*ones(1,length(f0)),pres(f0),'.','color',[.4 .4 .4],'markersize',flt(1).QCms);
                    set(hrf0,'hittest','off');
                    hold on
                end
                if any(f1)
                    hrf1 = plot(flt(i).cycle_number*ones(1,length(f1)),pres(f1),'.','color',[0 .6 0],'markersize',flt(1).QCms);
                    set(hrf1,'hittest','off');
                    hold on
                end
                if any(f2)
                    hrf2 = plot(flt(i).cycle_number*ones(1,length(f2)),pres(f2),'.','color',[.6 .6 0],'markersize',flt(1).QCms);
                    set(hrf2,'hittest','off');
                    hold on
                end
                if any(f3)
                    hrf3 = plot(flt(i).cycle_number*ones(1,length(f3)),pres(f3),'.','color',[.6 .6 0],'markersize',flt(1).QCms);
                    set(hrf3,'hittest','off');
                    hold on
                end
                if any(f4)
                    hrf4 = plot(flt(i).cycle_number*ones(1,length(f4)),pres(f4),'.','color',[.6 0 0],'markersize',flt(1).QCms);
                    set(hrf4,'hittest','off');
                    hold on
                end
                if any(f9)
                    hrf9 = plot(flt(i).cycle_number*ones(1,length(f9)),pres(f9),'.','color',[.6 0 .6],'markersize',flt(1).QCms);
                    set(hrf9,'hittest','off');
                    hold on
                end
            else
                if any(f0)
                    hdf0 = plot(flt(i).cycle_number*ones(1,length(f0)),pres(f0),'.','color',[.6 .6 .6],'markersize',flt(1).QCms);
                    set(hdf0,'hittest','off');
                    hold on
                end
                if any(f1)
                    hdf1 = plot(flt(i).cycle_number*ones(1,length(f1)),pres(f1),'g.','markersize',flt(1).QCms);
                    set(hdf1,'hittest','off');
                    hold on
                end
                if any(f2)
                    hdf2 = plot(flt(i).cycle_number*ones(1,length(f2)),pres(f2),'y.','markersize',flt(1).QCms);
                    set(hdf2,'hittest','off');
                    hold on
                end
                if any(f3)
                    hdf3 = plot(flt(i).cycle_number*ones(1,length(f3)),pres(f3),'y.','markersize',flt(1).QCms);
                    set(hdf3,'hittest','off');
                    hold on
                end
                if any(f4)
                    hdf4 = plot(flt(i).cycle_number*ones(1,length(f4)),pres(f4),'r.','markersize',flt(1).QCms);
                    set(hdf4,'hittest','off');
                    hold on
                end
                if any(f9)
                    hdf9 = plot(flt(i).cycle_number*ones(1,length(f9)),pres(f9),'m.','markersize',flt(1).QCms);
                    set(hdf9,'hittest','off');
                    hold on
                end
            end
            maxp = max(get(gca,'ylim'));
            %plot indicator if profile flags have been altered.
            if flt(i).editted == 1;
                plot(flt(i).cycle_number, -30,'rx')
                set(gca,'ylim',[-80 maxp]);
            end
        end
        hold off
        if isfield(flt(1),'maxP')
            maxP=nanmax(flt(i).pres);if maxP>flt(1).maxP || maxP==0 || isnan(maxP)==1;maxP=flt(1).maxP;end
            if flt(i).editted == 1;
                set(gca,'ylim',[-80 maxP]);
            else
                set(gca,'ylim',[0 maxP])
            end
        end
        set(gca,'ydir','rev');
        set(gca,'xlim',[ min([flt.cycle_number])-1  max([flt.cycle_number])+1])
    else
        disp(['Unable to match field name ', prop])
    end
    
    if axs == 5
%        set(handles.axes5,'ButtonDownFcn', @(hObject,eventdata)qc_gui('axes5_ButtonDownFcn',hObject,eventdata,guidata(hObject)))
        set(handles.axes5,'ButtonDownFcn', @(hObject,eventdata)qc_gui_new_Lola('axes5_ButtonDownFcn',hObject,eventdata,guidata(hObject)))
    end
    
function gui_plot_pos(hObject, eventdata, handles,axs,refresh)
    % function to plot profile positions
    eval(['axes(handles.axes',num2str(axs),');'])
    flt = getappdata(handles.figure1,'mydata');
    if refresh==0
        cla reset;
        lat = [flt.lat];
        lon = [flt.lon];
        
        bad = lon > 360 | lon < -360 | lat > 90 | lat < -90;
        lon = lon(~bad); lat = lat(~bad);
        
        current_profile = str2num(get(handles.text3,'string'));
        ii = find([flt.cycle_number] == current_profile);
        maxlon = max(lon);    minlon = min(lon);
        maxlat = max(lat);    minlat = min(lat);
        
        if minlat-flt(1).POSBorder < -90 ; minlat = -90+flt(1).POSBorder;end
        if maxlat+flt(1).POSBorder > 90 ; maxlat = 90-flt(1).POSBorder;end
        if minlon-flt(1).POSBorder < -180 ; minlon = -180+flt(1).POSBorder;end
        if maxlon-flt(1).POSBorder > 180 ; maxlon = 180-flt(1).POSBorder;end
        
        m_proj('mollweid','long',[minlon-flt(1).POSBorder maxlon+flt(1).POSBorder],'lat',[minlat-flt(1).POSBorder maxlat+flt(1).POSBorder])
        m_coast('patch',[.8 .9 .8]);
        m_grid('fontsize',10);hold on
        m_plot(lon,lat,'c.','markersize',6)
        m_plot(lon(1),lat(1),'g*','markersize',3)
        m_plot(lon(end),lat(end),'r*','markersize',3)
        handles.hActualPosition=m_plot(lon(ii),lat(ii),'bo','markerfacecolor','b','markersize',5);
        guidata(hObject,handles);
    else
        if ishandle(handles.hActualPosition)
            delete(handles.hActualPosition)
        end
        lat = [flt.lat];
        lon = [flt.lon];
        current_profile = str2num(get(handles.text3,'string'));
        ii = find([flt.cycle_number] == current_profile);
        handles.hActualPosition=m_plot(lon(ii),lat(ii),'bo','markerfacecolor','b','markersize',5);
        guidata(hObject, handles);
    end
    
    % --- Executes on button press in button_previous.
function button_previous_Callback(hObject, eventdata, handles)
    % hObject    handle to button_previous (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    current_profile = str2num(get(handles.text3,'string'));
    flt = getappdata(handles.figure1,'mydata');
    ii = find([flt.cycle_number] == current_profile);
    if ii > 1
        newprofile = flt(ii-1).cycle_number;
    else
        newprofile = current_profile;
    end
    set(handles.text3,'string',num2str(newprofile),'fontsize',11)
    
    % check if new profile is shallower then previous current_bin
    i2 = find([flt.cycle_number] == newprofile);
    current_bin = str2num(get(handles.text4,'string'));
    if current_bin > length(flt(i2).pres)
        set(handles.text4,'string',num2str(length(flt(i2).pres)),'fontsize',11)
    end
    
    gui_plot_profile(hObject, eventdata, handles,1)
    gui_plot_ts(hObject, eventdata, handles,4)
    
    popup_sel_index = get(handles.axes1_menu, 'Value');
    switch popup_sel_index
        case 1
            gui_plot_flags(hObject, eventdata, handles,5,'temp')
        case 2
            gui_plot_flags(hObject, eventdata, handles,5,'psal')
        case 3
            gui_plot_flags(hObject, eventdata, handles,5,'doxy')
    end
    
    popup_sel_2 = get(handles.popupmenu7, 'Value');
    switch popup_sel_2
        case 1
            gui_plot_pos(hObject, eventdata, handles,2,1)
        case 2
            gui_plot_ts(hObject, eventdata, handles,2)
        case 3
            gui_plot_temperature(hObject, eventdata, handles,2)
        case 4
            gui_plot_salt(hObject, eventdata, handles,2)
        case 8
            gui_plot_section(hObject, eventdata, handles,2,'temp',1)
        case 9
            gui_plot_section(hObject, eventdata, handles,2,'psal',1)
        case 10
            gui_plot_ts_climatology(hObject, eventdata, handles,2)
        case 11
            gui_plot_section(hObject, eventdata, handles,2,'doxy',1)
    end
    
    % --- Executes on button press in button_next.
function button_next_Callback(hObject, eventdata, handles)
    % hObject    handle to button_next (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % advance profile counter by one and replot.
    current_profile = str2num(get(handles.text3,'string'));
    flt = getappdata(handles.figure1,'mydata');
    ii = find([flt.cycle_number] == current_profile);
    if ii < length(flt)
        newprofile = flt(ii+1).cycle_number;
    else
        newprofile = current_profile;
    end
    set(handles.text3,'string',num2str(newprofile));
    
    
    % check if new profile is shallower then previous current_bin
    i2 = find([flt.cycle_number] == newprofile);
    current_bin = str2num(get(handles.text4,'string'));
    if current_bin > length(flt(i2).pres)
        set(handles.text4,'string',num2str(length(flt(i2).pres)),'fontsize',11)
    end

    
    gui_plot_profile(hObject, eventdata, handles,1)
    gui_plot_ts(hObject, eventdata, handles,4)
    popup_sel_index = get(handles.axes1_menu, 'Value');
    switch popup_sel_index
        case 1
            gui_plot_flags(hObject, eventdata, handles,5,'temp')
        case 2
            gui_plot_flags(hObject, eventdata, handles,5,'psal')
        case 3
            gui_plot_flags(hObject, eventdata, handles,5,'doxy')
    end
    
    popup_sel_2 = get(handles.popupmenu7, 'Value');
    switch popup_sel_2
        case 1
            gui_plot_pos(hObject, eventdata, handles,2,1)
        case 2
            gui_plot_ts(hObject, eventdata, handles,2)
        case 3
            gui_plot_temperature(hObject, eventdata, handles,2)
        case 4
            gui_plot_salt(hObject, eventdata, handles,2)
        case 8
            gui_plot_section(hObject, eventdata, handles,2,'temp',1)
        case 9
            gui_plot_section(hObject, eventdata, handles,2,'psal',1)
        case 10
            gui_plot_ts_climatology(hObject, eventdata, handles,2)
        case 11
            gui_plot_section(hObject, eventdata, handles,2,'doxy',1)
    end
    
    
    
    % --- Executes on mouse press over axes background.
function axes1_ButtonDownFcn(hObject, eventdata, handles)
    % hObject    handle to axes1 (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    xy1 = get(handles.axes1,'Currentpoint');
    x1 = xy1(1,1);
    y1 = xy1(1,2);
    
    %grab current limits of graph, we will re-use them if the graph is
    %zoomed
    xlim = get(handles.axes1,'xlim');
    ylim =  get(handles.axes1,'ylim');
    
    %match to closest point on current profile
    current_profile = str2num(get(handles.text3,'string'));
    flt = getappdata(handles.figure1,'mydata');
    ii = find([flt.cycle_number] == current_profile);
    pp = flt(ii).pres;
    popup_sel_index = get(handles.axes1_menu, 'Value');
    switch popup_sel_index
        case 1
            zz = flt(ii).temp;
        case 2
            zz = flt(ii).psal;
        case 3
            zz = flt(ii).doxy;
    end
    %scale by current axes dimensions
    YL= diff(get(handles.axes1,'ylim'));
    XL= diff(get(handles.axes1,'xlim'));
    dd = (x1 - zz).^2/XL + (y1-pp).^2/YL;
    id = find(dd == min(dd));
    new_bin = id;
    set(handles.text4,'string',num2str(new_bin))
    
    flt(1).xlim = [xlim];
    flt(1).ylim = [ylim];
    
    setappdata(handles.figure1,'mydata',flt);
    gui_plot_profile(hObject, eventdata, handles,1)
    
    % --- Executes on mouse press over axes background.
function axes2_ButtonDownFcn(hObject, eventdata, handles)
    % hObject    handle to axes2 (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
   fprintf('clicky \n')
    xy1 = round(get(handles.axes2,'Currentpoint'));
    
    x1 = xy1(1,1);
    y1 = xy1(1,2);
    plot(x1,y1,'m+'); hold on
    %fprintf('Apbt: [x,y] = [%d,%d] \n',x1,y1);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % --- Executes on mouse press over axes background.
function axes4_ButtonDownFcn(hObject, eventdata, handles)
    % hObject    handle to axes2 (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    xy1 = get(handles.axes4,'Currentpoint');
    x1 = xy1(1,1);
    y1 = xy1(1,2);
    %fprintf('Apbt: [x,y] = [%d,%d] \n',x1,y1);
    flt = getappdata(handles.figure1,'mydata');

    xx = []; yy = [];ii = [];
    
    for i = 1:length(flt)
        i1 = getfield(flt(i),['temp_qc']) == '1' & getfield(flt(i),['psal_qc']) == '1';
        % xx = [xx ; [getfield(flt,{i},'psal'{i1})]'];
        % yy = [yy ; [getfield(flt,{i},'temp'{i1})]'];
        xx = [xx ; [flt(i).psal(i1)]'];
        yy = [yy ; [flt(i).temp(i1)]'];
        ii = [ii; [flt(i).psal(i1)*0+flt(i).cycle_number]'];
    end
    
    %
    %scale by current axes dimensions
    YL= diff(get(handles.axes1,'ylim'));
    XL= diff(get(handles.axes1,'xlim'));
    dd = (x1 - xx).^2/XL + (y1-yy).^2/YL;
    id = find(dd == min(dd));
    id = id(1);  % take first element if multiple matches
    
    newprofile = ii(id);
    set(handles.text3,'string',num2str(newprofile))
    % replot things
    gui_plot_profile(hObject, eventdata, handles,1)
    gui_plot_ts(hObject, eventdata, handles,4)
    popup_sel_index = get(handles.axes1_menu, 'Value');
    switch popup_sel_index
        case 1
            gui_plot_flags(hObject, eventdata, handles,5,'temp')
        case 2
            gui_plot_flags(hObject, eventdata, handles,5,'psal')
        case 3
            gui_plot_flags(hObject, eventdata, handles,5,'doxy')
    end
    
    popup_sel_2 = get(handles.popupmenu7, 'Value');
    switch popup_sel_2
        case 1
            gui_plot_pos(hObject, eventdata, handles,2,1)
        case 2
            gui_plot_ts(hObject, eventdata, handles,2)
        case 3
            gui_plot_temperature(hObject, eventdata, handles,2)
        case 4
            gui_plot_salt(hObject, eventdata, handles,2)
        case 8
            gui_plot_section(hObject, eventdata, handles,2,'temp',1)
        case 9
            gui_plot_section(hObject, eventdata, handles,2,'psal',1)
        case 10
            gui_plot_ts_climatology(hObject, eventdata, handles,2)
        case 11
            gui_plot_section(hObject, eventdata, handles,2,'doxy',1)
    end
    
    
    % --- Executes on mouse press over axes background.
function axes5_ButtonDownFcn(hObject, eventdata, handles)
    % hObject    handle to axes1 (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    xy1 = get(handles.axes5,'Currentpoint');
    x1 = xy1(1,1);
    y1 = xy1(1,2);
    flt = getappdata(handles.figure1,'mydata');
    newprofile = round(x1);

    i2 = find([flt.cycle_number] == newprofile);
    if isempty(i2)
        %find the closest done
        i2 = find(abs([flt.cycle_number] - newprofile) == min(abs([flt.cycle_number] - newprofile)));
        newprofile = flt(i2).cycle_number;
    end
    set(handles.text3,'string',num2str(newprofile));

    
    new_pres = round(y1);
    pres  = flt(i2).pres;
    
    %find closest bin in pressure space
    new_bin = find(abs(pres-new_pres) == min(abs(pres-new_pres)));
    set(handles.text4,'string',num2str(new_bin));

    % replot things
    
    gui_plot_profile(hObject, eventdata, handles,1)
    gui_plot_ts(hObject, eventdata, handles,4)
    popup_sel_index = get(handles.axes1_menu, 'Value');
    switch popup_sel_index
        case 1
            gui_plot_flags(hObject, eventdata, handles,5,'temp')
        case 2
            gui_plot_flags(hObject, eventdata, handles,5,'psal')
        case 3
            gui_plot_flags(hObject, eventdata, handles,5,'doxy')
    end
    
    popup_sel_2 = get(handles.popupmenu7, 'Value');
    switch popup_sel_2
        case 1
             gui_plot_pos(hObject, eventdata, handles,2,1)
        case 2
            gui_plot_ts(hObject, eventdata, handles,2)
        case 3
            gui_plot_temperature(hObject, eventdata, handles,2)
        case 4
            gui_plot_salt(hObject, eventdata, handles,2)
        case 8
            gui_plot_section(hObject, eventdata, handles,2,'temp',1)
        case 9
            gui_plot_section(hObject, eventdata, handles,2,'psal',1)
        case 10
            gui_plot_ts_climatology(hObject, eventdata, handles,2)
        case 11
            gui_plot_section(hObject, eventdata, handles,2,'doxy',1)
    end
   
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % --- Executes on key release with focus on figure1 and none of its controls.
function figure1_KeyReleaseFcn(hObject, eventdata, handles)
    % hObject    handle to figure1 (see GCBO)
    % eventdata  structure with the following fields (see FIGURE)
    %	Key: name of the key that was released, in lower case
    %	Character: character interpretation of the key(s) that was released
    %	Modifier: name(s) of the modifier key(s) (i.e., control, shift) released
    % handles    structure with handles and user data (see GUIDATA)
    
    %disp([eventdata.Character ' ' eventdata.Key])
    switch eventdata.Key
        case 'rightarrow'
            current_profile = str2num(get(handles.text3,'string'));
            flt = getappdata(handles.figure1,'mydata');
            ii = find([flt.cycle_number] == current_profile);
            if ii < length(flt)
                newprofile = flt(ii+1).cycle_number;
            else
                newprofile = current_profile;
            end
            set(handles.text3,'string',num2str(newprofile))
            
            % check if new profile is shallower then previous current_bin
            i2 = find([flt.cycle_number] == newprofile);
            current_bin = str2num(get(handles.text4,'string'));
            if current_bin > length(flt(i2).pres)
                set(handles.text4,'string',num2str(length(flt(i2).pres)))
            end
            
            gui_plot_profile(hObject, eventdata, handles,1)
            gui_plot_ts(hObject, eventdata, handles,4)
            popup_sel_index = get(handles.axes1_menu, 'Value');
            switch popup_sel_index
                case 1
                    gui_plot_flags(hObject, eventdata, handles,5,'temp')
                case 2
                    gui_plot_flags(hObject, eventdata, handles,5,'psal')
                case 3
                    gui_plot_flags(hObject, eventdata, handles,5,'doxy')
            end
            
            
            popup_sel_2 = get(handles.popupmenu7, 'Value');
            switch popup_sel_2
                case 1
                    % trajectory
                case 2
                    gui_plot_ts(hObject, eventdata, handles,2)
                case 3
                    gui_plot_temperature(hObject, eventdata, handles,2)
                case 4
                    gui_plot_salt(hObject, eventdata, handles,2)
                case 8
                    gui_plot_section(hObject, eventdata, handles,2,'temp',1)
                case 9
                    gui_plot_section(hObject, eventdata, handles,2,'psal',1)
                case 10
                    gui_plot_ts_climatology(hObject, eventdata, handles,2)
                case 11
                    gui_plot_section(hObject, eventdata, handles,2,'doxy',1)
                    
            end
        case 'leftarrow'
            current_profile = str2num(get(handles.text3,'string'));
            flt = getappdata(handles.figure1,'mydata');
            ii = find([flt.cycle_number] == current_profile);
            if ii > 1
                newprofile = flt(ii-1).cycle_number;
            else
                newprofile = current_profile;
            end
            set(handles.text3,'string',num2str(newprofile))
            
            % check if new profile is shallower then previous current_bin
            i2 = find([flt.cycle_number] == newprofile);
            current_bin = str2num(get(handles.text4,'string'));
            if current_bin > length(flt(i2).pres)
                set(handles.text4,'string',num2str(length(flt(i2).pres)))
            end
            
            gui_plot_profile(hObject, eventdata, handles,1)
            gui_plot_ts(hObject, eventdata, handles,4)
            popup_sel_index = get(handles.axes1_menu, 'Value');
            switch popup_sel_index
                case 1
                    gui_plot_flags(hObject, eventdata, handles,5,'temp')
                case 2
                    gui_plot_flags(hObject, eventdata, handles,5,'psal')
                case 3
                    gui_plot_flags(hObject, eventdata, handles,5,'doxy')
            end
            
            popup_sel_2 = get(handles.popupmenu7, 'Value');
            switch popup_sel_2
                case 1
                    % trajectory
                case 2
                    gui_plot_ts(hObject, eventdata, handles,2)
                case 3
                    gui_plot_temperature(hObject, eventdata, handles,2)
                case 4
                    gui_plot_salt(hObject, eventdata, handles,2)
                case 8
                    gui_plot_section(hObject, eventdata, handles,2,'temp',1)
                case 9
                    gui_plot_section(hObject, eventdata, handles,2,'psal',1)
                case 10
                    gui_plot_ts_climatology(hObject, eventdata, handles,2)
                case 11
                    gui_plot_section(hObject, eventdata, handles,2,'doxy',1)
            end
            
        case 'uparrow'
            % decrement bin counter by one and replot.
            current_bin = str2num(get(handles.text4,'string'));
            current_profile = str2num(get(handles.text3,'string'));
            
            flt = getappdata(handles.figure1,'mydata');
            ii = find([flt.cycle_number] == current_profile);
            
            if current_bin > 1
                new_bin =  current_bin -1;
            else
                new_bin =  current_bin;
            end
            set(handles.text4,'string',num2str(new_bin))
            
            gui_plot_profile(hObject, eventdata, handles,1)
            
        case 'downarrow'
            % advance bin counter by one and replot.
            current_bin = str2num(get(handles.text4,'string'));
            current_profile = str2num(get(handles.text3,'string'));
            
            flt = getappdata(handles.figure1,'mydata');
            ii = find([flt.cycle_number] == current_profile);
            
            if current_bin < length(flt(ii).pres)
                new_bin =  current_bin +1;
            else
                new_bin =  current_bin;
            end
            set(handles.text4,'string',num2str(new_bin))
            
            gui_plot_profile(hObject, eventdata, handles,1)
    end
    
    
    % --- Executes on button press in button_higher.
function button_higher_Callback(hObject, eventdata, handles)
    % hObject    handle to button_higher (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % decrement bin counter by one and replot.
    current_bin = str2num(get(handles.text4,'string'));
    current_profile = str2num(get(handles.text3,'string'));
    
    flt = getappdata(handles.figure1,'mydata');
    ii = find([flt.cycle_number] == current_profile);
    
    if current_bin > 1
        new_bin =  current_bin -1;
    else
        new_bin =  current_bin;
    end
    set(handles.text4,'string',num2str(new_bin))
    
    gui_plot_profile(hObject, eventdata, handles,1)
    
    
    % --- Executes on button press in button_lower.
function button_lower_Callback(hObject, eventdata, handles)
    % hObject    handle to button_lower (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % advance bin counter by one and replot.
    current_bin = str2num(get(handles.text4,'string'));
    current_profile = str2num(get(handles.text3,'string'));
    
    flt = getappdata(handles.figure1,'mydata');
    ii = find([flt.cycle_number] == current_profile);
    
    if current_bin < length(flt(ii).pres)
        new_bin =  current_bin +1;
    else
        new_bin =  current_bin;
    end
    set(handles.text4,'string',num2str(new_bin))
    
    gui_plot_profile(hObject, eventdata, handles,1)
    
    
    % --- Executes on selection change in variables_to_flag.
function variables_to_flag_Callback(hObject, eventdata, handles)
    % hObject    handle to variables_to_flag (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Hints: contents = cellstr(get(hObject,'String')) returns variables_to_flag contents as cell array
    %        contents{get(hObject,'Value')} returns selected item from variables_to_flag
    
    
    % --- Executes during object creation, after setting all properties.
function variables_to_flag_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to variables_to_flag (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called
    
    % Hint: popupmenu controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    
    
    % --- Executes on selection change in flag_select.
function flag_select_Callback(hObject, eventdata, handles)
    % hObject    handle to flag_select (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Hints: contents = cellstr(get(hObject,'String')) returns flag_select contents as cell array
    %        contents{get(hObject,'Value')} returns selected item from flag_select
    
    % --- Executes during object creation, after setting all properties.
function flag_select_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to flag_select (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called
    
    % Hint: popupmenu controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    
    % --- Executes on button press in flag_point.
function flag_point_Callback(hObject, eventdata, handles)
    % hObject    handle to flag_point (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    %
    % Apply flag to Point
    
    
    current_profile = str2num(get(handles.text3,'string'));
    flt = getappdata(handles.figure1,'mydata');
    ii = find([flt.cycle_number] == current_profile);
    current_bin = str2num(get(handles.text4,'string'));
    
    popup_flag_val = get(handles.flag_select, 'Value'); %query popup to determine what flag value is specified.
    popup_flag_obj = get(handles.variables_to_flag, 'Value'); %query popup to determine what variables to apply flag value to
    popup_sel_adj = get(handles.adjusted_menu, 'Value');
   
    if popup_flag_val == 5; popup_flag_val = 9;   end  % reassign 5th value to 9 (missing)
    
%     switch popup_sel_adj
%         case 1
%             adj_state = [];
%         case 2
%             adj_state = '_adjusted';
%     end
    switch popup_flag_obj
        case 1  % flag only variable in foreground
            popup_sel_index = get(handles.axes1_menu, 'Value'); %query popup to determine what variable is in fore
            switch popup_sel_index
                case 1
%                     props = {['temp',adj_state]};
                    props = {'temp'};
                    if popup_sel_adj == 2
                        props = {'temp','temp_adjusted'};
                    end
                case 2
%                    props = {['psal',adj_state]};
                    props = {'psal'};
                    if popup_sel_adj == 2
                        props = {'psal','psal_adjusted'};
                    end
                case 3
%                    props = {['doxy',adj_state]};
                    props = {'doxy'};
                    if popup_sel_adj == 2
                        props = {'doxy','doxy_adjusted'};
                    end
            end
        case 2  %flag T,S
%            props = {['temp',adj_state],['psal',adj_state]};
            props = {'temp','psal'};
            if popup_sel_adj == 2
                props = {'temp','temp_adjusted','psal','psal_adjusted'};
            end
        case 3  % Flag P,T, S
%            props = {['pres',adj_state],['temp',adj_state],['psal',adj_state]};
            props = {'pres','temp','psal'};
            if popup_sel_adj == 2
                props = {'pres','pres_adjusted','temp','temp_adjusted','psal','psal_adjusted'};
            end
    end

    for i = 1:length(props)
        flt = setfield(flt,{ii},[char(props(i)),'_qc'],{current_bin},num2str(popup_flag_val));
        fprintf(1,'Setting QC Flag of %s: profile %i, pressure %5.1f to %i\n',char(props(i)),current_profile,flt(ii).pres(current_bin),popup_flag_val)
    end

    flt(ii).editted = 1;  %mark as editted
    setappdata(handles.figure1,'mydata',flt);
    gui_plot_profile(hObject, eventdata, handles,1);
    
    popup_sel_index = get(handles.axes1_menu, 'Value'); %query popup to determine what variable is in fore
    switch popup_sel_index
        case 1
            prop = 'temp';
        case 2
            prop = 'psal';
        case 3
            prop = 'doxy';
    end
    gui_plot_flags(hObject, eventdata, handles,5,prop)
    gui_plot_ts(hObject, eventdata, handles,4)

    popup_sel_index = get(handles.popupmenu7, 'Value');
    switch popup_sel_index
        case 2
            gui_plot_ts(hObject, eventdata, handles,2)
        case 8
            gui_plot_section(hObject, eventdata, handles,2,'temp',1)
        case 9
            gui_plot_section(hObject, eventdata, handles,2,'psal',1)
        case 11
            gui_plot_section(hObject, eventdata, handles,2,'doxy',1)
    end
    
    
    % --- Executes on button press in pushbutton9.
function pushbutton9_Callback(hObject, eventdata, handles)
    % hObject    handle to pushbutton9 (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    %
    % Apply flag to Point and all ABOVE
    
    current_profile = str2num(get(handles.text3,'string'));
    flt = getappdata(handles.figure1,'mydata');
    ii = find([flt.cycle_number] == current_profile);
    current_bin = str2num(get(handles.text4,'string'));
    
    popup_flag_val = get(handles.flag_select, 'Value');%query popup to determine what flag value is specified.
    popup_flag_obj = get(handles.variables_to_flag, 'Value');%query popup to determine what variables to apply flag value to
    popup_sel_index = get(handles.axes1_menu, 'Value'); %query popup to determine what variable is in fore
    popup_sel_adj = get(handles.adjusted_menu, 'Value');

    if popup_flag_val == 5; popup_flag_val = 9;   end  % reassign 5th value to 9 (missing)

%     switch popup_sel_adj
%         case 1
%             adj_state = [];
%         case 2
%             adj_state = '_adjusted';
%     end
    switch popup_flag_obj
        case 1  % flag only variable in foreground
            popup_sel_index = get(handles.axes1_menu, 'Value'); %query popup to determine what variable is in fore
            switch popup_sel_index
                case 1
%                     props = {['temp',adj_state]};
                    props = {'temp'};
                    if popup_sel_adj == 2
                        props = {'temp','temp_adjusted'};
                    end
                case 2
%                     props = {['psal',adj_state]};
                    props = {'psal'};
                    if popup_sel_adj == 2
                        props = {'psal','psal_adjusted'};
                    end
                case 3
                    props = {['doxy',adj_state]};
            end
        case 2  %flag T,S
%             props = {['temp',adj_state],['psal',adj_state]};
            props = {'temp','psal'};
            if popup_sel_adj == 2
                props = {'temp','temp_adjusted','psal','psal_adjusted'};
            end
        case 3  % Flag P,T, S
%             props = {['pres',adj_state],['temp',adj_state],['psal',adj_state]};
            props = {'pres','temp','psal'};
            if popup_sel_adj == 2
                props = {'pres','pres_adjusted','temp','temp_adjusted','psal','psal_adjusted'};
            end
    end
    
    %set the flag
    for i = 1:length(props)
        flt = setfield(flt,{ii},[char(props(i)),'_qc'],{1:current_bin},num2str(popup_flag_val));
        fprintf(1,'Setting QC Flag of %s: profile %i, pressure %5.1f AND ABOVE to %i\n',char(props(i)),current_profile,flt(ii).pres(current_bin),popup_flag_val)
        %insure any missing values are set to 9;
        % 4/11/2018 dw moved to cleanup_for_aoml.m
        %missing = isnan(getfield(flt,{ii},[char(props(i))]));
        %if any(missing)
        %    flt = setfield(flt,{ii},[char(props(i)),'_qc'],{find(missing)},'9');
        %end
    end
    flt(ii).editted = 1;  %mark as editted
    setappdata(handles.figure1,'mydata',flt);
    gui_plot_profile(hObject, eventdata, handles,1)
    
    switch popup_sel_index
        case 1
            prop = 'temp';
        case 2
            prop = 'psal';
        case 3
            prop = 'doxy';
    end
    
    gui_plot_flags(hObject, eventdata, handles,5,prop)
    gui_plot_ts(hObject, eventdata, handles,4)

    popup_sel_index = get(handles.popupmenu7, 'Value');
    switch popup_sel_index
        case 2
            gui_plot_ts(hObject, eventdata, handles,2)
        case 8
            gui_plot_section(hObject, eventdata, handles,2,'temp',1)
        case 9
            gui_plot_section(hObject, eventdata, handles,2,'psal',1)
        case 11
            gui_plot_section(hObject, eventdata, handles,2,'doxy',1)
    end
    
    
    % --- Executes on button press in pushbutton10.
function pushbutton10_Callback(hObject, eventdata, handles)
    % hObject    handle to pushbutton10 (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    %
    % Apply flag to Point and all BELOW
    
    current_profile = str2num(get(handles.text3,'string'));
    flt = getappdata(handles.figure1,'mydata');
    ii = find([flt.cycle_number] == current_profile);
    current_bin = str2num(get(handles.text4,'string'));
    max_bin = length(getfield(flt,{ii},'pres'));
    
    %query popup to determine what flag value is specified.
    popup_flag_val = get(handles.flag_select, 'Value'); %query popup to determine what variables to apply flag value to
    popup_flag_obj = get(handles.variables_to_flag, 'Value');
    popup_sel_index = get(handles.axes1_menu, 'Value');
    popup_sel_adj = get(handles.adjusted_menu, 'Value');
    if popup_flag_val == 5; popup_flag_val = 9;   end  % reassign 5th value to 9 (missing)

%     switch popup_sel_adj
%         case 1
%             adj_state = [];
%         case 2
%             adj_state = '_adjusted';
%     end
    switch popup_flag_obj
        case 1  % flag only variable in foreground
            popup_sel_index = get(handles.axes1_menu, 'Value'); %query popup to determine what variable is in fore
            switch popup_sel_index
                case 1
%                     props = {['temp',adj_state]};
                    props = {'temp'};
                    if popup_sel_adj == 2
                        props = {'temp','temp_adjusted'};
                    end
                case 2
%                     props = {['psal',adj_state]};
                    props = {'psal'};
                    if popup_sel_adj == 2
                        props = {'psal','psal_adjusted'};
                    end
                case 3
%                     props = {['doxy',adj_state]};
                    props = {'doxy'};
                    if popuup_sel_adj == 2
                        props = {'doxy','doxy_adjusted'};
                    end
            end
        case 2  %flag T,S
%             props = {['temp',adj_state],['psal',adj_state]};
            props = {'temp','psal'};
            if popup_sel_adj == 2
                props = {'temp','temp_adjusted','psal','psal_adjusted'};
            end
        case 3  % Flag P,T, S
%             props = {['pres',adj_state],['temp',adj_state],['psal',adj_state]};
            props = {'pres','temp','psal'};
            if popup_sel_adj == 2
                props = {'pres','pres_adjusted','temp','temp_adjusted','psal','psal_adjusted'};
            end
    end
    
    
    %set the flag
    for i = 1:length(props)
        flt = setfield(flt,{ii},[char(props(i)),'_qc'],{current_bin:max_bin},num2str(popup_flag_val));
        fprintf(1,'Setting QC Flag of %s: profile %i, pressure %5.1f AND BELOW to %i\n',char(props(i)),current_profile,flt(ii).pres(current_bin),popup_flag_val)
        %insure any missing values are set to 9;
        % 4/11/2018 dw moved to cleanup_for_aoml.m
        %missing = isnan(getfield(flt,{ii},[char(props(i))]));
        %if any(missing)
        %    flt = setfield(flt,{ii},[char(props(i)),'_qc'],{find(missing)},'9');
        %end
    end
    flt(ii).editted = 1;  %mark as editted
    setappdata(handles.figure1,'mydata',flt);
    gui_plot_profile(hObject, eventdata, handles,1)
    gui_plot_ts(hObject, eventdata, handles,4)

    
    switch popup_sel_index
        case 1
            prop = 'temp';
        case 2
            prop = 'psal';
        case 3
            prop = 'doxy';
    end
    gui_plot_flags(hObject, eventdata, handles,5,prop)
    
    
    % --- Executes on button press in togglebutton2.
function togglebutton2_Callback(hObject, eventdata, handles)
    % hObject    handle to togglebutton2 (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Hint: get(hObject,'Value') returns toggle state of togglebutton2
    
    % --- Executes on button press in save_changes.
function save_changes_Callback(hObject, eventdata, handles,varargin)
    % hObject    handle to save_changes (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    %save the changes
    %copy files from inpath to outpath
    flt = getappdata(handles.figure1,'mydata');
    if ~strcmp(flt(1).inpath,flt(1).outpath)
        eval(['!cp ',flt(1).inpath,'/* ',flt(1).outpath])
    end
    disp(['Backing up current changes to files in ',flt(1).outpath])
    %wrt_flt_gdac(flt);
        
    flt = feval(flt(1).write_func,flt);
    
    setappdata(handles.figure1,'mydata',flt);

    popup_sel_index = get(handles.axes1_menu, 'Value');
    switch popup_sel_index
        case 1
            gui_plot_flags(hObject, eventdata, handles,5,'temp')
        case 2
            gui_plot_flags(hObject, eventdata, handles,5,'psal')
        case 3
            gui_plot_flags(hObject, eventdata, handles,5,'doxy')
    end

    
    % --- Executes on key press with focus on quit_no_save and none of its controls.
function quit_no_save_KeyPressFcn(hObject, eventdata, handles)
    % hObject    handle to quit_no_save (see GCBO)
    % eventdata  structure with the following fields (see UICONTROL)
    %	Key: name of the key that was pressed, in lower case
    %	Character: character interpretation of the key(s) that was pressed
    %	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
    % handles    structure with handles and user data (see GUIDATA)
  
    
    
    % --- Executes on selection change in popupmenu7. This is the menu that
    % selects the different graphics
function popupmenu7_Callback(hObject, eventdata, handles)
    % hObject    handle to popupmenu7 (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Hints: contents = cellstr(get(hObject,'String')) returns popupmenu7 contents as cell array
    %        contents{get(hObject,'Value')} returns selected item from
    %        popupmenu7
    popup_sel_index = get(handles.popupmenu7, 'Value');
    switch popup_sel_index
        case 1
            gui_plot_pos(hObject, eventdata, handles,2,0)
        case 2
            gui_plot_ts(hObject, eventdata, handles,2)
        case 3
            gui_plot_temperature(hObject, eventdata, handles,2)
        case 4
            gui_plot_salt(hObject, eventdata, handles,2)
        case 5
            gui_plot_flags(hObject, eventdata, handles,2,'pres')
        case 6
            gui_plot_flags(hObject, eventdata, handles,2,'temp')
        case 7
            gui_plot_flags(hObject, eventdata, handles,2,'psal')
        case 8
            gui_plot_section(hObject, eventdata, handles,2,'temp',0)
        case 9
            gui_plot_section(hObject, eventdata, handles,2,'psal',0)
        case 10
            gui_plot_ts_climatology(hObject, eventdata, handles,2)
        case 11
            gui_plot_section(hObject, eventdata, handles,2,'doxy',0)
            
    end
    
    % --- Executes during object creation, after setting all properties.
function popupmenu7_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to popupmenu7 (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called
    
    % Hint: popupmenu controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    
    
    % --- Executes on button press in zoom_axes1.
function zoom_axes1_Callback(hObject, eventdata, handles)
    % hObject    handle to zoom_axes1 (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structumintre with handles and user data (see GUIDATA)
    
    % Hint: get(hObject,'Value') returns toggle state of zoom_axes1
    axs = 1;
    eval(['axes(handles.axes',num2str(axs),');'])
    button_state = get(hObject,'Value');
    if button_state == 1
        zoom on
    else
        zoom off
    end
    
    % --- Executes during object creation, after setting all properties.
function figure1_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to figure1 (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called
    
    
    % --- Executes on mouse motion over figure - except title and menu.
function figure1_WindowButtonMotionFcn(hObject, eventdata, handles)
    % hObject    handle to figure1 (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in plot_nearby.
function plot_nearby_Callback(hObject, eventdata, handles)
% hObject    handle to plot_nearby (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of plot_nearby
flt = getappdata(handles.figure1,'mydata');

if isfield(flt,'hist_ctd_dir')
    current_profile = str2num(get(handles.text3,'string'));
    current_bin = str2num(get(handles.text4,'string'));
    popup_sel_index = get(handles.axes1_menu, 'Value');
    switch popup_sel_index
        case 1
            prop = 'temp';
        case 2
            prop = 'psal';
        case 3
            prop = 'doxy';
    end
    popup_sel_adj = get(handles.adjusted_menu, 'Value');
    switch popup_sel_adj
        case 1
            %do nothing
            useAdj = 0;
        case 2
            prop = [prop,'_adjusted'];
            useAdj = 1;
    end
    flt(1).current_profile = current_profile;
    flt(1).prop = prop;
    flt(1).useAdj = useAdj;

    plot_nearby_new(flt)
else
    disp('Not available: Use Config to specify directories for historical data')
end
    


% --- Executes on button press in pushbutton12.
function pushbutton12_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton12 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%zoom out
flt = getappdata(handles.figure1,'mydata');
if isfield(flt,'xlim')
    flt = rmfield(flt,'xlim');
    flt = rmfield(flt,'ylim');
    setappdata(handles.figure1,'mydata',flt);
end

gui_plot_profile(hObject, eventdata, handles,1)


% --- Executes on selection change in adjusted_menu.
function adjusted_menu_Callback(hObject, eventdata, handles)
% hObject    handle to adjusted_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns adjusted_menu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from adjusted_menu
% flt = getappdata(handles.figure1,'mydata');
  
 set(handles.adjusted_menu,'ForegroundColor','black');
 
 popup_sel_index = get(handles.axes1_menu, 'Value');
 switch popup_sel_index
     case 1
         %            gui_plot_temperature(hObject, eventdata, handles,4)
         gui_plot_flags(hObject, eventdata, handles,5,'temp')
     case 2
         %            gui_plot_salt(hObject, eventdata, handles,4)
         gui_plot_flags(hObject, eventdata, handles,5,'psal')
     case 3
         %            gui_plot_doxy(hObject, eventdata, handles,4)
         gui_plot_flags(hObject, eventdata, handles,5,'doxy')
 end
 gui_plot_ts(hObject, eventdata, handles,4)
 gui_plot_profile(hObject, eventdata, handles,1)
 

% --- Executes during object creation, after setting all properties.
function adjusted_menu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to adjusted_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function [hour,min,sec]=s2hms(secs)
%S2HMS converts seconds to integer hour,minute,seconds %
sec=round(secs);
hour=floor(sec/3600);
min=floor(rem(sec,3600)/60);
sec=round(rem(sec,60));

function [r]=hms2h(h,m,s)
%HMS2H   Converts hours, minutes, seconds to decimal hours
r = h +(m+s/60)/60;

function out = merge(input1, input2)
%function out = merge(input1, input2)
% combines two matrices size by side and pads the one with smaller length
% with NaNs at the bottom 
[l1,w1] = size(input1);
[l2,w2] = size(input2);
  if l1 == l2
    out = [input1 input2];
  elseif l1 > l2
    out = [input1 [input2; nan*ones(l1-l2,w2)]];
  else
    out = [[ input1 ;nan*ones(l2-l1,w1)] input2];
  end

 function [gtime]=gregorian(julian)
%GREGORIAN  Converts digital Julian days to Gregorian calendar dates.  
%       Although formally, 
%       Julian days start and end at noon, here Julian days
%       start and end at midnight for simplicity.
%     
%       In this convention, Julian day 2440000 begins at 
%       0000 hours, May 23, 1968.
%
%     Usage: [gtime]=gregorian(julian) 
%
%        julian... input decimal Julian day number
%
%        gtime is a six component Gregorian time vector
%          i.e.   gtime=[yyyy mo da hr mi sec]
%                 gtime=[1989 12  6  7 23 23.356]
%        yr........ year (e.g., 1979)
%        mo........ month (1-12)
%        d........ corresponding Gregorian day (1-31)
%        h........ decimal hours
%
%  calls S2HMS
julian=julian+5.e-9;    % kludge to prevent roundoff error on seconds
%      if you want Julian Days to start at noon...
%      h=rem(julian,1)*24+12;
%      i=(h >= 24);
%      julian(i)=julian(i)+1;
%      h(i)=h(i)-24;
secs=rem(julian,1)*24*3600;
j = floor(julian) - 1721119;
in = 4*j -1;
y = floor(in/146097);
j = in - 146097*y;
in = floor(j/4);
in = 4*in +3;
j = floor(in/1461);
d = floor(((in - 1461*j) +4)/4);
in = 5*d -3;
m = floor(in/153);
d = floor(((in - 153*m) +5)/5);
y = y*100 +j;
mo=m-9;
yr=y+1;
i=(m<10);
mo(i)=m(i)+3;
yr(i)=y(i);
[hour,min,sec]=s2hms(secs);
gtime=[yr(:) mo(:) d(:) hour(:) min(:) sec(:)];

     function h = add_plot(x,y,ltype,linewidth,keepX);
         %function h = add_plot(x,y,ltype,label)
         % overplots new line to existing plot  keeping same y scale but creating a new
         % x-scale.   An axis for the new x-scale is added to the top of the plot.
         %   x: vector of x values
         %   y: vector of y values
         %   ltype: (opt) string designating line color and type
         %   label: a label for the axis
         %
         %
         % P.E. Robbins 1997.
         
         if nargin < 3;
             ltype = 'k-';
         end
         if nargin < 4;
             linewidth = 1;
         end
         if nargin < 5
             keepX = [];
         end
         xl = get(gca,'xlim');
xt = get(gca,'xtick') ;
% try to figure out good numbers from x
N = length(xt);
if isempty(keepX)
    minx = min(x);
    maxx = max(x);
else
    minx = keepX.min;
    maxx = keepX.max;
end
difx = maxx-minx;
dx = difx/N; % size of  increment of x;
% now round this increment to one signficant figure
if isempty(dx)
   return
end
p = fix(log10(dx));
if dx < 1
  p = p-1;
end
DX = fix((dx/(10^p)))*10^p;		%  this is increment
% now figure out min and max
MINX = floor((minx/(10^p)))*10^p;
MAXX = ceil((maxx/(10^p)))*10^p;
X = MINX:DX:MAXX;
%figure out transformation of new x to old x scale
tl = [MINX-DX/2 MAXX+DX/2];
m = diff(xl)/diff(tl);
b = xl(1) - m*tl(1);
hold on
if isstr(ltype)
    h = plot(x*m+b,y,ltype,'linewidth',linewidth);
else
    h = plot(x*m+b,y,'color',ltype,'linewidth',linewidth);
end
% pull color out of linetype
if isstr(ltype)
  clr = ltype(1);
else
  clr = ltype;
end


% --- Executes on button press in NextBad.
function NextBad_Callback(hObject, eventdata, handles)
% hObject    handle to NextBad (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%
% finds the next bad point and locates cursor there
flt = getappdata(handles.figure1,'mydata');
current_profile = str2num(get(handles.text3,'string'));
current_bin = str2num(get(handles.text4,'string'));
popup_sel_index = get(handles.axes1_menu, 'Value');
switch popup_sel_index
    case 1
        prop = 'temp';
    case 2
        prop = 'psal';
    case 3
        prop = 'doxy';
end
popup_sel_adj = get(handles.adjusted_menu, 'Value');
switch popup_sel_adj
    case 1
        %do nothing
    case 2
        prop = [prop,'_adjusted'];
end
istart = find(current_profile == [flt.cycle_number]);
for iflt = istart:length(flt);
    i2 = getfield(flt(iflt),[prop,'_qc']) == '2';
    i3 = getfield(flt(iflt),[prop,'_qc']) == '3';
    i4 = getfield(flt(iflt),[prop,'_qc']) == '4';
    
    ibad = i2 | i3 | i4;
    if iflt== istart  % don't count current point of any shallower
        ibad(1:current_bin) = 0;
    end
    if any(ibad)
        newprofile = flt(iflt).cycle_number;
        new_bin = min(find(ibad));
        break
    end
end
if exist('newprofile') ~=1
    disp('No more bad points')
    return
end
set(handles.text3,'string',num2str(newprofile))
set(handles.text4,'string',num2str(new_bin))
% replot things
gui_plot_profile(hObject, eventdata, handles,1)
gui_plot_ts(hObject, eventdata, handles,4)
popup_sel_index = get(handles.axes1_menu, 'Value');
switch popup_sel_index
    case 1
        gui_plot_flags(hObject, eventdata, handles,5,'temp')
    case 2
        gui_plot_flags(hObject, eventdata, handles,5,'psal')
    case 3
        gui_plot_flags(hObject, eventdata, handles,5,'doxy')
end
popup_sel_2 = get(handles.popupmenu7, 'Value');
switch popup_sel_2
    case 1
         gui_plot_pos(hObject, eventdata, handles,2,1)
    case 2
        gui_plot_ts(hObject, eventdata, handles,2)
    case 3
        gui_plot_temperature(hObject, eventdata, handles,2)
    case 4
        gui_plot_salt(hObject, eventdata, handles,2)
    case 8
        gui_plot_section(hObject, eventdata, handles,2,'temp',1)
    case 9
        gui_plot_section(hObject, eventdata, handles,2,'psal',1)
    case 10
        gui_plot_ts_climatology(hObject, eventdata, handles,2)
    case 11
        gui_plot_section(hObject, eventdata, handles,2,'doxy',1)
end


% --- Executes on button press in PreviousBad.
function PreviousBad_Callback(hObject, eventdata, handles)
% hObject    handle to PreviousBad (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% finds the previous bad point and locates cursor there
flt = getappdata(handles.figure1,'mydata');
current_profile = str2num(get(handles.text3,'string'));
current_bin = str2num(get(handles.text4,'string'));
popup_sel_index = get(handles.axes1_menu, 'Value');
switch popup_sel_index
    case 1
        prop = 'temp';
    case 2
        prop = 'psal';
    case 3
        prop = 'doxy';
end
popup_sel_adj = get(handles.adjusted_menu, 'Value');
switch popup_sel_adj
    case 1
        %do nothing
    case 2
        prop = [prop,'_adjusted'];
end
istart = find(current_profile == [flt.cycle_number]);
for iflt = istart:-1:1
    i2 = getfield(flt(iflt),[prop,'_qc']) == '2';
    i3 = getfield(flt(iflt),[prop,'_qc']) == '3';
    i4 = getfield(flt(iflt),[prop,'_qc']) == '4';
    
    ibad = i2 | i3 | i4;
    if iflt== istart  % don't count current point of any deeper
        ibad(current_bin:end) = 0;
    end
    if any(ibad)
        newprofile = flt(iflt).cycle_number;
        new_bin = max(find(ibad));
        break
    end
end
if exist('newprofile') ~=1
    disp('No previous bad points')
    return
end
set(handles.text3,'string',num2str(newprofile))
set(handles.text4,'string',num2str(new_bin))
% replot things
gui_plot_profile(hObject, eventdata, handles,1)
gui_plot_ts(hObject, eventdata, handles,4)
popup_sel_index = get(handles.axes1_menu, 'Value');
switch popup_sel_index
    case 1
        gui_plot_flags(hObject, eventdata, handles,5,'temp')
    case 2
        gui_plot_flags(hObject, eventdata, handles,5,'psal')
    case 3
        gui_plot_flags(hObject, eventdata, handles,5,'doxy')
end
popup_sel_2 = get(handles.popupmenu7, 'Value');
switch popup_sel_2
    case 1
        gui_plot_pos(hObject, eventdata, handles,2,1)
    case 2
        gui_plot_ts(hObject, eventdata, handles,2)
    case 3
        gui_plot_temperature(hObject, eventdata, handles,2)
    case 4
        gui_plot_salt(hObject, eventdata, handles,2)
    case 8
        gui_plot_section(hObject, eventdata, handles,2,'temp',1)
    case 9
        gui_plot_section(hObject, eventdata, handles,2,'psal',1)
    case 10
        gui_plot_ts_climatology(hObject, eventdata, handles,2)
    case 11
        gui_plot_section(hObject, eventdata, handles,2,'doxy',1)
end


% --- Executes on mouse press over figure background.
function figure1_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes when figure1 is resized.
function figure1_SizeChangedFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on key press with focus on plot_nearby and none of its controls.
function plot_nearby_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to plot_nearby (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.CONTROL.UICONTROL)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)


% --- Executes during object creation, after setting all properties.
function axes2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to axes2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: place code in OpeningFcn to populate axes2