classdef Velocity < RepeatableOperation
    % Velocity
    % Given a video, finds the speed and displacement of the template
    % within the video 
    
    properties (SetAccess = private)
        scale_img; % image that contains scale
        displacement;
        calibration; % converts px to um
        scale_length;
        img_cover;
        pause_button;
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
        insertion_type = 'start'; %%% or end?
        camera_fps = 15; % Pister lab camera fps
    end
    
    methods
        function obj = Velocity(src, axes, table, error, img_cover, pause_button,... 
                pixel_precision, max_displacement, resolution, ...
                scale_img, scale_length, error_report_handle)
            
            obj.scale_img = scale_img;
            obj.displacement = Displacement(src, axes, table, error, ...
                img_cover, pause_button, pixel_precision, max_displacement,...
                resolution, draw, error_report_handle);
            
            obj.scale_length = scale_length;
            obj.img_cover = img_cover;
            obj.pause_button = pause_button;
        end
        
        %For carrying out one time method calls that should be done before
        %calling of execute
        function startup(obj)
            set(obj.img_cover, 'Visible', 'Off');
            set(obj.pause_button, 'Visible', 'On');
            obj.initialize_algorithm();
            %obj.displacement.startup();
        end  
        
        function initialize_algorithm(obj)
            imshow(obj.scale_img);
            scale = imdistline;
            user_input = iptgetapi(scale);
            dist_in_pixels = user_input.getDistance();
            obj.calibration = obj.scale_length / dist_in_pixels;
            obj.finished();
        end
        
        function bool = finished(obj)
            bool = 1;
        end
    end    
end