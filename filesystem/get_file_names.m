%Author: Will Fehrnstrom, Jan. 26, 2017
%Institution: UC Berkeley
%Description: A collection of functions for navigating through a file
%system

%Param: Takes in a variable struct like the one returned from dir()
%Return: A character array of the file names contained in that struct
function [names] = get_file_names(file_struct)
    names = {}; 
    count = 1;
    for i = 1:length(file_struct)
        chr = file_struct(i).name;
        names{i} = chr;
    end
end

