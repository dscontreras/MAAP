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
    end

    properties (Constant)
        rx_data = {};
        name = 'Displacement';
        insertion_type = 'end';
    end

    methods
        function obj = Velocity(src, axes, table, error, img_cover, pause_button, pixel_precision, max_x_displacement, max_y_displacement, resolution, conversion, display, error_report_handle)
            obj.vid_src = src;
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
            if(nargin > 12) % 12 is the number of params for displacement
            % TODO: Better Error Handling
                obj.error_report_handle = error_report_handle;
            end
        end

        function startup(obj)
            obj.valid = obj.validate();
            set(obj.img_cover, 'Visible', 'Off');
            set(obj.pause_button, 'Visible', 'On');
            obj.initialize_algorithm();
            obj.im = zeros(obj.vid_src.get_num_pixels());
            obj.im = imshow(obj.im);
            colormap(gca, gray(256));
            obj.table_data = {'DispX'; 'DispY'; 'Velocity'};
        end

        function initialize_algorithm(obj)
            obj.current_frame = gather(grab_frame(obj.vid_src, obj));
            path = getappdata(0, 'img_path');
            % if template path is specified, use path. Else use user input%
            if ~strcmp(path,'') & ~isequal(path, [])
                obj.rect = find_rect(obj.vid_src.get_filepath(), path);
                obj.template = imcrop(obj.current_frame, obj.rect);
                obj.rect = [obj.rect(1) obj.rect(2) obj.rect(3)+1 obj.rect(4)+1];
                [obj.xtemp, obj.ytemp] = get_template_coords(obj.current_frame, obj.template);
            else
                [vid_height, vid_width] = size(obj.current_frame);
                [obj.template, obj.rect, obj.xtemp, obj.ytemp] = get_template(obj.current_frame, obj.axes, vid_height, vid_width);
                obj.rect = ceil(obj.rect);
            end
            obj.search_area_height  = 2 * obj.max_y_displacement + obj.rect(4) + 1; % imcrop will add 1 to the dimension
            obj.search_area_width   = 2 * obj.max_x_displacement + obj.rect(3) + 1; % imcrop will add 1 to the dimension
            obj.search_area_xmin    = obj.rect(1) - obj.max_x_displacement;
            obj.search_area_ymin    = obj.rect(2) - obj.max_y_displacement;
        end

        function execute(obj)
            prevX = 0;
            prevSecondsElapsed = 0;
            started = false;
            while ~obj.vid_src.finished()
                obj.current_frame = gather(rgb2gray(obj.vid_src.extractFrame()));
                frame = imgaussfilt(obj.current_frame, 2.5);
                if(strcmp(VideoSource.getSourceType(obj.vid_src), 'file'))
                    if(obj.vid_src.gpu_supported)
                        % [xoffSet, yoffSet, dispx,dispy,x, y] = meas_displacement_gpu_array(obj.template,obj.rect,obj.current_frame, obj.xtemp, obj.ytemp, obj.max_displacement, obj.res);
                        % [xoffSet, yoffSet, dispx,dispy,x, y] = meas_displacement_subpixel_gpu_array(obj.template,obj.rect,obj.current_frame, obj.xtemp, obj.ytemp, obj.pixel_precision, obj.max_displacement, obj.res);
                    else
                        [xoffSet, yoffSet, dispx,dispy,x, y] = meas_displacement(obj.template, obj.rect, frame, obj.xtemp, obj.ytemp, obj.pixel_precision, obj.max_x_displacement, obj.max_y_displacement, obj.res);
                        %[xoffSet, yoffSet, dispx,dispy,x, y] = meas_displacement(obj.template, obj.rect, obj.current_frame, obj.xtemp, obj.ytemp, obj.pixel_precision, obj.max_displacement, obj.res);
                        %[x_peak, y_peak, disp_x_pixel, disp_y_pixel, disp_x_micron, disp_y_micron] = obj.meas_displacement_fourier();
                    end
                else
                    if(obj.vid_src.gpu_supported)
                        [xoffSet, yoffSet, dispx,dispy,x, y] = meas_displacement_gpu_array(obj.template,obj.rect,obj.current_frame, obj.xtemp, obj.ytemp, obj.max_x_displacement, obj.max_y_displacement, obj.res);
                    else
                        [xoffSet, yoffSet, dispx,dispy,x, y] = meas_displacement(obj.template,obj.rect,obj.current_frame, obj.xtemp, obj.ytemp, obj.pixel_precision, obj.max_displacement, obj.res);
                    end
                end
                if obj.display
                    set(obj.im, 'CData', obj.current_frame);
                end
                if obj.draw
                    hrect = imrect(obj.axes, [obj.rect(1)+x, obj.rect(2)+y, obj.rect(3), obj.rect(4)]);
                end
                
                if ~started
                    started = true;
                    prevX = x; % x is displacement in pixels
                end
                updateTable(dispx, dispy, obj.table);
                obj.outputs('dispx') = [obj.outputs('dispx') dispx];
                obj.outputs('dispy') = [obj.outputs('dispy') dispy];
                obj.outputs('done') = obj.check_stop();  
                xoff = x*obj.conversion;
                yoff = y*obj.conversion;
                obj.xoff = [obj.xoff xoff];
                obj.yoff = [obj.yoff yoff];
                secondsElapsed = obj.index/obj.cameraFPS;
                obj.seconds = [obj.seconds secondsElapsed];
                if obj.index ~= 1
                    instVelocity = (x-prevX)*obj.conversion/(secondsElapsed - prevSecondsElapsed);
                else
                    instVelocity = 0;
                end
                obj.velocityTrack = [obj.velocityTrack instVelocity];
                xdisp = obj.xoff;
                ydisp = obj.yoff;
                time = obj.seconds;
                vel = obj.velocityTrack;
                obj.index = obj.index + 1;
                prevX = x;
                prevSecondsElapsed = secondsElapsed;
                settings_file_path = which('velocity.mat'); % Modify this to be better. There is no check on this and we should be using the saved_data_README.markdown as the file to look for anyhow
                save(settings_file_path, 'xdisp', 'ydisp', 'time', 'vel');
                % To have GUI table update continuously, remove nocallbacks
                drawnow limitrate nocallbacks;
                if obj.draw & ~obj.check_stop()
                    delete(hrect);
                end
                if obj.check_stop() 
                    Data = load('velocity.mat');
                    figure('Name', 'X Displacement Over Time');
                    plot(Data.time, Data.xdisp);

                    figure('Name', 'Velocity over Time');
                    plot(Data.time, Data.vel);
                    convertToCSV('velocity.mat') ;                    
                end
            end
        end

        function [xoffSet, yoffSet, dispx,dispy,x, y] = meas_displacement(obj)
            %% Whole Pixel Precision Coordinates
            img = obj.current_frame;
            [search_area, search_area_rect] = imcrop(img,[obj.search_area_xmin, obj.search_area_ymin, obj.search_area_width, obj.search_area_height]);
            c = normxcorr2(temp, search_area);
            [ypeak, xpeak] = find(c==max(c(:)));
            ypeak = ypeak - obj.rect(4); % account for the padding from normxcorr2
            xpeak = xpeak - obj.rect(3); % account for the padding from normxcorr2

            %% Subpixel Precision Coordinates

            % put the new min values relative to img, not search_area
            new_xmin = xpeak + round(search_area_rect(1)) - 1;
            new_ymin = ypeak + round(search_area_rect(2)) - 1;
            [moved_templated, displaced_rect] = imcrop(img, [new_xmin new_ymin, obj.rect(3) obj.rect(4)]);

            new_search_area_xmin = new_xmin - obj.min_displacement;
            new_search_area_ymin = new_ymin - obj.min_displacement;
            new_search_area_width = 2*obj.min_displacement  + obj.rect(3);
            new_search_area_height = 2*obj.min_displacement + obj.rect(4);

            [new_search_area, new_search_area_rect] = imcrop(img, [new_search_area_xmin new_search_area_ymin new_search_area_width new_search_area_height]);

            %% Interpolation
            %Interpolate both the new object area and the old and then compare
            %those that have subpixel precision in a normalized cross
            %correlation
            % BICUBIC INTERPOLATION - TEMPLATE
            interp_template = im2double(obj.template);
            [numRows,numCols,~] = size(interp_template); % Replace with rect?
            [X,Y] = meshgrid(1:numCols,1:numRows); %Generate a pair of coordinate axes
            [Xq,Yq]= meshgrid(1:obj.pixel_precision:numCols,1:obj.pixel_precision:numRows); %generate a pair of coordinate axes, but this time, increment the matrix by 0
            V=interp_template; %copy interp_template into V
            interp_template = interp2(X,Y,V,Xq,Yq, 'cubic');

            % BICUBIC INTERPOLATION - SEARCH AREA (FROM MOVED TEMPLATE
            interp_search_area = im2double(new_search_area);
            [numRows,numCols,~] = size(interp_search_area);
            [X,Y] = meshgrid(1:numCols,1:numRows);
            [Xq,Yq]= meshgrid(1:obj.pixel_precision:numCols,1:obj.pixel_precision:numRows);
            V=interp_search_area;
            interp_search_area = interp2(X,Y,V,Xq,Yq, 'cubic');

            c1 = normxcorr2(interp_template, interp_search_area);
            [new_ypeak, new_xpeak] = find(c1==max(c1(:)));
            new_xpeak = new_xpeak/(1/obj.pixel_precision);
            new_ypeak = new_ypeak/(1/obj.pixel_precision);
            new_xpeak = new_xpeak+round(new_search_area_rect(1));
            new_ypeak = new_ypeak+round(new_search_area_rect(2));

            yoffSet = new_ypeak-obj.rect(4);
            xoffSet = new_xpeak-obj.rect(3);

            %DISPLACEMENT IN PIXELS
            disp_y_pixel = new_ypeak-obj.ytemp;
            disp_x_pixel = new_xpeak-obj.xtemp;

            %DISPLACEMENT IN MICRONS
            dispx = disp_x_pixel * obj.res;
            dispy = disp_y_pixel * obj.res;

        end

        function [x_peak, y_peak, disp_x_pixel, disp_y_pixel, disp_x_micron, disp_y_micron] = meas_displacement_fourier(obj)
            %% Whole Pixel Precision Coordinates
            img = obj.current_frame;
            [search_area, ~] = imcrop(img,[obj.search_area_xmin, obj.search_area_ymin, obj.search_area_width, obj.search_area_height]);

            processed_search_area = obj.template_average - search_area;

            [ypeak, xpeak] = obj.fourier_cross_correlation(obj.fft_conj_processed_template, processed_search_area, obj.search_area_height, obj.search_area_width);

            new_xmin = xpeak - obj.min_displacement;
            new_ymin = ypeak - obj.min_displacement;

            %% Subpixel Precision Coordinates TODO: Refractor? This looks like a repetitive calculation

            new_width   = obj.rect(3)+2*obj.min_displacement;
            new_height  = obj.rect(4)+2*obj.min_displacement;
            [new_search_area, new_search_area_rect] = imcrop(search_area, [new_xmin new_ymin new_width new_height]);

            %% Interpolation
            %Interpolate both the new object area and the old and then compare
            %those that have subpixel precision in a normalized cross
            %correlation

            % BICUBIC INTERPOLATION - SEARCH AREA (FROM MOVED TEMPLATE
            interp_search_area = im2double(new_search_area);
            [numRows,numCols,~] = size(interp_search_area);
            [X,Y] = meshgrid(1:numCols,1:numRows);
            [Xq,Yq]= meshgrid(1:obj.pixel_precision:numCols,1:obj.pixel_precision:numRows);
            V=interp_search_area;
            interp_search_area = interp2(X,Y,V,Xq,Yq, 'cubic');

            processed_interp_search_area = obj.interp_template_average - interp_search_area;

            [new_ypeak, new_xpeak] = obj.fourier_cross_correlation(obj.fft_conj_processed_interp_template, processed_interp_search_area, obj.interp_search_area_height, obj.interp_search_area_width);

            new_ypeak = new_ypeak/(1/obj.pixel_precision);
            new_xpeak = new_xpeak/(1/obj.pixel_precision);

            y_peak = new_ypeak + obj.search_area_ymin + new_ymin;
            x_peak = new_xpeak + obj.search_area_xmin + new_xmin;

            %DISPLACEMENT IN PIXELS
            disp_y_pixel = new_ypeak-obj.ytemp;
            disp_x_pixel = new_xpeak-obj.xtemp;

            %DISPLACEMENT IN MICRONS
            disp_x_micron = disp_x_pixel * obj.res;
            disp_y_micron = disp_y_pixel * obj.res;
            
            if (y_peak > obj.rect(2)+10)
                "Hello"
            end
            

        end

        % Finds the cross correlation using fourier transforms
        % TODO: implement ability to be used for interpolated images
        function [ypeak, xpeak] = fourier_cross_correlation(obj, fft_conj_template, search_area, height, width)

                % TEMPLATE and SEARCH_AERA should be grayscaled images
                % Performs cross correlation of SEARCH_AREA and TEMPLATE
                % is not normalized and differs from normxcorr2
                % GRAYSCALE_INVERSION is the value used to invert the image
                % if it's a 255 bit image, it should be 120
                % if it's not (an the values range from 0...1, it should be 0.5
                % Or at least, I've had the most luck with these values
                % These values were gotten experimentally, they may need to be tweaked

                % Find the DTFT
                dtft_of_frame = fft2(search_area, height*2, width*2);

                % Take advantage of the correlation theorem
                % Corr(f, g) <=> element multiplication of F and conj(G) where F, G are
                % fourier transforms of the signals f, g
                R = dtft_of_frame.*fft_conj_template;
                R = R./abs(R); % normalize to get rid of values related to intensity of light
                r = real(ifft2(R));%, height, width));
                r = r(1:height, 1:width); % limit the location of where I look for the max

                [ypeak, xpeak] = find(r==max(r(:))); % the origin of where the template is
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
            bool = (~obj.valid && ~obj.validate(obj.error_tag)) | obj.vid_src.finished();
        end

        function vid_source = get.vid_src(obj)
            vid_source = obj.vid_src;
        end
        
        function valid = validate(obj)
            valid = obj.valid_max_displacement();
            valid = valid & obj.valid_pixel_precision();
        end

    end

end
