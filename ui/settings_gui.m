function varargout = settings_gui(varargin)
% SETTINGS_GUI MATLAB code for settings_gui.fig
%      SETTINGS_GUI, by itself, creates a new SETTINGS_GUI or raises the existing
%      singleton*.
%
%      H = SETTINGS_GUI returns the handle to a new SETTINGS_GUI or the handle to
%      the existing singleton*.
%
%      SETTINGS_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SETTINGS_GUI.M with the given input arguments.
%
%      SETTINGS_GUI('Property','Value',...) creates a new SETTINGS_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before settings_gui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to settings_gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help settings_gui

% Last Modified by GUIDE v2.5 16-Jun-2017 15:12:53

% Begin initialization code - DO NOT EDIT

gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @settings_gui_OpeningFcn, ...
                   'gui_OutputFcn',  @settings_gui_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   [] , ...
                   'browse_button', @browse_button_Callback);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before settings_gui is made visible.
function settings_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to settings_gui (see VARARGIN)

% Checks if user chose a template previously
img_path = getappdata(0, 'img_path');
if ~strcmp(img_path, '')
    set(handles.selected_file, 'String', img_path);
end

% Checks if user defined a default path previously
folder_path = getappdata(0, 'sys_start_path');
if ~strcmp('sys_start_path', '/Users/')
    set(handles.path_folder, 'String', folder_path);
end

% Choose default command line output for settings_gui
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);


% UIWAIT makes settings_gui wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = settings_gui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function start_path_edit_Callback(hObject, eventdata, handles)
% hObject    handle to start_path_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of start_path_edit as text
%        str2double(get(hObject,'String')) returns contents of start_path_edit as a double


% --- Executes during object creation, after setting all properties.
function start_path_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to start_path_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in start_path_submit.
%Brief: Assign a new start path to application data to be used when
%constructing file system parsers
function start_path_submit_Callback(btn, eventdata, handles)
% hObject    handle to start_path_submit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%Retrieve the new start path value from the start path editable box
new_start_path = get(handles.start_path_edit, 'String');
%Store the new start path value as sys_start_path in the application data
setappdata(0, 'sys_start_path', new_start_path);

% --- Executes on button press in browse_files.
function browse_files_Callback(hObject, eventdata, handles)
% hObject    handle to browse_files (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
foldername = uigetdir;
if foldername ~= 0
    %Store the new start path value as sys_start_path in the application data
    setappdata(0, 'sys_start_path', foldername);
    set(handles.path_folder, 'String', foldername);
else
    setappdata(0, 'sys_start_path', '/Users/');
    set(handles.selected_file, 'String', '/Users/');
end

% --- Executes on button press in browse_button.
function browse_button_Callback(hObject, eventdata, handles)
% hObject    handle to browse_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
filename = uigetfile({'*.png'; '*.jpg'; '*.jpeg'; '*.gif'; '*.tiff'}, 'Select an image');
if filename ~= 0
    setappdata(0, 'img_path', filename);
    set(handles.selected_file, 'String', filename);
else
    setappdata(0, 'img_path', '');
    set(handles.selected_file, 'String', 'No file selected');
end

% --- Executes during object creation, after setting all properties.
function selected_file_CreateFcn(hObject, eventdata, handles)
% hObject    handle to selected_file (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

function browse_button_CreateFcn(hObject, eventdata, handles)
% hObject    handle to browse_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

function browse_button_DeleteFcn(hObject, eventdata, handles)
% hObject    handle to browse_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
