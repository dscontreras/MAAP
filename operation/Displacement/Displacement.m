classdef Displacement < RepeatableOperation
    %VIDPLAY Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess = private) 
        vid_src;
        axes;
        error_tag;
        pixel_precision;
        max_displacement;
        template; rect; xtemp; ytemp;
        current_frame;
        table;
        img_cover;
        pause_button;
        table_data;
        stop_check_callback = @check_stop;
        im;
        res;
        xoff;
        yoff;
        draw; % toggles imrect
        
        % Properties for use when using fft2
        fft_conj_template;
        template_padded;
        template_grayscale_inverted;
        search_area_width;
        search_area_height;
    end

    properties (SetAccess = public)
        pause_bool;
        param_names;
        outputs = containers.Map('KeyType','char','ValueType','any');
        valid;
        new;
        error_report_handle;
        queue_index;
        start_check_callback = @RepeatableOperation.check_start;
        inputs = {};
    end
    
    properties (Constant)
        rx_data = {};
        name = 'Displacement';
        insertion_type = 'end';
    end

    methods
        function obj = Displacement(src, axes, table, error, img_cover, pause_button, pixel_precision, max_displacement, resolution, draw, error_report_handle)
            obj.vid_src = src;
            obj.axes = axes;
            obj.table = table;
            obj.error_tag = error;
            obj.img_cover = img_cover;
            obj.pause_button = pause_button;
            obj.pause_bool = false;
            obj.pixel_precision = str2double(pixel_precision);
            obj.max_displacement = str2double(max_displacement);
            obj.res = resolution;
            obj.new = true;
            obj.valid = true;
            obj.outputs('dispx') = 0;
            obj.outputs('dispy') = 0;
            obj.outputs('done') = false;
            obj.queue_index = -1;
            obj.xoff = [];
            obj.yoff = [];
            obj.draw = draw;
            if(nargin > 10) % 9 is the number of params for displacement
                obj.error_report_handle = error_report_handle;
            end
        end

        %For carrying out one time method calls that should be done before
        %calling of execute
        function startup(obj)
            obj.valid = obj.validate(obj.error_tag);
            set(obj.img_cover, 'Visible', 'Off');
            set(obj.pause_button, 'Visible', 'On');
            obj.initialize_algorithm();
            obj.table_data = {'DispX'; 'DispY'};
            obj.im = zeros(obj.vid_src.get_num_pixels());
            obj.im = imshow(obj.im);
        end
       
        function initialize_algorithm(obj)
            obj.current_frame = gather(grab_frame(obj.vid_src, obj));
            path = getappdata(0, 'img_path');
            % if template path is specified, use path. Else use user input%
            if ~strcmp(path,'')
                obj.rect = find_rect(obj.vid_src.get_filepath(), path);
                obj.template = imcrop(obj.current_frame, obj.rect);
                [obj.xtemp, obj.ytemp] = get_template_coords(obj.current_frame, obj.template);
                imshow(obj.template);
            else
                [obj.template, obj.rect, obj.xtemp, obj.ytemp] = get_template(obj.current_frame, obj.axes);
                obj.rect = ceil(obj.rect); 

                % Begin Fourier Method Code
                obj.search_area_width = 2*obj.max_displacement + obj.rect(3);
                obj.search_area_height = 2*obj.max_displacement + obj.rect(4);

                obj.template_grayscale_inverted = (120 - obj.template)*2; % Assumes image is 255 bit grayscale
                obj.template_padded = padarray(obj.template_grayscale_inverted, [(2*obj.search_area_height - obj.rect(4) + 1), (2*obj.search_area_width - obj.rect(3) + 1)], 'post');
                obj.fft_conj_template = conj(fft2(obj.template_padded));
            end
        end
        
        function execute(obj)  
            obj.current_frame = gather(grab_frame(obj.vid_src, obj)); 
            if(strcmp(VideoSource.getSourceType(obj.vid_src), 'file'))
                if(obj.vid_src.gpu_supported)
                    [xoffSet, yoffSet, dispx,dispy,x, y] = meas_displacement_gpu_array(obj.template,obj.rect,obj.current_frame, obj.xtemp, obj.ytemp, obj.max_displacement, obj.res);
                else
                    [xoffSet, yoffSet, dispx,dispy,x, y] = meas_displacement(obj.template,obj.rect,obj.current_frame, obj.xtemp, obj.ytemp, obj.pixel_precision, obj.max_displacement, obj.res);
                end
              else
                if(obj.vid_src.gpu_supported)
                    [xoffSet, yoffSet, dispx,dispy,x, y] = meas_displacement_gpu_array(obj.template,obj.rect,obj.current_frame, obj.xtemp, obj.ytemp, obj.max_displacement, obj.res);
                else
                    [xoffSet, yoffSet, dispx, dispy, x, y] = meas_displacement(obj.template,obj.rect,obj.current_frame, obj.xtemp, obj.ytemp, obj.pixel_precision, obj.max_displacement, obj.res);
                end
            end
              set(obj.im, 'CData', gather(obj.current_frame));
              if obj.draw == 1
                  hrect = imrect(obj.axes,[xoffSet, yoffSet, size(obj.template,2), size(obj.template,1)]);
              end
              updateTable(dispx, dispy, obj.table);
              data = get(obj.table, 'Data');
              obj.outputs('dispx') = [obj.outputs('dispx') dispx];
              obj.outputs('dispy') = [obj.outputs('dispy') dispy];
              obj.outputs('done') = obj.check_stop();
              obj.xoff = [obj.xoff xoffSet];
              obj.yoff = [obj.yoff yoffSet];
              xoff3 = obj.xoff;
              yoff3 = obj.yoff;
              save('gpu_displacement.mat', 'xoff3', 'yoff3');    
              
              % To have GUI table update continuously, remove nocallbacks
              drawnow limitrate nocallbacks;
              if obj.draw == 1
                  delete(hrect);
              end
        end

        %error_tag is now deprecated
        function valid = validate(obj, error_tag)
            valid = true;
            while(~strcmp(VideoSource.getSourceType(obj.vid_src), 'stream') && ~FileSystemParser.is_file(obj.vid_src.filepath))
                str = 'Displacement: Not passed a valid path on the filesystem'
                err = Error(Displacement.name, str, error_tag);
                feval(obj.error_report_handle, str);
                valid = false;
            end
            while(~valid_max_displacement(obj))
                str = 'Displacement: Max Displacement invalid';
                err = Error(Displacement.name, str, error_tag);
                feval(obj.error_report_handle, str);
                valid = false;
            end
            while(~valid_pixel_precision(obj))
                str = 'Displacement: Pixel Precision inputted not a number';
                err = Error(Displacement.name, str, error_tag);
                feval(obj.error_report_handle, str);
                valid = false;
            end
            if(valid)
                set(error_tag, 'Visible', 'Off');
            end
        end

        function valid = valid_max_displacement(obj)
            valid = true;
            frame = obj.get_frame();
            if(size(frame, 2) <= obj.max_displacement || isnan(obj.max_displacement) || size(frame, 1) <= obj.max_displacement);
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
            boolean = obj.pause_bool;
        end

        function pause(obj, handles)
            obj.pause_bool = true;
            set(handles.pause_vid, 'String', 'Resume Video');
        end

        function unpause(obj, handles)
            obj.pause_bool = false;
            set(handles.pause_vid, 'String', 'Pause Video');
        end

        function frame = get_frame(obj)
            frame = obj.vid_src.extractFrame();
        end
        
        
        function path = get_vid_path(obj)
            path = obj.vid_path;
        end
        
        function pixel_precision = get_pixel_precision(obj)
            pixel_precision = obj.pixel_precision;
        end
        
        function max_displacement = get_max_displacement(obj)
           max_displacement = obj.max_displacement;
        end
        
        function bool = check_stop(obj)
            if(~obj.valid && ~obj.validate(obj.error_tag))
                bool = true;
            else
                bool = obj.vid_src.finished();
            end
        end
        
        function vid_source = get.vid_src(obj)
            vid_source = obj.vid_src;
        end
        
    end

end
