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
        table_data;
        im;
        res;
        display
        draw; % toggles imrect
        min_displacement;
        template_matcher;
    end

    properties
        % Inherited
        source; 
        
        dispx;
        dispy;
    end


    properties (SetAccess = public)
        valid;
        error_report_handle;
    end

    methods
        function obj = DisplacementOperation(src, pixel_precision, max_x_displacement, ...
                max_y_displacement, resolution, ...
                axes, table, error, img_cover, ...
                draw, display, error_report_handle)
            obj.source = src;
            obj.axes = axes;
            obj.table = table;
            obj.error_tag = error;
            obj.img_cover = img_cover;
            obj.pixel_precision = str2double(pixel_precision);
            obj.max_x_displacement = str2double(max_x_displacement);
            obj.max_y_displacement = str2double(max_y_displacement);
            obj.res = resolution;
            obj.valid = true;
            obj.draw = draw;
            obj.display = display;
            obj.dispx = [];
            obj.dispy = [];
            obj.min_displacement = 2; % Default Value; TODO: make changeable
            obj.valid = obj.validate();

            % Set up the csv to save the data to
            obj.data_save_path = create_csv_for_data('Displacement');
            add_headers(obj.data_save_path, 'frame_num', 'dispx', 'dispy');
            if(nargin > 12) % 12 is the number of params for displacement
            % TODO: Better Error Handling
                obj.error_report_handle = error_report_handle;
            end

            % Graphical Setup
            set(obj.img_cover, 'Visible', 'Off');
            obj.current_frame = obj.source.extractFrame(); % Get an rgb2gray value
            obj.im = zeros(size(obj.current_frame));
            colormap(gca, gray(256));
            obj.table_data = {'DispX'; 'DispY'; 'Velocity'};

            % Creates Template Matcher
            obj.current_frame = gather(rgb2gray(obj.current_frame));
            obj.create_template_matcher();
            
            obj.im = imshow(obj.im);
        end

        %For carrying out one time method calls that should be done before
        %calling of execute
        function startup(obj)
        end

        function create_template_matcher(obj)
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

            obj.template_matcher = TemplateMatcher(obj.pixel_precision, ...
                obj.max_x_displacement, obj.max_y_displacement, obj.template, ...
                obj.min_displacement, obj.current_frame);
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
                dispy = -disp_y_pixel*obj.res; % Invert y to make it clear that up is positive and down is negative

                % Update what's displayed on the GUI
                if obj.display
                    set(obj.im, 'CData', gather(obj.current_frame));
                end
            
                if obj.draw
                    hrect = imrect(obj.axes,[x_peak, y_peak, obj.rect(3), obj.rect(4)]);
                end

                % Update the table
                updateTable(obj.table, dispx, dispy);
                obj.dispx = [obj.dispx dispx];
                obj.dispy = [obj.dispy dispy];

                % To have GUI table update continuously, remove nocallbacks
                drawnow limitrate; % nocallbacks; % Uncomment this if you don't need every frame displacement
                if obj.draw
                    delete(hrect);
                end

                % Update csv file
                add_to_csv(obj.data_save_path, [frame_num, dispx, dispy])

                % Prepare for the next iteration
                obj.current_frame = gather(grab_frame(obj.source));
                frame_num = frame_num + 1;
            end
            imrect(obj.axes,[x_peak, y_peak, obj.rect(3) obj.rect(4)]);            
        end

        function valid = validate(obj)
            valid = obj.valid_max_displacement();
            valid = valid & obj.valid_pixel_precision();
        end

        % TODO: Fix the max_displacement test in order to also check obj.max_displacement_y
        function valid = valid_max_displacement(obj)
            valid = true;
            frame = grab_frame(obj.source);
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

        function pixel_precision = get_pixel_precision(obj)
            pixel_precision = obj.pixel_precision;
        end

        function bool = check_stop(obj)
            bool = (~obj.valid && ~obj.validate(obj.error_tag)) | obj.source.finished();
        end
    end
end