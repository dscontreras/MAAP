%Author: Will Fehrnstrom, Jan. 26, 2017
%Institution: UC Berkeley
%Description: A collection of functions for navigating through a file
%system

%Param: Takes in a variable struct like the one returned from dir()
%Return: A character array of the file names contained in that struct
function [names] = get_file_names(file_struct)
    names = {}; %cell(1,10)
    count = 1;
    %disp(length(file_struct));
    for i = 1:length(file_struct)
        chr = file_struct(i).name;
        %str = string(chr);
        names{i} = chr;
    end
end

