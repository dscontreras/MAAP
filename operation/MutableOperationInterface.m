classdef MutableOperationInterface
    %MutableOperationInterface: Defined as an operation that also utilizes
    %the execute functions of sub_operations within its main execute.  In
    %other words, a Mutable Operation is one that can chain several
    %operations into a larger one
    
    
    properties (SetAccess = protected, GetAccess = protected)
        %how many fields this operation needs in order to execute
        %correctly
        num_fields;
        %Name of the operation
        name;
        %Which sub_operations will this operation employ in the execute
        %method?
        sub_operations;
        %Allows user to define how they want the execution method to go, as in 
        %which sub operations should execute before this operation's
        %execute, and which operations should execute after
        execute_chain; 
    end
    
    methods (Abstract, Static)
        constructPacket();
    end

    methods (Abstract)
        execute(obj);
    end
    
end

