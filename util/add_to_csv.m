function add_to_csv(csv_file_path, matrix)
    % Adds a 1d matrix to the passed in csv file
    dlmwrite(csv_file_path, matrix, '-append', 'precision', 10);
end
