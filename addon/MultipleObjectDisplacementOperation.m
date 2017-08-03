classdef MultipleObjectDisplacementOperation < Operation

    properties
        source;
        pixel_precision;
        number_of_objects;
        rects;
        template_matchers;
        first_frame;
        res;
        xdiffs; ydiffs;
        
        axes;
        table;
        error_tag;
        img_cover;
        pause_button;
        new;
        valid;
        draw;
        display;
        name = 'MultipleObjectDisplacementOperation'
        im;
    end

    methods
        function obj = MultipleObjectDisplacementOperation(src, pixel_precision, resolution, ...
            axes, table, error, img_cover, pause_button, ...
                draw, display)
            obj.source = src;
            obj.axes = axes;
            obj.table = table;
            obj.error_tag = error;
            obj.img_cover = img_cover;
            set(obj.img_cover, 'Visible', 'off')
            obj.pause_button = pause_button;
            obj.pixel_precision = str2double(pixel_precision);
            obj.res = resolution;
            obj.new = true;
            obj.valid = true;
            obj.draw = draw;
            obj.display = display;
            obj.first_frame = rgb2gray(obj.source.extractFrame());
            obj.template_matchers = {};
            obj.number_of_objects = 0;
        end

        function add_template_matcher(obj, template, max_displacement_x, max_displacement_y)
            obj.number_of_objects = obj.number_of_objects + 1;
            obj.template_matchers{obj.number_of_objects} = TemplateMatcher(obj.pixel_precision, max_displacement_x, max_displacement_y, template, 2, obj.first_frame);
        end

        % For use with GUI, 
        % Let the user draw something. In general, should only be used at
        % the very beginning
        function crop_template(obj, max_x_disp, max_y_disp)
            [vid_height, vid_width] = size(obj.first_frame);
            [temp, rect] = get_template(obj.first_frame, obj.axes, vid_height, vid_width);
            obj.add_template_matcher(temp, max_x_disp, max_y_disp); 
        end

        function execute(obj)
            img = obj.first_frame;
            frame_num = 1;
            hrects = cell(1, obj.number_of_objects);
            while ~obj.source.finished()
                % TODO: remove assumption that the source is of type VideoSource
                for idx = 1:obj.number_of_objects
                    tm = obj.template_matchers{idx};
                    [y_peak, x_peak, disp_y_pixel, disp_x_pixel] = tm.meas_displacement(img);
                    obj.xdiffs(idx, frame_num) = x_peak;
                    obj.ydiffs(idx, frame_num) = y_peak;
                    
                    % Update the GUI
                    if obj.display % Show the video
                        set(obj.im, 'CData', gather(img))
                    end
                    if obj.draw % Show the box
                        hrect = imrect(obj.axes, [x_peak, y_peak, tm.rect(3), tm.rect(4)]);
                        hrects{idx} = hrect; % Add to the list of rects
                    end
                    drawnow limitrate
                end
                
                % Prepare for the next iteration
                img = rgb2gray(obj.source.extractFrame());
                frame_num = frame_num + 1;

                % Remove all the hrect values
                if obj.draw
                    for idx = 1:numel(hrects)
                        delete(hrects{idx});
                    end
                end
            end
        end

        function startup(obj)
            obj.valid = obj.validate();
            
            % xdiffs, ydiffs has to be initialzed after obj.number_of_objects is set
            obj.xdiffs = zeros(obj.number_of_objects);
            obj.ydiffs = zeros(obj.number_of_objects);

            % Show on the image viewer in the GUI
            obj.im = zeros(obj.source.get_num_pixels());
            obj.im = imshow(obj.im);
            colormap(gca, gray(256));
        end

        function valid = validate(obj)
            valid = true;
        end
    end

end
