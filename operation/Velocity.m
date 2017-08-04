classdef Velocity < Operation
    % Velocity
    % Given a video, finds the speed and displacement of the template
    % within the video 
    
    properties (SetAccess = protected)
        axes; error_tag;
        
        pixel_precision;
        max_x_displacement; max_y_displacement; min_displacement;
        template;
        current_frame;
        cameraFPS;
        table;
        img_cover;
        table_data;
        im;
        index; % current frame count
        seconds;
        velocityTrack;
        conversion;
        res;
        dispx; dispy;
        rect;
        display;
        draw; % toggles imrect
    end
    properties
        % Inherited
        source
    end
    
    properties (SetAccess = public)
        valid;
        error_report_handle;
        template_matcher;
    end

    methods
        function obj = Velocity(src, axes, table, error, ...
            img_cover, pixel_precision, max_x_displacement, ...
             max_y_displacement, resolution, conversion, display, ...
             enable_rectangles)

            obj.source = src;
            obj.axes = axes;
            obj.table = table;
            obj.error_tag = error;
            obj.cameraFPS = 15; % speed of Swarm lab camera
            obj.img_cover = img_cover;
            obj.pixel_precision = str2double(pixel_precision);
            obj.max_x_displacement = str2double(max_x_displacement);
            obj.max_y_displacement = str2double(max_y_displacement);
            obj.res = resolution;
            obj.valid = true;
            obj.dispx = [];
            obj.dispy = [];
            obj.seconds = [];
            obj.velocityTrack = [];
            obj.conversion = str2double(conversion);
            obj.index = 1;
            obj.min_displacement = 2; % Default Value; TODO: make changeable
            obj.display = display;
            obj.current_frame = grab_frame(obj.source);
            
            obj.valid = obj.validate();
            set(obj.img_cover, 'Visible', 'Off');
            obj.im = zeros([size(obj.current_frame), 3]);
            colormap(gca, gray(256));
            obj.table_data = {'DispX'; 'DispY'; 'Velocity'};

            % Create template matcher
            obj.create_template_matcher();

            obj.im = imshow(obj.im);
            
            % CSV to save to
            obj.data_save_path = create_csv_for_data('Velocity');
            add_headers(obj.data_save_path, 'time', 'dispx', 'velocity');
        end

        function startup(obj)
        end

        function create_template_matcher(obj)
            path = getappdata(0, 'img_path');
            % if template path is specified, use path. Else use user input%
            if ~strcmp(path,'') && ~isequal(path, [])
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

                % Conversion from displacement in pixel to meters
                dispx = disp_x_pixel*obj.conversion;
                dispy = disp_y_pixel*obj.conversion;
                obj.dispx = [obj.dispx dispx];
                obj.dispy = [obj.dispy dispy];
                secondsElapsed = obj.index/obj.cameraFPS;
                obj.seconds = [obj.seconds secondsElapsed];
                
                % Estimate velocity
                if obj.index ~= 1
                    instVelocity = (disp_x_pixel-prevX)*obj.conversion/(secondsElapsed - prevSecondsElapsed);
                else
                    instVelocity = 0;
                end
                obj.velocityTrack = [obj.velocityTrack instVelocity];
                
                % Save values Let's fix that
                time = obj.seconds;
                vel = obj.velocityTrack;
                add_to_csv(obj.data_save_path, [secondsElapsed, dispx, instVelocity]);
                
                % To have GUI table update continuously, remove nocallbacks
                drawnow limitrate nocallbacks;
                if obj.rect
                    delete(hrect);
                end

                % Update for next iteration
                obj.index = obj.index + 1;
                prevX = disp_x_pixel;
                prevSecondsElapsed = secondsElapsed;
                obj.current_frame = gather(grab_frame(obj.source));
                
            end
            
            figure('Name', 'X Displacement Over Time');
            plot(obj.seconds, obj.dispx);
            figure('Name', 'Velocity over Time');
            plot(obj.seconds, vel);            
        end

        %error_tag is now deprecated     

        function valid = valid_max_displacement(obj)
            valid = true;
            frame = obj.current_frame;
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
        
        function valid = validate(obj)
            valid = obj.valid_max_displacement();
            valid = valid & obj.valid_pixel_precision();
        end

    end

end
