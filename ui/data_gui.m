function varargout = data_gui(varargin)
% DATA_GUI MATLAB code for data_gui.fig
%      DATA_GUI, by itself, creates a new DATA_GUI or raises the existing
%      singleton*.
%
%      H = DATA_GUI returns the handle to a new DATA_GUI or the handle to
%      the existing singleton*.
%
%      DATA_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in DATA_GUI.M with the given input arguments.
%
%      DATA_GUI('Property','Value',...) creates a new DATA_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before data_gui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to data_gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help data_gui

% Last Modified by GUIDE v2.5 11-May-2017 17:42:07

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @data_gui_OpeningFcn, ...
                   'gui_OutputFcn',  @data_gui_OutputFcn, ...
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

% --- Executes just before data_gui is made visible.
function data_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to data_gui (see VARARGIN)
% Choose default command line output for data_gui
handles.output = hObject;
addpath('operation')
clc;
global top_level;
global vid_height;
global vid_width;
global operation_queue;
global enabled_operations;
global current_operation;
global keymap;
keymap = containers.Map();
operation_queue = cell(0);
enabled_operations = {'Displacement', 'Stills', 'Voltage'};
vid_width = 1280;
vid_height = 1024;
top_level = true;
set(handles.trigger_panel, 'Visible', 'Off');
setappdata(0, 'maximum_displacement', -1);
setappdata(0, 'pixel_precision', -1);
setappdata(0, 'wait_status', 0);
setappdata(0, 'cam_name', '');
setappdata(0, 'outputfolderpath', [pwd FileSystemParser.get_file_separator() 'outputs']);
qpress = @q_press_handle;
map_keypress('q', qpress);
key_handle = @keypress_handle;
set(hObject, 'KeyPressFcn', key_handle);
% Update handles structure
guidata(hObject, handles);

% This sets up the initial plot - only do when we are invisible
% so window can get raised using data_gui.
%if strcmp(get(hObject,'Visible'),'off')
    %plot(rand(5));

