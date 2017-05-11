classdef FileSystemParser
    %FILESYSTEMPARSER 
    %   Author: Will Fehrnstrom
    %   Date: 2/1/2017
    %   Organization(s): UC Berkeley's SWARM Laboratory, Miramonte High
    %   School
    %   
    %   Description: This class is a file system model used in conjunction
    %   with Matlab's UI Listbox to navigate through a file system
    
    
    properties
        %Stores the contents of the current_dir
        current_dir 
        %Stores the path of the level of the file system the
        %FileSystemParser is currently on
        path
    end
    methods (Static)
        
        %Brief: Retrieve which video formats this OS supports
        function vid_formats = get_supported_vid_formats()
            if(strcmp(SysInfo.get_os(), 'Windows'))
                vid_formats = {'.avi'};
            else
                vid_formats = {'.mov'};
            end
        end
        
        %Brief: Retrieve which picture formats this OS supports
        function pic_formats = get_supported_pic_formats()
            %If the OS is Windows
            if(strcmp(SysInfo.get_os(), 'Windows'))
                pic_formats = ['.bmp', '.cur', '.gif', '.hdf4', '.ico', '.jpeg', '.pbm', '.pcx',
                    '.pgm', '.png', '.ppm', '.ras', '.tiff','.xwd']; 
            %If the OS is non-Windows(Unix or what have you)
            else
                pic_formats = ['.cur', '.gif', '.hdf4', '.ico', '.jpeg', '.pbm',
                    '.pgm', '.png', '.ppm', '.ras', '.tiff']; 
            end
        end
        
        %Brief: Retrieve which separator this OS uses
        function separator = get_file_separator()
            %Use the Windows file separator if the OS is Windows.
            if(strcmp(SysInfo.get_os(), 'Windows'))
                %separator = '\\';
                separator = '\';
            %Use the unix file separator if the OS is Unix.
            else
                separator = '/';
            end
        end
        
        %Brief: Retrieve which carriage return characters this OS uses
        function carriage = get_carriage_return()
            %Use the Windows Carriage return if the OS is Windows
            if(strcmp(SysInfo.get_os(), 'Windows'))
                carriage = '\r\n';
            %Use the unix file separator if the OS is unix
            else
                carriage = '\n';
            end
        end
        
        %Brief: Get what the start of the OS's filesystem is
        function file_system_start_path = get_file_system_start_path()
            %Get the Windows start path if the filesystem is a Windows one
            if(strcmp(SysInfo.get_os(), 'Windows'))
                file_system_start_path = 'C:\';
            %Use the unix start path if the OS is Unix.
            else
                file_system_start_path = '/';
            end 
        end
        
        %Brief: check whether a given path is a folder
        function is_a_folder = is_folder(folder_path)
            if(exist(folder_path) == 7)
                is_a_folder = true;
            else
                is_a_folder = false;
            end
        end
        
        %Brief: check whether a given path is a file
        function is_a_file = is_file(file_path)
            if(exist(file_path) == 2)
                is_a_file = true;
            else
                is_a_file = false;
            end
        end
    end
    
    methods
        %Brief: FileSystemParser Constructor.  Takes a path, and
        %appends this to the default start_path that can be specified as
        %the start directory in settings_gui
        %Params
        %path: the path to the filesystem parser, a character vector
        function obj = FileSystemParser(path)
            obj.path = '';
            start_path = getappdata(0, 'sys_start_path');
            if(obj.is_valid_path(start_path))
                obj.path = strcat(start_path, path);
            else
                obj.path = path;
            end
            
            if(length(obj.path) <= 0)
                obj.path = obj.get_file_system_start_path();
            end
            
            obj.current_dir = get_current_dir(obj, false, []);
        end
        
        
        %Brief: Go to a folder or an item in the filesystem
        %Params:
        function object = goto(object, folder)
            if(strcmp(class(folder), 'cell'))
                folder = char(folder);
            end
            %check that the folder exists
            if(exist([object.path FileSystemParser.get_file_separator() folder]) == 7)
                if(strcmp(folder, '..'))
                    indexes = strfind(object.path, FileSystemParser.get_file_separator());
                    lastindex = indexes(length(indexes));
                    if(strcmp(object.path(1:(lastindex)), '/'))
                        object.path = object.path(1:lastindex);
                    else
                        object.path = object.path(1:(lastindex - 1));
                    end
                else
                    if(~(strcmp(object.path, '/')))
                        object.path = strcat(object.path, FileSystemParser.get_file_separator(), folder);
                    else
                        object.path = strcat(object.path, folder);
                    end
                end
                object.current_dir = object.get_current_dir(false, []);
            else
                object.current_dir = {};
                disp('Error: Folder does not exist');
            end
            object.current_dir = char(object.current_dir);
        end
        
        %Brief:
                %get_current_dir() retrieves the file system elements
                %contained within the current directory
        %Params: 
        %       filter: Should the function apply a filter only allowing certain extensions?
        %       file_types: an array of strings of all the file types to return as
        %       part of the return array
        %PLEASE SEE: The functionality of filter and file_types is
        %unverified.  Please use get_current_dir(false, []) when calling
        %the method
        function out_files = get_current_dir(obj, filter, file_types) 
            %Get the names of the files within the current directory
            files = get_file_names(dir(obj.path));
            %Declare an array to store the files that will be piped to the
            %output
            out_files = [];
            %if we are filtering some files out
            if(filter)
               %iterate through those files
               for i = 1:length(files)
                   %store the current file in a variable called file
                   file = files{i};
                   %get a list of the indexes of . within the current
                   %file
                   ext_index_arr = strfind(files{i}, '.');
                   %If there are dots and therefore possible extensions
                   if(length(ext_index_arr) >= 0)
                    %get the starting index of the actual extension of the
                    %element
                    ext_index = ext_index_arr(length(ext_index_arr));
                    %get the extension by substringing file
                    ext = file(ext_index:ext_index + 1);
                    %compare this extension with a list of file extensions
                    %allowed
                    for j = 1:length(file_types)
                       %if this file extension is allowed
                       if(strcmp(ext, file_types(j)))
                           %add it to the outputted files
                           out_files = [out_files file];
                       end
                    end
                   else
                       out_files = [out_files file];
                   end
               end
            %otherwise just set the outputted files to files
            else
               out_files = files;
            end
            %Take the transpose for easier manipulation
            out_files = out_files.';
        end
        
        %Brief:  Finds any files matching the filename passed in the
        %current dir
        function file_array = find(obj, exp) 
            files = get_file_names(dir(obj.current_dir));
            for i = 1:length(files)
                if(~isempty(strfind(files(i), exp)))
                    file_array = [file_array, files(i)];
                end
            end
        end
        
        %Brief: Get Path of file
        function file_path = get_path(obj, file)
            file_path = strcat(obj.path, FileSystemParser.get_file_separator(), file);
        end
        
        %Brief:Function to check whether path_to_check is a valid path on
        %the file system
        function is_a_valid_path = is_valid_path(obj, path_to_check)
            is_a_valid_path = (exist([obj.path FileSystemParser.get_file_separator() path_to_check]) == 7 || (exist([path_to_check]) == 7));
        end
    end
    
end

