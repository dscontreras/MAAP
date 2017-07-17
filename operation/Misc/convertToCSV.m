% Converts a .mat file to a .csv file
function convertToCSV(filepath) 
    FileData = load(filepath);
    fields = fieldnames(FileData);
    for K = 1 : length(fields)
        thisvar = fields{K};
        thisdata = FileData.(thisvar);
        if ~isnumeric(thisdata)
            warning('Skipping field %s which is type %s instead of numeric', thisvar, class(thisvar));
        else
            file1 = sprintf('Velocity.csv', thisvar);
            dlmwrite(file1, thisdata, '-append');
        end
    end
end