classdef DisplacementFiber < DisplacementOperation
    properties (SetAccess = private)
        search_rect = [1080 371 400 10];
        microns_per_pixel = 2.49;
        fps = 15;
    end

    methods
        function obj = DisplacementFiber(src, axes, table, error, img_cover, pause_button, pixel_precision, resolution, draw, error_report_handle)
            obj = obj@DisplacementOperation(src, axes, table, error, img_cover, pause_button, pixel_precision, 0, 0, resolution, draw, error_report_handle);
        end
        
        function startup(obj)
            obj.valid = true;
            set(obj.img_cover, 'Visible', 'Off');
            set(obj.pause_button, 'Visible', 'On');
            obj.im = zeros(obj.source.get_num_pixels());
            obj.im = imshow(obj.im);
        end
        
        function execute(obj)
            displacement = [];
            started = false;
            startPos = -1;
            frameNum = 0;
            while ~obj.source.finished()
                obj.current_frame = gather(rgb2gray(obj.source.extractFrame()));
                frameNum = frameNum + 1;

                if obj.display
                    set(obj.im, 'CData', gather(obj.current_frame));
                end

                cropped = imadjust(imcrop(obj.current_frame, obj.search_rect), [.4; .5], [0; 1]);
                [~, xPixel] = find(max(cropped == 0), 1, 'last');
                xPixel = xPixel + obj.search_rect(1);
                if ~started
                    started = true;
                    startPos = xPixel;
                end
                
                xPos = obj.microns_per_pixel * (xPixel - startPos);
                yPos = obj.microns_per_pixel * obj.search_rect(2);
                displacement = [displacement; [frameNum / obj.fps, xPos]];
                
                hold on;
                plot(xPixel, obj.search_rect(2), 'r*');
                
                % To have GUI table update continuously, remove nocallbacks
                drawnow limitrate nocallbacks;
            end
            csvwrite('fiber_displacement_output.csv', displacement);
        end
        
        function valid = validate(obj)
            valid = obj.valid;
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
    end
end