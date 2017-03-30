classdef Queue < handle
    %QUEUE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess = 'private')
        %An index of which operations in the Queue need to be checked for
        %whether they should be deleted
        condition_evals;
        %Map of which operations in the queue transfer data to which other
        %functions
        data_transfer_map;
        %number of operations in the queue
        length;
        list;
    end
    
    methods
        %operation_list and data_transfer_map should be a cell arrays
        function obj = Queue(operation_list)
            if(nargin > 0)
                for i = 1:length(operation_list)
                    add_to_queue(operation_list{i});
                end
            else
                obj.condition_evals = {};
                obj.data_transfer_map = {};
                obj.length = 0;
            end
        end
        
        function add_to_queue(obj, operation)
            %If the object should be inserted at the start of the list
            if(strcmp(get(operation, 'insertion_type'), 'start'))
                for i = obj.length:1
                    obj.list{i + 1} = obj.list{i};
                end
                obj.list{1} = operation;
                extend_map(operation, 1);
            %Otherwise, insert it at the end
            else
                obj.list{obj.length + 1} = operation;
                extend_map(operation, obj.length + 1);
            end
            obj.length = obj.length + 1;
        end
        
        function extend_map(obj, operation, address_inserted)
            obj.data_transfer_map{address_inserted} = operation.find_dependents_in_queue(obj);
        end
        
        function execute(obj)
            outparams = {};
            for i = 1:obj.length
                if(get(obj.list{i}, 'num_args_in') <= 0)
                    if(get(obj.list{i}, 'num_args_out') >= 0)
                        outparams = obj.list{i}.execute();
                        transfer_data(obj.list{i}, outparams);
                    else
                        obj.list{i}.execute();
                    end
                else
                    try
                        if(get(obj.list{i}, 'num_args_out') >= 0)
                            outparams = obj.list{i}.execute(obj.list{i}.in_buffer{end});
                            transfer_data(obj.list{i}, outparams);
                        else
                            obj.list{i}.execute(obj.list{i}.in_buffer);
                        end
                        obj.list{i}.in_buffer = {};
                    catch(length(obj.list{i}.in_buffer) < 1)
                        error('operation expected more than one execute argument but it got none!');
                    end
                end
                stopped = feval(get(obj.list{i}, 'stop_check_callback'));
                if(stopped)
                    obj.list = obj.list{1:(i - 1), (i + 1):end};
                    obj.length = length(obj.list);
                end
            end
        end
        
        %START HERE
        function transfer_data(obj, sender, data_sent)
            %iterate through each dependent of the sender
            for i = 1:length(get(sender, 'dependents'))
                %operation_receiving is the operation is the one we are sending to
                operation_receiving = obj.list{i};
                %Now iterate through the data_transfer_map's list of data
                %to be sent
                for j = 1:length(obj.data_transfer_map{i}{2})
                    index_of_variable_needed_in_transfer_map = obj.data_transfer_map{i}{2}{j};
                    data_variable_needed = data_sent{index_of_variable_needed_in_transfer_map};
                    operation_receiving.set_in_buffer(index_of_variable_needed_in_transfer_map, data_variable_needed);
                end
            end
        end
        
        function delete(obj)
            for i = 1:obj.length
                delete(obj{i});
            end
            obj.length = 0;
            delete(obj);
        end
        
        function l = fetch_list(obj)
            l = obj.list;
        end
    end
    
end

