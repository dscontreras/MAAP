%%    ************************** Initialization *************************

<<<<<<< HEAD
v = VideoReader('/Users/timmytimmyliu/research/maap/videos/30V_1.avi');
=======
v = VideoReader('/Users/timmytimmyliu/research/maap/videos/45V_1.avi');
>>>>>>> 69e3ead3754dc29b8680b691f8f67639156d24f4
vWidth = v.Width;
vHeight = v.Height;

mov = struct('cdata',zeros(vHeight,vWidth,3,'uint8'),'colormap',[]);

% TODO: MODIFY THIS!
displacement = 50; % I need to ensure that displacement and the width/height of the template match up. 
% An easy fix would be to affect search_area_width/height. 
% Make everything even

<<<<<<< HEAD
rect = [730, 550, 70, 30];

originalFrame = rgb2gray(readFrame(v));
mov(1).cdata = originalFrame;
template = imcrop(originalFrame, rect);

%% Some code to make sure the rect value matches up

frame = originalFrame;
frame(rect(1):rect(1)+rect(4), rect(2):rect(2)+rect(3))=255;
imshow(frame);

%%

=======
rect = [730, 550, 70, 34];

originalFrame = rgb2gray(readFrame(v));
template = imcrop(originalFrame, rect);
imshow(template)
>>>>>>> 69e3ead3754dc29b8680b691f8f67639156d24f4
%DEFINE SEARCH AREA - obtained from no interpolated image
width = displacement; %search area width
height = displacement; %search area height

<<<<<<< HEAD
=======
% TODO: something to ensure that width/height-templateW/templateH can be divided by 2!

>>>>>>> 69e3ead3754dc29b8680b691f8f67639156d24f4
search_area_xmin = rect(1) - width; %xmin of search area
search_area_ymin = rect(2)- height; %ymin of search area
search_area_width = 2*width+rect(3); %Get total width of search area
search_area_height = 2*height+rect(4); %Get total height of search area
<<<<<<< HEAD
k = 2;
=======
%[search_area, search_area_rect] = imcrop(img,[search_area_xmin search_area_ymin search_area_width search_area_height]); 
%%    ************************** Initialization 2 *************************
v = VideoReader('/Users/timmytimmyliu/research/maap/videos/45V_1.avi');
k = 1;
>>>>>>> 69e3ead3754dc29b8680b691f8f67639156d24f4
while v.hasFrame
    frame = readFrame(v);
    frame = rgb2gray(frame); 
    mov(k).cdata = frame;
    k = k + 1;
end
<<<<<<< HEAD
%%    ************************** Video *************************

i = 1; % change the value of i here to change where you start from
% to run 1 frame, change i to that frame value and uncomment the i=1000
% line below
count = 0;
while i < k-1
    %imtool(template);
    template = imcrop(originalFrame, rect);
    img = mov(i).cdata;
    
    [search_area, search_area_rect] = imcrop(img,[search_area_xmin search_area_ymin search_area_width search_area_height]); 
=======
%%    ************************** Read One Frame *************************
i = 1;
%i = 39;
%i = 148;
% i = 179
% i = 196
% i = 247 
% i = 271
% i = 288
% i = 312
% i = 319
% i = 363
% i = 403
while i < k-1 & i > 0
    template = imcrop(originalFrame, rect);
    %imshow(template);
    img = mov(i).cdata;
    
    [search_area, search_area_rect] = imcrop(img,[search_area_xmin search_area_ymin search_area_width search_area_height]); 
    %imshow(search_area)
>>>>>>> 69e3ead3754dc29b8680b691f8f67639156d24f4
    % Original alg
    c = normxcorr2(template, search_area); %So perform normalized cross correlation to find where the
                                            %template is in the image right now
    %imshow(search_area)
    %FIND PEAK CROSS-CORRELATION
    [ypeak, xpeak] = find(c==max(c(:))); %find where the template's starting x and y's are in the image
<<<<<<< HEAD
    
    [yR, xR] = fourier_cross_correlation(template, search_area, search_area_height, search_area_width);
    
    % Check if the peaks differ by more than 1 (so 2)
    if abs(ypeak - yR) > 1 | abs(xpeak - xR) > 1
        count = count + 1;
        [i*-1, ypeak, xpeak, yR, xR] % tells you which frame failed
    end
    i = i + 1;
    %i = 1000 % uncomment this if you only want to check one particular
    %frame value
