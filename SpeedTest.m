function SpeedTest()
%SPEEDTEST Summary of this function goes here
%   Detailed explanation goes here
    figure;
    x = 0:100;
    y = 0:100;
    iterations = 300;
    hAx = axes;
    plot(x, y);
%    drawnow;
%    disp('imshow');
%    avg = 0;
%    for i = 1:iterations
%    image = rand(1024,1280);
%    tic;
%    hIm = imshow(image, 'Parent', hAx);
%     drawnow;
%     time = toc;
%     avg = avg + time;
%     end
%     avg = avg/iterations;
%     disp('imshow avg');
%     disp(avg);
%     disp('cdata');
%     avg = 0;
%     for i = 1:iterations
%         tic;
%         set(hIm, 'CData', rand(1024, 1280));
%         drawnow;
%         time = toc;
%         avg = avg + time;
%     end
%     avg = avg / iterations;
%     disp('cdata avg');
%     disp(avg);
    im = imshow(randi(1024, 1280, 'uint8'));
    disp('cdata gpu');
    avg = 0;
    for i = 1:iterations
        tic;
        set(im, 'CData', gather(randi(1024, 1280, 'uint8' , 'gpuArray')));
        drawnow;
        time = toc;
        avg = avg + time;
    end
    avg = avg / iterations;
    disp('gpu cdata avg');
    disp(avg);
    disp('cdata nongpu');
    avg = 0;
    for i = 1:iterations
        tic;
        set(im, 'CData', randi(1024, 1280, 'uint8'));
        drawnow;
        time = toc;
        avg = avg + time;
    end
    avg = avg / iterations;
    disp('cdata nongpu avg');
    disp(avg);
end

