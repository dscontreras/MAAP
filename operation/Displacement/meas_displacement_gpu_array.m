function [xoffSet, yoffSet, dispx,dispy,x, y] = meas_displacement_gpu_array(template,rect, img, xtemp, ytemp, max_displacement, resolution)
%%    ************************** WHOLE PIXEL PRECISION COORDINATES *************************

    MIN_DISPLACEMENT = 2;
    template = gpuArray(template);

    %DEFINE SEARCH AREA - obtained from no interpolated image
    width = max_displacement; 
    height = max_displacement;

    search_area_xmin = rect(1) - width;
    search_area_ymin = rect(2)- height;
    search_area_width = 2*width+rect(3);
    search_area_height = 2*height+rect(4);
    [search_area, search_area_rect] = imcrop(img,[search_area_xmin search_area_ymin search_area_width search_area_height]); 

    %PERFORM NORMALIZED CROSS-CORRELATION
    %Note: Jessica tried to perform Gradient Descent NCC Surface but
    %the timing was problematic.  The NCC Surface algorithm only
    %accepted entire images, and was subsequently too slow.
    c = normxcorr2(template, search_area);

    %FIND PEAK CROSS-CORRELATION
    [ypeak, xpeak] = find(c==max(c(:)));   
    xpeak = gather(xpeak+round(search_area_rect(1))-1);
    ypeak = gather(ypeak+round(search_area_rect(2))-1);

    new_xmin = (xpeak - rect(3));
    new_ymin = (ypeak - rect(4));

    yoffSet = new_xmin;
    xoffSet = new_ymin;
    
    %DISPLACEMENT IN PIXELS
    y = new_ypeak - ytemp;
    x = new_xpeak - xtemp;
    
    %resolution's units are m/pixel
    dispx = x * resolution;
    dispy = y * resolution;
end