end
count % how may frames failed

% The below is to visualize a few things
or = search_area;
new = search_area;
or(ypeak:ypeak + 10, xpeak: xpeak + 10) = 255;
new(yR:yR + 10, xR: xR + 10) = 255;
subplot(2, 3, 1)
imshow(or)
subplot(2, 3, 2)
imshow(new)
subplot(2, 3, 3)
imshow(template)

template = -template+100;
search_area = -search_area+100;
subplot(2, 3, 4)
imshow(origT)
subplot(2, 3, 5)
imshow(origS)

%% **** Even More stuff? ****

%i = 21; % blurry ness
% i = 39; % blurry ness
% i = 196; % blurryness? y value is waaay to far off
% i = 206; % not sure if blurryness can explain this one
% i = 271; % very blury
% i = 288;% very blury
% i = 312;% very blury
% i = 363; % very blury
% i = 403; % very blury
% i = 420;% very blury


i = [21, 39, 196, 206, 271];
g = [288, 312, 363, 403, 420];
l = length(i)
lg = g
z = 1
for idx = 1:numel(i)
    element = i(idx)
    subplot(2, l, z);
    img = mov(element).cdata;
    [search_area, search_area_rect] = imcrop(img,[search_area_xmin search_area_ymin search_area_width search_area_height]); 
    imshow(search_area);
    z = z + 1;
end
for idx = 1:numel(g)
    element = g(idx)
    subplot(2, l, z);
    img = mov(element).cdata;
    [search_area, search_area_rect] = imcrop(img,[search_area_xmin search_area_ymin search_area_width search_area_height]); 
    imshow(search_area);
    z = z + 1;
end
=======

    % Padding: So this is necessary because of some assumption that is made by
    % the convolution/correlation theorem!

    % Pad search_area
    search_area_padded = padarray(search_area, [search_area_rect(1), search_area_rect(2)], 'pre');


    % Pad Template
    [m1, n1] = size(search_area_padded);
    [m2, n2] = size(template);
    template_padded = padarray(template, [(m1-m2), (n1-n2)], 'pre');

    % Use property that convolution of h and conj(f(x)) = cross-correlation of the two
    % template = flip(template, 1);
    % template = flip(template, 2);
    % template = conj(template);
    %imtool(template);

    % Find the DTFT of the two
    dtftOfFrame = fft2(search_area_padded);
    dtftOfTemplate = conj(fft2(template_padded));

    R = dtftOfFrame.*dtftOfTemplate;
    R = R./abs(R); 
    %imshow(R)
    r = ifft2(R);
    %imshow(r)
    % Find maximum value in each column
    [yR, xR] = find(r==max(r(:)));

    % Remove effects from the padding and the 1 indexing
    % After all, I added search_area_rect to the two dimensions to pad template
    yR = yR - search_area_rect(1)-1;
    xR = xR - search_area_rect(2)-1;
    if abs(ypeak - yR) > 1 | abs(xpeak - xR) > 1 
        i
        yDiff = [ypeak, yR] %xpeak/ypeak are what peaks are supposed to be
        xDiff = [xpeak , xR] % xR/yR are our observed peaks
    end
    i = i + 1;
    %i = 1000;
end
% subplot(1, 3, 1)

% imshow(template)
% subplot(1, 3, 2)
% imshow(search_area)
% subplot(1, 3, 3)
% imshow(r)
%%    ************************** Additional Testing *************************
or = search_area;
new = search_area;
if yR < 0
    yR = 1
end
if xR < 0
    xR = 1
end
or(ypeak:ypeak + 10, xpeak: xpeak + 10) = 3;
new(yR:yR + 10, xR: xR + 10) = 3;
subplot(1, 2, 1)
imshow(or)
subplot(1, 2, 2)
imshow(new)

>>>>>>> 69e3ead3754dc29b8680b691f8f67639156d24f4

















<<<<<<< HEAD
=======

 
>>>>>>> 69e3ead3754dc29b8680b691f8f67639156d24f4
