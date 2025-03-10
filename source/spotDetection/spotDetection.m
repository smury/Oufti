function spotDetection
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
%function spotFinderZ
%oufti.v0.2.9
%@author:  Ahmad J Paintdakhi
%@date:    November 21 2012
%@copyright 2012-2014 Yale University
%==========================================================================
%**********output********:
%**********Input********:
%=========================================================================
% PURPOSE:
%This function is used for locating flourescent labeled molecules/proteins
%etc... The function creates a structure named spots in the cellList.meshData
%field containing the following fields.
%       l:  coordinate along the centerline.
%       magnitude:  brightness of the spots (combined brightness under the 
%                   Gaussian fit excluding background.
%       w:  width of th spots (one of the Gaussian fit parameters).
%       h:  heigh of the spots(one of the Gaussian fit parameters).
%       b:  background under spots (one of the Gaussian fit parameters).
%       d:  signed distance from the centerline.
%       x:  euclidian coordinate from the left of the image.
%       y:  euclidian coordinate from the top of the image.
%       positions:  segment number in which the spot is located.  The spot
%                   can be outside of the cell if cell is dilated.
%       rmse:  adjusted square error of the fit.  
%       confidenceInterval_b_h_w_x_y:  an array of confidence intervals for
%       the h, w, x, and y values.
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------

global handles1 handles params imageHandle

%-------------------------------------------------------------------------------------
%checkbformats checks for Bio-Formats Viewer library.  This library provides a useful
%function that loads stack images that are not tif.
bformats = checkbformats(1);
%-------------------------------------------------------------------------------------
pos = get(handles.maingui,'position');
screenSize = get(0,'ScreenSize');
pos = [max(pos(1),1) max(1,min(pos(2),screenSize(4)-20-max(pos(4),600)))...
      max(pos(3:4),[1000 600])];

panelshift=0;
handles1.spotFinderPanel = uipanel('Parent',handles.maingui,'units','pixels',...
                            'Position',[pos(3)-1000+725 pos(4)-800+485 272 250],'ButtonDownFcn',@mainkeypress,...
                            'ResizeFcn',@resizefcn,'Interruptible','off','Title','spotDetection');
handles1.parameterPanel = uipanel(handles1.spotFinderPanel,'units','pixels','Position',[135 32+panelshift 130 175]);
handles1.outputpanel = uipanel(handles1.spotFinderPanel,'units','pixels','Position',[8 32+panelshift 120 175]);

%-----------------------------------------------------------------------------------
%date: November 21 2012
%author:  Ahmad J. Paintdakhi
%new panel for the parameter window.
uicontrol(handles1.parameterPanel,'units','pixels','Position',[5 152 118 16],...
          'Style','text','String','Parameters','FontWeight','bold',...
          'HorizontalAlignment','center');
% % % uicontrol(handles1.parameterPanel,'units','pixels','Position',[1 135 120 16],...
% % %           'Style','text','String','minHeight','HorizontalAlignment','left');
% % % handles1.heightCutoffBeforeFit = uicontrol(handles1.parameterPanel,'units','pixels',...
% % %                       'Position',[75 135 50 16],'Style','edit','String',' ',...
% % %                       'BackgroundColor',[1 1 1],'HorizontalAlignment','left');
% % uicontrol(handles1.parameterPanel,'units','pixels','Position',[1 115 120 16],...
% %           'Style','text','String','HeightAfterFit','HorizontalAlignment','left');                  
% % handles1.heightCutoffAfterFit = uicontrol(handles1.parameterPanel,'units','pixels',...
% %                       'Position',[75 115 50 16],'Style','edit','String',' ',...
% %                       'BackgroundColor',[1 1 1],'HorizontalAlignment','left');                  
uicontrol(handles1.parameterPanel,'units','pixels','Position',[1 115 120 16],...
          'Style','text','String','wavelet scale','HorizontalAlignment','left');
handles1.scale = uicontrol(handles1.parameterPanel,'units','pixels','Position',...
                [85 115 40 16],'Style','edit','String','1','BackgroundColor',...
                [1 1 1],'HorizontalAlignment','left');
            
uicontrol(handles1.parameterPanel,'units','pixels','Position',[1 95 120 16],...
          'Style','text','String','low pass','HorizontalAlignment','left');
handles1.lowPass = uicontrol(handles1.parameterPanel,'units','pixels','Position',...
                [85 95 40 16],'Style','edit','String','2','BackgroundColor',...
                [1 1 1],'HorizontalAlignment','left');
handles1.minThreshText = uicontrol(handles1.parameterPanel,'units','pixels','Position',[1 75 120 16],...
          'Style','text','String','spot radius','HorizontalAlignment','left');
handles1.spotRadius = uicontrol(handles1.parameterPanel,'units','pixels',...
                      'Position',[85 75 40 16],'Style','edit','String','3',...
                      'BackgroundColor',[1 1 1],'HorizontalAlignment','left');
uicontrol(handles1.parameterPanel,'units','pixels','Position',[1 55 120 16],...
          'Style','text','String','int. threshold','HorizontalAlignment','left');
handles1.int_threshold = uicontrol(handles1.parameterPanel,'units','pixels',...
                         'Position',[85 55 40 16],'Style','edit','String','0.4',...
                         'BackgroundColor',[1 1 1],'HorizontalAlignment','left');
uicontrol(handles1.parameterPanel,'units','pixels','Position',[1 35 120 16],...
          'Style','text','String','min region size','HorizontalAlignment','left');
handles1.minRegionSize = uicontrol(handles1.parameterPanel,'units','pixels',...
                      'Position',[85 35 40 16],'Style','edit','String','0',...
                      'BackgroundColor',[1 1 1],'HorizontalAlignment','left');

%-----------------------------------------------------------------------------------
%-----------------------------------------------------------------------------------
%date: December 4 2012
%author:  Ahmad J. Paintdakhi
handles1.maxRadiusText = uicontrol(handles1.parameterPanel,'units','pixels','Position',[1 15 120 16 ],...
          'Style','text','String','fit radius','HorizontalAlignment','left');
handles1.fitRadius = uicontrol(handles1.parameterPanel,'units','pixels',...
                           'Position',[85 15 40 16],'Style','edit','String',...
                           '2.45','BackgroundColor',[1 1 1],...
                           'HorizontalAlignment','left');
%date: February 12, 2014
%author:  Ahmad J. Paintdakhi
handles1.freqPassText = uicontrol(handles1.parameterPanel,'units','pixels','Position',[1 35 120 16],...
          'Style','text','String','freqToPass','HorizontalAlignment','left','Visible','off');
handles1.freqToPass = uicontrol(handles1.parameterPanel,'units','pixels',...
                           'Position',[85 35 40 16],'Style','edit','String',...
                           '0.75','BackgroundColor',[1 1 1],...
                           'HorizontalAlignment','left','Visible','off');
handles1.minAreaText = uicontrol(handles1.parameterPanel,'units','pixels','Position',[1 18 50 16],...
          'Style','text','String','minArea','HorizontalAlignment','left','Visible','off');
handles1.minArea = uicontrol(handles1.parameterPanel,'units','pixels',...
                           'Position',[85 18 40 16],'Style','edit','String',...
                           '12','BackgroundColor',[1 1 1],...
                           'HorizontalAlignment','left','Visible','off');
handles1.maxAreaText = uicontrol(handles1.parameterPanel,'units','pixels','Position',[1 2 50 16],...
          'Style','text','String','maxArea','HorizontalAlignment','left','Visible','off');
handles1.maxArea = uicontrol(handles1.parameterPanel,'units','pixels',...
                           'Position',[85 2 40 16],'Style','edit','String',...
                           '43','BackgroundColor',[1 1 1],...
                           'HorizontalAlignment','left','Visible','off');
%-----------------------------------------------------------------------------------

uicontrol(handles1.outputpanel,'units','pixels','Position',[6 152 105 16],'Style','text','String','Output','FontWeight','bold','HorizontalAlignment','center');
handles1.outimg = uicontrol(handles1.outputpanel,'units','pixels','Position',[5 124 105 16],'Style','checkbox','String','Images','Callback',@checkchange_cbk,'KeyPressFcn',@mainkeypress);
handles1.outsaveimg = uicontrol(handles1.outputpanel,'units','pixels','Position',[12 105 90 16],'Style','checkbox','String','Save','Enable','off','KeyPressFcn',@mainkeypress);
handles1.outshowmesh = uicontrol(handles1.outputpanel,'units','pixels','Position',[12 86 90 16],'Style','checkbox','String','Show meshes','Enable','off','KeyPressFcn',@mainkeypress);
handles1.outmesh = uicontrol(handles1.outputpanel,'units','pixels','Position',[5 66 105 16],'Style','checkbox','String','Meshes','Callback',@checkchange_cbk,'KeyPressFcn',@mainkeypress);
handles1.outfile = uicontrol(handles1.outputpanel,'units','pixels','Position',[12 47 90 16],'Style','checkbox','String','File','Enable','off','KeyPressFcn',@mainkeypress);
handles1.outscreen = uicontrol(handles1.outputpanel,'units','pixels','Position',[12 28 90 16],'Style','checkbox','String','Workspace','Enable','off','KeyPressFcn',@mainkeypress);
uicontrol(handles1.outputpanel,'units','pixels','Position',[5 5 30 16],'Style','text','String','Field','HorizontalAlignment','left','KeyPressFcn',@mainkeypress);
handles1.outfield = uicontrol(handles1.outputpanel,'units','pixels','Position',[35 5 70 16],'Style','edit','String','spots','BackgroundColor',[1 1 1],'HorizontalAlignment','left');


handles1.helpbtn = uicontrol(handles1.spotFinderPanel,'units','pixels','Position',[5 212+panelshift 50 20],'String','Help','Callback',@help_cbk,'Enable','on','KeyPressFcn',@mainkeypress);
handles1.loadstack = uicontrol(handles1.spotFinderPanel,'units','pixels','Position',[155 212+panelshift 50 20],'Style','checkbox','value',1,'String','stack','Enable','on','KeyPressFcn',@mainkeypress);
handles1.multGauss = uicontrol(handles1.spotFinderPanel,'units','pixels','Position',[65 212+panelshift 80 20],'Style','checkbox','value',0,'String','mult. Gauss','Enable','on','KeyPressFcn',@mainkeypress);
handles1.filtWin = uicontrol(handles1.spotFinderPanel,'units','pixels','Position',[210 212+panelshift 50 20],'Style','checkbox','value',0,'String','filtWin','Enable','on','KeyPressFcn',@mainkeypress);
% % % handles1.COM = uicontrol(handles1.spotFinderPanel,'units','pixels','Position',[210 212+panelshift 50 20],'Style','checkbox','Value',1,'String','GAU','Enable','on','KeyPressFcn',@mainkeypress,'Callback',@runCOM);
handles1.adjustbtn = uicontrol(handles1.spotFinderPanel,'units','pixels','Position',[5 5+panelshift 125 22],'String','Adjust','Callback',@run_cbk,'KeyPressFcn',@mainkeypress);
handles1.run = uicontrol(handles1.spotFinderPanel,'units','pixels','Position',[140 5+panelshift 125 22],'String','Run','Callback',@run_cbk,'KeyPressFcn',@mainkeypress);
handles1.stop = uicontrol(handles1.spotFinderPanel,'units','pixels','Position',[5 5+panelshift 125 22],'String','Stop','Callback',@stop_cbk,'KeyPressFcn',@mainkeypress,'Visible','off');
handles1.postProcessButton = uicontrol(handles1.spotFinderPanel,'units','pixels','Position',[140 5+panelshift 125 22],'String','Post-fit Processing','Callback',@postFitProcessing,'KeyPressFcn',@mainkeypress,'Visible','off');
handles1.calculate = [];
%range values for frame
handles1.rangec = uicontrol(handles1.spotFinderPanel,'units','pixels','pos',[5 25 145 12],'Style','text','String','Use range of frames:','visible','off','HorizontalAlignment','left');
handles1.range1 = uicontrol(handles1.spotFinderPanel,'units','pixels','pos',[135 22 50 12],'Style','edit','String','','BackgroundColor',[1 1 1],'Visible','off');
handles1.range2 = uicontrol(handles1.spotFinderPanel,'units','pixels','pos',[195 22 50 12],'Style','edit','String','','BackgroundColor',[1 1 1],'Visible','off');

%range values for cell
handles1.cellRange = uicontrol(handles1.spotFinderPanel,'units','pixels','pos',[5 8 145 12],'Style','text','String','Use range of cells:','visible','off','HorizontalAlignment','left');
handles1.cellRange1 = uicontrol(handles1.spotFinderPanel,'units','pixels','pos',[135 5 50 12],'Style','edit','String','','BackgroundColor',[1 1 1],'Visible','off');
handles1.cellRange2 = uicontrol(handles1.spotFinderPanel,'units','pixels','pos',[195 5 50 12],'Style','edit','String','','BackgroundColor',[1 1 1],'Visible','off');
drawnow();pause(0.005);

%------------------------------------------------
%November 26, 2012
%Ahmad.P
%updates params structure with parameters
%values from the gui window.
if isfield(handles1,'spotParams')
   handles1.scale.String = num2str(handles1.spotParams.scale);
   handles1.spotRadius.String = num2str(handles1.spotParams.spotRadius);
   handles1.lowPass.String = num2str(handles1.spotParams.lowPass);
   handles1.minRegionSize.String = num2str(handles1.spotParams.minRegionSize);
   handles1.int_threshold.String = num2str(handles1.spotParams.int_threshold);
   handles1.fitRadius.String = num2str(handles1.spotParams.fitRadius);
   if isfield(handles1.spotParams,'postMinWidth')
       handles1.postMinWidth.String = num2str(handles1.spotParams.postMinWidth);
   end
   if isfield(handles1.spotParams,'postMaxWidth')
       handles1.postMaxWidth.String = num2str(handles1.spotParams.postMaxWidth);
   end
   if isfield(handles1.spotParams,'postMinHeight')
       handles1.postMinHeight.String = num2str(handles1.spotParams.postMinHeight);
   end 
   if isfield(handles1.spotParams,'postError')
       handles1.postError.String = num2str(handles1.spotParams.postError);
   end 
end
params = getParameters(handles1,params);

%------------------------------------------------

handles1.spotList = [];

firstFolder='';
spotFinderImageFile = '';
signalMeshFileName = '';
trainOnRange = true;
panelshift = 25;
adjustmode = false;
adjustmaingui();
w = [];

% % % function runCOM(hObject, eventdata)
% % %    if  get(handles1.COM,'value') == 1
% % %        set(handles1.maxRadiusText,'Visible','off');
% % %        set(handles1.maxRadius,'Visible','off');
% % %        set(handles1.freqPassText,'Visible','on');
% % %        set(handles1.freqToPass,'Visible','on');
% % %        set(handles1.intensityThresh,'Visible','on');
% % %        set(handles1.cutoffFreq,'Visible','off');
% % %        set(handles1.cutoffFreqText,'Visible','off');
% % %        set(handles1.intensityThreshText,'Visible','on');
% % %        set(handles1.minAreaText,'Visible','on');
% % %        set(handles1.minArea,'Visible','on');
% % %        set(handles1.maxAreaText,'Visible','on');
% % %        set(handles1.maxArea,'Visible','on');
% % %    else
% % %        set(handles1.maxRadiusText,'Visible','on');
% % %        set(handles1.maxRadius,'Visible','on');
% % %        set(handles1.freqPassText,'Visible','off');
% % %        set(handles1.freqToPass,'Visible','off');
% % %        set(handles1.intensityThresh,'Visible','off');
% % %        set(handles1.cutoffFreq,'Visible','on');
% % %        set(handles1.cutoffFreqText,'Visible','on');
% % %        set(handles1.intensityThreshText,'Visible','off');
% % %        set(handles1.minAreaText,'Visible','off');
% % %        set(handles1.minArea,'Visible','off');
% % %        set(handles1.maxAreaText,'Visible','off');
% % %        set(handles1.maxArea,'Visible','off');
% % %    end
% % % 
% % % end
function mainkeypress(hObject, eventdata)
    
c = get(handles.maingui,'CurrentCharacter');
if isempty(c)
    return;
% % % elseif strcmp(c,'+') || double(c)==43 || strcmp(c,'=') || double(c)==61 % '+' - Perform training on a range of frames
% % % trainOnRange = true;
% % % panelshift=25;
% % % adjustmaingui
% % % elseif strcmp(c,'-') || double(c)==45 % '-' - Perform training on all frames
% % % trainOnRange = false;
% % % panelshift=60;
% % % adjustmaingui
elseif double(c)==28 % left arrow - go to previous cell
set(handles1.spotFinderPanel,'UserData',-1);
elseif double(c)==29 % right arrow - go to next cell
set(handles1.spotFinderPanel,'UserData',1);
elseif double(c)==27 % ESC - stop
set(handles1.spotFinderPanel,'UserData',0);
stoprun();
end

end  %mainKeyPress()
function adjustmaingui
    resizefcn();
    if trainOnRange
        set(handles1.rangec,'Visible','on');
        set(handles1.range1,'Visible','on');
        set(handles1.range2,'Visible','on');
        set(handles1.cellRange,'Visible','on');
        set(handles1.cellRange1,'Visible','on');
        set(handles1.cellRange2,'Visible','on');
    else

        set(handles1.rangec,'Visible','off');
        set(handles1.range1,'Visible','off');
        set(handles1.range2,'Visible','off');
        set(handles1.cellRange,'Visible','off');
        set(handles1.cellRange1,'Visible','off');
        set(handles1.cellRange2,'Visible','off');
        set(handles1.helpbtn,'pos',[10 212+panelshift 50 20]);
        set(handles1.loadstack,'pos',[155 212+panelshift 50 20]);
        set(handles1.multGauss,'pos',[65 212+panelshift 80 20]);
        set(handles1.filtWin,'pos',[210 212+panelshift 40 20]);
        set(handles1.adjustbtn,'pos',[5 5+panelshift 125 22]);
        set(handles1.run,'pos',[140 5+panelshift 125 22]);
        set(handles1.parameterPanel,'pos',[135 32+panelshift 130 175]);
        set(handles1.outputpanel,'pos',[8 32+panelshift 120 175]);
    end
end  %adjustmaingui()
function checkchange_cbk(hObject, eventdata)
if hObject==handles1.outmesh && get(handles1.outmesh,'Value')==1
   set(handles1.outscreen,'Enable','on')
   set(handles1.outfile,'Enable','on')
   handles1.outfile.Value = 1;
   handles1.outscreen.Value = 0;
elseif hObject==handles1.outmesh && get(handles1.outmesh,'Value')==0
   set(handles1.outscreen,'Enable','off')
   set(handles1.outfile,'Enable','off')
end

if hObject==handles1.outmesh && get(handles1.outmesh,'Value')==1 && get(handles1.outfile,'Value')==0
   set(handles1.outscreen,'Value',1)
elseif hObject==handles1.outfile && get(handles1.outscreen,'Value')==0 && get(handles1.outfile,'Value')==0
   set(handles1.outfile,'Value',1)
end
        
if hObject==handles1.outimg && get(handles1.outimg,'Value')==1
   set(handles1.outsaveimg,'Enable','on')
   set(handles1.outshowmesh,'Enable','on')
elseif hObject==handles1.outimg && get(handles1.outimg,'Value')==0
   set(handles1.outsaveimg,'Enable','off')
   set(handles1.outsaveimg,'Value',0)
   set(handles1.outshowmesh,'Enable','off')
   set(handles1.outshowmesh,'Value',0)
end

end  %checkchange()

function stoprun(hObject, eventdata)

set(handles1.run,'Style','pushbutton','String','Run','Callback',@run_cbk);
set(handles1.adjustbtn,'Style','pushbutton','String','Adjust','Callback',@run_cbk);
set(handles1.range1,'Enable','on')
set(handles1.range2,'Enable','on')
set(handles1.cellRange1,'Enable','on')
set(handles1.cellRange2,'Enable','on')
if isfield(handles1,'fig')&&ishandle(handles1.fig), delete(handles1.fig); end
end  %stoprun()

function stop_cbk(hObject, eventdata)
disp('Exiting adjust mode.');
if ishandle(handles1.spotFinderPanel), set(handles1.spotFinderPanel,'UserData',0); end
stoprun();
end  %stop_cbk()

function next_cbk(hObject, eventdata)
set(handles1.spotFinderPanel,'UserData',1);
end

function prev_cbk(hObject, eventdata)
set(handles1.spotFinderPanel,'UserData',-1);
end

function help_cbk(hObject, eventdata)
% % % folder = fileparts(which('spotFinderZ.m'));
% % % w = fullfile2(folder,'help.htm');
% % % if ~isempty(w), web(w); end
web('http://www.oufti.org/quickstart.htm');

end

function postFitProcessing(hObject,eventdata)
    
    fillPostProcessVariables();
  
end
 
%--------------------------------------------------------------------------------
function run_cbk(hObject, eventdata)
global  spotlist lst rawS1Data rawS2Data cellList signalData p
trainOnRange;
try
    warning('off','MATLAB:load:variableNotFound');
catch
end
%------------------------------------------------
%November 26, 2012
%Ahmad.P
%updates params structure with parameters
%values from the gui window.
if isfield(handles1,'spotParams')
   handles1.scale.String = num2str(handles1.spotParams.scale);
   handles1.spotRadius.String = num2str(handles1.spotParams.spotRadius);
   handles1.lowPass.String = num2str(handles1.spotParams.lowPass);
   handles1.minRegionSize.String = num2str(handles1.spotParams.minRegionSize);
   handles1.int_threshold.String = num2str(handles1.spotParams.int_threshold);
   handles1.fitRadius.String = num2str(handles1.spotParams.fitRadius);
   if isfield(handles1.spotParams,'postMinWidth') && ishandle(handles1.spotParams)
       handles1.postMinWidth.String = num2str(handles1.spotParams.postMinWidth);
   end
   if isfield(handles1.spotParams,'postMaxWidth')&& ishandle(handles1.spotParams)
       handles1.postMaxWidth.String = num2str(handles1.spotParams.postMaxWidth);
   end
   if isfield(handles1.spotParams,'postMinHeight')&& ishandle(handles1.spotParams)
       handles1.postMinHeight.String = num2str(handles1.spotParams.postMinHeight);
   end 
   if isfield(handles1.spotParams,'postError')&& ishandle(handles1.spotParams)
       handles1.postError.String = num2str(handles1.spotParams.postError);
   end 
end
params = getParameters(handles1,params);
handles1.spotParams = params;
%------------------------------------------------
if hObject==handles1.adjustbtn
   adjustmode = true;
   resizefcn();
   set(handles1.run,'Style','pushbutton','String','Next','Callback',@next_cbk);
   set(handles1.adjustbtn,'Style','pushbutton','String','Previous','Callback',@prev_cbk);
   set(handles1.range1,'Enable','off')
   set(handles1.range2,'Enable','off')
   set(handles1.cellRange1,'Enable','off')
   set(handles1.cellRange2,'Enable','off')
else
   adjustmode = false;
end

% Ask to input images and meshes
disp(' ')
if isempty(rawS1Data) || size(rawS1Data,3) == sum(cellfun('isempty',cellList.meshData))
    imageChoice = 'No';
else
    imageChoice = questdlg('Would you like to use present data and image files?',...
                        'Use current or new dataset','Yes','No','No');
end
switch imageChoice
    case 'No'
         if get(handles1.loadstack,'Value')
            if bformats
                [filename,pathname] = uigetfile('*.*','Select file with signal images',spotFinderImageFile);
            else
                [filename,pathname] = uigetfile({'*.tif';'*.tiff'},'Select file with signal images',spotFinderImageFile);
            end
            if isempty(filename)||isequal(filename,0), stoprun(); return; end
            spotFinderImageFile = fullfile2(pathname,filename);
            [~,signalData] = loadimagestack(3,spotFinderImageFile,1,0);
            firstFolder = fileparts(spotFinderImageFile);
         else
            folder = uigetdir(spotFinderImageFile,'Select folder with signal images');
            if isempty(folder)||isequal(folder,0), stoprun(); return, end
            signalData = loadimageseries(folder,1);
            spotFinderImageFile = folder;
            firstFolder = fileparts(spotFinderImageFile); 
         end
         pause(0.05);
         %java.lang.Thread.sleep(1000);  %wait one second 
         try
            [FileName,PathName] = uigetfile2('*.mat','Select file with signal meshes',firstFolder);
        catch ME
            ME.stack;
            stoprun();
        end
        if isempty(FileName)||isequal(FileName,0), stoprun; return, end
        signalMeshFileName = [PathName '/' FileName];
        try
            l = load(signalMeshFileName,'cellList','spotParams');
            if isfield(l,'cellList')
                cellList = l.cellList;
            end
            if isfield(l,'spotParams')
               handles1.spotParams = l.spotParams;
               handles1.scale.String = num2str(handles1.spotParams.scale);
               handles1.spotRadius.String = num2str(handles1.spotParams.spotRadius);
               handles1.lowPass.String = num2str(handles1.spotParams.lowPass);
               handles1.minRegionSize.String = num2str(handles1.spotParams.minRegionSize);
               handles1.int_threshold.String = num2str(handles1.spotParams.int_threshold);
               handles1.fitRadius.String = num2str(handles1.spotParams.fitRadius);
               if isfield(handles1.spotParams,'postMinWidth')
                   handles1.postMinWidth.String = num2str(handles1.spotParams.postMinWidth);
               end
               if isfield(handles1.spotParams,'postMaxWidth')
                   handles1.postMaxWidth.String = num2str(handles1.spotParams.postMaxWidth);
               end
               if isfield(handles1.spotParams,'postMinHeight')
                   handles1.postMinHeight.String = num2str(handles1.spotParams.postMinHeight);
               end 
               if isfield(handles1.spotParams,'postError')
                   handles1.postError.String = num2str(handles1.spotParams.postError);
               end 
                
            end
            
        catch ME
            ME.stack;
            stoprun();
        end            
    case 'Yes'
       
            signalChoice = questdlg('Signal1 or Signal2?',...
                        'which signal?','Signal1','Signal2','Signal1');
                switch signalChoice
                    case 'Signal1'
                        signalData = rawS1Data;
                        if isempty(signalData(:,:,1)),disp('make sure Signal1 is loaded'); return;end
                    case 'Signal2'
                        signalData = rawS2Data;
                        if isempty(signalData(:,:,1)),disp('make sure Signal2 is loaded'); return;end
                end
end
if ~isfield(cellList,'meshData'), cellList = oufti_makeNewCellListFromOld(cellList);end

params = getParameters(handles1,params);
handles1.spotParams = params;
outimg = get(handles1.outimg,'Value');
saveImg = get(handles1.outsaveimg,'Value') && get(handles1.outimg,'Value');
showMesh = get(handles1.outshowmesh,'Value') && get(handles1.outimg,'Value');
outfile = get(handles1.outfile,'Value') && get(handles1.outmesh,'Value');
outscreen = get(handles1.outscreen,'Value') && get(handles1.outmesh,'Value');
outfield = get(handles1.outfield,'String');
L1 = size(signalData,3);

try        
if length(cellList.meshData)>size(signalData,3), cellList.meshData = cellList.meshData(1:size(signalData,3)); end
if length(cellList.meshData)<size(signalData,3), for i=length(cellList.meshData):size(signalData,3), cellList.meshData{i}=[]; end; end
catch ME
    ME.stack
    disp('cellList is empty, try loading non-empty cellList');
    stoprun();
end

% Asking for image names if images need to be saved
if saveImg && ~adjustmode
   choice = questdlg('Would you like to save images as a stack?',...
                     'Image Type','Yes','No','No');
   switch choice
          case 'No'
              [FileName,pathname] = uiputfile('*.tif', 'Enter a filename for the first image',fileparts(signalMeshFileName));
              if(FileName==0), stoprun(); return; end;
              if length(FileName)>4 && strcmp(FileName(end-3:end),'.tif'), FileName = FileName(1:end-4); end
              lng = size(signalData,3);
              ndig = ceil(log10(lng+1));
              istart = 1;
              for k=1:ndig
                  if length(FileName)>=k && ~isempty(str2double(FileName(end-k+1:end)))
                     istart = str2double(FileName(end-k+1:end));
                  else
                     k=k-1; %#ok<FXSET>
                     break
                  end
               end
               outFileNameImg = [pathname, '/', FileName(1:end-k)];
           case 'Yes'
               [FileName,pathname] = uiputfile('*.tif', 'Enter a filename for the stack image',fileparts(signalMeshFileName));
               if(FileName==0), stoprun; return; end;
               if length(FileName)>4 && strcmp(FileName(end-3:end),'.tif'), FileName = FileName(1:end-4); end
               outFileNameImg = [pathname, '/', FileName(1:end)];
    end
end
        
% Ask for the output file name
if outfile
    [FileName,PathName] = uiputfile('*.mat', 'Enter a filename to save the mesh to',signalMeshFileName);
    targetMeshFileName = [PathName '/' FileName];
end

% Get frame range
if trainOnRange % && adjustmode
   cellRange1 = str2num(get(handles1.cellRange1,'String'));
   cellRange2 = str2num(get(handles1.cellRange2,'String'));
   range1 = str2num(get(handles1.range1,'String'));
   if isempty(range1), range1 = 1; end
   range2 = str2num(get(handles1.range2,'String'));
   if isempty(range2), range2 = L1; end
else
   range1 = 1;
   range2 = L1;
   cellRange1 = str2num(get(handles1.cellRange1,'String'));
   cellRange2 = str2num(get(handles1.cellRange2,'String'));
end
framerange = [];
for r = range1:range2
    if r<=length(cellList.meshData) && ~isempty(cellList.meshData{r}),framerange = [framerange r]; end
end
if isempty(framerange), return; end
%-----------------------------------------------------------------------------------
%November 28, 2012.
%Ahmad.P
try
warning off
w = imageFilterAndDisplay(framerange,cellRange1,cellRange2,adjustmode,outfile, ...
                      outscreen,outfield,params,L1,signalData);
catch err
          for ii = 1:length(err.stack)
      disp(['Error in ' err.stack(ii).file ' in line ' num2str(err.stack(ii).line)])
      end
      disp(['Error Message:' err.message])
end      
%-----------------------------------------------------------------------------------

% Displaying and saving images
if outimg==1 && ~adjustmode
   tempCellRange1 = cellRange1;
   tempCellRange2 = cellRange2;
   for frame=framerange
       figure
       if isempty(tempCellRange1), cellRange1 = 1; end
       if isempty(tempCellRange2), cellRange2 = size(cellList.meshData{frame},2); end 
       img = uint16(signalData(:,:,frame));
       imshow(img,[])
       %img2 = img*0;
       if exist('cellList','var')==1
          mgn = [];
          xpos = [];
          ypos = [];
          str = []; 
          for cell = cellRange1:cellRange2
              cellNum = cellList.cellId{frame}(cell);
              cellPositionInFrame = oufti_cellId2PositionInFrame(cellNum,frame,cellList);
              if  oufti_doesCellStructureHaveMesh(cellNum,frame,cellList) && isfield(cellList.meshData{frame}{cell},outfield)
                  eval(['str = cellList.meshData{frame}{cellPositionInFrame}.' outfield ';']);
                  xpos = [xpos str.x];
                  ypos = [ypos str.y];
               end
           end
           if max(mgn)>1, mgn=mgn/max(mgn); end
           hold on
           if showMesh
              for cell = cellRange1:cellRange2
                  cellNum = cellList.cellId{frame}(cell);
                  cellPositionInFrame = oufti_cellId2PositionInFrame(cellNum,frame,cellList);
                  if oufti_doesCellStructureHaveMesh(cellNum,frame,cellList)
                     mesh = cellList.meshData{frame}{cellPositionInFrame}.mesh;
                     color = [0 1 0];
                     plot(mesh(:,1),mesh(:,2),mesh(:,3),mesh(:,4),'Color',color)
                     e = round(size(mesh,1)/2);
                     text(double(round(mean([mesh(e,1);mesh(e,3)]))),double(round(mean([mesh(e,2);mesh(e,4)]))), ...
                     num2str(cellNum),'HorizontalAlignment','center','FontSize',7,'color',color);
                   end
               end
            end
            for i=1:length(mgn)
                %img2(min(size(img,1),max(1,round(ypos(i)))),min(size(img,2),max(1,round(xpos(i))))) = mgn(i)*intmax(class(img));
                plot(xpos(i),ypos(i),'.','color',[abs(mgn(i)) 0 1-abs(mgn(i))],'markersize',15)
            end
            hold off
       end
       warning off
       title(['Image ' num2str(frame) ' of ' num2str(L1)])
       if saveImg
          if strcmp(choice,'No')
             fnum = frame+istart-1;
             cfilename = [outFileNameImg num2str(fnum,['%.' num2str(ndig) 'd']) '.tif'];
             imwrite(img2,cfilename,'tif','Compression','none');
             else
             cfilename = [outFileNameImg '.tif'];
             imwrite(img2,cfilename,'tif','Compression','none','WriteMode','append');
           end
        end
        warning on
   end
end

% Saving data
if outscreen,assignin('base','cellList',cellList); disp('Data was written to cellList array');end
if outfile
   if ~strcmp(signalMeshFileName,targetMeshFileName) && ~isempty(signalMeshFileName)
       copyfile(signalMeshFileName,targetMeshFileName,'f');
   end
   spotParams = params;
   if exist(targetMeshFileName,'file')
       save(targetMeshFileName,'spotParams','cellList','p','-append')
   else
       save(targetMeshFileName,'spotParams','cellList','p');
   end
   disp(['Data was saved to ' num2str(targetMeshFileName)]);
end
delete(w); pause(0.05);

        
% Nested functions

function h=createfigure
h.fig = figure('WindowButtonDownFcn',@selectclick,'KeyPressFcn',@figurekeypress,'CloseRequestFcn',@figureclosereq);
% g = get(h.fig,'children');
% delete(g);
% h.ax = axes;
s = get(h.fig,'pos');
s = [s(1:2)-round(s(3:4)/2)-200 400 400];
set(h.fig,'pos',s)
end

function figureclosereq(hObject, eventdata)
delete(h.fig);
stop_cbk(hObject, eventdata)
end

function figurekeypress(hObject, eventdata)
c = get(h.fig,'CurrentCharacter');
if isempty(c)
   return;
elseif double(c)==28 % left arrow - go to previous cell
       set(handles1.spotFinderPanel,'UserData',-1);
elseif double(c)==29 % right arrow - go to next cell
       set(handles1.spotFinderPanel,'UserData',1);
elseif double(c)==27 % ESC - stop
       set(handles1.spotFinderPanel,'UserData',0);
       stoprun();
end
end

function selectclick(hObject, eventdata)
if ~ishandle(imageHandle.fig) ||  ~ishandle(imageHandle.ax) || isempty(spotlist), return; end
   ps = get(imageHandle.ax,'CurrentPoint');
   xlimit = get(imageHandle.ax,'XLim');
   ylimit = get(imageHandle.ax,'YLim');
   x = ps(1,1);
   y = ps(1,2);
   if x<xlimit(1) || x>xlimit(2) || y<ylimit(1) || y>ylimit(2), return; end
   dst = (y-spotlist(:,8)).^2+(x-spotlist(:,9)).^2;
   [mindst,minind] = min(dst);
   if mindst>mean(xlimit(2)-xlimit(1),ylimit(2)-ylimit(1))^2/10, return; end
   lst(minind) = ~lst(minind);
   handles1.spotList{frame}{cell}.lst(minind) = lst(minind);
   if lst(minind)
       set(imageHandle.spots(minind),'Color',[1 0.1 0]);
       disp('Selected spot:')
   else
       set(imageHandle.spots(minind),'Color',[0 0.8 0]);
       disp('Unselected spot:')
   end
   spotlist = handles1.spotList{frame}{cell}.spotlist;
   disp([' background: ' num2str(spotlist(minind,1))])
   disp([' squared width: ' num2str(spotlist(minind,2))])
   disp([' height: ' num2str(spotlist(minind,3))])
   disp([' relative squared error: ' num2str(spotlist(minind,4))])
   disp([' perimeter variance: ' num2str(spotlist(minind,5))])
   disp([' filtered/unfiltered ratio: ' num2str(spotlist(minind,6))])
end %function selectclick()


end %function run_cbk()
%

end

%% Global functions
function fillPostProcessVariables
global params 
  %%%stoprun();
    params = postProcessingParamWindow(params);
    

end

function resizefcn(hObject, eventdata)
global handles1 handles 
c = get(handles.maingui,'CurrentCharacter');
set(handles1.stop,'pos',[5 40 125 22],'Visible','on');
set(handles1.postProcessButton,'pos',[135 40 125 22],'Visible','on');
screenSize = get(0,'ScreenSize');
pos = get(handles.maingui,'position');
pos = [max(pos(1),1) max(1,min(pos(2),screenSize(4)-20-max(pos(4),600))) max(pos(3:4),[1000 600])];
if strcmp(c,'+') || ishandle(handles1.adjustbtn)
set(handles1.spotFinderPanel,'pos',[pos(3)-1000+725 pos(4)-800+445 272 310]);
set(handles1.parameterPanel,'pos',[135 90 130 175]);
set(handles1.outputpanel,'pos',[5 90 120 175]);
set(handles1.helpbtn,'pos',[5 270 50 20]);
set(handles1.multGauss,'pos',[65 270 80 20]);
set(handles1.loadstack,'pos',[155 270 50 20]);
set(handles1.filtWin,'pos',[210,270,50,20]);
set(handles1.adjustbtn,'pos',[5 65 125 22]);
set(handles1.run,'pos',[135 65 125 22]);
% % % set(handles1.GAU,'pos',[225 270 42 20]);
else
% resizes the main program window

set(handles1.spotFinderPanel,'pos',[pos(3)-1000+725 pos(4)-800+485 272 250])
end
end

function [d,e] = uigetfile2(a,b,c)
    f=true;
    while f
        try
            [d,e] = uigetfile(a,b,c);
            f=false;
        catch
% % %             pause(0.01)
            java.lang.Thread.sleep(1000);  %wait one second 
            f=true;
        end
    end
end

function dangle = cellangle(mesh1,mesh2)
    angle1 = angle(mesh1(1,1)-mesh1(end,1)+1i*(mesh1(1,2)-mesh1(end,2)));
    angle2 = angle(mesh2(1,1)-mesh2(end,1)+1i*(mesh2(1,2)-mesh2(end,2)));
    dangle = abs(mod(angle1-angle2+pi,2*pi)-pi);
end



function B = im2double2(A)
    B = zeros(size(A),'double');
    for i=1:size(A,3)
        B(:,:,i) = im2double(A(:,:,i));
    end
end


