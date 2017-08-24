classdef DisplacementFiber < DisplacementOperation
    properties (SetAccess = private)
        search_rect = [1080 371 400 10];
        microns_per_pixel = 2.49;
        fps = 15;
    end

    methods
        function obj = DisplacementFiber(src, pixel_precision, resolution, axes, table, error, img_cover, draw, conversion_rate, error_report_handle)
            obj = obj@DisplacementOperation(src, pixel_precision, 0, 0, resolution, ...
                axes, table, error, img_cover, draw, true, false, error_report_handle);
            % TODO: Change assumption that display = true
            %obj.microns_per_pixel = conversion_rate;
            obj.valid = true; % TODO: better valid. For now, however, we'll leave that to the user

            % Set up the image viewer
            set(obj.img_cover, 'Visible', 'Off');
            obj.im = zeros(size(obj.current_frame));
            obj.im = imshow(obj.im);
            colormap(gca, gray(256));
        end
        
        function startup(obj)
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
            prevXPixel = 0;
            while ~obj.source.finished()
                obj.current_frame = gather(grab_frame(obj.source));
                frame = imgaussfilt(obj.current_frame, 2);
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
                    prevXPos = (xPixel-startPos)*obj.microns_per_pixel;
                    prevXPixel = xPixel;
                end
              
                xPos = obj.microns_per_pixel * (xPixel - startPos); % total x displacement in microns
                xDisp = xPos - prevXPos; % x displacement in microns (curr frame - prev frame)
                
                yPos = obj.microns_per_pixel * obj.search_rect(2);
                displacement = [displacement xPos];
                secondsElapsed = frameNum/obj.fps; % time elapsed from start
                time = [time secondsElapsed];
                if frameNum ~= 1
                    instVelocity = xDisp/(secondsElapsed - prevSecondsElapsed);
                else
                    instVelocity = 0;
                end
                velocity = [velocity instVelocity];

                % Save data
                % TODO
                full_path = what('saved_data'); 
                [parentdir, ~, ~] = fileparts(full_path.path);
                mat_file_path = [parentdir '/velocity2.mat'];
                save(mat_file_path, 'displacement', 'time', 'velocity');
                prevXPos = xPos;
                prevXPixel = xPixel;
                prevSecondsElapsed = secondsElapsed;
                hold on;
                plot(xPixel, obj.search_rect(2), 'r*');
                
                % To have GUI table update continuously, remove nocallbacks
                drawnow limitrate nocallbacks;
            end
            Data = load(mat_file_path);
            figure('Name', 'X displacement over time');
            plot(Data.time, Data.displacement);
            
            figure('Name', 'Velocity over time');
            plot(Data.time, Data.velocity);
            convertToCSV(mat_file_path, 'DisplacementFiber')
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