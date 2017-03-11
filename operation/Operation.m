classdef Operation < handle
    %OPERATION Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods (Static)
        function playVideo(path, colorspace, axes)
            videoReader = vision.VideoFileReader(path);
            if(strcmp(colorspace, 'none'))
                while(~isDone(videoReader))
                    draw_frame(videoReader, axes);
                end
            else
                while(~isDone(videoReader))
                    frame = step(videoReader);
                    if(strcmp(colorspace, 'intensity'))
                        frame = rgb2gray(frame);                        
                    end
                    imshow(frame, 'Parent', axes);
                    drawnow;
                end
            end
        end

        function draw_frame(videoReader, axes)
            frame = step(videoReader);
            imshow(frame, 'Parent', axes);
            drawnow;
        end

        function get_displacement(path, colorspace, pixel_precision, max_displacement)
            
        end
        
        function frame_capture(source, number, interval, key)

        end

        function take_picture()

        end

        function get_voltage() %UNIMPLEMENTED

        end

        function handle_sub_functions(sub_functions, sub_function_params)
            for i = 1:length(sub_functions)
                a = sub_functions(i);
                
                a();
            end
        end

    end
    
end

