function SpeedTestNonGPU()
        im = imshow(randi(720, 720, 'uint8'));
        avg = 0;
        for i = 1:100
            tic;
            set(im, 'CData', randi(720, 720, 'uint8'));
            n = toc;
            avg = 
        end
        drawnow;
end

