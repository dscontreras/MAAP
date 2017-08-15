function distance = get_line(scale_img, axes)
    line = showLine(axes, scale_img);
    h = iptgetapi(line);
    h.setLabelVisible(false);
    distance = h.getDistance();
end
%--------------------------------------------------------------------------
function line = showLine(axes, scale_img)
    global vid_height; 
    global vid_width;
    vid_height = 1024;
    vid_width = 1280;

    checkAxes(axes);
    checkFrame(scale_img);

    line = displayLine(axes, scale_img);
end
%--------------------------------------------------------------------------
function checkAxes(axes)
    % Check if the axis exists.
    if ~isHandleType(axes, 'axes')
        % Figure was closed
        return;
    end
end
%--------------------------------------------------------------------------
function checkFrame(scale_img)
% Validate input image
    validateattributes(scale_img, ...
        {'uint8', 'uint16', 'int16', 'double', 'single','logical'}, ...
        {'real','nonsparse'}, 'insertShape', 'I', 1)

    % Input image must be grayscale or truecolor RGB.
    errCond=(ndims(scale_img) >3) || ((size(scale_img,3) ~= 1) && (size(scale_img,3) ~=3));
    if (errCond)
        error('Input image must be grayscale or truecolor RGB');
    end
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
end

%--------------------------------------------------------------------------
function flag = isHandleType(h, hType)
% Check if handle, h, is of type hType
    if isempty(h)
        flag = false;
    else
        flag = ishandle(h) && strcmpi(get(h,'type'), hType);
    end
end

%--------------------------------------------------------------------------
function line = displayLine(axes, scale_img)
% Display image in the specified axis
figure, imshow(scale_img);
line = imdistline(gca);
%set(hAxis, ...
    %'YDir','reverse',...
    %'TickDir', 'out', ...
    %'XGrid', 'off', ...
    %'YGrid', 'off', ...
    %'PlotBoxAspectRatioMode', 'auto', ...
    %'Visible', 'off');
end

