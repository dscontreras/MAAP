function [save_path] = create_csv_for_data(descriptor)
    full_path = which('saved_data_README.markdown');
    [parentdir, ~, ~] = fileparts(full_path);
    save_path = [parentdir '/' descriptor '.' datestr(datetime('now')) '.csv'];
end