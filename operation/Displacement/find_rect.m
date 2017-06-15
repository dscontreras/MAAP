function rect = find_rect(videoReader, templateFilePath)
    firstFrame = rgb2gray(readFrame(videoReader));
    template = rgb2gray(imread(templateFilePath));
    
    %-- Adapted from https://stackoverflow.com/a/32664730
    frameWidth = size(firstFrame, 2);
    frameHeight = size(firstFrame, 1);
    templateWidth = size(template, 2);
    templateHeight = size(template, 1);

    Ga = fft2(firstFrame);
    Gb = fft2(template, frameHeight, frameWidth);
    c = real(ifft2((Ga.*conj(Gb))./abs(Ga.*conj(Gb))));

    [ypeak, xpeak] = find(c == max(c(:)));
    rect = [xpeak(1), ypeak(1), templateWidth, templateHeight];
end