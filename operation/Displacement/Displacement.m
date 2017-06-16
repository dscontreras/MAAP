classdef Displacement < RepeatableOperation
    % Displacement
    % Given a video, finds the location of the a template image within the
    % video and findes the displacement between the first frame and every
    % frame within the video. 
    
    properties (SetAccess = private) 
        vid_src;
        axes;
        error_tag;
        pixel_precision;
        max_displacement;
        template; rect; xtemp; ytemp;
        current_frame;
        table;
        img_cover;
        pause_button;
        table_data;
        stop_check_callback = @check_stop;
        im;
        res;
        xoff;
        yoff;
        
        % 
        search_area_width; search_area_height;
        search_area_xmin; search_area_ymin;
        min_displacement; 
        
        % Properties for use when using fft2
        fft_conj_template;
        template_padded;
        template_grayscale_inverted;
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
        insertion_type = 'end';
    end

    methods
        function obj = Displacement(src, axes, table, error, img_cover, pause_button, pixel_precision, max_displacement, resolution, error_report_handle)
            obj.vid_src = src;
            obj.axes = axes;
            obj.table = table;
            obj.error_tag = error;
            obj.img_cover = img_cover;
            obj.pause_button = pause_button;
            obj.pause_bool = false;
            obj.pixel_precision = str2double(pixel_precision);
            obj.max_displacement = str2double(max_displacement);
            obj.res = resolution;
            obj.new = true;
            obj.valid = true;
            obj.outputs('dispx') = 0;
            obj.outputs('dispy') = 0;
            obj.outputs('done') = false;
            obj.queue_index = -1;
            obj.xoff = [];
            obj.yoff = [];
            obj.min_displacement = 2; % Default Value; TODO: make changeable
            
            % TODO: Better Error Handling
            if(nargin > 9) %8 is the number of params for displacement
                obj.error_report_handle = error_report_handle;
            end
        end

        %For carrying out one time method calls that should be done before
        %calling of execute
        function startup(obj)
            obj.valid = obj.validate(obj.error_tag);
            set(obj.img_cover, 'Visible', 'Off');
            set(obj.pause_button, 'Visible', 'On');
            obj.initialize_algorithm();
            obj.table_data = {'DispX'; 'DispY'};
            obj.im = zeros(obj.vid_src.get_num_pixels());
            obj.im = imshow(obj.im);
        end
       
        function initialize_algorithm(obj)
            obj.current_frame = gather(grab_frame(obj.vid_src, obj));
            [obj.template, obj.rect, obj.xtemp, obj.ytemp] = get_template(obj.current_frame, obj.axes);
            obj.rect = ceil(obj.rect); 
            
            % 
            obj.search_area_height  = 2 * obj.max_displacement + obj.rect(3);
            obj.search_area_width   = 2 * obj.max_displacement + obj.rect(4);
            obj.search_area_xmin    = obj.rect(1) - obj.max_displacement;
            obj.search_area_ymin    = obj.rect(2) - obj.max_displacement;
            
            % Begin Fourier Method Code
            obj.search_area_width = 2*obj.max_displacement + obj.rect(3);
            obj.search_area_height = 2*obj.max_displacement + obj.rect(4);
            
            obj.template_grayscale_inverted = (120 - obj.template)*2; % Assumes image is 255 bit grayscale
            
            % + 1 needed as imcrop(I, rect) adds 1 to each dimension
            obj.template_padded = padarray(obj.template_grayscale_inverted, [(2*obj.search_area_height - obj.rect(4) + 1), (2*obj.search_area_width - obj.rect(3) + 1)], 'post');
            obj.fft_conj_template = conj(fft2(obj.template_padded));
            
        end
        
        function execute(obj)  
            obj.current_frame = gather(grab_frame(obj.vid_src, obj));
            if(strcmp(VideoSource.getSourceType(obj.vid_src), 'file'))
                if(obj.vid_src.gpu_supported)
                    % [xoffSet, yoffSet, dispx,dispy,x, y] = meas_displacement_gpu_array(obj.template,obj.rect,obj.current_frame, obj.xtemp, obj.ytemp, obj.max_displacement, obj.res);
                    % [xoffSet, yoffSet, dispx,dispy,x, y] = meas_displacement_subpixel_gpu_array(obj.template,obj.rect,obj.current_frame, obj.xtemp, obj.ytemp, obj.pixel_precision, obj.max_displacement, obj.res);
                else
                    [xoffSet, yoffSet, dispx,dispy,x, y] = obj.meas_displacement();
                    % [xoffSet, yoffSet, dispx,dispy,x, y] = meas_displacement_fourier(obj.template,obj.rect,obj.current_frame, obj.xtemp, obj.ytemp, obj.pixel_precision, obj.max_displacement, obj.res, obj.fft_conj_template);
                end
            else
                if(obj.vid_src.gpu_supported)
                    [xoffSet, yoffSet, dispx,dispy,x, y] = meas_displacement_gpu_array(obj.template,obj.rect,obj.current_frame, obj.xtemp, obj.ytemp, obj.max_displacement, obj.res);
                else
                    [xoffSet, yoffSet, dispx, dispy, x, y] = meas_displacement(obj.template,obj.rect,obj.current_frame, obj.xtemp, obj.ytemp, obj.pixel_precision, obj.max_displacement, obj.res);
                end
            end
            
            obj.im.CData = obj.current_frame;
            updateTable(dispx, dispy, obj.table);
            obj.outputs('dispx') = [obj.outputs('dispx') dispx];
            obj.outputs('dispy') = [obj.outputs('dispy') dispy];
            obj.outputs('done') = obj.check_stop();
            if obj.check_stop()
                % draws rect around last location of template in blue %
                draw_rect(obj.current_frame, obj.im, xoffSet, yoffSet, obj.template, obj.axes);
                % draws rect around first location of template in red %
                h = imrect(obj.axes, [obj.rect(1), obj.rect(2), obj.rect(3), obj.rect(4)]);
                setColor(h, 'red');
            end
            obj.xoff = [obj.xoff xoffSet];
            obj.yoff = [obj.yoff yoffSet];
            xoff3 = obj.xoff;
            yoff3 = obj.yoff;
            save('gpu_displacement.mat', 'xoff3', 'yoff3');
            drawnow limitrate nocallbacks;
        end

        function [xoffSet, yoffSet, dispx,dispy,x, y] = meas_displacement(obj)
            %% Whole Pixel Precision Coordinates
            img = obj.current_frame;
            [search_area, search_area_rect] = imcrop(img,[obj.search_area_xmin, obj.search_area_ymin, obj.search_area_width, obj.search_area_height]);
            c = normxcorr2(obj.template, search_area);
            [ypeak, xpeak] = find(c==max(c(:)));
             
            % Shouldn't we be subtracting to account for normxcorr2
            % padding? 
            xpeak = xpeak + round(search_area_rect(1)) - 1;%move xpeak to the other side of the template rect.
            ypeak = ypeak + round(search_area_rect(2)) - 1;%move ypeak down to the bottom of the template rect.
            %% Subpixel Precision Coordinates
            
            % What? 
            new_xmin = xpeak - obj.rect(3);
            new_ymin = ypeak - obj.rect(4);
            [moved_templated, displaced_rect] = imcrop(img, [new_xmin new_ymin, obj.rect(3) obj.rect(4)]);
            
            new_search_area_xmin = new_xmin - obj.min_displacement;
            new_search_area_ymin = new_ymin - obj.min_displacement; 
            new_search_area_width = 2*obj.min_displacement  + obj.rect(3);
            new_search_area_height = 2*obj.min_displacement + obj.rect(4);
            
            [new_search_area, new_search_area_rect] = imcrop(img, [new_search_area_xmin new_search_area_ymin new_search_area_width new_search_area_height]);
            
            %% Interpolation
            %Interpolate both the new object area and the old and then compare
            %those that have subpixel precision in a normalized cross
            %correlation
            % BICUBIC INTERPOLATION - TEMPLATE
            interp_template = im2double(obj.template);
            [numRows,numCols,~] = size(interp_template); % Replace with rect? 
            [X,Y] = meshgrid(1:numCols,1:numRows); %Generate a pair of coordinate axes
            [Xq,Yq]= meshgrid(1:obj.pixel_precision:numCols,1:obj.pixel_precision:numRows); %generate a pair of coordinate axes, but this time, increment the matrix by 0
            V=interp_template; %copy interp_template into V
            interp_template = interp2(X,Y,V,Xq,Yq, 'cubic');

            % BICUBIC INTERPOLATION - SEARCH AREA (FROM MOVED TEMPLATE
            interp_search_area = im2double(new_search_area);
            [numRows,numCols,~] = size(interp_search_area);
            [X,Y] = meshgrid(1:numCols,1:numRows);
            [Xq,Yq]= meshgrid(1:obj.pixel_precision:numCols,1:obj.pixel_precision:numRows);
            V=interp_search_area;
            interp_search_area = interp2(X,Y,V,Xq,Yq, 'cubic');
            
            c1 = normxcorr2(interp_template, interp_search_area);
            [new_ypeak, new_xpeak] = find(c1==max(c1(:)));
            new_xpeak = new_xpeak/(1/obj.pixel_precision);
            new_ypeak = new_ypeak/(1/obj.pixel_precision);
            new_xpeak = new_xpeak+round(new_search_area_rect(1));
            new_ypeak = new_ypeak+round(new_search_area_rect(2));
            
            yoffSet = new_ypeak-obj.rect(4);
            xoffSet = new_xpeak-obj.rect(3);
            
            %DISPLACEMENT IN PIXELS
            y = new_ypeak-obj.ytemp;
            x = new_xpeak-obj.xtemp;
            
            %DISPLACEMENT IN MICRONS
            dispx = x * obj.res;
            dispy = y * obj.res;
            
        end
        
        function [xoffSet, yoffSet, dispx,dispy,x, y] = meas_displacement_fourier(obj)
            %% Whole Pixel Precision Coordinates
            
            [ypeak, xpeak] = obj.fourier_cross_correlation(obj.fft_conj_template, search_area, search_area_height, search_area_width, rect, 120);
            xpeak = xpeak+round(search_area_rect(1))-1; %move xpeak to the other side of the template rect.
            ypeak = ypeak+round(search_area_rect(2))-1; %move y peak down to the bottom of the template rect.
        
            %% Subpixel Precision Coordinates TODO: Refractor? This looks like a repetitive calculation
            new_xmin = xpeak - obj.rect(3);
            new_ymin = ypeak - obj.rect(4);
            [moved_templated, displaced_rect] = imcrop(img, [new_xmin new_ymin, obj.rect(3) obj.rect(4)]);
            
            new_search_area_xmin = new_xmin - obj.min_displacement;
            new_search_area_ymin = new_ymin - obj.min_displacement; 
            new_search_area_width = 2*obj.min_displacement  + obj.rect(3);
            new_search_area_height = 2*obj.min_displacement + obj.rect(4);
            
            [new_search_area, new_search_area_rect] = imcrop(img, [new_search_area_xmin new_search_area_ymin new_search_area_width new_search_area_height]);
            
            %% Interpolation
            %Interpolate both the new object area and the old and then compare
            %those that have subpixel precision in a normalized cross
            %correlation
            % BICUBIC INTERPOLATION - TEMPLATE
            interp_template = im2double(obj.template);
            [numRows,numCols,~] = size(interp_template); % Replace with rect? 
            [X,Y] = meshgrid(1:numCols,1:numRows); %Generate a pair of coordinate axes
            [Xq,Yq]= meshgrid(1:obj.pixel_precision:numCols,1:obj.pixel_precision:numRows); %generate a pair of coordinate axes, but this time, increment the matrix by 0
            V=interp_template; %copy interp_template into V
            interp_template = interp2(X,Y,V,Xq,Yq, 'cubic');

            % BICUBIC INTERPOLATION - SEARCH AREA (FROM MOVED TEMPLATE
            interp_search_area = im2double(new_search_area);
            [numRows,numCols,~] = size(interp_search_area);
            [X,Y] = meshgrid(1:numCols,1:numRows);
            [Xq,Yq]= meshgrid(1:obj.pixel_precision:numCols,1:obj.pixel_precision:numRows);
            V=interp_search_area;
            interp_search_area = interp2(X,Y,V,Xq,Yq, 'cubic');
            
            c1 = normxcorr2(interp_template, interp_search_area);
            [new_ypeak, new_xpeak] = find(c1==max(c1(:)));
            new_xpeak = new_xpeak/(1/obj.pixel_precision);
            new_ypeak = new_ypeak/(1/obj.pixel_precision);
            new_xpeak = new_xpeak+round(new_search_area_rect(1));
            new_ypeak = new_ypeak+round(new_search_area_rect(2));
            
            yoffSet = new_ypeak-obj.rect(4);
            xoffSet = new_xpeak-obj.rect(3);
            
            %DISPLACEMENT IN PIXELS
            y = new_ypeak-obj.ytemp;
            x = new_xpeak-obj.xtemp;
            
            %DISPLACEMENT IN MICRONS
            dispx = x * obj.res;
            dispy = y * obj.res;
            
        end
        
        function [xpeak, ypeak] = fouier_cross_correlation(obj, fft_conj_template, search_area, search_area_height, search_area_width, grayscale_inversion)
                
                % TEMPLATE and SEARCH_AERA should be grayscaled images
                % Performs cross correlation of SEARCH_AREA and TEMPLATE
                % is not normalized and differs from normxcorr2
                % GRAYSCALE_INVERSION is the value used to invert the image
                % if it's a 255 bit image, it should be 120
                % if it's not (an the values range from 0...1, it should be 0.5
                % Or at least, I've had the most luck with these values
                % These values were gotten experimentally, they may need to be tweaked
                
                
                % Some image preprocessing; Assumes a gray scale image and inverts the
                % colors to make the edges stand out
                search_area = (grayscale_inversion-search_area)*4.5; % To ensure that motion blur doesn't "erase" critical contours
                
                % Pad search_area; Necessary to avoid corruption at edges
                search_area_padded = padarray(search_area, [search_area_height, search_area_width], 'post');
                
                % Find the DTFT of the two
                dtft_of_frame = fft2(search_area_padded);
                
                % Take advantage of the correlation theorem
                % Corr(f, g) <=> element multiplication of F and conj(G) where F, G are
                % fourier transforms of the signals f, g
                R = dtft_of_frame.*fft_conj_template;
                R = R./abs(R); % normalize to get rid of values related to intensity of light
                r = ifft2(R);
                
                [ypeak, xpeak] = find(r==max(r(:))); % the origin of where the template is
                
                % Add the template size to the get right most corner rather than the
                % origin to match the output of normxcorr2
                ypeak = ypeak + obj.rect(4) - 1;
                xpeak = xpeak + obj.rect(3) - 1;
            end

        
        %error_tag is now deprecated
        function valid = validate(obj, error_tag)
            valid = true;
            while(~strcmp(VideoSource.getSourceType(obj.vid_src), 'stream') && ~FileSystemParser.is_file(obj.vid_src.filepath))
                str = 'Displacement: Not passed a valid path on the filesystem'
                err = Error(Displacement.name, str, error_tag);
                feval(obj.error_report_handle, str);
                valid = false;
            end
            while(~valid_max_displacement(obj))
                str = 'Displacement: Max Displacement invalid';
                err = Error(Displacement.name, str, error_tag);
                feval(obj.error_report_handle, str);
                valid = false;
            end
            while(~valid_pixel_precision(obj))
                str = 'Displacement: Pixel Precision inputted not a number';
                err = Error(Displacement.name, str, error_tag);
                feval(obj.error_report_handle, str);
                valid = false;
            end
            if(valid)
                set(error_tag, 'Visible', 'Off');
            end
        end

        function valid = valid_max_displacement(obj)
            valid = true;
            frame = obj.get_frame();
            if(size(frame, 2) <= obj.max_displacement || isnan(obj.max_displacement) || size(frame, 1) <= obj.max_displacement);
                valid = false;
            end 
        end
        
        function valid = valid_pixel_precision(obj)
            valid = true;
            if(isnan(obj.pixel_precision))
                valid = false;
            end
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

        function frame = get_frame(obj)
            frame = obj.vid_src.extractFrame();
        end
        
        
        function path = get_vid_path(obj)
            path = obj.vid_path;
        end
        
        function pixel_precision = get_pixel_precision(obj)
            pixel_precision = obj.pixel_precision;
        end
        
        function max_displacement = get_max_displacement(obj)
           max_displacement = obj.max_displacement;
        end
        
        function bool = check_stop(obj)
            bool = (~obj.valid && ~obj.validate(obj.error_tag)) | obj.vid_src.finished();
        end
        
        function vid_source = get.vid_src(obj)
            vid_source = obj.vid_src;
        end
        
    end

end

