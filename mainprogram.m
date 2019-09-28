function varargout = mainprogram(varargin)
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @mainprogram_OpeningFcn, ...
                   'gui_OutputFcn',  @mainprogram_OutputFcn, ...
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


function mainprogram_OpeningFcn(hObject, eventdata, handles, varargin)
handles.output = hObject;

% initiate custom variables
handles.tcpobj = [];
handles.data = [];
handles.counter = 0;

% initiate user data
set(handles.btnOpenCon,'enable','on');
set(handles.btnCloseCon,'enable','off');
color1 = get(handles.edtConStatus,'backgroundcolor');
color2 = [.7 .9 .7];

% parameters of tcp/ip reading
max_image_size = 500;
color_channels = 3;
bytes_num_of_integer = 4;
progress_size = max_image_size*max_image_size*color_channels*bytes_num_of_integer;
step_count = 10;
step_size = progress_size/step_count;

% gui data stored
handles.progress_size = progress_size;
handles.step_count = step_count;
handles.step_size = step_size;

% save user data
set(handles.edtConStatus,'UserData',struct('color1',color1,...
                                           'color2',color2,...
                                           'counter',1,...
                                           'stepsize',step_size,...
                                           'flagprocess',0,...
                                           'data',[]));

% display tcp/ip connection status: first time, connection is still closed
set(handles.edtConStatus,'String','Connection Status: closed');

% display ip address of current computer where matlab is run
[a,b,c] = computerInfo;
if(strcmp(c,'127.0.0.1')) 
    c = ' Localhost, not connected';
end
set(handles.edtCompIP,'String',c);

% check previously input ip's
ise = exist('ips.mat','file');
if(ise == 2)
    set(handles.btnPickIP,'enable','on');
else
    set(handles.btnPickIP,'enable','off');
end
% Update handles structure
guidata(hObject, handles);

% UIWAIT makes mainprogram wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = mainprogram_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

function edtAndroidIP_Callback(hObject, eventdata, handles)


function edtAndroidIP_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function edtCompIP_Callback(hObject, eventdata, handles)


function edtCompIP_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function edtPortNumber_Callback(hObject, eventdata, handles)

function edtPortNumber_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function btnOpenCon_Callback(hObject, eventdata, handles)
% check IP and Port
ipStr = get(handles.edtAndroidIP,'String');
port = str2num(get(handles.edtPortNumber,'String'));

% if IP or Port is empty then display message
if(isempty(ipStr) || isempty(port))
    errordlg('Both IP and port cannot be empty','Setting Error');
    return;
end

% save ip to ips.mat
ipandro = get(handles.edtAndroidIP,'string');
if(exist('ips.mat','file')==2)
    ipmat = load('ips.mat');
    ips = ipmat.ips;
    flag = 0;
    for i=1:length(ips)
        if(strcmp(ips{i},ipandro)==1)
            flag = 1;
            break
        end
    end
    if(flag==0)
        ips{length(ips)+1} = ipandro;
        save ips.mat ips;
    end
else
    ips{1} = ipandro;  
    save ips.mat ips;
end
set(handles.btnPickIP,'enable','on');
drawnow;

% setup tcpip object...
handles.tcpobj = tcpip(ipStr,port);

% act as a Server
set(handles.tcpobj,'NetworkRole','server');
% same as in Android setting, but multiplied by 4 because Android sends as
% integer, and Matlab reads as byte (1 integer = 4 bytes)
% max width of Bitmap x max height of Bitmap x 3 color channels x 4
set(handles.tcpobj,'InputBufferSize',handles.progress_size);

% mode
set(handles.tcpobj,'ReadAsyncMode','continuous');
set(handles.tcpobj,'BytesAvailableFcnMode','byte');
% read every (75000 x 4) available integer so totally, Matlab will do fread 
% 10 times
set(handles.tcpobj,'BytesAvailableFcnCount',handles.step_size);
% set the bytes available callback
set(handles.tcpobj,'BytesAvailableFcn',{@tcpbytesavailfcn,...
                                            handles.edtConStatus,...
                                            handles.axes1,hObject,...
                                            handles.btnCloseCon,...
                                            handles.chk1,...
                                            handles.table});
% set the error callback
set(handles.tcpobj,'ErrorFcn',@tcpbyteserrorfcn);
% % get userdata
% datauser = get(handles.edtConStatus,'UserData');
% datauser.tcpobj = handles.tcpobj;
% set(handles.edtConStatus,'UserData',datauser);

