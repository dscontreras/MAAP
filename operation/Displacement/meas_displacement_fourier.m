function [xoffSet, yoffSet, dispx,dispy,x, y, maxval] = meas_displacement_fourier(template,rect, img, xtemp, ytemp, precision, displacement, res, fft_conj_template, fft_conj_interp_template, interp_template2)
min_displacement = 2; %pixel unit
Xm =40*10^(-6); %distance according to chip dimensions in microns
Xp = 184.67662; %distance according image in pixels. Correspond to Xm
%%    ************************** WHOLE PIXEL PRECISION COORDINATES *************************

%DEFINE SEARCH AREA - obtained from no interpolated image
width = displacement; %search area width
height = displacement; %search area height

search_area_xmin = rect(1) - width; %xmin of search area
search_area_ymin = rect(2)- height; %ymin of search area
search_area_width = 2*width+rect(3); %Get total width of search area
search_area_height = 2*height+rect(4); %Get total height of search area
[search_area, search_area_rect] = imcrop(img,[search_area_xmin search_area_ymin search_area_width search_area_height]); 

%"\tFourier"
[ypeak, xpeak] = fourier_cross_correlation(fft_conj_template, search_area, search_area_height, search_area_width, rect, 120);
%toc
xpeak = xpeak+round(search_area_rect(1))-1; %move xpeak to the other side of the template rect.
ypeak = ypeak+round(search_area_rect(2))-1; %move y peak down to the bottom of the template rect.

%% ************************** SUBPIXEL PRECISION COORDINATES *************************
%GENERATE MOVED TEMPLATE
%new_xmin = (xpeak-xtemp) + rect(1); 
new_xmin = (xpeak-rect(3));
%new_ymin = (ypeak-ytemp) + rect(2); 
new_ymin = (ypeak-rect(4));
[moved_template, displaced_rect] = imcrop(img,[new_xmin new_ymin rect(3) rect(4)]);

%GENERATE NEW SEARCH AREA (BASED IN MOVED TEMPLATE)
width1 = min_displacement; %set the width margin between the displaced template, and the search area as width1
height1 = min_displacement; %set the height margin between the displaced template, and the search area as height1
new_search_area_xmin = displaced_rect(1) - width1; 
new_search_area_ymin = displaced_rect(2)- height1;
new_search_area_width = 2*width1+displaced_rect(3);
new_search_area_height = 2*height1+displaced_rect(4);
[new_search_area, new_search_area_rect] = imcrop(img,[new_search_area_xmin new_search_area_ymin new_search_area_width new_search_area_height]);

%Interpolate both the new object area and the old and then compare
%those that have subpixel precision in a normalized cross
%correlation
% BICUBIC INTERPOLATION - TEMPLATE
interp_template = im2double(template);
[numRows,numCols,dim] = size(interp_template);
[X,Y] = meshgrid(1:numCols,1:numRows); %Generate a pair of coordinate axes 
[Xq,Yq]= meshgrid(1:precision:numCols,1:precision:numRows); %generate a pair of coordinate axes, but this time, increment the matrix by 0
V=interp_template; %copy interp_template into V

interp_template = interp2(X,Y,V,Xq,Yq, 'cubic'); 


% BICUBIC INTERPOLATION - SEARCH AREA (FROM MOVED TEMPLATE
interp_search_area = im2double(new_search_area);
[numRows,numCols,dim] = size(interp_search_area);
[X,Y] = meshgrid(1:numCols,1:numRows);
[Xq,Yq]= meshgrid(1:precision:numCols,1:precision:numRows);
V=interp_search_area;

interp_search_area = interp2(X,Y,V,Xq,Yq, 'cubic'); 
%"\tInterpolation"
%toc


 %PERFORM NORMALIZED CROSS-CORRELATION
c1 = normxcorr2(interp_template,interp_search_area); %Now perform normalized cross correlation on the interpolated images

%FIND PEAK CROSS-CORRELATION

[new_ypeak, new_xpeak] = find(c1==max(c1(:)));  


%[new_ypeak1, new_xpeak1] = fourier_cross_correlation(fft_conj_interp_template, interp_search_area, interp_search_area_height, interp_search_area_width, rect, 0.5);

% "\t Normxcorr2 2"
% toc
new_xpeak = new_xpeak/(1/precision);
new_ypeak = new_ypeak/(1/precision);
new_xpeak = new_xpeak+round(new_search_area_rect(1));
new_ypeak = new_ypeak+round(new_search_area_rect(2));

yoffSet = new_ypeak-(size(template,1));
xoffSet = new_xpeak-(size(template,2));

%DISPLACEMENT IN PIXELS
y = new_ypeak-ytemp;
x = new_xpeak-xtemp;

%DISPLACEMENT IN MICRONS    
dispx = x * res;
dispy = y * res;
    
    
end

