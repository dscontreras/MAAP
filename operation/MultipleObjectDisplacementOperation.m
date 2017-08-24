classdef MultipleObjectDisplacementOperation < Operation

    properties
        source;
        pixel_precision;
        number_of_objects;
        rects;
        template_matchers;
        current_frame;
        res;
        xdiffs; ydiffs;
        
        axes;
        table;
        error_tag;
        img_cover;
        new;
        valid;
        draw;
        display;
        im;
    end

    methods
        function obj = MultipleObjectDisplacementOperation(src, pixel_precision, resolution, ...
            axes, table, error, img_cover, ...
                draw, display)
            obj.source = src;
            obj.axes = axes;
            obj.table = table;
            obj.error_tag = error;
            obj.img_cover = img_cover;
            obj.pixel_precision = str2double(pixel_precision);
            obj.res = resolution;
            obj.new = true;
            obj.valid = true;
            obj.draw = draw;
            obj.display = display;
            obj.current_frame = grab_frame(obj.source);
            obj.template_matchers = {};
            obj.number_of_objects = 0;

            set(obj.img_cover, 'Visible', 'off')

            % Set up csv to save data
            obj.data_save_path = create_csv_for_data('Displacement');
        end

        function add_template_matcher(obj, template, max_displacement_x, max_displacement_y)
            obj.number_of_objects = obj.number_of_objects + 1;
            obj.template_matchers{obj.number_of_objects} = TemplateMatcher(obj.pixel_precision, max_displacement_x, max_displacement_y, template, 2, obj.current_frame);
        end

        % For use with GUI, 
        % Let the user draw something. In general, should only be used at
        % the very beginning
        function crop_template(obj, max_x_disp, max_y_disp)
            [vid_height, vid_width] = size(obj.current_frame);
            [temp, rect] = get_template(obj.current_frame, obj.axes, vid_height, vid_width);
            obj.add_template_matcher(temp, max_x_disp, max_y_disp); 
        end

        function execute(obj)
            img = obj.current_frame;
            frame_num = 1;
            hrects = cell(1, obj.number_of_objects);

            % This is the data I'll be writing to the CSV
            data_to_save = zeros(1, obj.number_of_objects*2 + 1);
            while ~obj.source.finished()
                % TODO: remove assumption that the source is of type VideoSource
                data_to_save(1) = frame_num;
                for idx = 1:obj.number_of_objects
                    tm = obj.template_matchers{idx};
                    [y_peak, x_peak, disp_y_pixel, disp_x_pixel] = tm.meas_displacement(img);
                    obj.ydiffs(idx, frame_num) = disp_y_pixel*obj.res;
                    obj.xdiffs(idx, frame_num) = disp_x_pixel*obj.res;
                    
                    % Update the GUI
                    if obj.display % Show the video
                        set(obj.im, 'CData', gather(img))
                    end
                    if obj.draw % Show the box
                        hrect = imrect(obj.axes, [x_peak, y_peak, tm.rect(3), tm.rect(4)]);
                        hrects{idx} = hrect; % Add to the list of rects
                    end
                    drawnow limitrate
                    data_to_save(2*idx) = disp_x_pixel*obj.res;
                    data_to_save(2*idx + 1) = disp_y_pixel*obj.res;
                end
                
                % Prepare for the next iteration
                img = grab_frame(obj.source);
                frame_num = frame_num + 1;

                % Remove all the hrect values
                if obj.draw
                    for idx = 1:numel(hrects)
                        delete(hrects{idx});
                    end
                end

                % Update my data_csv
                add_to_csv(obj.data_save_path, data_to_save)
            end
        end

        function startup(obj)
            
            % xdiffs, ydiffs has to be initialzed after obj.number_of_objects is set
            obj.xdiffs = zeros(obj.number_of_objects);
            obj.ydiffs = zeros(obj.number_of_objects);

            header_str = 'frame_num';
            for idx = 1:obj.number_of_objects
                idx = int2str(idx);
                header_str = [header_str ',' 'dispx' idx ',' 'dispy' idx];
            end

            add_headers(obj.data_save_path, header_str);

            % Show on the image viewer in the GUI
            obj.im = zeros([size(obj.current_frame) 3]);
            obj.im = imshow(obj.im);
            colormap(gca, gray(256));

            obj.valid = obj.validate();
        end

        function valid = validate(obj)
            valid = true;
        end
    end

end
