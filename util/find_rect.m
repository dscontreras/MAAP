%% TODO: Subtract mean of template from template and firstFrame to account for light intensity %%
function rect = find_rect(frame, template)
    % Uses phase correlation to quickly find the frame in the template
    % Only to be used in the first frame for a rought idea of where the template exist
    % In general, we suggest using TemplateMatcher
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
    ypeak = ypeak - templateHeight + 1;
    xpeak = xpeak - templateWidth  + 1;

    rect = [xpeak(1), ypeak(1), templateWidth, templateHeight];
end
