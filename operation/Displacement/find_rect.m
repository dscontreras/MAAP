%% TODO: Subtract mean of template from template and firstFrame to account for light intensity %%
function rect = find_rect(video, template)
    videoReader = VideoReader(video);
    firstFrame = rgb2gray(readFrame(videoReader));
    if length(size(template)) == 3
        template = rgb2gray(template);
    end
    
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