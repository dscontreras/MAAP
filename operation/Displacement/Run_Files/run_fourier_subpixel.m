v = VideoReader('../../../../R1C1/45V_1.avi');
vWidth = v.Width;
vHeight = v.Height;

mov = struct('cdata',zeros(vHeight,vWidth,3,'uint8'),'colormap',[]);

displacement = 50;

%rect = [730, 550, 70, 30];
%%
k = 2;
while v.hasFrame 
    frame = readFrame(v);
    frame = rgb2gray(frame); 
    mov(k).cdata = frame;
    k = k + 1;
end

rect = [590, 500, 60, 25];

originalFrame = rgb2gray(readFrame(v));
mov(1).cdata = originalFrame;
mov(2).cdata = rgb2gray(readFrame(v));
template = imcrop(originalFrame, rect);
background = mov(18).cdata;
background = imcrop(background, [rect(1)-50 rect(2)-50 rect(3)+100 rect(4)+100]);
imshow(background)
%% Fourier
template = imcrop(mov(2).cdata, rect);
background = mov(291).cdata;
background = imcrop(background, [rect(1)-50 rect(2)-50 rect(3)+100 rect(4)+100]);
imshow(background);
% calculate padding
bx = size(background, 2); 
by = size(background, 1);

tx = size(template, 2); % used for bbox placement
ty = size(template, 1);

%% fft from stackoverflow
%c = real(ifft2(fft2(background) .* fft2(template, by, bx)));

%// Change - Compute the cross power spectrum
gray_inversion = mean(mean(template));
background_gray = gray_inversion - background;

template_gray = gray_inversion - template;

Ga = fft2(background_gray);
Gb = fft2(template_gray, by, bx);
c = real(ifft2((Ga.*conj(Gb))./abs(Ga.*conj(Gb))));

%%
template = imcrop(mov(2).cdata, rect);
background = mov(291).cdata;
background = imcrop(background, [rect(1)-50 rect(2)-50 rect(3)+100 rect(4)+100]);

gray_inversion = mean(mean(template));
background_gray = gray_inversion - background;
template_gray = gray_inversion - template;

bx = size(background, 2); 
by = size(background, 1);
tx = size(template, 2); % used for bbox placement
ty = size(template, 1);
gray_inversion = mean(mean(template));
template_gray = gray_inversion - template;
Gb = conj(fft2(template_gray, by*2, bx*2));
%%
tic
background_gray = gray_inversion - background;
Ga = fft2(background_gray, by*2, bx*2);

R = Ga.*Gb;
R = R./abs(R);
c1 = real(ifft2(R));
[max_c, imax]   = max(abs(c(:)));
[ypeak, xpeak] = find(c == max(c(:)));
toc
%%

% find peak correlation
[max_c, imax]   = max(abs(c(:)));
[ypeak, xpeak] = find(c == max(c(:)));
figure; surf(c), shading flat; % plot correlation    

% display best match
hFig = figure;
hAx  = axes;

%// New - no need to offset the coordinates anymore
%// xpeak and ypeak are already the top left corner of the matched window
position = [xpeak(1), ypeak(1), tx, ty];
imshow(background, 'Parent', hAx);
imrect(hAx, position);

figure; imshow(template)

%% Normxcorr2
tic
c = normxcorr2(template, background);
[yp, xp] = find(c==max(c(:)));
toc
%%
yp = yp - ty;
xp = xp - tx;

[max_c, imax]   = max(abs(c(:)));
[ypeak, xpeak] = find(c == max(c(:)));
figure; surf(c), shading flat; % plot correlation   
hFig = figure;
hAx  = axes;
position = [xp, yp, tx, ty];
imshow(background, 'Parent', hAx);
imrect(hAx, position);

figure; imshow(template)

