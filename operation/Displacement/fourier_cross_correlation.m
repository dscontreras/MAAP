function [ypeak, xpeak] = fourier_cross_correlation(template, search_area, search_area_height, search_area_width, rect, grayscale_inversion)
    
    % TEMPLATE and SEARCH_AERA should be grayscaled images
    % Performs cross correlation of SEARCH_AREA and TEMPLATE
    % is not normalized and differs from normxcorr2
    % GRAYSCALE_INVERSION is the value used to invert the image
    % if it's a 255 bit image, it should be 120
    % if it's not (an the values range from 0...1, it should be 0.5
    % Or at least, I've had the most luck with these values 
    % These values were gotten experimentally, they may need to be tweaked

    
    % Some image preprocessing; Assumes a gray scale image and inverts the
    % colors to make the edges stand out
    search_area = (grayscale_inversion-search_area)*2; % To ensure that motion blur doesn't "erase" critical contours
    template = (grayscale_inversion - template)*2;
    
    subplot(2, 1, 1);
    imshow(search_area)
    subplot(2, 1, 2);
    imshow(template);
    
    % Pad search_area; Necessary to avoid corruption at edges
    search_area_padded = padarray(search_area, [search_area_height, search_area_width], 'post');
    [m, n] = size(template);
    template_padded = padarray(template, [2*search_area_height - m , 2*search_area_width-n], 'post');
    
    subplot(2, 1, 1);
    imshow(search_area_padded)
    subplot(2, 1, 2);
    imshow(template_padded);
    
    % Find the DTFT of the two
    dtft_of_frame = fft2(search_area_padded);
    fft_conj_template = conj(fft2(template_padded));

    % Take advantage of the correlation theorem
    % Corr(f, g) <=> element multiplication of F and conj(G) where F, G are
    % fourier transforms of the signals f, g
    R = dtft_of_frame.*fft_conj_template;
    R = R./abs(R); % normalize to get rid of values related to intensity of light
    r = ifft2(R); 
    
    [ypeak, xpeak] = find(r==max(r(:))); % the origin of where the template is   
end
