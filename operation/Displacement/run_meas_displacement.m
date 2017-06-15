v = VideoReader('/Users/timmytimmyliu/research/maap/videos/30V_1.avi');
vWidth = v.Width;
vHeight = v.Height;
%rect = [730, 550, 70, 30];
rect = [584, 493, 74, 35];
%rect = find_rect(v, 'template.png') 
originalFrame = rgb2gray(readFrame(v));
k = 1;
mov = struct('cdata',zeros(vHeight,vWidth,3,'uint8'),'colormap',[]);

while v.hasFrame 
    frame = readFrame(v);
    frame = rgb2gray(frame); 
    mov(k).cdata = frame;
    k = k + 1;
end
k
template = imcrop(originalFrame, rect);
img = mov(21).cdata;
displacement = 50;
xtemp = rect(1);
ytemp = rect(2);
precision = 0.5; 
res = 0.5; 

tic
[xoffSet, yoffSet, dispx,dispy,x, y, c1] = meas_displacement(template, rect, img, xtemp, ytemp, precision, displacement, res);
disp = toc;

tic
[xoffSet1, yoffSet1, dispx1,dispy1,x1, y1, c11] = meas_displacement2(template, rect, img, xtemp, ytemp, precision, displacement, res);
disp1 = toc;

tic
[xoffSet2, yoffSet2, dispx2,dispy2,x2, y2, c12] = meas_displacement3(template, rect, img, xtemp, ytemp, precision, displacement, res);
disp2 = toc;

tic
[xoffSet3, yoffSet3, dispx3,dispy3,x3, y3, c13] = meas_displacement4(template, rect, img, xtemp, ytemp, precision, displacement, res);
disp3 = toc;

times = [disp disp1 disp2 disp3];
    dlmwrite('disp_times2.dat', times, '-append');
    % Video: 50V_1.avi; 30 trials:
    % col1: interp2 and normxcorr2 (original): 0.01586208500000001
    % col2: *interp2 and normxcorr2: 0.015590505
    % col3: interp2 and fourier_xc: 0.022950125
    % col4: *interp2 and fourier_xc: 0.02235597499999999
%{
% Is meas_displacement == meas_displacement2
xoffSet == xoffSet1
yoffSet == yoffSet1
dispx == dispx1
dispy == dispy1
x == x1
y == y1
c1 == c11 
%}


%{
% Is meas_displacement == meas_displacement3
xoffSet == xoffSet2
yoffSet == yoffSet2
dispx == dispx2
dispy == dispy2
x == x2
y == y2
c1 == c12 
%}

%{
% Is meas_displacement == meas_displacement4
xoffSet == xoffSet3
yoffSet == yoffSet3
dispx == dispx3
dispy == dispy3
x == x3
y == y3
c1 == c13
 %}

