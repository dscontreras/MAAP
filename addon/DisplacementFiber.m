classdef DisplacementFiber < DisplacementOperation
    properties (SetAccess = private)
        search_rect = [1080 371 400 10];
        microns_per_pixel = 2.49;
        fps = 15;
    end

    methods
        function obj = DisplacementFiber(src, axes, table, error, img_cover, pause_button, pixel_precision, resolution, draw, conversion_rate, error_report_handle)
            obj = obj@DisplacementOperation(src, axes, table, error, img_cover, pause_button, pixel_precision, 0, 0, resolution, draw, error_report_handle);
            %obj.microns_per_pixel = conversion_rate;
        end
        
        function startup(obj)
            obj.valid = true;
            set(obj.img_cover, 'Visible', 'Off');
            set(obj.pause_button, 'Visible', 'On');
            obj.im = zeros(obj.source.get_num_pixels());
            obj.im = imshow(obj.im);
            colormap(gca, gray(256));
        end
        
        function execute(obj)
            displacement = [];
            velocity = [];
            time = [];
            started = false;
            startPos = -1;
            frameNum = 0;
            prevXPos = 0;
            prevSecondsElapsed = 0;
            while ~obj.source.finished()
                obj.current_frame = gather(grab_frame(obj.source, obj));
                frame = imgaussfilt(obj.current_frame, 0.5);
                frameNum = frameNum + 1;

                if obj.display
                    set(obj.im, 'CData', obj.current_frame);
                end

                cropped = imadjust(imcrop(frame, obj.search_rect), [.4; .5], [0; 1]);
                [~, xPixel] = find(max(cropped == 0), 1, 'last');
                xPixel = xPixel + obj.search_rect(1);
                if ~started
                    started = true;
                    startPos = xPixel;
                    prevXPos = xPixel*obj.microns_per_pixel;
                end
                pxDisp = xPixel - startPos;
                if abs(xPixel-startPos) <= 1
                    xPos = 0;
                else
                    xPos = obj.microns_per_pixel * (xPixel - startPos); % total x displacement in microns
                end
                xDisp = xPos - prevXPos; % x displacement in microns (curr frame - prev frame)
                yPos = obj.microns_per_pixel * obj.search_rect(2);
                displacement = [displacement pxDisp];
                secondsElapsed = frameNum/obj.fps; % time elapsed from start
                time = [time secondsElapsed];
                if frameNum ~= 1
                    instVelocity = xDisp/(secondsElapsed - prevSecondsElapsed);
                else
                    instVelocity = 0;
                end
                velocity = [velocity instVelocity];
                settings_file_path = which('velocity2.mat');
                save(settings_file_path, 'displacement', 'time', 'velocity');
                prevXPos = xPos;
                prevSecondsElapsed = secondsElapsed;
                hold on;
                plot(xPixel, obj.search_rect(2), 'r*');
                
                % To have GUI table update continuously, remove nocallbacks
                drawnow limitrate nocallbacks;
            end
            Data = load('velocity2.mat');
            figure('Name', 'X displacement over time');
            plot(Data.time, Data.displacement);
            
            figure('Name', 'Velocity over time');
            plot(Data.time, Data.velocity);
            csvwrite('fiber_displacement_output.csv', Data.displacement);
            csvwrite('fiber_velocity_output.csv', Data.velocity);
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