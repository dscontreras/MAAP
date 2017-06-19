v = VideoReader('../../../../R1C1/45V_1.avi');
vWidth = v.Width;
vHeight = v.Height;

mov = struct('cdata',zeros(vHeight,vWidth,3,'uint8'),'colormap',[]);

max_displacement = 50;
min_displacement = 2;

rect = [590, 500, 60, 25];

originalFrame = rgb2gray(readFrame(v));
mov(1).cdata = originalFrame;
k = 2;
while v.hasFrame
    frame = readFrame(v);
    frame = rgb2gray(frame);
    mov(k).cdata = frame;
    k = k + 1;
end

%% Initialization
template = imcrop(originalFrame, rect);

search_area_height  = 2 * max_displacement + rect(4) + 1; % imcrop will add 1 to the dimension
search_area_width   = 2 * max_displacement + rect(3) + 1; % imcrop will add 1 to the dimension
search_area_xmin    = rect(1) - max_displacement;
search_area_ymin    = rect(2) - max_displacement;

% Make sure that when darks match up in both the
% image/template, they count toward the correlation
% We subtract from the mean as we know that darks are the
% edges.
template_average    = mean(mean(template));
processed_template  = template_average - template;
fft_conj_processed_template = conj(fft2(processed_template, search_area_height*2, search_area_width*2));

% The frame we will crop out when interpolating will have size (template_height + 2*min + 1, template_width+2*min+1)
% Interpolation takes that and the resulting dimension size is (k - 1)/pixel_precision + 1;
interp_search_area_width 	= (rect(3) + 2 * min_displacement + 1 - 1)/pixel_precision + 1;
interp_search_area_height 	= (rect(4) + 2 * min_displacement + 1 - 1)/pixel_precision + 1;

interp_template = im2double(template);
numRows 			= rect(4);
numCols 			= rect(3);
[X, Y] 				= meshgrid(1:numCols, 1:numRows);
[Xq, Yq] 			= meshgrid(1:pixel_precision:numCols, 1:pixel_precision:numRows);
V 					= interp_template;
interp_template = interp2(X, Y, V, Xq, Yq, 'cubic');

interp_template_average = mean(mean(interp_template));
processed_interp_template = interp_template_average - interp_template;
fft_conj_processed_interp_template = conj(fft2(processed_interp_template, interp_search_area_height*2, obj.interp_search_area_width*2));


%% Pixel Precision
frame = mov(290).cdata;
frame = imcrop(frame, [rect(1)-50 rect(2)-50 rect(3)+100 rect(4)+100]);
processed_frame = average - frame;
dtft_of_frame = fft2(processed_frame, fy*2, fx*2);
R = dtft_of_frame.*template_dtft_conj;
R = R./abs(R);
r = real(ifft2(R));

[ypeak, xpeak] = find(r==max(r(:)));

%% Subpixel
smaller_frame = imcrop(frame, [xpeak, ypeak, rect(3)+2*min_displacement, rect(4) + 2*min_displacement]);

interp_search_area = im2double(smaller_frame);
[numRows,numCols,~] = size(smaller_frame); % Replace with rect?
[X, Y] = meshgrid(1:numCols, 1:numRows);
[Xq, Yq] = meshgrid(1:precision:numCols, 1:precision:numRows);
V = interp_search_area;
interp_search_area = interp2(X, Y, V, Xq, Yq, 'cubic');
processed_interp_search_area = interp_average - interp_search_area;

%% Fourier

dtft_of_interp_frame = fft2(processed_interp_search_area, f_interp_y*2, f_interp_x*2);
R = dtft_of_interp_frame.*interp_template_dtft_conj;
R = R./abs(R);
r = real(ifft2(R));

[ypeak_sub, xpeak_sub] = find(r == max(r(:)));

final_ypeak = ypeak_sub * precision;
final_xpeak = xpeak_sub * precision;





%% Normxcorr

c = normxcorr2(template, smaller_frame);
[ypeak_sub_n, xpeak_sub_n] = find(c==max(c(:)));
ypeak = ypeak - ty
xpeak = xpeak - tx


%%
interp_search_area = interp2(X, Y, V, Xq, Yq, 'cubic');
interp_search_area(ypeak_sub:ypeak_sub+10, xpeak_sub:xpeak_sub+10) = 1;
% interp_search_area(ypeak_sub_n:ypeak_sub_n+10, xpeak_sub_n:xpeak_sub_n+10) = 1;
%interp_search_area(0:0+10, 0:xpeak_sub+10) = 1;
imshow(interp_search_area)
