classdef RyanGCAOperation < Operation

properties
    source
    template_matcher;
    res;
end

methods
    function obj = RyanGCAOperation(src, res)
        obj.source = src;
        first_frame = src.extractFrame();
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
        y_values = [-count:-1];
        x_values = [-count:-1];
        for i = 1:count
            bb = rectangles(i).BoundingBox;
            if abs(bb(3) - bb(4)) > 3
                continue
            end
            y_values(i) = bb(2);
            x_values(i) = bb(1);
        end

        median_y = median(y_values);
        median_x = mean(x_values); 

        % TODO: Get the res of the video somehow. 

        obj.template_matcher = TemplateMatcher(src, 1, 20, 20, temp, 1, first_frame); % src, pixel_precision, m_d_x, m_d_y, template, min_d
    end

    function [displacement_x, displacement_y] = execute(obj)
        displacement_x = [-5000:-1]; % Assumes that the video is < 5000 frames
        displacement_y = [-5000:-1]; % Assumes that the video is < 5000 frames
        index = 1;
        while ~obj.source.finished()
            img = obj.source.extractFrame();
            [y_peak, x_peak, disp_y_pixel, disp_x_pixel] = tm.meas_displacement(img);
            [y_peak, x_peak, disp_y_pixel, disp_x_pixel] = tm.meas_displacement_fourier(img);
            displacement_x(index) = disp_x_pixel * obj.res;
            displacement_y(index) = disp_y_pixel * obj.res;
            index = index + 1;
        end
    end

    function startup(obj)
    end

end

end