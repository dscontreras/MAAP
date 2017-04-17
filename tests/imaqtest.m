function avg_time = imaqtest(cam_name)
%IMAQ Test for timing webcam acquisition
%Detailed explanation goes here
if(isempty(videoinput(cam_name)))
    error('No videoinput with that name!');
else
    cam = videoinput(cam_name);
    cam.FramesPerTrigger = Inf;
    triggerconfig(cam, 'manual');
    fig = figure;
    drawnow;
    setappdata(0, 'keypressed', ''); 
    avg = 0;
    set(fig, 'KeyPressFcn', @(h_obj, event) setappdata(0, 'keypressed', event.Key));
    i = 0;
    start(cam);
    image = imshow(getsnapshot(cam));
    trigger(cam);
    while(~strcmp(getappdata(0, 'keypressed'), 'q'))
        tic;
        %frame = gpuArray(uint8(getdata(cam) * 255));
        frame = gpuArray(getdata(cam, 1, 'uint8'));
        %vidplayer.step(gather(frame));
        set(image, 'CData', gather(frame));
        drawnow;
        n = toc;
        disp(n);
        avg = avg + n;
        i = i + 1;
    end
    avg_time = avg/i;
    disp('Average time to display an image in seconds');
    disp(avg_time);
    delete(cam);
    clear cam;
    close(fig);
end


