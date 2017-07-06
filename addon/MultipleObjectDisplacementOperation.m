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
        function obj = MultipleObjectDisplacementOperation(src, pixel_precision, resolution_meters)
            obj.source = src;
            obj.first_frame = obj.source.extractFrame();
            obj.pixel_precision = pixel_precision;
            obj.number_of_objects = 0;
            obj.rects = [];
            obj.template_matchers = [];
            obj.res = resolution_meters;
        end

        function add_template_matcher(obj, template_file_path, max_displacement_x, max_displacement_y)
            obj.number_of_objects = obj.number_of_objects + 1;
            obj.template_matchers{obj.number_of_objects} = TemplateMatcher(obj.source, obj.pixel_precision, max_displacement_x, max_displacement_y, template_file_path, 2, 20, obj.first_frame);
        end

        function execute(obj)
            while ~obj.source.finished()
                % TODO: remove assumption that the source is of type VideoSource
                img = rgb2gray(obj.source.extractFrame());
                for idx = 1:numel(obj.template_matchers)
                    [y_peak, x_peak, disp_y_pixel, disp_x_pixel] = obj.template_matchers{idx}.meas_displacement_fourier(img);
                    [y_peak, x_peak]
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
