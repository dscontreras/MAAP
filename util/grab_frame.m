function [frame] = grab_frame(src, displacement_obj)
%GRAB_FRAME generalized function for retrieving a frame from a given
%source.  Function will work whether the source is a camera or a video
%file.  Additional sources are not supported currently.  

%EXTRACT FRAME
try
    frame = src.extractFrame();
catch
    error('Frame unextractable.  Terminating frame grab.');
end
%IMAGE TREATMENT
frame = rgb2gray(frame);

