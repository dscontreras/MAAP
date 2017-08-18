function [save_path] = create_mat_for_ui_settings(name)
    % Creates a .mat file inside ui/persistent settings
    saved_data_folders = what('persistent_settings/');
    for idx = 1:length(saved_data_folders)
        [parentdir, ~, ~] = fileparts(saved_data_folders(idx).path);
        [~, parentdir_name, ~] = fileparts(parentdir);
        if strcmp(parentdir_name, 'ui')
            break;
        end
    end
    dir_separator = FileSystemParser.get_file_separator()
    save_path = [parentdir dir_separator 'persistent_settings' dir_separator  name '.mat'];
    
end
