function tableObj = updateTable(tableObj, varargin)
    data = get(tableObj, 'Data');

    nVarargs = length(varargin);

    for idx = 1:nVarargs
        data{idx, 1} = varargin{idx};
    end
    set(tableObj, 'Data', data);
end

