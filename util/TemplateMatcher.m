classdef TemplateMatcher < handle & matlab.mixin.Heterogeneous
    %% Given a template and a File Source, finds the location of the template in each frame of the video

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
            first_frame = rgb2gray(first_frame);
            obj.rect = find_rect(obj.source.get_filepath(), template_file_path);
            obj.template = imcrop(first_frame, obj.rect);
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
            obj.processed_template  = int16(obj.template) - obj.template_average;
            obj.fft_conj_processed_template = conj(fft2(obj.processed_template, obj.search_area_height*2, obj.search_area_width*2));

            % Find the interpolated template
            obj.interp_template = obj.interpolate(obj.template, obj.pixel_precision, obj.rect(3), obj.rect(4));

            % I add 1 as imcrop will add 1 to each dimension
            [obj.interp_search_area_height, obj.interp_search_area_width] = size(obj.interp_template);

            obj.interp_template_average = mean(mean(obj.interp_template));
            obj.processed_interp_template = obj.interp_template - obj.interp_template_average;
            obj.fft_conj_processed_interp_template = conj(fft2(obj.processed_interp_template, obj.interp_search_area_height*2, obj.interp_search_area_width*2));

            % The following is necessary to do the normxcorr2 when looking at a smaller part of an image
            % TODO: explain in more detail
            obj.interp_search_area_height = obj.smaller_search_area_length+1;
            obj.interp_search_area_width = obj.smaller_search_area_length+1;
            obj.interp_template = imcrop(obj.interp_template, [1 1 obj.smaller_search_area_length-1 obj.smaller_search_area_length-1]);
            obj.processed_interp_template = imcrop(obj.processed_interp_template, [1 1 obj.smaller_search_area_length-1 obj.smaller_search_area_length-1]);
        end

        function [y_peak, x_peak, disp_y_pixel, disp_x_pixel] = meas_displacement_fourier(obj, img)
            [search_area, ~] = imcrop(img,[obj.search_area_xmin, obj.search_area_ymin, obj.search_area_width, obj.search_area_height]);

            processed_search_area = int16(search_area) - obj.template_average;

            [ypeak, xpeak] = obj.fourier_cross_correlation(obj.fft_conj_processed_template, processed_search_area, obj.search_area_height, obj.search_area_width);

            new_xmin = xpeak - obj.min_displacement;
            new_ymin = ypeak - obj.min_displacement;

            new_width   = obj.smaller_search_area_length-1;
            new_height  = obj.smaller_search_area_length-1;

            [new_search_area, new_search_area_rect] = imcrop(search_area, [new_xmin new_ymin new_width new_height]);

            interp_search_area = obj.interpolate(new_search_area, obj.pixel_precision, new_search_area_rect(3)+1, new_search_area_rect(4)+1);

            processed_interp_search_area = interp_search_area - obj.interp_template_average;
            c1 = normxcorr2(obj.processed_interp_template, processed_interp_search_area);

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
            disp_y_pixel = y_peak - obj.rect(2);
            disp_x_pixel = x_peak - obj.rect(1);
        end

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
                dtft_of_frame = fft2(search_area, height*2, width*2);

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
