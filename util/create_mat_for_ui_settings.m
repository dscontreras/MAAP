function [save_path] = create_mat_for_ui_settings(name)
    saved_data_folders = what('persistent_settings/');
    for idx = 1:length(saved_data_folders)
        [parentdir, ~, ~] = fileparts(saved_data_folders(idx).path);
        [~, parentdir_name, ~] = fileparts(parentdir);
        if strcmp(parentdir_name, 'ui')
            break;
        end
    end
    save_path = [parentdir '/persistent_settings/' name '.mat'];
    
end