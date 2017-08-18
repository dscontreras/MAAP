function [save_path] = create_csv_for_data(descriptor)
    % Creates and saves a csv file in the saved_data folder
    saved_data_folders = what('saved_data');
    for idx = 1:length(saved_data_folders)
        [parentdir, ~, ~] = fileparts(saved_data_folders(idx).path);
        [~, parentdir_name, ~] = fileparts(parentdir);
        if strcmp(parentdir_name, 'MAAP')
            break;
        end
    end
    dir_separator = FileSystemParser.get_file_separator()
    save_path = [parentdir dir_separator 'saved_data' dir_separator  descriptor '.' datestr(datetime('now')) '.csv'];
end
