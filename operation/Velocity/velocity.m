v = VideoReader('E:\projects\MAAP\videos\wire_moving_short_video.avi');
rect = [1080 371 400 10];
started = false;
startPos = -1;
microns_per_pixel = 2.49;
displacement = [];
fps = 15;
frameNum = 1;
while hasFrame(v)
    frame = rgb2gray(readFrame(v));

    cropped = imadjust(imcrop(frame, rect), [.4; .5], [0; 1]);
    [~, xLoc] = find(max(cropped == 0), 1, 'last');
    xLoc = xLoc + rect(1);
    if ~started
        started = true;
        startPos = xLoc;
    end
    yLoc = rect(2);
    
    displacement = [displacement; [frameNum / fps, microns_per_pixel * (xLoc - startPos)]];
    frameNum = frameNum + 1;
 
    % Used for tracking how much the wire has been displaced.
%     imshow(frame);
%     hold on;
%     plot(xLoc, yLoc, 'r*');
%     hnd1=text(100,100, num2str(microns_per_pixel * (xLoc - startPos)));
%     set(hnd1,'FontSize',16);
%     set(hnd1, 'Color', 'y');
%     drawnow limitrate;
end
csvwrite('fiber_displacement_output.csv', displacement);
