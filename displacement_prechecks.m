function [state_arr] = displacement_prechecks(pixel_precision, max_displacement)
%DISPLACEMENT_PRECHECKS Summary of this function goes here
%   Detailed explanation goes here
    state_arr = [];
    if(pixel_precision == -1)
        state_arr(1) = 1;
    end
    if(max_displacement == -1)
        state_arr(2) = 1;
    end
end

