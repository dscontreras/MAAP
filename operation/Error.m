classdef Error
    %ERROR Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        msg; %the error message
        type; %the type of operation the error originates from
        descriptor; %description of the error
        guidisplay; %object that will display the error
    end
    
    methods
        function obj = Error(type, descriptor, guidisplay)
            msg = ['ERR: ' type descriptor];
            if(~isempty(guidisplay))
                set(guidisplay, 'Visible', 'On');
                set(guidisplay, 'String', msg);
            end
        end
        
        function string = message(obj)
            string = 'ERR: ';
            string = string + obj.type + obj.descriptor;
        end
    end
    
end

