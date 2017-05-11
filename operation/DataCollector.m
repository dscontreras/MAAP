classdef DataCollector < Operation
    %DATACOLLECTER Summary of this class goes here
    %   Detailed explanation goes here
    properties(SetAccess = private)
        dataArray;
        output_folder_path;
        format;
    end
    
    properties(SetAccess = public)
        outputs = containers.Map('KeyType','char','ValueType','int32');
        param_names;
        inputs;
        valid;
        new;
        error_report_handle;
        queue_index = -1;
        start_check_callback;
    end
    
    properties(SetAccess = public, Constant)
        rx_data = {'-1:all'};
        name = 'DataCollecter';
        insertion_type = 'end';
    end
    
    methods(Static)
        function timestamp = construct_timestamp(obj)
            datestring = datestr(datetime('now'));
            datestring = strrep(datestring, ' ', '_');
            datestring = strrep(datestring, ':', '_');
            timestamp = datestring;
        end  
    end
    
    methods
        function obj = DataCollector(start_check_callback, output_folder_path, format, error_report_handle)
            obj.valid = true;
            obj.new = true;
            obj.output_folder_path = output_folder_path;
            obj.start_check_callback = start_check_callback;
            obj.format = format;
            if(nargin > 3)
                obj.error_report_handle = error_report_handle;
            end           
        end
        
        function valid = validate(obj, error_tag)
            valid = true;
        end
        
        function startup(obj)
           obj.valid = obj.validate(); 
        end
        
        function execute(obj, argsin)
            if(nargin > 1)
                cached_names = cell(0);
                for i = 1:length(argsin)
                    if(strcmp(obj.format, 'txt'))
                        if(length(cached_names) == 0 || ~strcmp(obj.param_names{1, i}, cached_names{end}))
                            timestamp = DataCollector.construct_timestamp();
                            filename = [obj.output_folder_path obj.param_names{1, i} '_' timestamp '.txt'];
                            file = fopen(filename, 'w');
                            cached_names = [cached_names obj.param_names{1, i}];
                        end
                        if(i == 1)
                            formatspec = ['%s:' FileSystemParser.get_carriage_return()];
                        else
                            formatspec = [FileSystemParser.get_carriage_return() '%s:' FileSystemParser.get_carriage_return()];
                        end
                        fprintf(file, formatspec, obj.param_names{2, i});
                        numformatspec = ['%5.2u' FileSystemParser.get_carriage_return()];
                        fprintf(file, numformatspec, argsin{i});
                    elseif(strcmp(obj.format, 'mat'))
                        if(length(cached_names) == 0 || ~strcmp(obj.param_names{1, i}, cached_names{end}))
                            timestamp = DataCollector.construct_timestamp();
                            filename = [obj.output_folder_path obj.param_names{1, i} '_' timestamp '.mat'];
                            data_to_save = cat(1, obj.param_names(2, :), argsin);
                            save(filename, 'data_to_save');
                        end
                    end
                    if(strcmp(obj.format, 'txt'))
                        fclose(file);
                    end
                end
            end
        end
    end
    
end

