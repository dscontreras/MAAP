classdef VideoPlayer < Operation
    %VIDPLAY Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess = private) 
        vid_path;
        vid_colorspace;
        vid_axes;
    end

    properties (SetAccess = public)
        pause_bool;
    end
    
    methods(Static)
        function string = name(obj)
            string = 'VideoPlayer: ';
        end
    end

    methods
        function obj = VideoPlayer(path, axes, colorspace)
            obj.vid_path = path;
            obj.vid_axes = axes;
            obj.vid_colorspace = colorspace;
            obj.pause_bool = false;
        end

        function execute(obj, handles)
            videoReader = vision.VideoFileReader(obj.vid_path);
            set(handles.image_cover, 'Visible', 'Off');
            set(handles.pause_vid, 'Visible', 'On');
            if(strcmp(obj.vid_colorspace, 'none'))
                while(~isDone(videoReader))
                    if(~obj.paused())
                        frame = step(videoReader);
                        imshow(frame, 'Parent', obj.vid_axes);
                        drawnow;
                    end
                end
            else
                while(~isDone(videoReader))
                    if(~obj.paused())
                        frame = step(videoReader);
                        if(strcmp(obj.vid_colorspace, 'intensity'))
                            frame = rgb2gray(frame);                        
                        end
                        imshow(frame, 'Parent', obj.vid_axes);
                        drawnow;
                    end
                end
            end
            set(handles.pause_vid, 'Visible', 'Off');
        end

        function valid = validate(obj, handles)
            valid = true;
            if(~FileSystemParser.is_file(obj.path))
                err = Error(VideoPlayer.name(), 'Not passed a valid path on the filesystem', handles.vid_error_tag);
                valid = false;
            end
            if(~valid_color_space(obj))
                err = Error(VideoPlayer.name(), 'Invalid Color Space', handles.vid_error_tag);
                valid = false;
            end
        end

        function valid = valid_color_space(obj)
            valid_spaces = ['rgb', 'intensity', 'none'];
            valid = false;
            for i = 1:length(valid_spaces)
                if(strcmp(obj.vid_colorspace, valid_spaces(i)))
                    valid = true;
                end
            end
        end

        function boolean = paused(obj)
            boolean = (obj.pause_bool || ~obj.goodstate());
        end

        function good = goodstate(obj)
            good = true; %TODO: Implement goodstate
        end

        function pause(obj, handles)
            obj.pause_bool = true;
            set(handles.pause_vid, 'String', 'Resume Video');
        end

        function unpause(obj, handles)
            obj.pause_bool = false;
            set(handles.pause_vid, 'String', 'Pause Video');
        end

        function draw_frame(videoReader, axes)
            frame = step(videoReader);
            imshow(frame, 'Parent', axes);
            drawnow;
        end
    end
    

end

