function [ypeak, xpeak] = fourier_cross_correlation(fft_conj_template, search_area, search_area_height, search_area_width, rect, grayscale_inversion)
    
    % TEMPLATE and SEARCH_AERA should be grayscaled images
    % Performs cross correlation of SEARCH_AREA and TEMPLATE
    % is not normalized and differs from normxcorr2
    % GRAYSCALE_INVERSION is the value used to invert the image
    % if it's a 255 bit image, it should be 120
    % if it's not (an the values range from 0...1, it should be 0.5
    % Or at least, I've had the most luck with these values 
    % These values were gotten experimentally, they may need to be tweaked

    
    % Some image preprocessing
    % Assumes a grayscale image and inverts the colors to make the edges stand
    % out
    search_area = (grayscale_inversion-search_area)*4.5; % To ensure that motion blur doesn't "erase" critical contours

    % Pad search_area
    % This is necessary because the convolution theorem/correlation theorem
    % assumes that the images are periodic so without this padding there would
    % be corruption at the edges
    search_area_padded = padarray(search_area, [search_area_height, search_area_width], 'post');
    
    % Find the DTFT of the two
    dtft_of_frame = fft2(search_area_padded);

    % Take advantage of the correlation theorem
    % Corr(f, g) <=> element multiplication of F and conj(G) where F, G are
    % fourier transforms of the signals f, g
    R = dtft_of_frame.*fft_conj_template;
    R = R./abs(R); % normalize to get rid of values related to intensity of light
    r = ifft2(R); 
    
    % Find maximum value. 
    [ypeak, xpeak] = find(r==max(r(:))); % the origin of where the template is

    % Add the template size to the get right most corner rather than the
    % origin to match the output of normxcorr2
    ypeak = ypeak + rect(4) - 1; 
    xpeak = xpeak + rect(3) - 1; 
end
