% Reference: http://proceedings.spiedigitallibrary.org/proceeding.aspx?articleid=980710

function interp = FourierInterpolation(template, rect, img, xtemp, ytemp, precision, displacement, res)
interp_template = im2double(template);
[numRows, numCols, ~] = size(interp_template);
[X, Y] = meshgrid(1:numCols, 1:numRows);
[Xq, Yq] = meshgrid(1:precision:numCols, 1:precision:numRows);
V = interp_template;

%% ******* TODO: determine interpolation ratio along x- and y-coordinates ******** %%


%% ******* Transform image to Frequency Domain ****** %% 
V = fft2(V);

%% ******* Multiply FT by phase term ****** %% 


%% ******* Transform back into spatial domain ***** %% 
V = ifft2(V);

%% ******* Repeat steps 3 and 4 until all images covering missing points are obtained ****** %% 


%% ******* Interlace elements of all images ****** %%
% TODO: Change this so it uses Fourier Transform and not the interp2 function
interp = interp2(X, Y, V, Xq, Yq, 'cubic');  % original algorithm
