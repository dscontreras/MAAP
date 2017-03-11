classdef FileSource < VideoSource
    %FILESOURCE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        filepath;
        videoReader;
        options;
    end
    
    methods
        function obj = FileSource(filein)
            obj.filepath = filein;
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
            %ERROR HERE WHITE FRAMES OUTPUTTED.  FIX.
            frame = gpuArray(uint8(readFrame(obj.videoReader) * 255));
            
        end
        
    end
    
end

