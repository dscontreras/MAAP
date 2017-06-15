function [ypeak, xpeak] = fourier_cross_correlation(template, search_area, search_area_height, search_area_width, grayscale_inversion)
    
    % TEMPLATE and SEARCH_AERA should be grayscale images
    % Performs cross correlation of SEARCH_AREA and TEMPLATE
    % is not normalized and differs from normxcorr2
    % GRAYSCALE_INVERSION is the value used to invert the image
    % if it's a 255 bit image, it should be 120
    % if it's not (an the values range from 0...1, it should be 0.5
    % Or at least, I've had the most luck with these values

    
    % Some image preprocessing
    % Assumes a grayscale image and inverts the colors to make the edges stand
    % out
    template = (grayscale_inversion-template)*2;
    search_area = (grayscale_inversion-search_area)*4.5; % To ensure that motion blur doesn't "erase" critical contours

    % Pad search_area
    % This is necessary because the convolution theorem/correlation theorem
    % assumes that the images are periodic so without this padding there would
    % be corruption at the edges
    search_area_padded = padarray(search_area, [search_area_height, search_area_width], 'post');

    % Pad Template to be the same size as the padded search_area
    [m1, n1] = size(search_area_padded);
    [m2, n2] = size(template);
    template_padded = padarray(template, [(m1-m2), (n1-n2)], 'post');
    % Find the DTFT of the two
    dtftOfFrame = fft2(search_area_padded);
    dtftOfTemplate = fft2(template_padded);
    conj_dtftOfTemplate = conj(dtftOfTemplate);

    % Take advantage of the correlation theorem
    % Corr(f, g) <=> element multiplication of F and conj(G) where F, G are
    % fourier transforms of the signals f, g
    R = dtftOfFrame.*conj_dtftOfTemplate;
    R = R./abs(R); % normalize to get rid of values related to intensity of light
    r = ifft2(R); 
    
    % Find maximum value. 
    [ypeak, xpeak] = find(r==max(r(:))); % the origin of where the template is

    % Add the template size to the get right most corner rather than the
    % origin to match the output of normxcorr2
    ypeak = ypeak + m2 - 1; 
    xpeak = xpeak + n2 - 1; 
end
