classdef Velocity < Operation
    % Velocity
    % Given a video, finds the speed and displacement of the template
    % within the video 
    
    properties (SetAccess = protected)
        vid_src;
        rect;
        axes;
        error_tag;
        pixel_precision;
        max_x_displacement;
        max_y_displacement;
        template;
        xtemp; 
        ytemp;
        current_frame;
        cameraFPS;
        table;
        img_cover;
        pause_button;
        table_data;
        stop_check_callback = @check_stop;
        im;
        index; % current frame count
        seconds;
        velocityTrack;
        conversion;
        res;
        xoff; yoff;
        display;
        draw; % toggles imrect

        % Properties needed for fourier analysis
        search_area_width; search_area_height;
        search_area_xmin;  search_area_ymin;
        min_displacement;

        template_average;
        processed_template; fft_conj_processed_template;

        interp_search_area_width; interp_search_area_height;
        interp_template; interp_template_average;
        processed_interp_template; fft_conj_processed_interp_template;

    end
    properties
        % Inherited
        source
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
        template_matcher;
    end

    properties (Constant)
        rx_data = {};
        name = 'Displacement';
        insertion_type = 'end';
    end

    methods
        function obj = Velocity(src, axes, table, error, ...
            img_cover, pause_button, pixel_precision, max_x_displacement, ...
             max_y_displacement, resolution, conversion, display, ...
             enable_rectangles)

            obj.source = src;
            obj.axes = axes;
            obj.table = table;
            obj.error_tag = error;
            obj.cameraFPS = 15; % speed of Swarm lab camera
            obj.img_cover = img_cover;
            obj.pause_button = pause_button;
            obj.pause_bool = false;
            obj.pixel_precision = str2double(pixel_precision);
            obj.max_x_displacement = str2double(max_x_displacement);
            obj.max_y_displacement = str2double(max_y_displacement);
            obj.res = resolution;
            obj.new = true;
            obj.valid = true;
            obj.outputs('dispx') = 0;
            obj.outputs('dispy') = 0;
            obj.outputs('done') = false;
            obj.queue_index = -1;
            obj.xoff = [];
            obj.yoff = [];
            obj.seconds = [];
            obj.velocityTrack = [];
            obj.conversion = str2double(conversion);
            obj.index = 1;
            obj.min_displacement = 2; % Default Value; TODO: make changeable
            obj.display = display;
        end

        function startup(obj)
            obj.valid = obj.validate();
            set(obj.img_cover, 'Visible', 'Off');
            set(obj.pause_button, 'Visible', 'On');
            obj.initialize_algorithm();
            obj.im = zeros(obj.source.get_num_pixels());
            obj.im = imshow(obj.im);
            colormap(gca, gray(256));
            obj.table_data = {'DispX'; 'DispY'; 'Velocity'};
        end

        function initialize_algorithm(obj)
            obj.current_frame = gather(grab_frame(obj.source));
            path = getappdata(0, 'img_path');
            % if template path is specified, use path. Else use user input%
            if ~strcmp(path,'') & ~isequal(path, [])
                temp = imread(path);
                obj.rect = find_rect(obj.current_frame, temp);
                obj.template = imcrop(obj.current_frame, obj.rect);
                obj.rect = [obj.rect(1) obj.rect(2) obj.rect(3)+1 obj.rect(4)+1];
            else
                [vid_height, vid_width] = size(obj.current_frame);
                [obj.template, obj.rect] = get_template(obj.current_frame, obj.axes, vid_height, vid_width);
            end
            obj.template_matcher = TemplateMatcher(obj.pixel_precision,...
             obj.max_x_displacement, obj.max_y_displacement, obj.template, ...
             obj.min_displacement, obj.current_frame);
            obj.template_matcher.change_template(obj.template, obj.rect);
        end

        function execute(obj)
            prevX = 0;
            prevSecondsElapsed = 0;
            started = false;

            while ~obj.source.finished()
                obj.current_frame = gather(grab_frame(obj.source));
                frame = imgaussfilt(obj.current_frame, 2.5);
                
                [y_peak, x_peak, disp_y_pixel,disp_x_pixel] = obj.template_matcher.meas_displacement_norm_cross_correlation(obj.current_frame);
                dispx = disp_x_pixel*obj.res;
                dispy = disp_y_pixel*obj.res;

                if obj.display
                    set(obj.im, 'CData', obj.current_frame);
                end

                if obj.rect
                    hrect = imrect(obj.axes, [obj.rect(1)+disp_x_pixel, obj.rect(2)+disp_y_pixel, obj.rect(3), obj.rect(4)]);
                end
                
                if ~started
                    started = true;
                    prevX = disp_x_pixel; % x is displacement in pixels
                end

                % Some additional gui 
                updateTable(obj.table, dispx, dispy);
                obj.outputs('dispx') = [obj.outputs('dispx') dispx];
                obj.outputs('dispy') = [obj.outputs('dispy') dispy];
                obj.outputs('done') = obj.check_stop();  

                % Conversion from displacement in pixel to meters
                xoff = disp_x_pixel*obj.conversion;
                yoff = disp_y_pixel*obj.conversion;
                obj.xoff = [obj.xoff xoff];
                obj.yoff = [obj.yoff yoff];
                secondsElapsed = obj.index/obj.cameraFPS;
                obj.seconds = [obj.seconds secondsElapsed];
                
                % Estimate velocity
                if obj.index ~= 1
                    instVelocity = (disp_x_pixel-prevX)*obj.conversion/(secondsElapsed - prevSecondsElapsed);
                else
                    instVelocity = 0;
                end
                obj.velocityTrack = [obj.velocityTrack instVelocity];

                % Save values
                x_disp = obj.xoff;
                y_disp = obj.yoff;
                time = obj.seconds;
                vel = obj.velocityTrack;

                full_path = which('saved_data_README.markdown'); 
                [parentdir, ~, ~] = fileparts(full_path);
                mat_file_path = [parentdir '/velocity.mat'];
                save(mat_file_path, 'x_disp', 'time', 'vel');
                
                % To have GUI table update continuously, remove nocallbacks
                drawnow limitrate nocallbacks;
                if obj.rect
                    delete(hrect);
                end

                % Update for next iteration
                obj.index = obj.index + 1;
                prevX = disp_x_pixel;
                prevSecondsElapsed = secondsElapsed;
            end
            Data = load('velocity.mat');
            figure('Name', 'X Displacement Over Time');
            plot(Data.time, Data.x_disp);
            figure('Name', 'Velocity over Time');
            plot(Data.time, Data.vel);
            convertToCSV(mat_file_path, 'Velocity');
            delete(mat_file_path)                    
        end

        %error_tag is now deprecated     

        function valid = valid_max_displacement(obj)
            valid = true;
            frame = obj.get_frame();
            if(size(frame, 2) <= obj.max_x_displacement || isnan(obj.max_x_displacement) || size(frame, 1) <= obj.max_x_displacement)
                valid = false;
            end
            
            if(size(frame, 2) <= obj.max_y_displacement || isnan(obj.max_y_displacement) || size(frame, 1) <= obj.max_y_displacement)
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
            bool = (~obj.valid && ~obj.validate(obj.error_tag)) | obj.source.finished();
        end

        function vid_source = get.source(obj)
            vid_source = obj.source;
        end
        
        function valid = validate(obj)
            valid = obj.valid_max_displacement();
            valid = valid & obj.valid_pixel_precision();
        end

    end

end
