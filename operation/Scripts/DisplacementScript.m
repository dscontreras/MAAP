% DisplacementScript 
% Given a video, finds the location of the a template image within the
% video and finds the displacement between the first frame and every
% frame within the video and puts it into a csv file titled 'displacement.csv'.
%   CSV format: 
%       Row 1: X displacement
%       Row 2: Y displacement
%       Row 3: Time elapsed
%
% DisplacementScript does not use the GUI
% To use the GUI, see run data_gui.m and select the "Displacement" option
%
% *Required parameters: videopath and templatepath
%   All other parameters are optional
    
function DisplacementScript(videopath, templatepath, max_x_displacement, max_y_displacement, res, pixel_precision, fps)
    video = VideoReader(videopath);
    template = rgb2gray(imread(templatepath));
    frame = readFrame(video);
    frame = rgb2gray(frame);
    rect = find_rect(frame, template);
    template = imcrop(frame, rect);
    rect = [rect(1) rect(2) rect(3)+1 rect(4)+1];
    [xtemp, ytemp] = get_template_coords(frame, template);
    if nargin <= 2
        max_x_displacement = 50; % default max x displacement
        max_y_displacement = 50; % default max y displacement
    end
    if nargin <= 4
        res = 5.86E-6; % default resolution
        pixel_precision = 0.5; % default pixel precision
        fps = video.FrameRate; % default fps for camera
    end
    tic;
    execute_script(video, template, rect, xtemp, ytemp, max_x_displacement, max_y_displacement, res, pixel_precision, fps);
    toc
end

function execute_script(video, template, rect, xtemp, ytemp, max_x_displacement, max_y_displacement, res, precision, fps)
    numFrames = video.Duration * fps;
    xdisp = zeros(1, round(numFrames));
    ydisp = zeros(1, round(numFrames));
    timeElapsed = zeros(1, round(numFrames));
    frameNum = 1;
    
    while hasFrame(video)
        img = gather(rgb2gray(readFrame(video)));
        [xoffSet, yoffSet, dispx,dispy,x, y] = meas_displacement(template, rect, img, xtemp, ytemp, ...
            precision, max_x_displacement, max_y_displacement, res);
        time = frameNum / fps;
        timeElapsed(frameNum) = time;
        xdisp(frameNum) = dispx;
        ydisp(frameNum) = -1*dispy; % origin is top left
        
        frameNum = frameNum + 1;
    end
    displacement = [xdisp; ydisp; timeElapsed];
    csvwrite('displacement.csv', displacement);
end