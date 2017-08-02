classdef MultipleObjectDisplacementOperation < Operation

    properties
        source;
        pixel_precision;
        number_of_objects;
        rects;
        template_matchers;
        first_frame;
        res;
    end

    methods
        function obj = MultipleObjectDisplacementOperation(src, pixel_precision, resolution_meters, ...
            axes, table, error, img_cover, pause_button, ...
                draw, display, error_report_handle)
            if nargin == 12
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
            else
                obj.source = src;
                obj.pixel_precision = pixel_precision;
                obj.max_x_displacement = max_x_displacement;
                obj.max_y_displacement = max_y_displacement;
                if nargin == 4 % No resolution input
                    obj.res = 5.85E-6; % This is just the default swarm Lab
                end
                obj.using_gui = false;
            end
        end

        function add_template_matcher(obj, template, max_displacement_x, max_displacement_y)
            obj.number_of_objects = obj.number_of_objects + 1;
            obj.template_matchers{obj.number_of_objects} = TemplateMatcher(obj.pixel_precision, max_displacement_x, max_displacement_y, template, 2, 20, obj.first_frame);
        end

        % For use with GUI, 
        % Let the user draw something
        function add_template(obj)
            [vid_height, vid_width] = size(obj.first_frame);
            [obj.template, obj.rect, obj.xtemp, obj.ytemp] = get_template(obj.current_frame, obj.axes, vid_height, vid_width);
            obj.rect = ceil(obj.rect);
        end

        function execute(obj)
            while ~obj.source.finished()
                % TODO: remove assumption that the source is of type VideoSource
                img = rgb2gray(obj.source.extractFrame());
                for idx = 1:numel(obj.template_matchers)
                    [y_peak, x_peak, disp_y_pixel, disp_x_pixel] = obj.template_matchers{idx}.meas_displacement(img);
                end
            end
        end

        function startup(obj)
        end

        function valid = validate(obj)
            valid = true;
        end
    end

end
