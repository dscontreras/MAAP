classdef DisplacementComb < DisplacementOperation
    % Finds the displacement of a comb-like object in a video
    % This is to allow for DisplacementOperation to be a more general (but
    % less accurate) form of the solution we need at Swarm Lab
    
    properties 
        smaller_search_area_length; 
    end
    
    methods
        
        function obj = DisplacementComb(src, axes, table, error, img_cover, pause_button, pixel_precision, max_displacement, resolution, draw, error_report_handle, smaller_search_area_length)
            
            obj = obj@DisplacementOperation(src, axes, table, error, img_cover, pause_button, pixel_precision, max_displacement, resolution, draw, error_report_handle);
            obj.smaller_search_area_length = smaller_search_area_length;
        
        end
        
        function initialize_algorithm(obj)
            initialize_algorithm@DisplacementOperation(obj)
            
            

            % I add 1 as imcrop will add 1 to each dimension
            obj.interp_search_area_height = obj.smaller_search_area_length;
            obj.interp_search_area_width = obj.smaller_search_area_length; 
            
            obj.fft_conj_processed_interp_template = conj(fft2(obj.processed_interp_template, obj.interp_search_area_height*2, obj.interp_search_area_width*2));
        end
        
        
        % TODO: remove this repetitive code
        function [x_peak, y_peak, disp_x_pixel, disp_y_pixel, disp_x_micron, disp_y_micron] = meas_displacement_fourier(obj)
            % Whole Pixel Precision Coordinates
            img = obj.current_frame;
            [search_area, ~] = imcrop(img,[obj.search_area_xmin, obj.search_area_ymin, obj.search_area_width, obj.search_area_height]);

            processed_search_area = search_area - obj.template_average;

            [ypeak, xpeak] = obj.fourier_cross_correlation(obj.fft_conj_processed_template, processed_search_area, obj.search_area_height, obj.search_area_width);
            
            new_xmin = xpeak - obj.min_displacement;
            new_ymin = ypeak - obj.min_displacement;

            new_width   = obj.smaller_search_area_length;
            new_height  = obj.smaller_search_area_length;
            [new_search_area, new_search_area_rect] = imcrop(search_area, [new_xmin new_ymin new_width new_height]);

            % Interpolation
            %Interpolate both the new object area and the old and then compare
            %those that have subpixel precision in a normalized cross
            %correlation

            % BICUBIC INTERPOLATION - SEARCH AREA (FROM MOVED TEMPLATE
            interp_search_area = im2double(new_search_area);
            [numRows,numCols,~] = size(interp_search_area);
            [X,Y] = meshgrid(1:numCols,1:numRows);
            [Xq,Yq]= meshgrid(1:obj.pixel_precision:numCols,1:obj.pixel_precision:numRows);
            V=interp_search_area;
            interp_search_area = interp2(X,Y,V,Xq,Yq, 'cubic');

            processed_interp_search_area = interp_search_area - obj.interp_template_average;

            [new_ypeak, new_xpeak] = obj.fourier_cross_correlation(obj.fft_conj_processed_interp_template, processed_interp_search_area, obj.interp_search_area_height, obj.interp_search_area_width);

            new_ypeak = new_ypeak/(1/obj.pixel_precision);
            new_xpeak = new_xpeak/(1/obj.pixel_precision);

            y_peak = new_ypeak + obj.search_area_ymin + new_ymin;
            x_peak = new_xpeak + obj.search_area_xmin + new_xmin;

            %DISPLACEMENT IN PIXELS
            disp_y_pixel = obj.rect(2) - y_peak;
            disp_x_pixel = obj.rect(1) - x_peak;

            %DISPLACEMENT IN MICRONS
            disp_y_micron = disp_y_pixel * obj.res;
            disp_x_micron = disp_x_pixel * obj.res;
        end
    end
end