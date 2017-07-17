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
            end
        end

        function add_to_map(obj, operation, address_inserted)
            obj.data_transfer_map{address_inserted} = operation.outputs;
        end

        function extend_map(obj, operation)
            obj.data_transfer_map(operation.name) = operation.outputs;
        end

        function execute(obj, index)
            obj.active = true;
            for i = index:obj.length
                if obj.list{i}.validate()
                    obj.list{i}.startup();
                    obj.list{i}.execute();
                else
                    obj.report_error("Your operation is not valid");
                    obj.active = false;
                    break;
                end
            end
        end

        function resume_execution(obj)
            obj.run_to_finish(obj.pause_index);
        end


        function successful = run_to_finish(obj, starting_index)
            % Because we aren't implementing pause/resume functionality,
            % this just calls execute
            obj.execute(1);
            successful = true;
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