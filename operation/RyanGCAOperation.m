classdef RyanGCAOperation < Operation

properties
    source
    template_matcher;
    res;
    rect;
end

methods
    function obj = RyanGCAOperation(src, res)
        obj.source = src;
        first_frame = grab_frame(obj.source)
        obj.res = res;
        % Find the template;
        % Some assumptions that are made: 
        % 1. It's somewhere in the middle 
        %       - The median y value will give us which rectangles to look at
        %       - The mean x value will tell us where the "middle" of the rectangles is
        % 2. It looks like squares. 

        rectangles = locate_rectangles(first_frame);
        [h, w] = size(first_frame);

        count = numel(rectangles);
        y_values        = zeros(1, count);
        x_values        = zeros(1, count);
        width_values    = zeros(1, count);
        height_values   = zeros(1, count);
        index = 1;
        for i = 1:count
            bb = rectangles(i).BoundingBox;
            % Filter out the non-squares
            if abs(bb(3) - bb(4)) > 3
                continue
            end
            x_values(index)         = bb(1);
            y_values(index)         = bb(2);
            width_values(index)     = bb(3);
            height_values(index)    = bb(4);
            index = index + 1;
        end
        
        % Filter out all values of y, x, width, height that is 0
        k = find(y_values == 0, 1);
        y_values = y_values(1:k-1);
        k = find(x_values == 0, 1);
        x_values = x_values(1:k-1);
        k = find(height_values == 0, 1);
        height_values = height_values(1:k-1);
        k = find(width_values == 0, 1);
        width_values = width_values(1:k-1);
        
        median_y = median(y_values);
        mean_x = mean(x_values); 
        mean_height = mean(height_values);
        mean_width = mean(width_values);

        % Now I get the rect I need. 
        potential_x = w;
        potential_y = h;
        for i = 1:count
            bb = rectangles(i).BoundingBox;
            bb_x = bb(1);
            bb_y = bb(2);
            % Find the x closest to the mean
            if abs(bb_x - mean_x) < abs(potential_x - mean_x)
                potential_x = bb_x;
            end
            % Find the closest y to the median
            if abs(bb_y - median_y) < abs(potential_y - median_y)
                potential_y = bb_y;
            end
        end
        obj.rect = [potential_x potential_y mean_width*3 mean_height]; % Let's look at just three boxes for now
        temp = imcrop(first_frame, obj.rect);
        % TODO: Get the res of the video somehow. 

        obj.template_matcher = TemplateMatcher(src,1, 0, 0, temp, 1, first_frame); % src, pixel_precision, m_d_x, m_d_y, template, min_d
        obj.rect = obj.template_matcher.rect;
    end

    function [loc_x, loc_y, indices] = execute(obj)
        loc_x = [-5000:-1]; % Assumes that the video is < 5000 frames
        loc_y = [-5000:-1]; % Assumes that the video is < 5000 frames
        indices_of_interest = [];
        index = 1;
        
        % First frame
        [h, w] = size(obj.template_matcher.template);
        img = grab_frame(obj.source);
        [y_peak, x_peak, disp_y_pixel, disp_x_pixel] = obj.template_matcher.meas_displacement(img);
        loc_x(index) = x_peak;
        loc_y(index) = y_peak;
        new_temp = imcrop(img, [x_peak, y_peak, w, h]);
        obj.template_matcher.change_template(new_temp, [x_peak, y_peak, w, h]);
        prev_x = x_peak;
        prev_y = y_peak;
        
        while ~obj.source.finished()
            index = index + 1;
            img = grab_frame(obj.source);
            [y_peak, x_peak, disp_y_pixel, disp_x_pixel] = obj.template_matcher.meas_displacement(img);
            
            loc_x(index) = x_peak;
            loc_y(index) = y_peak;
            
            if abs(prev_x - x_peak) > 2
                indices_of_interest = [indices_of_interest index - 1];
                indices_of_interest = [indices_of_interest index];
            end
            
            new_temp = imcrop(img, [x_peak, y_peak, w, h]);
            obj.template_matcher.change_template(new_temp, [x_peak, y_peak, w, h]);
            prev_x = x_peak;
            prev_y = y_peak;
        end
        
        k = find(loc_x < 0);
        loc_x = loc_x(1:k-1);
        loc_y = loc_y(1:k-1);
        indices = indices_of_interest;
        
        full_path = which('saved_data_README.markdown'); 
        [parentdir, ~, ~] = fileparts(full_path);
        mat_filename = [parentdir '/temp' datestr(datetime('now')) '.mat'];
        dispx = obj.dispx;
        dispy = obj.dispy;
        save(mat_filename, 'dispx', 'dispy')
        convertToCSV(mat_filename, 'GCA')
        delete(mat_filename)
        "Done"        
    end

    function startup(obj)
    end

end

end