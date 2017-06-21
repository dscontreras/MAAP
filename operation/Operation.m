classdef (Abstract) Operation < handle & matlab.mixin.Heterogeneous
    %OPERATION Summary of this class goes here
    %   Detailed explanation goes here
    
    % TODO: Add scalable error handling. The current `error_report_handle`
    % is not adequate
    properties(Access = public, Abstract)
    end
    
    properties(Access = public, Abstract, Constant)
    end

    methods(Abstract)      
        %METHOD: execute
        %The most important method of the operational design model
        %implemented for this GUI.  This method specifies what operation
        %the operation object will perform when called in a given queue.
        %This could be displaying an image, retrieving data from a sensor,
        %or logging a value, but the execute method code must be consistent
        %for a given operation type.  Whether it takes argument(s) does not
        %have to be consistent for any given operation.
        execute(obj, argsin);
        %METHOD: startup
        %Does any initial calculation that may not have been possible
        %during the instantiation of the operation. 
        %TODO: remove the need for such a function. In the end, I should
            %only have to use instnantiate and call execute
        startup(obj, varargin);
        
    end
end

