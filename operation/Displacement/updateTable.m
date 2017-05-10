function tableObj = updateTable(x, y, tableObj)
    data = get(tableObj, 'Data');
    data{1, 1} = x;
    %invert matlab's coordinate system for y, since we want postive y
    %defined as increasing upwards
    data{2, 1} = -y;
    set(tableObj, 'Data', data);
end

