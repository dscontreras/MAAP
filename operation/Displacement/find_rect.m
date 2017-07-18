%% TODO: Subtract mean of template from template and firstFrame to account for light intensity %%
function rect = find_rect(frame, template)
    if length(size(frame)) == 3
        frame = rgb2gray(frame);
    end
    if length(size(template)) == 3
        template = rgb2gray(template);
    end
    
    %-- Adapted from https://stackoverflow.com/a/32664730
    templateWidth = size(template, 2);
    templateHeight = size(template, 1);

    c = normxcorr2(template, frame);
    [ypeak, xpeak] = find(c==max(c(:)));
    ypeak = ypeak - templateHeight;
    xpeak = xpeak - templateWidth;

    rect = [xpeak(1), ypeak(1), templateWidth, templateHeight];
end