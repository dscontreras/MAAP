classdef StringOperations
    %STR Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods (Static)
        %Returns an array of strings that have been decomposed from one
        %long character array
        function arr = decompose(string, separator)
            indexes = strfind(string, separator);
            indexes = [indexes (length(string) + 1)];
            arr = [];
            count = 1
            for i = 1:(length(indexes) - 1)
                disp(string((indexes(i) + 1):(indexes(i+1) - 1)));
                %if we are actually adding something to the array
                if(length(string((indexes(i) + 1):(indexes(i+1) - 1))) > 0)
                    arr(count) = string((indexes(i) + 1):(indexes(i+1) - 1));
                end
                count = count + 1;
            end
        end
        
        function outstring = compose(string, new_string, separator)
            outstring = '';
            strarr = string(arr);
            for i = 1:length(strarr)
                if(~(strcmp(strarr(i), '/')))
                    outstring = [outstring separator strarr(i)];
                else
                    outstring = [outstring strarr(i)];
                end
                disp(outstring);
            end
            outstring = char(join(outstring, ''));
        end
        
    end
    
end

