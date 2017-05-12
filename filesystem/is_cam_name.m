function bool = is_cam_name(cam_name)
    bool = true;
    cams = getfield(imaqhwinfo, 'InstalledAdaptors');
    for i = 1:length(cams)
        if(strcmp(cams{i}, cam_name))
            bool = true;
        end
    end
end

