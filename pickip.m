function varargout = pickip(varargin)
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @pickip_OpeningFcn, ...
                   'gui_OutputFcn',  @pickip_OutputFcn, ...
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

function pickip_OpeningFcn(hObject, eventdata, handles, varargin)
handles.output = '';
ipmat = load('ips.mat');
set(handles.listbox1,'string',ipmat.ips);
guidata(hObject, handles);

set(handles.figure1,'WindowStyle','modal')

uiwait(handles.figure1);

function varargout = pickip_OutputFcn(hObject, eventdata, handles)
varargout{1} = handles.output;

delete(handles.figure1);

function pushbutton1_Callback(hObject, eventdata, handles)
cells = cellstr(get(handles.listbox1,'String'));
val = get(handles.listbox1,'Value');
strip = cells{val};
handles.output = strip;

guidata(hObject, handles);

uiresume(handles.figure1);

function pushbutton2_Callback(hObject, eventdata, handles)
uiresume(handles.figure1);

function figure1_CloseRequestFcn(hObject, eventdata, handles)
if isequal(get(hObject, 'waitstatus'), 'waiting')
    uiresume(hObject);
else
    delete(hObject);
end


function figure1_KeyPressFcn(hObject, eventdata, handles)
if isequal(get(hObject,'CurrentKey'),'escape')    
    uiresume(handles.figure1);
end    
    
if isequal(get(hObject,'CurrentKey'),'return')
    uiresume(handles.figure1);
end    

function listbox1_Callback(hObject, eventdata, handles)

function listbox1_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
