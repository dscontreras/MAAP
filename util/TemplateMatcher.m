classdef TemplateMatcher < handle & matlab.mixin.Heterogeneous
    % Given a template and a File Source, finds the location of the template in each frame of the video

    properties
        source;
        pixel_precision;
        max_displacement_x;
        max_displacement_y;
        rect;
        template;
        min_displacement;
        smaller_search_area_length;

        % Properties needed for fourier analysis
        search_area_width; search_area_height;
        search_area_xmin;  search_area_ymin;

        template_average;
        processed_template; fft_conj_processed_template;

        interp_search_area_width; interp_search_area_height;
        interp_template; interp_template_average;
        processed_interp_template; fft_conj_processed_interp_template;

        smaller_processed_interp_template; smaller_template;
    end

    methods
        % For now, assumes that m_d_x, m_d_y is a double of some kind
        function obj = TemplateMatcher(src, pixel_precision, m_d_x, m_d_y, template_file_path, min_d, smaller_search_area_length, first_frame)
            obj.source                      = src;
            obj.pixel_precision             = pixel_precision;
            obj.max_displacement_x          = m_d_x;
            obj.max_displacement_y          = m_d_y;
            obj.min_displacement            = min_d;
            obj.smaller_search_area_length  = smaller_search_area_length;

            % TODO: validate check?

            % TODO: Fix the problem of us just discarding the first frame.
            if length(size(first_frame)) == 3
                first_frame = rgb2gray(first_frame);
            end
            %[xmin ymin width height]
            obj.rect = find_rect(obj.source.get_filepath(), template_file_path);
            obj.template = im2double(imcrop(first_frame, obj.rect));
            obj.rect = [obj.rect(1) obj.rect(2) obj.rect(3)+1 obj.rect(4)+1]; % Account for the +1 that imcrop adds
            
            % Set up some of the sizes that will be used in the future
            obj.search_area_height  = 2 * obj.max_displacement_y + obj.rect(4);
            obj.search_area_width   = 2 * obj.max_displacement_x + obj.rect(3);
            obj.search_area_xmin    = obj.rect(1) - obj.max_displacement_x;
            obj.search_area_ymin    = obj.rect(2) - obj.max_displacement_y;

            % Make sure that when darks match up in both the
            % image/template, they count toward the correlation
            % We subtract from the mean as we know that darks are the
            % edges.
            obj.template_average    = mean(mean(obj.template));
            obj.processed_template  = obj.template - obj.template_average;
            obj.fft_conj_processed_template = conj(fft2(obj.processed_template, obj.search_area_height, obj.search_area_width));

            % Find the interpolated template
            obj.interp_template = obj.interpolate(obj.template, obj.pixel_precision, obj.rect(3), obj.rect(4));

            % I add 1 as imcrop will add 1 to each dimension
            [obj.interp_search_area_height, obj.interp_search_area_width] = size(obj.interp_template);

            obj.interp_template_average = mean(mean(obj.interp_template));
            obj.processed_interp_template = obj.interp_template - obj.interp_template_average;
            obj.fft_conj_processed_interp_template = conj(fft2(obj.processed_interp_template, obj.interp_search_area_height, obj.interp_search_area_width));

            % The following is necessary to do the normxcorr2 when looking at a smaller part of an image
            % TODO: explain in more detail
            obj.interp_search_area_height = obj.smaller_search_area_length+1;
            obj.interp_search_area_width = obj.smaller_search_area_length+1;
            obj.smaller_template = imcrop(obj.interp_template, [1 1 obj.smaller_search_area_length-1 obj.smaller_search_area_length-1]);
            obj.smaller_processed_interp_template = imcrop(obj.processed_interp_template, [1 1 obj.smaller_search_area_length-1 obj.smaller_search_area_length-1]);            
        end

        function [y_peak, x_peak, disp_y_pixel, disp_x_pixel] = meas_displacement_fourier(obj, img)
            [search_area, search_area_rect] = imcrop(img,[obj.search_area_xmin, obj.search_area_ymin, obj.search_area_width-1, obj.search_area_height-1]);

            search_area = im2double(search_area);
            
            processed_search_area = search_area - obj.template_average;

            [ypeak, xpeak] = obj.fourier_cross_correlation(obj.fft_conj_processed_template, processed_search_area, obj.search_area_height, obj.search_area_width);

            new_xmin = xpeak - obj.min_displacement;
            new_ymin = ypeak - obj.min_displacement;

            new_width   = obj.rect(3)+2*obj.min_displacement;
            new_height  = obj.rect(4)+2*obj.min_displacement;

            [new_search_area, new_search_area_rect] = imcrop(search_area, [new_xmin new_ymin new_width new_height]);

            interp_search_area = obj.interpolate(new_search_area, obj.pixel_precision, new_search_area_rect(3)+1, new_search_area_rect(4)+1);

            processed_interp_search_area = interp_search_area - obj.interp_template_average;
            
            c1 = normxcorr2(obj.processed_interp_template, processed_interp_search_area);

            [new_ypeak, new_xpeak] = find(c1==max(c1(:)));

            new_ypeak = new_ypeak - size(obj.processed_interp_template, 1);
            new_xpeak = new_xpeak - size(obj.processed_interp_template, 2);
            
            % Account for precision
            new_xpeak = new_xpeak/(1/obj.pixel_precision);
            new_ypeak = new_ypeak/(1/obj.pixel_precision);

            % Find the peak coordinates in terms of the full image
            y_peak = new_ypeak + obj.search_area_ymin + new_ymin;
            x_peak = new_xpeak + obj.search_area_xmin + new_xmin;
            

            %DISPLACEMENT IN PIXELS
            disp_y_pixel = y_peak - obj.rect(2);
            disp_x_pixel = x_peak - obj.rect(1);
        end

        % Uses normxcorr2 to find the location of obj.template in IMG for both pixel precision and subpixel precision
        function [y_peak, x_peak, disp_y_pixel, disp_x_pixel] = meas_displacement(obj, img)
            [y_peak, x_peak, disp_y_pixel, disp_x_pixel] = obj.meas_displacement_norm_cross_correlation(img);
        end

        function [y_peak, x_peak, disp_y_pixel, disp_x_pixel] = meas_displacement_norm_cross_correlation(obj, img)
            Xm =40*10^(-6); %distance according to chip dimensions in microns
            Xp = 184.67662; %distance according image in pixels. Correspond to Xm
            %    ************************** WHOLE PIXEL PRECISION COORDINATES *************************

            %DEFINE SEARCH AREA - obtained from no interpolated image
            width = obj.max_displacement_x; %search area width
            height = obj.max_displacement_y; %search area height

            search_area_xmin = obj.rect(1) - width; %xmin of search area
            search_area_ymin = obj.rect(2)- height; %ymin of search area
            search_area_width = 2*width+obj.rect(3); %Get total width of search area
            search_area_height = 2*height+obj.rect(4); %Get total height of search area
            [search_area, search_area_rect] = imcrop(img,[search_area_xmin search_area_ymin search_area_width search_area_height]); 

            %"\tNormxCorr2"
            c = normxcorr2(im2uint8(obj.template), search_area);

            [ypeak, xpeak] = find(c==max(c(:)));

            xpeak = xpeak+round(search_area_rect(1))-1; %move xpeak to the other side of the template rect.
            ypeak = ypeak+round(search_area_rect(2))-1; %move y peak down to the bottom of the template rect.
            
            % ************************** SUBPIXEL PRECISION COORDINATES *************************
            %GENERATE MOVED TEMPLATE
            %new_xmin = (xpeak-xtemp) + rect(1); 
            new_xmin = (xpeak-obj.rect(3));
            %new_ymin = (ypeak-ytemp) + rect(2); 
            new_ymin = (ypeak-obj.rect(4));
            [moved_template, displaced_rect] = imcrop(img,[new_xmin new_ymin obj.rect(3) obj.rect(4)]);

            %GENERATE NEW SEARCH AREA (BASED IN MOVED TEMPLATE)
            width1 = obj.min_displacement; %set the width margin between the displaced template, and the search area as width1
            height1 = obj.min_displacement; %set the height margin between the displaced template, and the search area as height1
            new_search_area_xmin = displaced_rect(1) - width1; 
            new_search_area_ymin = displaced_rect(2)- height1;
            new_search_area_width = 2*width1+displaced_rect(3);
            new_search_area_height = 2*height1+displaced_rect(4);
            [new_search_area, new_search_area_rect] = imcrop(img,[new_search_area_xmin new_search_area_ymin new_search_area_width new_search_area_height]);

            interp_search_area = obj.interpolate(new_search_area, obj.pixel_precision, new_search_area_width+1, new_search_area_height+1);
            
             %PERFORM NORMALIZED CROSS-CORRELATION
             c1 = normxcorr2(obj.interp_template,interp_search_area); %Now perform normalized cross correlation on the interpolated images

            %FIND PEAK CROSS-CORRELATION
            [new_ypeak, new_xpeak] = find(c1==max(c1(:)));  

            new_xpeak = new_xpeak/(1/obj.pixel_precision);
            new_ypeak = new_ypeak/(1/obj.pixel_precision);
            new_xpeak = new_xpeak+round(new_search_area_rect(1));
            new_ypeak = new_ypeak+round(new_search_area_rect(2));

            y_peak = new_ypeak-(size(obj.template,1));
            x_peak = new_xpeak-(size(obj.template,2));

            %DISPLACEMENT IN PIXELS
            disp_y_pixel = y_peak - obj.rect(2);
            disp_x_pixel = x_peak - obj.rect(1);            
        end
    end

    methods (Access = private)
        function interpolated_image = interpolate(obj, img, pixel_precision, numCols, numRows)
            interpolated_image = im2double(img);
            [X,Y] = meshgrid(1:numCols,1:numRows);
            [Xq,Yq]= meshgrid(1:pixel_precision:numCols,1:pixel_precision:numRows);
            V=interpolated_image;
            interpolated_image = interp2(X,Y,V,Xq,Yq, 'cubic');
        end

        function [ypeak, xpeak] = fourier_cross_correlation(obj, fft_conj_template, search_area, height, width)

                % TEMPLATE and SEARCH_AERA should be grayscaled images
                % Performs cross correlation of SEARCH_AREA and TEMPLATE
                % is not normalized and differs from normxcorr2
                % GRAYSCALE_INVERSION is the value used to invert the image
                % if it's a 255 bit image, it should be 120
                % if it's not (an the values range from 0...1, it should be 0.5
                % Or at least, I've had the most luck with these values
                % These values were gotten experimentally, they may need to be tweaked

                % Find the DTFT
                dtft_of_frame = fft2(search_area);

                % Take advantage of the correlation theorem
                % Corr(f, g) <=> element multiplication of F and conj(G) where F, G are
                % fourier transforms of the signals f, g
                R = dtft_of_frame.*fft_conj_template;
                R = R./abs(R); % normalize to get rid of values related to intensity of light
                r = real(ifft2(R));%, height, width));
                r = r(1:height, 1:width); % limit the location of where I look for the max

                [ypeak, xpeak] = find(r==max(r(:))); % the origin of where the template is
                ypeak = ypeak - 1;
                xpeak = xpeak - 1;
        end
    end

end
