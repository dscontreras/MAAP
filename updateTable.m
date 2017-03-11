function tableObj = updateTable(x, y, tableObj)
    data = get(tableObj, 'Data');
    data{1, 2} = x;
    data{2, 2} = y;
    set(tableObj, 'Data', data);
    drawnow;
end

