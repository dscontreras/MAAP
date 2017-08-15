% Finds x- and y-coordinates for user template given the initial frame % 
function [xtemp, ytemp] = get_template_coords(frame, template)
    
    % Performed normalized cross correlation %
    c = normxcorr2(template, frame);
    
    % Find peak cross correlation
    [ytemp, xtemp] = find(c==max(c(:)));