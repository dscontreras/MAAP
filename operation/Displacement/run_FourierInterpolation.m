v = VideoReader('/Users/timmytimmyliu/research/maap/videos/45V_1.avi');
vWidth = v.Width;
vHeight = v.Height;
rect = [730, 550, 70, 30];
originalFrame = rgb2gray(readFrame(v));
k = 1;
while v.hasFrame & k < 120
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
tic
interp = FourierInterpolation(template, rect, img, xtemp, ytemp, precision, displacement, res)
toc