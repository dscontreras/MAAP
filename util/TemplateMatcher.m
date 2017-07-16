classdef TemplateMatcher < handle & matlab.mixin.Heterogeneous
    % Given a template and a File Source, finds the location of the template in each frame of the video

    properties
        source;
        pixel_precision;
        max_displacement_x;
        max_displacement_y;
        rect;
        template; template_height; template_width;
        min_displacement;
        interp_template;
        
        
    end

    methods
        function obj = TemplateMatcher(src, pixel_precision, m_d_x, m_d_y, template, min_d, first_frame)
            obj.source                      = src;
            obj.pixel_precision             = pixel_precision;
            obj.max_displacement_x          = m_d_x;
            obj.max_displacement_y          = m_d_y;
            obj.min_displacement            = min_d;

            % TODO: validate check?

            % TODO: Fix the problem of us just discarding the first frame.
            if length(size(first_frame)) == 3
                first_frame = rgb2gray(first_frame);
            end
            obj.rect = find_rect(obj.source.get_filepath(), template);
            obj.template = im2double(imcrop(first_frame, obj.rect));
            [obj.template_height, obj.template_width] = size(obj.template);
            obj.rect = [obj.rect(1) obj.rect(2) obj.template_width obj.template_height];

            % Find the interpolated template
            obj.interp_template = obj.interpolate(obj.template, obj.pixel_precision, obj.rect(3), obj.rect(4));
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
            
            y_peak = new_ypeak - obj.template_height;
            x_peak = new_xpeak - obj.template_width;

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
    end

end
