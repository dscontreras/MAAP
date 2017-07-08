function [template, rect] = showCrop(hAxis, frame, height, width)
global vid_height; 
global vid_width;
vid_height = height;
vid_width = width;
% This helper function is provided in support of the example 'Video Display
% in a Custom User Interface'. It displays a frame of video on a
% user-defined axis.

%   Copyright 2004-2010 The MathWorks, Inc.

checkAxes(hAxis);
checkFrame(frame);

[template, rect] = displayImage(hAxis, frame);

%--------------------------------------------------------------------------
function checkAxes(hAxis)
% Check if the axis exists.
if ~isHandleType(hAxis, 'axes')
    % Figure was closed
    return;
end

%--------------------------------------------------------------------------
function checkFrame(frame)
% Validate input image
validateattributes(frame, ...
    {'uint8', 'uint16', 'int16', 'double', 'single','logical'}, ...
    {'real','nonsparse'}, 'insertShape', 'I', 1)

% Input image must be grayscale or truecolor RGB.
errCond=(ndims(frame) >3) || ((size(frame,3) ~= 1) && (size(frame,3) ~=3));
if (errCond)
    error('Input image must be grayscale or truecolor RGB');
end

%--------------------------------------------------------------------------
function frame = convertToUint8RGB(frame)
% Convert input data type to uint8
if ~isa(class(frame), 'uint8')
    frame = im2uint8(frame);
end

% If the input is grayscale, turn it into an RGB image
if (size(frame,3) ~= 3) % must be 2d
    frame = cat(3,frame, frame, frame);
end

%--------------------------------------------------------------------------
function flag = isHandleType(h, hType)
% Check if handle, h, is of type hType
if isempty(h)
    flag = false;
else
    flag = ishandle(h) && strcmpi(get(h,'type'), hType);
end

%--------------------------------------------------------------------------
function [template, rect] = displayImage(hAxis, frame)
global vid_height;
global vid_width;
% Display image in the specified axis
frame = imresize(frame,  [vid_height, vid_width]); % 1200, 1920 for other videos 
[template, rect] = imcrop(frame);
rect

%set(hAxis, ...
    %'YDir','reverse',...
    %'TickDir', 'out', ...
    %'XGrid', 'off', ...
    %'YGrid', 'off', ...
    %'PlotBoxAspectRatioMode', 'auto', ...
    %'Visible', 'off');

