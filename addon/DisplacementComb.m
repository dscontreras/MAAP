classdef DisplacementComb < DisplacementOperation
    % Finds the displacement of a comb-like object in a video
    % This is to allow for DisplacementOperation to be a more general (but
    % less accurate) form of the solution we need at Swarm Lab

    properties
        % Redefine the search area such that we look only for the top left
        % corner of the comb rather than the entire comb. Hopefully, a
        % smaller search area will allow us to use normxcorr2 and thereby
        % not lose accuracy without losing the gains in speed we've seen so
        % far using fourier analysis
        smaller_search_area_length; % In reality, this will be 1 less than the actual length because of imcrop's weird addition of 1 to the dimension
    end

    methods

        function obj = DisplacementComb(src, axes, table, error, img_cover, pause_button, pixel_precision, max_displacement, resolution, draw, error_report_handle, smaller_search_area_length)

            obj = obj@DisplacementOperation(src, axes, table, error, img_cover, pause_button, pixel_precision, max_displacement, resolution, draw, error_report_handle);
            obj.smaller_search_area_length = smaller_search_area_length;

        end

        function initialize_algorithm(obj)
            initialize_algorithm@DisplacementOperation(obj)

            % I add 1 as imcrop will add 1 to each dimension
            obj.interp_search_area_height = obj.smaller_search_area_length+1;
            obj.interp_search_area_width = obj.smaller_search_area_length+1;

            obj.interp_template = imcrop(obj.interp_template, [1 1 obj.smaller_search_area_length obj.smaller_search_area_length]);            
        end


        % TODO: remove the repetitive code
        function [x_peak, y_peak, disp_x_pixel, disp_y_pixel, disp_x_micron, disp_y_micron] = meas_displacement_fourier(obj)
            % Whole Pixel Precision Coordinates
            img = obj.current_frame;
            [search_area, ~] = imcrop(img,[obj.search_area_xmin, obj.search_area_ymin, obj.search_area_width, obj.search_area_height]);
            
            processed_search_area = search_area - obj.template_average;

            [ypeak, xpeak] = obj.fourier_cross_correlation(obj.fft_conj_processed_template, processed_search_area, obj.search_area_height, obj.search_area_width);
            
            new_xmin = xpeak - obj.min_displacement;
            new_ymin = ypeak - obj.min_displacement;

            new_width   = obj.smaller_search_area_length-1;
            new_height  = obj.smaller_search_area_length-1;
            %new_width   = size(obj.template, 2) + obj.min_displacement*2; 
            %new_height  = size(obj.template, 1) + obj.min_displacement*2;
            
            [new_search_area, new_search_area_rect] = imcrop(search_area, [new_xmin new_ymin new_width new_height]);
            
            % BICUBIC INTERPOLATION - SEARCH AREA (FROM MOVED TEMPLATE
            interp_search_area = im2double(new_search_area);
            numCols = new_search_area_rect(3)+1;
            numRows = new_search_area_rect(4)+1;
            [X,Y] = meshgrid(1:numCols,1:numRows);
            [Xq,Yq]= meshgrid(1:obj.pixel_precision:numCols,1:obj.pixel_precision:numRows);
            V=interp_search_area;
            interp_search_area = interp2(X,Y,V,Xq,Yq, 'cubic');
            
            % TODO: Subtract mean from interp_search_area?
            
            c1 = normxcorr2(obj.interp_template, interp_search_area);
            
            [new_ypeak, new_xpeak] = find(c1==max(c1(:)));

            % Account for padding (the 1 is to account for imcrop)
            new_xpeak = new_xpeak - obj.smaller_search_area_length-1;
            new_ypeak = new_ypeak - obj.smaller_search_area_length-1;
            
            % Account for precision
            new_xpeak = new_xpeak/(1/obj.pixel_precision);
            new_ypeak = new_ypeak/(1/obj.pixel_precision);

            % Find the peak coordinates in terms of the full image
            y_peak = new_ypeak + obj.search_area_ymin + new_ymin;
            x_peak = new_xpeak + obj.search_area_xmin + new_xmin;

            %DISPLACEMENT IN PIXELS
            disp_y_pixel = ypeak - obj.rect(2);
            disp_x_pixel = xpeak - obj.rect(1);

            %DISPLACEMENT IN MICRONS
            disp_y_micron = disp_y_pixel * obj.res;
            disp_x_micron = disp_x_pixel * obj.res;
        end
    end
    
    % TODO: Make sure that smaller length < size of template/size of
    % search_area
end
