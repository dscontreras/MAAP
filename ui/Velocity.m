classdef Velocity < RepeatableOperation
    % Velocity
    % Given a video, finds the speed and displacement of the template
    % within the video 
    
    properties (SetAccess = private)
        scale_img; % image that contains scale
        calibration; % converts px to um
        scale_length;
        img_cover;
        pause_button;
        stop_check_callback = @check_stop;
        vid_src;
        axes;
        table;
        error; 
        pixel_precision;
        max_displacement; 
        res;
        xoff; yoff;
        table_data;
        current_frame;
        im;
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
        name = 'Velocity';
        insertion_type = 'end'; 
        camera_fps = 15; % Pister lab camera fps
    end
    
    methods
        function obj = Velocity(src, axes, table, error, img_cover, pause_button,... 
                pixel_precision, max_displacement, resolution, ...
                scale_img, scale_length, error_report_handle)
            obj.scale_img = imread(scale_img);
            obj.scale_length = scale_length;
            obj.img_cover = img_cover;
            obj.pause_button = pause_button;
            obj.vid_src = src;
            obj.new = true;
            obj.valid = true;
            obj.axes = axes;
            obj.table = table;
            obj.error = error;
            obj.pixel_precision = str2double(pixel_precision);
            obj.max_displacement = str2double(max_displacement);
            obj.res = resolution;
            obj.outputs('dispx') = 0;
            obj.outputs('dispy') = 0;
            obj.outputs('velocity') = 0;
            obj.outputs('done') = false;
            obj.xoff = [];
            obj.yoff = [];
            if(nargin > 11) % 11 is the number of params for velocity
                obj.error_report_handle = error_report_handle;
            end   
        end
        
        %For carrying out one time method calls that should be done before
        %calling of execute
        function startup(obj)
            set(obj.img_cover, 'Visible', 'Off');
            %imshow(obj.scale_img);
            set(obj.pause_button, 'Visible', 'On');
            obj.table_data = {'DispX'; 'DispY'; 'Velocity'};
            obj.im = zeros(obj.vid_src.get_num_pixels());
            distance = get_line(obj.scale_img, obj.axes);
            obj.calibration = obj.scale_length / distance;
            %obj.im = imshow(obj.im);
        end  
        
        function execute(obj)
            return;
        end
        
        function bool = check_stop(obj)
            bool = true;
        end
        
        function valid = validate(obj, error_tag)
            valid = obj.displacement.validate(error_tag);
        end
        
        function bool = paused(obj)
            bool = false;
        end
    end    
end