function colored = color_image(img, y, x, height, width, val)
	colored = img;
	colored(y:y+height, x:x+width) = val;
end