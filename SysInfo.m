classdef SysInfo
    %SYSINFO Summary of this class goes here
    %   Detailed explanation goes here
    
    methods(Static)
        function os_type = get_os()
            persistent os;
            if(ispc)
              os = 'Windows';
            else
              os = 'Unix';
            end
            os_type = os;
        end
    end
    
end

