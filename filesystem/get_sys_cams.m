function cams = get_sys_cams()
    cams = getfield(imaqhwinfo, 'InstalledAdaptors');
end

