function colored = color_image(img, y, x, height, width, val)
    % Returns a copy of img but with the rectangle y:y+height, x:x+height changed to val
    colored = img;
	colored(y:y+height, x:x+width) = val;
end
