classdef GapCloserArrayDisplacement < Operation

properties
    source
    template_matcher;
    res;
end

methods
    function obj = GapCloserArrayDisplacement(src, pixel_precision, m_d_x, m_d_y, template_file_path, min_d, smaller_search_area_length, resolution)
        obj.source = src;
        first_frame = src.extractFrame();
        obj.res = resolution;
        obj.template_matcher = TemplateMatcher(src, pixel_precision, m_d_x, m_d_y, template_file_path, min_d, smaller_search_area_length, first_frame)
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