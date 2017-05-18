classdef (Abstract) Operation < handle
    %OPERATION Summary of this class goes here
    %   Detailed explanation goes here
    
%     properties (Abstract, SetAccess = private)
%         %The value checked to determine when this operation should start in the queue.
%         %Once started, this condition is no longer checked 
%         start_check_callback;
%     end
    
    properties(Access = public, Abstract)
        %outputs is a map containing key:value pairs of the form "name
        %of the output variable"(of type string):value of the
        %variable(varies).  You, as a coder may pick and choose which
        %values outputted from execute() may be sent, and documented by the
        %output map.
        outputs;
        %indicates whether the object is in a good state or not
        valid;
        %new indicates whether the operation is new on the stack
        new;
        %input_param_names is a cell matrix that is 2xn where n is the
        %number of parameters for the operation.
        param_names;
        %error_report_handle stores the handle that should execute when
        %this operation encounters an error and cannot continue, this
        %handle will be from a function defined in queue.
        error_report_handle;
        %queue_index is a marker that denotes where numerically in the
        %queue the operation was placed.  queue_index is set to -1 if the
        %operation is not part of a queue
        queue_index;
        %The value checked to determine when this operation should start in the queue.
        %Once started, this condition is no longer checked 
        start_check_callback;
        inputs;
    end
    
    properties(Access = public, Abstract, Constant)
        %Name of the operation
        name;
        %names of operations that this operation object will receive data
        %from, and what it will receive from them.  Stored in the format:
        %{name_of_operation_receiving_from, {params_to_receive}}
        %in a given queue.  Information is not passed from queue to queue
        %in the scheduler
        rx_data;
        %insertion_type controls where this operation should be inserted in
        %a queue.  Currently, there are no guarantees as to a specific
        %index at which an operation will be placed.  This is intended as
        %an enumeration, where the possible values are {start, end}
        insertion_type;
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
        %METHOD: validate
        %validate ensures that the operation is in good health whenever it
        %is called, and that all its internal variables are storing
        %correctly bounded and correctly typed values.
        validate(obj);
    end
    
    methods
        
        function report_error(obj, error)
            obj.valid = false;
            error_msg = strcat(obj.name, '_operation: ', error);
            try
                feval(obj.error_report_handle);
            catch(feval(obj.error_report_handle, error_msg))
                disp('ERROR_REPORT_HANDLE FAILED TO EXECUTE');
            end
        end

        function args_out = get_num_args_out(obj)
           args_out = length(obj.outputs);
        end
        
        function args_in = get_num_args_in(obj)
           args_in = length(obj.inputs);
        end
        
        function set_error_report_handle(obj, handle)
            obj.error_report_handle = handle;
        end
        
    end
    
end

