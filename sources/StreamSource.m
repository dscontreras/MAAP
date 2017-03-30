classdef StreamSource < VideoSource
    %STREAMSOURCE Summary of this class goes here
    %   Class for describing the various properties of an input source
    %   that resembles a stream, with input continuously coming in
    
    properties
        inputcam;
        options;
        end_btn;
    end
    
    methods
        %OBJECT CONSTRUCTOR
        %Params:
        %camname: the identifier of the camera to be used as an image
        %acquisition device
        %options: cell array of camera options in the order:
        %(FramesPerTrigger, triggertype, trigger repeat)
        %Outputs:
        %Object of class StreamSource
        function obj = StreamSource(camname, opts)
            try
                disp(nargin);
                %Set the input camera of the stream source to a videoinput
                %with identifier camname
                obj.inputcam = videoinput(camname);
                if(nargin > 1)
                    obj.options = opts;
                else
                    disp('auto options');
                    obj.options = {1, 'manual', Inf};
                end
            catch E
                %If camname does not actually correctly identify any image
                %acquisition camera then set the camera automatically to
                %pointgey
                if(strcmp(E.identifier, 'imaq:videoinput:invalidAdaptorName'))
                    available_cams = getfield(imaqhwinfo, 'InstalledAdaptors');
                    index_of_pointgrey = strmatch('pointgrey', available_cams);
                    obj.inputcam = videoinput(char(available_cams(index_of_pointgrey)));
                end
            end
            %configure the camera according to options
            obj.inputcam.FramesPerTrigger = obj.options{1};
            triggerconfig(obj.inputcam, obj.options{2});
            obj.inputcam.TriggerRepeat = obj.options{3};
            %now start the camera
            start(obj.inputcam);
        end
        
        %extractFrame
        %Description: extract a single frame from the source stream
        %Params:
        %obj
        %Output: A frame matrix of uint8 type.  Any use of frame must be in
        %conjunction with a gather(frame) operation, since the location of
        %the array is inside the GPU
        function frame = extractFrame(obj)
            trigger(obj.inputcam);
            frame = gpuArray(getdata(obj.inputcam, 1, 'uint8'));
        end

        %extractFrames
        %Description: extract a single frame from the source stream
        %Params
        %obj
        %numFrames: The number of frames to collect from the stream
        %Output: A frames matrix of uint8 type and a length equal to the number of frames.  
        %Any use of frames must be in
        %conjunction with a gather(frame) operation, since the location of
        %the array is inside the GPU
        function frames = extractFrames(obj, num_frames)
            frames = gpuArray(getdata(obj.inputcam, num_frames, 'uint8'));
        end
        
        %start
        %Description: used to start the camera in order to be able to then
        %collect frames.  You must start the camera and then start
        %collecting data within a certain period of time, otherwise a
        %timeout will occur, and you must then call start again.
        %Params:
        %obj
        function start(obj)
            start(obj.inputcam);
        end
        
        function bool = finished(obj)
            if(get(obj.end_btn, 'Value') == 1)
                bool = true;
            else
                bool = false;
            end
        end
        
        function resolution = get_resolution(obj)
            trigger(obj.inputcam);
            frame = obj.extractFrame();
            resolution = size(frame);
        end
    end
    
end

