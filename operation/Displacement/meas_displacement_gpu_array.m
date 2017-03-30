function [xoffSet, yoffSet, dispx,dispy,x, y] = meas_displacement_gpu_array(template,rect, img, xtemp, ytemp, displacement)
%MEAS_DISPLACEMENT_GPU_ARRAY Summary of this function goes here
%   Detailed explanation goes here
disp('PRE-INITIALIZATION');
tic;
min_displacement = 2; %pixel unit
global vid_height;
global vid_width;
vid_height = 1024;
vid_width = 1280;
Xm =40*10^(-6); %distance according to chip dimensions in microns
Xp = 184.67662; %distance according image in pixels. Correspond to Xm
%%    ************************** WHOLE PIXEL PRECISION COORDINATES *************************
    template = gpuArray(template);

    %DEFINE SEARCH AREA - obtained from no interpolated image
    width = displacement; 
    height = displacement;

    search_area_xmin = rect(1) - width;
    search_area_ymin = rect(2)- height;
    search_area_width = 2*width+rect(3);
    search_area_height = 2*height+rect(4);
    [search_area, search_area_rect] = imcrop(img,[search_area_xmin search_area_ymin search_area_width search_area_height]); 
    disp(toc);

    %PERFORM NORMALIZED CROSS-CORRELATION
    %Note: Jessica tried to perform Gradient Descent NCC Surface but
    %the timing was problematic.  The NCC Surface algorithm only
    %accepted entire images, and was subsequently too slow.
    disp('NORMXCORR');
    tic;
    c = normxcorr2(template, search_area);
    disp(toc);

    %FIND PEAK CROSS-CORRELATION
    [ypeak, xpeak] = find(c==max(c(:)));   
    xpeak = gather(xpeak+round(search_area_rect(1))-1);
    ypeak = gather(ypeak+round(search_area_rect(2))-1);

    yoffSet = ypeak-(size(template,1));
    xoffSet = xpeak-(size(template,2));

    %DISPLACEMENT IN PIXELS
    y = ypeak - ytemp;
    x = xpeak - xtemp;
    
    %DISPLACEMENT In meters
    dispx = Xm*x/Xp;
    dispy = Xm*y/Xp;
end

