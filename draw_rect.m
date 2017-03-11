%DATAGUI
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
%DESCRIPTION : This function draws a rectangle around the template.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%
function draw_rect(RGB, xoffSet, yoffSet, template, hAxes, vid_height, vid_width)
    disp('Assignment:');
    tic;
    axes = hAxes;
    disp(toc);
    disp('imresize:');
    tic;
    RGB = imresize(RGB, [vid_height vid_width]);
    disp(toc);
    disp('imshow:');
    tic;
    imshow(RGB, 'Parent', axes); 
    disp(toc);
    disp('imrect:');
    tic;
    imrect(axes,[xoffSet, yoffSet, size(template,2), size(template,1)]); %draw a rectangle on axes, with rectangle: [x, y, w, h]
    disp(toc);
    disp('drawnow:');
    tic;
    drawnow; 
    disp(toc);
end

