classdef (Abstract) VideoSource < handle
    %VIDEOSOURCE Summary of this class goes here
    %   Detailed explanation goes here

    properties (Abstract)
        gpu_supported;
    end

    methods(Abstract)
        frame = extractFrame(obj)
        bool  = finished(obj)
    end

    methods(Static)
        function source = getSourceType(src)
            if(isa(src, 'vision.VideoFileReader'))
                source = 'file';
            elseif(isa(src, 'FileSource'))
                source = 'file';
            elseif(isa(src, 'StreamSource'))
                source = 'stream';
            elseif(isa(src, 'videoinput'))
                source = 'stream';
            end
        end
    end

    methods
        function gpu_supported = determine_gpu_support(obj)
            gpu_supported = gpuDeviceCount > 0
        end
    end

end
