matrix = [1 4 1; 4 7 2; 3 8 0];
[X,Y] = meshgrid(1:3,1:3);
[Xq,Yq]= meshgrid(1:0.5:3,1:0.5:3);
q = qinterp2(X,Y,matrix, Xq,Yq, 0.5, 2);
i = interp2(X, Y, matrix, Xq, Yq, 'linear');
q
i
