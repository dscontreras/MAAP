function ImTest()
    clc;
    v = VideoReader('displacement_video.avi');
    vidRead = vision.VideoFileReader('displacement_video.avi');
    avg = 0;
    avg2 = 0;
%     while(hasFrame(v))
%         tic;
%         f = readFrame(v);
%         w = toc;
%         avg = avg + w;
%         tic;
%         fr = step(vidRead);
%         l = toc;
%         avg2 = avg2 + l;
%     end
%     disp('VIDREADER READFRAME');
%     disp(avg/20);
%     disp('VIDREAD STEP');
%     disp(avg2/20);
    imArr = [];
    disp('GPU ENABLED');
    figure;
    frame = gather(imArr(:,:,:,1));
    im = imshow(frame);
    avg = 0;
    i = 1;
    while(hasFrame(v))
        tic;
        frame = gpuArray(uint8(readFrame(v) * 255));
        set(im, 'CData', gather(frame));
        drawnow;
        n = toc;
        i = i + 1;
        avg = avg + n;
    end
    disp('AVG FRAMERATE:');
    disp(avg/i);
    avg = 0;
    i = 1;
    while(i < (size(imArr, 4) + 1))
        tic;
        imshow(step(vidRead));
        drawnow;
        n = toc;
        i = i + 1;
        avg = avg + n;
    end
    disp('AVG FRAMERATE 2:');
    disp(avg/(size(imArr, 4)));
%     i = 1;
%     while(~isDone(vidRead))
%         tic;
%         imshow(step(vidRead));
%         drawnow;
%         n = toc;
%         i = i + 1;
%         avg = avg + n;
%     end
%     disp('AVG FRAMERATE:');
%     disp(avg);
end

