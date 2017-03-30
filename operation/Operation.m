classdef Operation < handle
    %OPERATION Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = private)
        %The value checked for the conditional, either a function to call
        %to check, or a number, specifying a preset number of iterations
        %the operation will execute
        stop_check_callback = @check_stop;    
        %names of operations that this operation object will send data to
        %in a given queue, and what it will send to them, {.  Information is not passed from queue to queue
        %in the scheduler
        tx_data;
        %names of operations that this operation object will receive data
        %from, and what it will receive from them.  Stored in the format:
        %{name_of_operation_receiving_from, {params_to_receive}}
        %in a given queue.  Information is not passed from queue to queue
        %in the scheduler
        rx_data;
        %The in_buffer holds incoming data from other operations.  It only
        %holds data from one previous execution of the queue, and no
        %further
        in_buffer;
        %insertion_type controls where this operation should be inserted in
        %a queue.  Currently, there are no guarantees as to a specific
        %index at which an operation will be placed.  This is intended as
        %an enumeration, where the possible values are {start, end}
        insertion_type;
        %args_in is a constant variable that determines how many arguments
        %this program's execute should accept
        num_args_in = 0;
        %args_out is a constant variable that determines how many arguments
        %this program's execute should output
        num_args_out = 0;
        %dependents is a list of all the operation classes that depend on
        %this one
        dependents = {};
    end
    
    properties
        %Outputs defines the names of the outputs of the execute function
        %NOTE: IT IS CRITICAL THAT THE ORDER OF OUTPUTS IS THE SAME AS THE
        %ACTUAL ORDER THAT VARIABLES ARE RETURNED FROM EXECUTE()
        outputs = {};
        %Inputs defines the names of the outputs of the execute function
        %NOTE: IT IS CRITICAL THAT THE ORDER OF INPUTS IS THE SAME AS THE
        %ACTUAL ORDER THAT VARIABLES ARE PASSED INTO EXECUTE()
        inputs = {};
    end

    methods
        %METHOD: stop_on
        %Used to configure the operation's stop condition in the queue, which in turn determines whether the operation
        %should remain in the queue after it executes.
        %Should the operation only execute once?  If so, it has
        %a single_shot stop type
        %Should it execute a certain number of times? If so, it has a repeat
        %stop type, and the stop trigger specified should be some number of
        %times for the operation to execute
        %Should it stop on some other conditional? If so, it has a trigger
        %stop type, and you must provide the handle of the function to call
        %that the queue will evaluate each time after the operation executes
        %Params: obj
        %condition_type: {'repeat', 'trigger', 'single_shot'}.  Configures
        %how the container queue of this operation should assess whether it
        %should remain in the queue for another execution, or remove it
        %stop_trigger: can either be not passed, a number, or a function
        %handle depending on the condition_type
        function bool = check_stop(obj)
            
        end
        
        %METHOD: execute
        %The most important method of the operational design model
        %implemented for this GUI.  This method specifies what operation
        %the operation object will perform when called in a given queue.
        %This could be displaying an image, retrieving data from a sensor,
        %or logging a value, but the execute method code must be consistent
        %for a given operation type.  Whether it takes argument(s) does not
        %have to be consistent for any given operation.
        function execute(obj, argin)
            
        end
     
        function dependents = find_dependents_in_queue(obj, queue)
            dependents = {};
            list_struct = queue.fetch_list();
            for i = 1:length(list_struct)
                if(list_struct{i}.depends_on(obj))
                    dependents = [dependents {i, match_outputs_with_inputs(obj, list_struct{i})}];
                end
            end
        end
        
        function bool = depends_on(obj, operation)
            bool = false;
            other_op_dependents = get(operation, 'dependents');
            for i = 1:length(other_op_dependents)
                if(strcmp(obj.name, other_op_dependents{i}))
                    bool = true;
                end
            end
        end
        
        function indexes = match_outputs_with_inputs(op1, op2)
            indexes = {};
            count = 1;
            length_of_1 = length(op1.outputs);
            length_of_2 = length(op2.inputs);
            shortest_length = length_of_1;
            if(length_of_2 < length_of_1)
                shortest_length = length_of_2;
            end
            for i = 1:shortest_length
                if(strcmp(op1.outputs{i}, op2.inputs{i}))
                    indexes{count} = i;
                    count = count + 1;
                end
            end
        end
        
        function set_in_buffer(obj, index, value)
            obj.in_buffer{index} = value;
        end
        
        function val = get.stop_check_callback(obj)
            val = obj.stop_check_callback;
        end
        
        function insert_type = get.insertion_type(obj)
            insert_type = obj.insertion_type;
        end
        
        function rx = get.rx_data(obj)
            rx = obj.rx_data;
        end
        
        function tx = get.tx_data(obj)
            tx = obj.tx_data;
        end
        
        function deps = get.dependents(obj)
            deps = obj.dependents;
        end
        
        function buf = get.in_buffer(obj)
            buf = obj.in_buffer;
        end

    end
    
end

