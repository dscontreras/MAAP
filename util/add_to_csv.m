function add_to_csv(csv_file_path, matrix)
    dlmwrite(csv_file_path, matrix, '-append', 'precision', 10);
end