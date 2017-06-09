v = VideoReader('/Users/timmytimmyliu/research/maap/videos/50V_1.avi');
vWidth = v.Width;
vHeight = v.Height;
%rect = [730, 550, 70, 30];
rect = [600, 500, 70, 30];
originalFrame = rgb2gray(readFrame(v));
k = 1;
while v.hasFrame 
    frame = readFrame(v);
    frame = rgb2gray(frame); 
    mov(k).cdata = frame;
    k = k + 1;
end
template = imcrop(originalFrame, rect);
img = mov(21).cdata;
displacement = 50;
xtemp = rect(1);
ytemp = rect(2);
precision = rand; 
res = rand; 
tic
[xoffSet, yoffSet, dispx,dispy,x, y, c1, orig_interp2_time] = meas_displacement(template, rect, img, xtemp, ytemp, precision, displacement, res);
orig_displacement_time = toc;

tic
[xoffSet1, yoffSet1, dispx1,dispy1,x1, y1, c11, new_interp2_time] = meas_displacement2(template, rect, img, xtemp, ytemp, precision, displacement, res);
new_displacement_time = toc;

times = [orig_interp2_time new_interp2_time orig_displacement_time new_displacement_time]
%dlmwrite('normxcorr2_times.dat', times, '-append');
%dlmwrite('fourier_xc_times.dat', times, '-append');

% Notes:
%   - normxcorr2 cols: [orig_interp2_time new_interp2_time orig_disp_time new_disp_time]
%   - fourier_xc cols: [normxcorr_time fourier_xc_time orig_disp_time new_disp_time]
%       fourier_xc also takes takes in interp2 and qinterp2 times
%   - normxcorr2 col1 average: 0.0014133960000000001
%   - normxcorr2 col2 average: 0.001651706
%   - normxcorr2 col3 average: 0.019213669999999995
%   - normxcorr2 col4 average: 0.0167706
%
%   - fourier_xc col1 average: 0.00846834
%   - fourier_xc col2 average: 0.00839264
%   - fourier_xc col3 average: 0.1109929
%   - fourier_xc col4 average: 0.1103465


%{
xoffSet == xoffSet1
yoffSet == yoffSet1
dispx == dispx1
dispy == dispy1
x1 == x
y == y1
c1 == c11 
%}


