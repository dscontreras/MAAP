classdef RepeatableOperation < Operation
    %REPEATABLEOPERATION Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Abstract, SetAccess = private)
        %The value checked for the conditional, either a function to call
        %to check, or a number, specifying a preset number of iterations
        %the operation will execute
        stop_check_callback;  
    end
    
    methods(Abstract)
        %METHOD: check_stop
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
        bool = check_stop(obj)
    end
    
    methods (Static) 
        function bool = check_start()
            bool = true;
        end
    end
    
end

