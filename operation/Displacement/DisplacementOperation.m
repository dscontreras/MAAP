classdef DisplacementOperation < Operation
    % Displacement
    % Given a video, finds the location of the a template image within the
    % video and finds the displacement between the first frame and every
    % frame within the video.

    properties (SetAccess = protected)
        axes;
        error_tag;
        pixel_precision;
        max_x_displacement;
        max_y_displacement;
        template; rect; xtemp; ytemp;
        current_frame;
        table;
        img_cover;
        pause_button;
        table_data;
        stop_check_callback = @check_stop;
        im;
        res;
        xoff; yoff;
        display
        draw; % toggles imrect
        min_displacement;
        template_matcher;

        data_save_path;
    end

    properties
        % Inherited
        source;
        dispx;
        dispy;
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
        name = 'Displacement';
        insertion_type = 'end';
    end

    methods
        function obj = DisplacementOperation(src, pixel_precision, max_x_displacement, ...
                max_y_displacement, resolution, ...
                axes, table, error, img_cover, pause_button, ...
                draw, display, error_report_handle)
            obj.source = src;
            obj.axes = axes;
            obj.table = table;
            obj.error_tag = error;
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
            obj.draw = draw;
            obj.display = display;
            obj.dispx = [];
            obj.dispy = [];
            obj.min_displacement = 2; % Default Value; TODO: make changeable

            obj.data_save_path = create_csv_for_data('Descriptor')
            add_headers(obj.data_save_path, 'frame_num', 'dispx', 'dispy');
            if(nargin > 12) % 12 is the number of params for displacement
            % TODO: Better Error Handling
                obj.error_report_handle = error_report_handle;
            end
        end

        %For carrying out one time method calls that should be done before
        %calling of execute
        function startup(obj)
            %obj.valid = obj.validate(obj.error_tag);
            % Hack to get the scripting side a little easier
            obj.valid = obj.validate();
            set(obj.img_cover, 'Visible', 'Off');
            set(obj.pause_button, 'Visible', 'On');
            % initialize algorithm must go these two set functions
            obj.initialize_algorithm();
            obj.table_data = {'DispX'; 'DispY'; 'Velocity'};
            obj.im = zeros(obj.source.get_num_pixels());
            obj.im = imshow(obj.im);
            colormap(gca, gray(256));
        end

        function initialize_algorithm(obj)
            obj.current_frame = gather(rgb2gray(obj.source.extractFrame()));
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

            obj.template_matcher = TemplateMatcher(obj.pixel_precision, obj.max_x_displacement, obj.max_y_displacement, obj.template, obj.min_displacement, obj.current_frame);
            obj.template_matcher.change_template(obj.template, obj.rect); % Make sure the template is what it should be. 
            % Remember that `temp` and obj.template are not the same so the
            % `find_rect` inside TemplateMatcher gives us a different
            % result. 
        end

        function execute(obj)
            frame_num = 1;
            while ~obj.source.finished()
                % obj.current_frame should already be set from initialize_algorithm
                % TODO: Add ability to use GPU
                [y_peak, x_peak, disp_y_pixel,disp_x_pixel] = obj.template_matcher.meas_displacement_norm_cross_correlation(obj.current_frame);
                dispx = disp_x_pixel*obj.res;
                dispy = disp_y_pixel*obj.res;

                % Update what's displayed on the GUI
                if obj.display
                    set(obj.im, 'CData', gather(obj.current_frame));
                end
            
                if obj.draw
                    hrect = imrect(obj.axes,[x_peak, y_peak, obj.rect(3), obj.rect(4)]);
                end
                % Update the table
                updateTable(dispx, dispy, obj.table);
                obj.dispx = [obj.dispx dispx];
                obj.dispy = [obj.dispy -dispy]; % Invert y to make it clear that up is positive and down is negative

                % To have GUI table update continuously, remove nocallbacks
                drawnow limitrate; % nocallbacks; % Uncomment this if you don't need every frame displacement
                if obj.draw == 1 & ~obj.check_stop()
                    delete(hrect);
                end

                % Update csv file
                add_to_csv(obj.data_save_path, [frame_num, dispx, dispy])

                % Prepare for the next iteration
                obj.current_frame = gather(rgb2gray(obj.source.extractFrame()));
                frame_num = frame_num + 1;
            end
            imrect(obj.axes,[x_peak, y_peak, obj.rect(3) obj.rect(4)]);            
        end

        function [x_peak, y_peak, disp_x_micron,disp_y_micron,disp_x_pixel, disp_y_pixel] = meas_displacement(obj)
            % Whole Pixel Precision Coordinates
            img = obj.current_frame;
            [search_area, search_area_rect] = imcrop(img,[obj.search_area_xmin, obj.search_area_ymin, obj.search_area_width, obj.search_area_height]);

            c = normxcorr2(obj.template, search_area);
            [ypeak, xpeak] = find(c==max(c(:)));
            ypeak = ypeak - obj.rect(4); % account for the padding from normxcorr2
            xpeak = xpeak - obj.rect(3); % account for the padding from normxcorr2

            % Subpixel Precision Coordinates

            % put the new min values relative to img, not search_area
            new_xmin = xpeak + round(search_area_rect(1)) - 1;
            new_ymin = ypeak + round(search_area_rect(2)) - 1;
            [moved_templated, displaced_rect] = imcrop(img, [new_xmin new_ymin, obj.rect(3) obj.rect(4)]);

            new_search_area_xmin = new_xmin - obj.min_displacement;
            new_search_area_ymin = new_ymin - obj.min_displacement;
            new_search_area_width = 2*obj.min_displacement  + obj.rect(3);
            new_search_area_height = 2*obj.min_displacement + obj.rect(4);

            [new_search_area, new_search_area_rect] = imcrop(img, [new_search_area_xmin new_search_area_ymin new_search_area_width new_search_area_height]);

            % Interpolation
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

            % ERROR? It subtracts the size(template) not
            % size(interp_template)
            y_peak = new_ypeak-obj.rect(4);
            x_peak = new_xpeak-obj.rect(3);
            %yoffSet = new_ypeak - size(interp_template, 1);
            %xoffSet = new_xpeak - size(interp_template, 2);

            %DISPLACEMENT IN PIXELS
            disp_x_pixel = new_xpeak-obj.ytemp;
            disp_y_pixel = new_ypeak-obj.xtemp;

            %DISPLACEMENT IN MICRONS
            disp_x_micron = disp_x_pixel * obj.res;
            disp_y_micron = disp_y_pixel * obj.res;

        end

        function valid = validate(obj)
            valid = obj.valid_max_displacement();
            valid = valid & obj.valid_pixel_precision();
        end

        % TODO: Fix the max_displacement test in order to also check obj.max_displacement_y
        function valid = valid_max_displacement(obj)
            valid = true;
            frame = obj.source.extractFrame();
            if(size(frame, 2) <= obj.max_x_displacement || isnan(obj.max_x_displacement) || size(frame, 1) <= obj.max_x_displacement)
                valid = false;
            end
            if (size(frame, 2) <= obj.max_y_displacement || isnan(obj.max_y_displacement) || size(frame, 1) <= obj.max_y_displacement)
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

        function pixel_precision = get_pixel_precision(obj)
            pixel_precision = obj.pixel_precision;
        end

        function bool = check_stop(obj)
            bool = (~obj.valid && ~obj.validate(obj.error_tag)) | obj.source.finished();
        end
    end
end