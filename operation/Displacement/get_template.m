%%   ******************************  AUTOMATION - PROBE STATION MEASUREMENTS *************************************
% Summer intership 2015 - University of California Berkeley
% Pister's Group - Swarm Lab
% Home institution - Universidade Federal de Ouro Preto
% Exchange program - Ciencias sem Fronteiras 
% Sponsors - CAPES 
%            CNPq
%            Brazilian Federal Government     
% Student: Jesssica Ferreira Soares
% Advisor: David Burnett
% Email: jekasores@yahoo.com.br
%        JFerreiraSoares01@wildcats.jwu.edu
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%DESCRIPTION : This function allow the user crop an object from the image
%to be use as the template. The initial coordinates of the object are also
%calculated here.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%
function [template, rect, xtemp, ytemp] = get_template(gray, displayObj, vid_height, vid_width)

    %DEFINE TEMPLATE - Obtained from interpolated image
    [template, rect] = showCrop(displayObj, gray, vid_height, vid_width);

    %PERFORM NORMALIZED CROSS-CORRELATION
    c = normxcorr2(template,gray);
    
    %FIND PEAK CROSS-CORRELATION
    [ytemp, xtemp] = find(c==max(c(:)));    
end
