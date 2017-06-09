v = VideoReader('E:/microscopeanalysis/videos/45V_1.avi');
vWidth = v.Width;
vHeight = v.Height;
% rect = [730, 550, 70, 30];
rect = find_rect('E:/microscopeanalysis/videos/45V_1.avi', 'E:\microscopeanalysis\template.png');
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
precision = 1;
res = 1;
%tic
[xoffSet, yoffSet, dispx,dispy,x, y, c1] = meas_displacement(template, rect, img, xtemp, ytemp, precision, displacement, res);
%toc
%tic
[xoffSet1, yoffSet1, dispx1,dispy1,x1, y1, c11] = meas_displacement2(template, rect, img, xtemp, ytemp, precision, displacement, res);
%toc

xoffSet == xoffSet1
yoffSet == yoffSet1
dispx == dispx1
dispy == dispy1
x1 == x
y == y1
c1 == c11

