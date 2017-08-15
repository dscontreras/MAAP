function [save_path] = create_csv_for_data(descriptor)
    saved_data_folders = what('saved_data');
    for idx = 1:length(saved_data_folders)
        [parentdir, ~, ~] = fileparts(saved_data_folders(idx).path);
        [~, parentdir_name, ~] = fileparts(parentdir);
        if strcmp(parentdir_name, 'MAAP')
            break;
        end
    end
    save_path = [parentdir '/saved_data/' descriptor '.' datestr(datetime('now')) '.csv'];
end