% update GUI handles
guidata(handles.figure1,handles);

% connection status is now waiting for android to connect...
set(handles.edtConStatus,'String','Connection Status: waiting for connection...');
set(handles.btnCloseCon,'enable','on');
set(handles.btnOpenCon,'enable','off');

% immediately refresh UI layout
drawnow;

% open tcpip object, this will enable android to connect to Matlab...
fopen(handles.tcpobj);
% readasync(handles.tcpobj);

% connection status is now connected
set(handles.edtConStatus,'String',['Connection Status: connected to: ' ipStr]);
drawnow;

function btnCloseCon_Callback(hObject, eventdata, handles)

% close tcp object
if(~isempty(handles.tcpobj))
    if(strcmp(get(handles.tcpobj,'Status'),'open'))
        fclose(handles.tcpobj);    
    end
end

% enable open button, disable close button, set status to closed
set(handles.btnCloseCon,'enable','off');
set(handles.btnOpenCon,'enable','on');
set(handles.edtConStatus,'String','Connection Status: closed');

function figure1_CloseRequestFcn(hObject, eventdata, handles)
if(~isempty(handles.tcpobj))
    if(isobject(handles.tcpobj))
        if(strcmp(get(handles.tcpobj,'Status'),'open'))
%             stopasync(handles.tcpobj);
            fclose(handles.tcpobj);
        end
        delete(handles.tcpobj);
        clear handles.tcpobj
    end
end
delete(hObject);

function edtConStatus_Callback(hObject, eventdata, handles)

function edtConStatus_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function btnPickIP_Callback(hObject, eventdata, handles)
ip = pickip;
if(isempty(ip))
    return
end
set(handles.edtAndroidIP,'string',ip);

function [userName, hostName, ipAddress] = computerInfo()
h = java.net.InetAddress.getLocalHost();
hostName = char(h.getHostName());
ipAddress = char(h.getHostAddress().toString());
switch computer
    case {'GLNX86','GLNXA64','MACI','MACI64'}
        userName = getenv('USER');
    case {'PCWIN','PCWIN64'}
        userName = getenv('USERNAME');
    otherwise
        throw(MException('computerInfo:UnsupportedArchitecture', computer));
end

function tcpbytesavailfcn(hObject,eventdata,hs,hx,hbo,hbc,hck,htbl)
% ------------------------------------------------------------------
% hObject = handle of TCP/IP Object
% hs      = handle of StatusBar Object
% hx      = handle of axes
% hbo     = handle of button open connection
% hbc     = handle of button close connection
% hck     = handle of checkbox display rectangle
% htbl    = handle of table list to write intensities value
% all custom variables are stored in StatusBar's UserData
% ------------------------------------------------------------------
% userdata
EventDataTime = eventdata.Data.AbsTime;
userdata = get(hs,'UserData');
data = userdata.data;
flag = userdata.flagprocess;
color1 = userdata.color1;
color2 = userdata.color2;
stepsize = userdata.stepsize;
counter = userdata.counter;
tcpobj = hObject; %userdata.tcpobj;
if(get(hObject,'BytesAvailable')>0) 
    sz = stepsize/4;
    a = fread(hObject,sz,'int32'); 
    counter1 = counter;
    counter2 = counter+sz;
    if(a(1)==998)
        % this is the start
        set(hs,'String','Status: Receiving data...','backgroundcolor',color2); 
        drawnow;
        flag = 1;        
        data(counter1:(counter2-1)) = a;
    elseif(a(1)==9999)
        % request to close connection from Android