% UIWAIT makes data_gui wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = data_gui_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on selection change in img_options.
%Brief: This function executes whenever there is a selection change within
%the video input selection listbox that doubles as a file system parser
function img_options_Callback(img_options, eventdata, handles)
% img_options    handle to img_options (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%Retrieve the current selection within the list box
value = ListboxOperations.get_current_selection(img_options);
src_type = '-1';
%Clear any errors displayed about invalid video selections
clear_error(handles.vid_error_tag);
%top_level is a boolean that indicates whether the listbox is at the top
%level of selections
global top_level; 
%parser is the FileSystemParser object, responsible for navigating the file
%system
global parser;
%Declare two variables vid_height and vid_width which keep the allowed
%frame size constant in the video player so multiple videos can be played
global vid_width;
global vid_height;

%If at the top level of the parsing system 
if(top_level)
    %Make the text to the side of the listbox about directly entering a
    %video source path visible, and also make visible the direct path entry
    %field
    set(handles.src_path_edit_tag, 'Visible', 'On');
    set(handles.src_path_edit, 'Visible', 'On');
    %and the selection is Pre-Recorded Video
    if(strcmp(value, 'Pre-Recorded Video'))
        %Make the text above the listbox about selecting a video visible
        set(handles.vid_select_tag, 'Visible', 'On');
        %Since we chose Pre-Recorded Video, we're going to go to a file
        %tree navigation now, and we are no longer at the top level
        top_level = false;
        %Construct the file system navigational tool, parser
        parser = FileSystemParser('');
        %Reset our listbox selection to the first element
        ListboxOperations.reset_selection(img_options);
        %Change the options contained within the listbox to the highest
        %level directory within the computer's filesystem
        ListboxOperations.change_options(img_options, parser.current_dir);
        %Make a button for returning to the top level of the selection tool
        item_toggle_visibility(handles.return_to_options);
        src_type = 'file';
        set(handles.stream_type, 'Value', 0.0);
        set(handles.file_type, 'Value', 1.0);
    %Value selected is stream
    else
        top_level = false;
        set(handles.stream_type, 'Value', 1.0);
        set(handles.file_type, 'Value', 0.0);
        src_type = 'stream';
        ListboxOperations.change_options(img_options, get_sys_cams());
    end
%Must be selecting an element in the filesystem or a camera
else 
    if(is_cam_name(value))
        src_type = 'stream';
        setappdata(0, 'cam_name', value);
    else
        %Assemble the full path of the element
        element_path = [parser.path, FileSystemParser.get_file_separator() value];
        %If that path leads to a folder
        if(FileSystemParser.is_folder(element_path))
            %go to the folder in the filesystem
            parser = parser.goto(value);
            %Reset our listbox selection to the first element
            ListboxOperations.reset_selection(img_options);
            %Change the listbox's options to now be the contents of the folder
            %just entered
            ListboxOperations.change_options(img_options, parser.current_dir);
        %If that path leads to a file
        elseif(FileSystemParser.is_file(element_path))
            %Get the indexes of . within the value selected in the listbox
            exts = strfind(value, '.');
            %Get the index of the . that is for the file extension
            extindex = exts(length(exts));
            %Get the value of the extension
            extension = value(extindex:end);
            %Declare a variable that stores whether the given extension is
            %supported for our purposes
            supported = false;
            %Retrieve a list of all the extensions that are supported for video
            supported_extensions = parser.get_supported_vid_formats();
            %Iterate through the supported extensions
            for i = 1:length(supported_extensions)
                %if the extension is an accepted extension
                if(strcmp(extension, supported_extensions(i))) 
                    supported = true;
                end
            end
            %Now that we know whether the file type is supported or not, if it
            %is supported
            if(supported)
                %Construct an object that reads the video
                src_type = 'file';
                setappdata(0, 'vid_path', parser.get_path(value));
            else
                %Print to the console that the video type is not supported
                disp('Error: VIDEO TYPE NOT SUPPORTED');
                %Display the error to the GUI as well
                disp_error('Error: VIDEO TYPE NOT SUPPORTED', handles.vid_error_tag);
            end
        end
    end
end
img_options.UserData = src_type;
%Save any changes we've made
guidata(img_options, handles);
%end

% Hints: contents = cellstr(get(hObject,'String')) returns img_options contents as cell array
%        contents{get(hObject,'Value')} returns selected item from img_options


% --- Executes during object creation, after setting all properties.
function img_options_CreateFcn(hObject, eventdata, handles)
% hObject    handle to img_options (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% --- Executes on button press in begin_preview.
function begin_preview_Callback(begin_preview, eventdata, handles)
% hObject    handle to begin_preview (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)




% --- Executes on button press in begin_capture.
%Brief: Begin capturing video from the input stream specified
%NOTE: At current, it just plays a sample video in the current directory
%TODO: Implement streaming functionality
function begin_capture_Callback(begin_capture, eventdata, handles)
%Construct a videoReader object that takes in a video file as input
videoReader = vision.VideoFileReader('sample_iTunes.mov');
%Step through that video and display it frame by frame on the GUI
while(~isDone(videoReader))
    frame = step(videoReader);
    showFrameOnAxis(handles.img_viewer, frame);
end


% hObject    handle to begin_capture (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles  structure with handles and user data (see GUIDATA)


% --- Executes on button press in displacement_check.
function displacement_check_Callback(displacement_switch, eventdata, handles)
% hObject    handle to displacement_check (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

toggle_visibility(displacement_switch, handles.displacement_panel);
%if we are measuring displacement
check_operations(handles.displacement_check, handles.capture_check, handles.voltage_check, handles);
guidata(displacement_switch, handles);
% Hint: get(hObject,'Value') returns toggle state of displacement_check

% --- Executes on selection change in input_type.
function input_type_Callback(input_type, eventdata, handles)
% hObject    handle to input_type (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns input_type contents as cell array
%        contents{get(hObject,'Value')} returns selected item from input_type


% --- Executes during object creation, after setting all properties.
function input_type_CreateFcn(input_type, eventdata, handles)
% hObject    handle to input_type (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(input_type,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(input_type,'BackgroundColor','white');
end



% --- Executes on selection change in listbox2.
function listbox2_Callback(hObject, eventdata, handles)
% hObject    handle to listbox2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns listbox2 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listbox2


% --- Executes during object creation, after setting all properties.
function listbox2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listbox2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end





function key_to_trigger_edit_trigger_Callback(hObject, eventdata, handles)
% hObject    handle to key_to_trigger_edit_trigger (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of key_to_trigger_edit_trigger as text
%        str2double(get(hObject,'String')) returns contents of key_to_trigger_edit_trigger as a double


% --- Executes during object creation, after setting all properties.
function key_to_trigger_edit_trigger_CreateFcn(hObject, eventdata, handles)
% hObject    handle to key_to_trigger_edit_trigger (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end





function frames_on_trigger_edit_trigger_Callback(hObject, eventdata, handles)
% hObject    handle to frames_on_trigger_edit_trigger (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of frames_on_trigger_edit_trigger as text
%        str2double(get(hObject,'String')) returns contents of frames_on_trigger_edit_trigger as a double


% --- Executes during object creation, after setting all properties.
function frames_on_trigger_edit_trigger_CreateFcn(hObject, eventdata, handles)
% hObject    handle to frames_on_trigger_edit_trigger (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end




function file_destination_edit_trigger_Callback(hObject, eventdata, handles)
% hObject    handle to file_destination_edit_trigger (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of file_destination_edit_trigger as text
%        str2double(get(hObject,'String')) returns contents of file_destination_edit_trigger as a double


% --- Executes during object creation, after setting all properties.
function file_destination_edit_trigger_CreateFcn(hObject, eventdata, handles)
% hObject    handle to file_destination_edit_trigger (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end




function time_between_frames_edit_trigger_Callback(hObject, eventdata, handles)
% hObject    handle to time_between_frames_edit_trigger (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of time_between_frames_edit_trigger as text
%        str2double(get(hObject,'String')) returns contents of time_between_frames_edit_trigger as a double


% --- Executes during object creation, after setting all properties.
function time_between_frames_edit_trigger_CreateFcn(hObject, eventdata, handles)
% hObject    handle to time_between_frames_edit_trigger (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function file_type_edit_trigger_Callback(hObject, eventdata, handles)
% hObject    handle to file_type_edit_trigger (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of file_type_edit_trigger as text
%        str2double(get(hObject,'String')) returns contents of file_type_edit_trigger as a double


% --- Executes during object creation, after setting all properties.
function file_type_edit_trigger_CreateFcn(hObject, eventdata, handles)
% hObject    handle to file_type_edit_trigger (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% --- Executes on button press in capture_check.
%Brief: This function executes when the checkbox under Still Selection is
%toggled
function capture_check_Callback(capture_check, eventdata, handles)
% hObject    handle to capture_check (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%Toggle the visibility of the still selection panel
%The still selection panel is a panel used for specifying settings for
%taking photos of a stream or a video
toggle_visibility(capture_check, handles.still_selection_panel);
check_operations(handles.displacement_check, handles.capture_check, handles.voltage_check, handles);
%Now save changes to the GUI
guidata(capture_check, handles);
% Hint: get(hObject,'Value') returns toggle state of capture_check


% --- Executes on button press in voltage_check.
function voltage_check_Callback(hObject, eventdata, handles)
% hObject    handle to voltage_check (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of voltage_check


% --- Executes during object creation, after setting all properties.
function img_viewer_CreateFcn(hObject, eventdata, handles)
% hObject    handle to img_viewer (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: place code in OpeningFcn to populate img_viewer


function maximum_displacement_edit_displacement_Callback(hObject, eventdata, handles)
% hObject    handle to maximum_displacement_edit_displacement (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: get(hObject,'String') returns contents of maximum_displacement_edit_displacement as text
%        str2double(get(hObject,'String')) returns contents of maximum_displacement_edit_displacement as a double


% --- Executes during object creation, after setting all properties.
function maximum_displacement_edit_displacement_CreateFcn(hObject, eventdata, handles)
% hObject    handle to maximum_displacement_edit_displacement (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function pixel_precision_edit_displacement_Callback(hObject, eventdata, handles)
% hObject    handle to pixel_precision_edit_displacement (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of pixel_precision_edit_displacement as text
%        str2double(get(hObject,'String')) returns contents of pixel_precision_edit_displacement as a double


% --- Executes during object creation, after setting all properties.
function pixel_precision_edit_displacement_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pixel_precision_edit_displacement (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function file_type_edit_frame_Callback(hObject, eventdata, handles)
% hObject    handle to file_type_edit_frame (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of file_type_edit_frame as text
%        str2double(get(hObject,'String')) returns contents of file_type_edit_frame as a double


% --- Executes during object creation, after setting all properties.
function file_type_edit_frame_CreateFcn(hObject, eventdata, handles)
% hObject    handle to file_type_edit_frame (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function destination_edit_frame_Callback(hObject, eventdata, handles)
% hObject    handle to destination_edit_frame (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of destination_edit_frame as text
%        str2double(get(hObject,'String')) returns contents of destination_edit_frame as a double


% --- Executes during object creation, after setting all properties.
function destination_edit_frame_CreateFcn(hObject, eventdata, handles)
% hObject    handle to destination_edit_frame (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function num_frames_edit_frame_Callback(hObject, eventdata, handles)
% hObject    handle to num_frames_edit_frame (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of num_frames_edit_frame as text
%        str2double(get(hObject,'String')) returns contents of num_frames_edit_frame as a double


% --- Executes during object creation, after setting all properties.
function num_frames_edit_frame_CreateFcn(hObject, eventdata, handles)
% hObject    handle to num_frames_edit_frame (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function time_between_frames_edit_frame_Callback(hObject, eventdata, handles)
% hObject    handle to time_between_frames_edit_frame (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of time_between_frames_edit_frame as text
%        str2double(get(hObject,'String')) returns contents of time_between_frames_edit_frame as a double


% --- Executes during object creation, after setting all properties.
function time_between_frames_edit_frame_CreateFcn(hObject, eventdata, handles)
% hObject    handle to time_between_frames_edit_frame (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function file_type_edit_video_Callback(hObject, eventdata, handles)
% hObject    handle to file_type_edit_video (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of file_type_edit_video as text
%        str2double(get(hObject,'String')) returns contents of file_type_edit_video as a double


% --- Executes during object creation, after setting all properties.
function file_type_edit_video_CreateFcn(hObject, eventdata, handles)
% hObject    handle to file_type_edit_video (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function capture_type_edit_video_Callback(hObject, eventdata, handles)
% hObject    handle to capture_type_edit_video (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of capture_type_edit_video as text
%        str2double(get(hObject,'String')) returns contents of capture_type_edit_video as a double


% --- Executes during object creation, after setting all properties.
function capture_type_edit_video_CreateFcn(hObject, eventdata, handles)
% hObject    handle to capture_type_edit_video (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function destination_edit_video_Callback(hObject, eventdata, handles)
% hObject    handle to destination_edit_video (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of destination_edit_video as text
%        str2double(get(hObject,'String')) returns contents of destination_edit_video as a double


% --- Executes during object creation, after setting all properties.
function destination_edit_video_CreateFcn(hObject, eventdata, handles)
% hObject    handle to destination_edit_video (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function frame_rate_edit_video_Callback(hObject, eventdata, handles)
% hObject    handle to frame_rate_edit_video (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of frame_rate_edit_video as text
%        str2double(get(hObject,'String')) returns contents of frame_rate_edit_video as a double


% --- Executes during object creation, after setting all properties.
function frame_rate_edit_video_CreateFcn(hObject, eventdata, handles)
% hObject    handle to frame_rate_edit_video (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function capture_length_edit_video_Callback(hObject, eventdata, handles)
% hObject    handle to capture_length_edit_video (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of capture_length_edit_video as text
%        str2double(get(hObject,'String')) returns contents of capture_length_edit_video as a double


% --- Executes during object creation, after setting all properties.
function capture_length_edit_video_CreateFcn(hObject, eventdata, handles)
% hObject    handle to capture_length_edit_video (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%Brief: toggle_visibility is intended to set the visibility of any panel
%object based on whether a checkbox or switch is on or off.  If it's on,
%the panel should be displayed.  If it's off, the panel should be invisible
%Params:
%switch_obj: The switch that is either on or off
%panel_obj: The panel that is to be made visible or invisible
function toggle_visibility(switch_obj, panel_obj)
    if(get(switch_obj, 'Value') == 1)
        set(panel_obj, 'Visible', 'On');
    else
        set(panel_obj, 'Visible', 'Off');
    end

%Brief: Toggle any gui object's visibility (This one is pretty self
%explanatory).
function item_toggle_visibility(obj)
    %if the object's visible attribute is set to 'On', meaning it's visible
    if(strcmp(get(obj, 'Visible'), 'On'))
        %Make the object invisible
        set(obj, 'Visible', 'Off');
    else
        %Otherwise, make it invisible
        set(obj, 'Visible', 'On');
    end



% --- Executes on button press in still_photo_check.
function still_photo_check_Callback(hObject, eventdata, handles)
% hObject    handle to still_photo_check (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of still_photo_check

% --- Executes on button press in video_record_check.
%Brief: Function toggles the visibility of a video recording settings panel
%based off of the checkbox "Record Video?" under still selection
function video_record_check_Callback(video_record_check, eventdata, handles)
% hObject    handle to video_record_check (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%Toggle the visibility of the panel used to set all the video recording
%options
toggle_visibility(video_record_check, handles.video_panel);
%Save changes we've made to the GUI
guidata(video_record_check, handles);
% Hint: get(hObject,'Value') returns toggle state of video_record_check


% --- Executes on button press in return_to_options.
%Brief: This function returns the listbox filesystem parser menu back to
%the "top level", where users can select whether they want to analyze data
%from a stream or pre-recorded video.  It resets the values contained
%within the listbox to the top-level options
function return_to_options_Callback(btn, eventdata, handles)
%These are the two selectable options at the top level.
options = {'Pre-Recorded Video', 'Stream'};
%Select the first element in the listbox before changing the items
%contained to ensure that the value selected actually exists and is not out
%of bounds
set(handles.img_options, 'Value', 1);
%Now update the list of options in the GUI listbox
set(handles.img_options, 'String', options);
%Make the prompt displayed above the listbox about selecting a video invisible
set(handles.vid_select_tag, 'Visible', 'Off');
%Top Level is a global boolean indicating whether the listbox is currently
%at its highest level in terms of navigation
global top_level;
%If it isn't already set, set it.
if(~top_level)
    top_level = true;
end
%Make the button used to navigate to the top level invisible.
set(btn, 'Visible', 'Off');
%Save any changes made to the GUI.
guidata(btn, handles);
% hObject    handle to return_to_options (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in settings.
%Brief: On a button click of "Settings", this function is triggered and
%runs the code within setting_gui.m
function settings_Callback(hObject, eventdata, handles)
    %Run the code within settings_gui.m
    settings_gui;
% hObject    handle to settings (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%Brief: Used for displaying error tags on a MATLAB GUI. 
%Params:
%error_tag: is the GUI error's object tag
%msg: The error message to be displayed on the GUI
function disp_error(msg, error_tag)
    set(error_tag, 'Visible', 'On');
    set(error_tag, 'String', msg);
 
%Brief: Used for clearing error tags on a MATLAB GUI. Error tag is the GUI
%error's object tag
%Params:
%error_tag: is the GUI error's object tag
function clear_error(error_tag)
    set(error_tag, 'Visible', 'Off');


% --- Executes on button press in play_video.
function play_video_Callback(hObject, eventdata, handles)
% hObject    handle to play_video (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
vidplay = VideoPlayer(getappdata(0, 'vid_path'), handles.img_viewer, 'none');
add_to_queue(vidplay);
queue_step(handles);

% --- Executes on button press in preview_start.
function preview_start_Callback(btn, eventdata, handles)
% hObject    handle to preview_start (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%TODO: Let user select which camera feed they want to use for live preview
if(isempty(videoinput('pointgrey')))
    error('Video input: Pointgrey does not exist!');
else
    setappdata(0, 'preview_done', false);
    set(handles.image_cover, 'Visible', 'Off');
    stream = videoinput('pointgrey');
    set(stream, 'FramesPerTrigger', Inf);
    triggerconfig(stream, 'manual');
    start(stream);
    trigger(stream);
    while(isvalid(stream) && ~getappdata(0, 'preview_done'))
        frame = gpuArray(getdata(stream, 1, 'uint8'));
        set(image, 'CData', gather(frame));
        drawnow;
    end
end


% --- Executes on button press in begin_operation_btn.
function begin_operation_btn_Callback(begin_measurement_btn, eventdata, handles)
    if(get(handles.displacement_check, 'Value') == 1)
        res_entry_obj = findobj('Tag', 'source_resolution_entry');
        resolution = res_entry_obj.UserData;
        if(isnumeric(resolution) && resolution > 0)
            %if the resolution is a number greater than zero then use it
            res = resolution;
        else
            %Default resolution for pister lab
            res = 5.86E-6;
        end
        %Reset the video error tag
        set(handles.vid_error_tag, 'String', '');
        pixel_precision = getappdata(0, 'pixel_precision');
        max_displacement = getappdata(0, 'maximum_displacement');  
        img_options = findobj('Tag', 'img_options');
        src_type = img_options.UserData;
        if(strcmp(src_type, 'stream'))
            cam_name = getappdata(0, 'cam_name');
            src = StreamSource(cam_name);    
        else
            path = getappdata(0, 'vid_path');
            src = FileSource(path, res);
        end
        displacement = Displacement(src, handles.img_viewer, handles.data_table, handles.vid_error_tag, handles.image_cover, handles.pause_vid, pixel_precision, max_displacement, res);
        arr = {displacement};
        handle = @display_error;
        q = Queue(handle, arr);
        output_file_location = [getappdata(0, 'outputfolderpath') FileSystemParser.get_file_separator()];
        d = DataCollector(@displacement.check_stop, output_file_location, 'mat');
        q.add_to_queue(d);
        while ~q.finished()
            q.execute();
        end
    end
% hObject    handle to begin_operation_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in save_frame_capture_options.
function save_frame_capture_options_Callback(hObject, eventdata, handles)
% hObject    handle to save_frame_capture_options (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%TODO-Check validity of all frame capture options
setappdata(0, 'num_frames', get(handles.num_frames_edit_frame, 'String'));
setappdata(0, 'time_between_frames', get(handles.time_between_frames_edit_frame), 'String');
setappdata(0, 'file_destination', get(handles.destination_edit_frame));
setappdata(0, 'file_type', get(handles.file_type_edit_frame));

% --- Executes on button press in save_displacement_options.
function save_displacement_options_Callback(hObject, eventdata, handles)
% hObject    handle to save_displacement_options (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
setappdata(0, 'pixel_precision', get(handles.pixel_precision_edit_displacement, 'String'));
setappdata(0, 'maximum_displacement', get(handles.maximum_displacement_edit_displacement, 'String'));
if(getappdata(0, 'wait_status'))
    uiresume;
end
    

% --- Executes on button press in save_video_options.
function save_video_options_Callback(hObject, eventdata, handles)
% hObject    handle to save_video_options (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
setappdata(0, 'framerate', get(handles.frame_rate_edit_video, 'String'));
setappdata(0, 'file_destination', get(handles.destination_edit_video));
setappdata(0, 'capture_type', get(handles.capture_type_edit_video));
setappdata(0, 'file_type', get(handles.file_type_edit_video));
setappdata(0, 'capture_length', get(handles.capture_length_edit_video));

% --- Executes on button press in save_trigger_options.
function save_trigger_options_Callback(hObject, eventdata, handles)
% hObject    handle to save_trigger_options (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
setappdata(0, 'trigger_key', get(handles.key_to_trigger_edit_trigger));
setappdata(0, 'frames_on_trigger', get(handles.frames_on_trigger_edit_trigger));
setappdata(0, 'file_destination', get(handles.file_destination_edit_trigger));
setappdata(0, 'time_between_frames', get(handles.time_between_frames_edit_trigger));
setappdata(0, 'file_type', get(handles.file_type_edit_trigger));

function check_operations(displacement_check, capture_check, voltage_check, handles)
measuring_displacement = get(displacement_check, 'Value');
capturing_stills = get(capture_check, 'Value');
measuring_voltage = get(voltage_check, 'Value');
if(~measuring_displacement && ~measuring_voltage && ~capturing_stills)
    set(handles.begin_operation_btn, 'Visible', 'Off');
else
    set(handles.begin_operation_btn, 'Visible', 'On');
end

function [operations] = get_operations(displacement_check, capture_check, voltage_check, handles)
measuring_displacement = get(displacement_check, 'Value');
capturing_stills = get(capture_check, 'Value');
measuring_voltage = get(voltage_check, 'Value');
operations = [measuring_displacement capturing_stills measuring_voltage];

function queue_step(handles)
global operation_queue;
global current_operation;
dbstop if error;
if(length(operation_queue) > 0)
    item_up = operation_queue{1};
    if(length(operation_queue) > 1)
        for i = length(operation_queue):2
            operation_queue{i - 1} = operation_queue{i};
        end
    end
    current_operation = item_up;
    item_up.execute(handles);
end
    
function add_to_queue(operation)
global operation_queue;
operation_queue{length(operation_queue) + 1} = operation;



function src_path_edit_Callback(hObject, eventdata, handles)
% hObject    handle to src_path_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of src_path_edit as text
%        str2double(get(hObject,'String')) returns contents of src_path_edit as a double
img_options = findobj('Tag', 'img_options');
if(FileSystemParser.is_file(get(hObject, 'String')))
    setappdata(0, 'vid_path', get(hObject, 'String'));
    img_options.UserData = 'file';
elseif(is_cam_name(get(hObject, 'String')))
    img_options.UserData = 'stream';
    setappdata(0, 'cam_name', get(hObject, 'String'));
end

% --- Executes on button press in pause_vid.
function pause_vid_Callback(hObject, eventdata, handles)
% hObject    handle to pause_vid (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global current_operation;
if(~current_operation.paused())
    current_operation.pause(handles);
else
    current_operation.unpause(handles);
end

function map_keypress(key, func)
global keymap;
keymap(key) = func;

function keypress_handle(hObject, eventdata, handles)
global keymap;
if(isKey(keymap, eventdata.Key))
   functData = keymap(eventdata.Key);
   functHandle = functData(1);
   functParams = functData(2);
   functHandle(functParams);
end

function q_press_handle(params)
setappdata(0, 'preview_done', true);

function display_error(msg)
setappdata(0, 'error_msg', msg);
setappdata(0, 'wait_status', 1);
error_gui;
uiwait;



function source_resolution_entry_Callback(hObject, eventdata, handles)
% hObject    handle to source_resolution_entry (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of source_resolution_entry as text
%        str2double(get(hObject,'String')) returns contents of source_resolution_entry as a double
hObject.UserData = str2double(get(hObject, 'String'));

% --- Executes during object creation, after setting all properties.
function source_resolution_entry_CreateFcn(hObject, eventdata, handles)
% hObject    handle to source_resolution_entry (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function src_path_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to src_path_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in stream_type.
function stream_type_Callback(hObject, eventdata, handles)
% hObject    handle to stream_type (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
img_options = findobj('Tag', 'img_options');
if(get(hObject, 'Value') == 1)
    img_options.UserData = 'stream';
else
    img_options.UserData = '-1';
end
% Hint: get(hObject,'Value') returns toggle state of stream_type


% --- Executes on button press in file_type.
function file_type_Callback(hObject, eventdata, handles)
% hObject    handle to file_type (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
img_options = findobj('Tag', 'img_options');
if(get(hObject, 'Value') == 1)
    img_options.UserData = 'file';
else
    img_options.UserData = '-1';
end
% Hint: get(hObject,'Value') returns toggle state of file_type
