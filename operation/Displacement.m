classdef Displacement < Operation
    %VIDPLAY Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess = private) 
        vid_path;
        vid_colorspace;
        axes;
        pixel_precision;
        max_displacement;
        valid;
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
        function obj = Displacement(path, axes, colorspace, pixel_precision, max_displacement)
            obj.vid_path = path;
            obj.axes = axes;
            obj.vid_colorspace = colorspace;
            obj.pause_bool = false;
            obj.pixel_precision = str2double(pixel_precision);
            obj.max_displacement = str2double(max_displacement);
        end

        function execute(obj, handles)
            set(handles.image_cover, 'Visible', 'Off');
            set(handles.pause_vid, 'Visible', 'On');
            table_data = {'DispX'; 'DispY'};
            [array_pixel, array_micro] = read_video(obj, handles, table_data);
            set(handles.pause_vid, 'Visible', 'Off');
            figure;plot(array_pixel);title('Object displacement - Subpixel');
            legend('Displacement in X','Displacement in Y','Location','southwest')
            xlabel('Frames') % x-axis label
            ylabel('Pixels') % y-axis label
            drawnow;
            set(handles.image_cover, 'Visible', 'On');
        end

        function valid = validate(obj, handles)
            valid = true;
            if(~FileSystemParser.is_file(obj.vid_path))
                err = Error(Displacement.name(), 'Not passed a valid path on the filesystem', handles.vid_error_tag);
                valid = false;
            end
            if(~valid_color_space(obj))
                err = Error(Displacement.name(), 'Invalid Color Space', handles.vid_error_tag);
                valid = false;
            end
            if(~valid_max_displacement(obj))
                err = Error(Displacement.name(), 'Max Displacement too large', handles.vid_error_tag);
                valid = false;
            end
            if(valid)
                set(handles.vid_error_tag, 'Visible', 'Off');
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

        function valid = valid_max_displacement(obj)
            valid = true;
            vidReader = vision.VideoFileReader(obj.vid_path);
            frame = vidReader.step();
            if(size(frame, 2) < obj.max_displacement || isnan(obj.max_displacement))
                valid = false;
            end 
        end
        
        function valid = valid_pixel_precision(obj)
            valid = true;
            if(isnan(obj.pixel_precision))
                valid = false;
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
        
        function path = get_vid_path(obj)
            path = obj.vid_path;
        end
        
        function color = get_vid_colorspace(obj)
            color = obj.vid_colorspace;    
        end
        
        function pixel_precision = get_pixel_precision(obj)
            pixel_precision = obj.pixel_precision;
        end
        
        function max_displacement = get_max_displacement(obj)
           max_displacement = obj.max_displacement;
        end
    end
    

end

