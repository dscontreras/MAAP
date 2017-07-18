% Given an image, attempts to find the squares that are present in many of the objects that are being studied such as the GCA
% x, y, width, height represents the `rect` that would be used for template matching

% Rectangles will have some amount of rectangles. Access each square as you would any array. Access the elements of the rectangles by getting the BoundingBox. 
% The BoundingBox is of the form [xmin ymin width height]
function [rectangles] = location_rectangles(img)
    % Convert to grayscale if necessary
    if length(size(img)) == 3
        img = rgb2gray(img);
    end
    img = im2double(img);
    I = img;
    Ibw = ~imbinarize(I);
    Ifill = imfill(Ibw,'holes');
    Iarea = bwareaopen(Ifill,100);
    Ifinal = bwlabel(Iarea);
    stat = regionprops(Ifinal,'boundingbox');
    rectangles = stat;
end
    