%         stopasync(tcpobj);
        fclose(tcpobj);
        set(hbo,'enable','on');
        set(hbc,'enable','off');
        set(hs,'string','Connection Status: closed');
        drawnow;
        return;
    else
        if flag == 1
            iterminator = find(a==999);
            if(~isempty(iterminator))
                % this is when we reach the terminator                
                set(hs,'String','Processing image...');
                drawnow;
                data(counter1:(counter1+iterminator-1)) = a(1:iterminator);
                imgdata = data(4:length(data)-1);
                w = data(2);
                h = data(3);
                dtr = reshape(imgdata,3,w*h);
                dtr1 = reshape(dtr(1,:),w,h)';
                dtr2 = reshape(dtr(2,:),w,h)';
                dtr3 = reshape(dtr(3,:),w,h)';
                img = zeros(h,w,3);
                img(:,:,1) = dtr1;
                img(:,:,2) = dtr2;
                img(:,:,3) = dtr3;
                img = uint8(img);
                % do Image Processing to detect the chemical glass objects
                % and calculate the intensity of each chemical glass
                intensities = process_image(img,hck,hx);
                set(htbl,'Data',intensities);
                % send intensity values back to Android
                send_intensity(tcpobj,intensities);
                % update UI
                set(hs,'String',['Status: Last data received on ' datestr(EventDataTime,13)],'backgroundcolor',color1);
                drawnow;  
                % save data to database
                savedata(intensities);
                % clear all variables
                flag = 0;
                counter = 1;
                data = []; 
                set(hs,'UserData',struct('color1',color1,...
                                         'color2',color2,...
                                         'counter',counter,...
                                         'stepsize',stepsize,...
                                         'flagprocess',flag,...
                                         'data',data));
                
            else
                % this is when we still have to store the data
                data(counter1:(counter2-1)) = a;
            end
        else
            % flag == 0, do nothing
        end           
    end
    if flag == 1
        counter = counter2;
        set(hs,'UserData',struct('color1',color1,...
                                 'color2',color2,...
                                 'counter',counter,...
                                 'stepsize',stepsize,...
                                 'flagprocess',flag,...
                                 'data',data));
    else
        % do nothing if we already reached terminator
    end
    
end

function tcpbyteserrorfcn(hObject,eventdata)
errordlg(eventdata.Data.Message,'Error');

function pushbutton4_Callback(hObject, eventdata, handles)
c = imread('chemical_glasses_image.jpg');
intensities = process_image(c,handles.chk1,handles.axes1);
set(handles.table,'Data',intensities);

function chk1_Callback(hObject, eventdata, handles)

function send_intensity(tcpobj,intensities)
terminator = 999;
starter = 998;
if(isempty(tcpobj))
    return
end
if(isempty(intensities))
    fwrite(tcpobj,starter,'double');
    fwrite(tcpobj,terminator,'double');
    return
end
r = size(intensities,1);
c = size(intensities,2);
fwrite(tcpobj,starter,'double');
% send intensity values to Android
for i=1:r
    for j=1:c
        % send intensities per objects detected, per color channel
        fwrite(tcpobj,intensities(i,j),'double');
    end
end
fwrite(tcpobj,terminator,'double');

function savedata(intensities)
% compare chemical intensity value with the values in
% database
if(isempty(intensities))
    return
end
if(exist('database.mat','file'))
    % load existing database
    sdata = load('database.mat');
    save_data = sdata.save_data;
    rsave = size(save_data,1);
    rinten = size(intensities,1);
    % compare data in existing database with current
    % intensity
    flag = 0;
    for i=1:rinten
        if(flag==1)
            break
        end
        for j=1:rsave
            inten_save = save_data{j,2};
            inten_current = intensities(i,4);
            if(round(inten_save)==round(inten_current))
                msg = strcat(char(save_data{j,1}),' detected');
                msgbox(msg,'Chemical Detection','modal');
                flag = 1;
                break;
            end
        end
    end
    if(flag==0)
        % intensities values has not yet saved before
        % prompt saving option to user
        x = inputdlg('Input Chemical name',...
                     'Chemical Detection', [1 50]);
        if(isempty(x))
            return
        end
        for i=1:rinten
             % get the intensity of image (index 4 only)
            intens = intensities(i,4);
            % save the data in the order: 
            % [name1 intensity1]
            % [name2 intensity2] and so on
            save_data{rsave+i,1} = x;
            save_data{rsave+i,2} = intens;
        end
        save database.mat save_data;
    end
else
    % prompt saving option to user
    x = inputdlg('Input Chemical name',...
                 'Chemical Detection', [1 50]);
    if(isempty(x))
        return
    end
    rinten = size(intensities,1);
    % iterate for each object detected
    save_data = cell(rinten,2);
    for i=1:rinten
        % get the intensity of image (index 4 only)
        intens = intensities(i,4);
        % save the data in the order: 
        % [name1 intensity1]
        % [name2 intensity2] and so on
        save_data{i,1} = x;
        save_data{i,2} = intens;
    end
    save database.mat save_data;                    
end
