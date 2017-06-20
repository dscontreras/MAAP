classdef Queue < handle
    %QUEUE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess = private)
        %An index of which operations in the Queue need to be checked for
        %whether they should be deleted
        condition_evals;
        %Map of which operations in the queue transfer data to which other
        %functions
        data_transfer_map = containers.Map('KeyType','char','ValueType','any');
        %number of operations in the queue
        length;
        %the actual contents of the queue
        list;
        %flag indicating whether the queue has finished its chain of
        %execution
        done;
        %flag indicating whether the queue is nominal
        valid;
        %error_report_handle stores a function handle given from scheduler which executes when
        %queue or any object in the queue encounters an error
        error_report_handle;   
        %Boolean flag checking whether object is paused
        paused;
        %Index to pick off from when unpausing
        pause_index;
        %active is a boolean flag indicating whether this object is
        %currently executing or in the process of executing
        active;
    end
    
    properties(Access = public, Constant)
        name = 'Queue';
    end
    
    methods
        %operation_list and data_transfer_map should be a cell arrays
        function obj = Queue(error_handle, operation_list)
            obj.error_report_handle = error_handle;
            obj.length = 0;
            obj.done = false;
            obj.active = false;
            obj.paused = false;
            obj.pause_index = 1;
            if(nargin > 1)
                for i = 1:length(operation_list)
                    obj.add_to_queue(operation_list{i});
                end
            else
                obj.condition_evals = {};
            end
        end
        
        function add_to_queue(obj, operation)
            %TODO assert operation is of type operation
            obj.length = obj.length + 1;
            %set the object in the queue's callback for error handling to
            %this Queue's error handling function, so that the error can
            %correctly propagate up the object hierarchy, from operation to
            %queue to the data_gui itself
            operation.set_error_report_handle(@obj.report_error);
            %If the object should be inserted at the start of the list
            if(strcmp(operation.insertion_type, 'start'))
                for i = obj.length:1
                    obj.list{i + 1} = obj.list{i};
                    obj.list{i + 1}.queue_index = obj.list{i + 1}.queue_index + 1;
                end
                obj.list{1} = operation;
                operation.queue_index = 1;
                obj.add_to_map(operation, 1);
            %Otherwise, insert it at the end
            else
                obj.list{obj.length} = operation;
                operation.queue_index = obj.length;
                obj.extend_map(operation);
                [~, input_op_names, params] = obj.parse_rx_data(operation);
                operation.param_names = [input_op_names; params];
                operation.inputs = cell(1, length(input_op_names));
            end
        end
        
        function add_to_map(obj, operation, address_inserted)
            obj.data_transfer_map{address_inserted} = operation.outputs;
        end
        
        function extend_map(obj, operation)
            obj.data_transfer_map(operation.name) = operation.outputs;
        end
        
        function execute(obj, index)
            i = 1;
            obj.active = true;
            if(nargin > 1)
                i = index;
            end
            while(i <= obj.length)
                if(~obj.list{i}.new || feval(obj.list{i}.start_check_callback))
                    
                    if(obj.paused)
                        obj.pause_index = i;
                        return;
                    end
                    
                    if(obj.list{i}.new)
                        obj.list{i}.new = false;
                        obj.list{i}.startup();
                    end
                    % TODO: No need to check if it's empty, should be handled by operation itself
                    if(isempty(obj.list{i}.rx_data))
                        obj.list{i}.execute();
                    else
                        inputs = obj.retrieve_operation_inputs(obj.list{i});
                        obj.list{i}.execute(inputs); 
                    end
                    
                    stopped = obj.list{i}.check_stop();
                    if(stopped)
                        obj.list(i) = [];
                        obj.length = length(obj.list);
                        if(obj.length == 0)
                            obj.done = true;
                            obj.active = false;
                        end
                    end
                    
                end
                i = i + 1;
            end
        end
        
        function resume_execution(obj)
            obj.run_to_finish(obj.pause_index);
        end
            
        
        function successful = run_to_finish(obj, starting_index)
            while(~obj.finished() && ~obj.paused)
                if(nargin > 1)
                    obj.execute(starting_index);
                else
                    obj.execute();
                end
            end
            if(obj.paused)
                successful = false;
            else   
                successful = true;
            end
        end
        
        function bool = finished(obj)
            bool = obj.done;
        end
        
        function delete(obj)
            for i = 1:obj.length
                delete(obj.list{i});
            end
            obj.length = 0;
            delete(obj);
        end
        
        function l = fetch_list(obj)
            l = obj.list;
        end
        
        function inputs = retrieve_operation_inputs(obj, operation)
            inputs = {};
            input_operation_names = operation.param_names(1, :);
            params_to_get = operation.param_names(2, :);
            for i = 1:length(input_operation_names)
                map_to_retrieve_from = obj.data_transfer_map(input_operation_names{i});
                inputs = [inputs map_to_retrieve_from(params_to_get{i})];
            end
        end
        
        %for the example string input "displacement:dispx", displacement is
        %the input operation_name, and dispx is the param to get.
        function [diff_operation_names, input_operation_names, params_to_get] = parse_rx_data(obj, operation)
            count = 1;
            diff_operation_names = cell(0);
            input_operation_names = cell(0);
            params_to_get = cell(0);
            for i = 1:length(operation.rx_data)
                colon_index = strfind(operation.rx_data{i}, ':');
                input_operation_names{count} = char(operation.rx_data{i}(1:(colon_index - 1)));
                if(length(diff_operation_names) > 0)
                    for j = 1:length(diff_operation_names)
                       if(~strcmp(input_operation_names{count}, diff_operation_names{j}))
                            diff_operation_names = [diff_operation_names input_operation_names{count}];
                       end
                    end
                end
                params_to_get{count} = char(operation.rx_data{i}(colon_index + 1:length(operation.rx_data{i})));
                [num, is_numeric] = str2num(input_operation_names{count});
                %if the input_operation_name is actually a number, then
                %this means that this number specifies the position of the
                %input_operation relative to the operation receiving the
                %input in the queue
                index_of_operation_to_receive_from = 0;
                index = operation.queue_index;
                if(is_numeric)
                    if(index <= 0)
                        obj.report_error('No such operation found in queue.');
                    else
                        index_of_operation_to_receive_from = index + num;
                    end
                    if((index_of_operation_to_receive_from > length(obj.list) || index_of_operation_to_receive_from < 1))
                        obj.report_error('Queue list index out of bounds exception');
                    else
                        input_operation_names{count} = obj.list{index_of_operation_to_receive_from}.name;
                    end
                else
                    %TODO: Implement this nearest neighbor only valid for
                    %inputs behind the operation requesting input
                    matches = obj.pos_in_queue_of_name(input_operation_names{count});
                    %Create an array filled with the same number: the index
                    %of the current operation
                    index_array = index * ones(1, length(matches));
                    distance_cell = cellfun(@minus, num2cell(index_array), matches, 'UniformOutput', false);
                    distance_arr = cell2mat(distance_cell);
                    distance_arr(distance_arr < 0) = 0;
                    [~, closest_index] = min(distance_arr(distance_arr > 0));
                    index_of_operation_to_receive_from = matches{closest_index};
                end
                if(strcmp(params_to_get{count}, 'all'))
                    op_name = input_operation_names{count};
                    param_names = keys(obj.data_transfer_map(op_name));
                    count = count - 1;
                    for j = 1:length(param_names)
                       count = count + 1;
                       input_operation_names{count} = op_name;
                       params_to_get{count} = param_names{j};
                    end
                end
                count = count + 1;
            end
        end
        
        %determine the index of an operation in the queue list
        function position = pos_in_queue(obj, operation)
            position = {};
            count = 0;
            for i = 1:length(obj.list)
                if(strcmp(operation.name, obj.list{i}.name))
                    count = count + 1;
                    position{count} = i;
                end
            end 
        end
        
        function position = pos_in_queue_of_name(obj, name)
            position = {};
            count = 0;
            for i = 1:length(obj.list)
                if(strcmp(name, obj.list{i}.name))
                    count = count + 1;
                    position{count} = i;
                end
            end 
        end
        
        function report_error(obj, error_msg)
            obj.valid = false;
            msg = strcat(obj.name, ': ', error_msg);
            feval(obj.error_report_handle, msg);
        end
        
        function pause(obj)
            obj.paused = true;
        end
        
        function unpause(obj)
            obj.paused = false;
            if(obj.active)
                obj.resume_execution();
            end
        end
        
        function bool = is_paused(obj)
            bool = obj.paused;
        end
        
        function stop_execution(obj)
           obj.pause();
           obj.done = true;
        end
        
    end
end

