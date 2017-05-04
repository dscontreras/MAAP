function varargout = error_gui(varargin)
% ERROR_GUI MATLAB code for error_gui.fig
%      ERROR_GUI, by itself, creates a new ERROR_GUI or raises the existing
%      singleton*.
%
%      H = ERROR_GUI returns the handle to a new ERROR_GUI or the handle to
%      the existing singleton*.
%
%      ERROR_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in ERROR_GUI.M with the given input arguments.
%
%      ERROR_GUI('Property','Value',...) creates a new ERROR_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before error_gui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to error_gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help error_gui

% Last Modified by GUIDE v2.5 26-Apr-2017 17:17:22

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @error_gui_OpeningFcn, ...
                   'gui_OutputFcn',  @error_gui_OutputFcn, ...
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


% --- Executes just before error_gui is made visible.
function error_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to error_gui (see VARARGIN)

%Set error message to the correct error
error_msg = getappdata(0, 'error_msg');

set(handles.error_tag, 'String', error_msg);

% Choose default command line output for error_gui
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes error_gui wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = error_gui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
