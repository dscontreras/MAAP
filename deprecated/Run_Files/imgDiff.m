v = VideoReader('/Users/timmytimmyliu/research/maap/videos/wire_moving_short_video.mov');
vWidth = v.Width;
vHeight = v.Height;
firstFrame = rgb2gray(readFrame(v));
i = 1;
while i < 300
    readFrame(v);
    i = i + 1;
end
secondFrame = rgb2gray(readFrame(v));
img = imabsdiff(secondFrame, firstFrame);
imshow(img);