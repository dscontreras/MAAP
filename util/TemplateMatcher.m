classdef TemplateMatcher < handle & matlab.mixin.Heterogeneous
    % Given a template and a File Source, finds the location of the template in each frame of the video

    properties
        pixel_precision;
        max_displacement_x; max_displacement_y; min_displacement;
        template; template_height; template_width; rect;
        interp_template;
        % In the case of changing templates, I'll need these values. 
        orig_template_y; orig_template_x;
    end

    methods
        function obj = TemplateMatcher(pixel_precision, m_d_x, m_d_y, template, min_d, first_frame)
            obj.pixel_precision             = pixel_precision;
            obj.max_displacement_x          = m_d_x;
            obj.max_displacement_y          = m_d_y;
            obj.min_displacement            = min_d;

            % TODO: validate check?

            % TODO: Fix the problem of us just discarding the first frame.
            if length(size(first_frame)) == 3
                first_frame = rgb2gray(first_frame);
            end
            obj.rect = find_rect(first_frame, template);
            obj.template = im2double(imcrop(first_frame, obj.rect));
            [obj.template_height, obj.template_width] = size(obj.template);
            obj.rect = [obj.rect(1) obj.rect(2) obj.template_width obj.template_height];
            obj.orig_template_y = obj.rect(2);
            obj.orig_template_x = obj.rect(1);

            % Find the interpolated template
            obj.interp_template = obj.interpolate(obj.template, obj.pixel_precision, obj.rect(3), obj.rect(4));
        end

        % Uses normxcorr2 to find the location of obj.template in IMG for both pixel precision and subpixel precision
        function [y_peak, x_peak, disp_y_pixel, disp_x_pixel] = meas_displacement(obj, img)
            if nargin ~= 3
                zero_pad = false;
            end
            [y_peak, x_peak, disp_y_pixel, disp_x_pixel] = obj.meas_displacement_norm_cross_correlation(img);
        end

        % ZERO_PAD is an argument used to determine whether or not the search_area should be zero_padded. 
        % How much it should be zero_padded is determined by the max_displacement_x and max_displacement_y
        % The search_area will be a crop of the IMG determined by OBJ.RECT then zero_padded. 
        function [y_peak, x_peak, disp_y_pixel, disp_x_pixel] = meas_displacement_norm_cross_correlation(obj, img)
            Xm = 40*10^(-6); %distance according to chip dimensions in microns
            Xp = 184.67662; %distance according image in pixels. Correspond to Xm
            %    ************************** WHOLE PIXEL PRECISION COORDINATES *************************

            % Get Pixel Accuracy
            [ypeak, xpeak, search_area_rect] = obj.normalized_cross_correlation(img, [obj.max_displacement_y, obj.max_displacement_x], obj.rect, false);
            new_xmin = xpeak+round(search_area_rect(1))-1;
            new_ymin = ypeak+round(search_area_rect(2))-1;

            % Subpixel Accuracy
            new_rect = [new_xmin new_ymin obj.rect(3) obj.rect(4)];
            [y_peak, x_peak, ~] = obj.normalized_cross_correlation(img, [obj.min_displacement, obj.min_displacement], new_rect, true);

            %DISPLACEMENT IN PIXELS from original position
            disp_y_pixel = y_peak - obj.orig_template_y;
            disp_x_pixel = x_peak - obj.orig_template_x;  
        end
        
        function change_template(obj, template, rect)
            obj.template = template;
            obj.rect = rect;
            [obj.template_height, obj.template_width] = size(template);
            obj.rect = [rect(1) rect(2) obj.template_width obj.template_height];
            obj.interp_template = obj.interpolate(obj.template, obj.pixel_precision, obj.rect(3), obj.rect(4));
        end
    end

    % Methods for testing; Not to be generally be used outside the class
    methods (Access = public)
        function interpolated_image = interpolate(obj, img, pixel_precision, numCols, numRows)
            interpolated_image = im2double(img);
            [X,Y] = meshgrid(1:numCols,1:numRows);
            [Xq,Yq]= meshgrid(1:pixel_precision:numCols,1:pixel_precision:numRows);
            V=interpolated_image;
            interpolated_image = interp2(X,Y,V,Xq,Yq, 'cubic');
        end

        % if ZERO_PAD, the cropped image will be of RECT and padded with zeros everywhere else. 
        % This is in the case in which there are similar objects just out of RECT that can be avoided in this way. 
        % The math will work out the same due to the padding. 
        function [y_peak, x_peak, search_area_rect] = normalized_cross_correlation(obj, img, displacement, rect, interpolate)
            width = displacement(2);
            height = displacement(1);

            search_area_xmin    = rect(1) - width;
            search_area_ymin    = rect(2) - height;
            search_area_width   = 2*width + rect(3);
            search_area_height  = 2*height + rect(4);

            [search_area, search_area_rect] = imcrop(img,[search_area_xmin search_area_ymin search_area_width search_area_height]); 

            if interpolate
                interp_search_area = obj.interpolate(search_area, obj.pixel_precision, search_area_width + 1, search_area_height + 1);
                c = normxcorr2(obj.interp_template, interp_search_area);
                [y_peak, x_peak] = find(c==max(c(:)));
                x_peak = x_peak/(1/obj.pixel_precision);
                y_peak = y_peak/(1/obj.pixel_precision);
                x_peak = x_peak+round(search_area_rect(1));
                y_peak = y_peak+round(search_area_rect(2));
            else
                c = normxcorr2(im2uint8(obj.template), search_area);

                [y_peak, x_peak] = find(c==max(c(:)));
            end
            y_peak = y_peak - obj.template_height;
            x_peak = x_peak - obj.template_width;
        end
    end

end
