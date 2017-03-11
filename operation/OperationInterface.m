classdef OperationInterface
    %OperationInterface: An operation is any operation that the GUI user
    %wants to be able to perform, such as measuring the displacement of an
    %object under a microscope, recording the voltage, recording video,
    %taking photos, playing a video, etc...
    %----------------------------------------------------------------------
    %Operation: How is it implemented?
    %----------------------------------------------------------------------
    %Each operation has a packet structure which is passed into a queue
    %that processes and steps through operations that have been requested
    %by the user. This packet structure is of the format:
    %"OperationName:Field1, Field2,...FieldN:end"
    properties (SetAccess = protected, GetAccess = protected)
        num_fields;
        name;
    end
    
    methods (Abstract, Static)
        constructPacket();
    end

    methods (Abstract)
        execute(obj);
    end
    
end

