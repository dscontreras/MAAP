classdef ListboxOperations
    %LISTBOXOPERATIONS
    %   Author: Will Fehrnstrom
    %   Date: 2/3/2017
    %   Organization(s): UC Berkeley SWARM Lab, Miramonte High School
    %
    %   Description: ListboxOperations is a static class containing easily understood listbox
    %   operations

    
    properties
    end
    
    methods (Static)
        %Brief: retrieves the current item selected in a given listbox
        %       It does not return the index of the current item, but
        %       rather the selected item itself
        %Params:
        %       listbox_object: the listbox to retrieve the selected item from
        function selection = get_current_selection(listbox_object)
            %retrieve the listbox options
            options = get(listbox_object, 'String');
            %retrieve the selection from the listbox options
            selection = options{get(listbox_object, 'Value')};
        end
        
        %Brief: Reset our listbox selection to value 1
        %       Often used to reset the selection before changing the
        %       values contained within the listbox so that the listbox
        %       doesn't throw a fit, because that wouldn't be good
        %Params:
        %       listbox_object: the listbox to reset
        function reset_selection(listbox_object)
            %Reset the item selected to the first item
            set(listbox_object, 'Value', 1);
        end
        
        %Brief: Change the options contained within the listbox to a new
        %       set of options
        %Params:
        %       listbox_object: the listbox to be modified
        %       new_options: a cell array of new options
        function change_options(listbox_object, new_options)
            %Set the listbox options to a string array converted from the
            %cell array passed in
            set(listbox_object, 'String', cellstr(new_options));
        end
    end
    
end

