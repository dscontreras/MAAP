function tableObj = updateTable(tableObj, varargin)
    % Updates the tableObj with the series of variables in varargin
    % tableObj should be the table object in data_gui
    data = get(tableObj, 'Data');

    nVarargs = length(varargin);

    for idx = 1:nVarargs
        data{idx, 1} = varargin{idx};
    end
    set(tableObj, 'Data', data);
end

