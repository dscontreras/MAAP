classdef FileSource < VideoSource
    %FILESOURCE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        filepath;
        videoReader;
        resolution_meters;
        options;
        gpu_supported;
    end
    
    methods
        function obj = FileSource(filein, resolution_meters)
            obj.filepath = filein;
            obj.resolution_meters = resolution_meters;
            obj.gpu_supported = obj.determine_gpu_support();
            try
                obj.videoReader = VideoReader(filein);
            catch E
                if(strcmp(E.identifier, 'MATLAB:audiovideo:VideoReader:FileNotFound'))
                    userinputpath = input('Please enter the desired video file path: ', 's');
                    obj.videoReader = VideoReader(userinputpath);
                end
            end
        end
        
        function frame = extractFrame(obj)
            if(obj.gpu_supported)
                frame = gpuArray(readFrame(obj.videoReader));
            else
                frame = readFrame(obj.videoReader);
            end
        end
        
        function bool = finished(obj)
            bool = ~hasFrame(obj.videoReader);
        end
        
        function resolution = get_num_pixels(obj)
               if(hasFrame(obj.videoReader))
                   frame = readFrame(obj.videoReader);
                   resolution = size(frame);
               else
                   error('obj.videoReader has no frames to read.');
               end
        end
        
        function filepath = get_filepath(obj)
            filepath = obj.filepath; 
        end
    end
    
end

