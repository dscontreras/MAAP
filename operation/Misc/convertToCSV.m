% Converts a .mat file to a .csv file
function convertToCSV(filename) 
    FileData = load(filename);
    fields = fieldnames(FileData);
    full_path = which('saved_data_README.markdown');
    [parentdir, ~, ~] = fileparts(full_path);
    save_path = [parentdir '/' datestr(datetime('now')) '.csv'];
	matrix = [];
    for K = 1 : length(fields)
        thisvar = fields{K};
        thisdata = FileData.(thisvar);
        if ~isnumeric(thisdata)
            warning('Skipping field %s which is type %s instead of numeric', thisvar, class(thisvar));
        else
            matrix = horzcat(matrix, thisdata.');
        end
    end
    matrix = horzcat([1:length(thisdata)].', matrix);
    % write the header string to the file

    %turn the headers into a single comma seperated string if it is a cell
    %array, 
    header_string = 'frame_num';
    for i = 1:length(fields)
        header_string = [header_string,',',fields{i}];
    end
    
    fid = fopen(save_path,'w');
    fprintf(fid,'%s\r\n',header_string);
    fclose(fid);
    dlmwrite(save_path, matrix, '-append', 'precision', 10);
end