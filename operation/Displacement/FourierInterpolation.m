function interp = FourierInterpolation(template, precision)
interp_template = im2double(template);
[numRows, numCols, ~] = size(interp_template);
[x, y] = meshgrid(1:numCols, 1:numRows);
[xq, yq] = meshgrid(1:precision:numCols, 1:precision:numRows);
v = interp_template;
% TODO: Change this so it uses Fourier Transform and not the interp2 function
interp = interp2(x, y, v, xq, yq, 'cubic'); 
