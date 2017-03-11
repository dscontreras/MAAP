function SpeedTestGPU()
        im = imshow(randi(720, 720, 'uint8', 'gpuArray'));
        set(im, 'CData', gather(randi(720, 720, 'uint8', 'gpuArray')));
        drawnow;
end

