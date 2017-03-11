classdef VideoSource < handle
    %VIDEOSOURCE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods (Static)
        function source = getSourceType(src)
            if(isa(src, 'vision.VideoFileReader'))
                source = 'file';
            elseif(isa(src, 'videoinput'))
                source = 'stream';
            end
        end
    end
    
end

