classdef (Abstract) VideoSource < handle
    %VIDEOSOURCE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties 
        gpu_supported;
    end
    
    methods (Static)
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
        function resolution = get_resolution()
            
        end
        
        function gpu_supported = determine_gpu_support(obj)
            if(strcmp(SysInfo.get_os(), 'Windows'))
                gpu_supported = true;
            else
                gpu_supported = false;
            end
        end
    end
    
end

