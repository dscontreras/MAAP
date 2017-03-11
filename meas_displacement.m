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
%DESCRIPTION : This function calculates the coordinate in subpixels of the
%moved template. It also gives the object displacement in subpixels and
%microns
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%
function [xoffSet, yoffSet, dispx,dispy,x, y, c1] = meas_displacement(template,rect, img, xtemp, ytemp, precision, displacement, axes)
min_displacement = 2; %pixel unit
global vid_height;
global vid_width;
vid_height = 1024;
vid_width = 1280;
Xm =40*10^(-6); %distance according to chip dimensions in microns
Xp = 184.67662; %distance according image in pixels. Correspond to Xm
%%    ************************** WHOLE PIXEL PRECISION COORDINATES *************************
     
        %DEFINE SEARCH AREA - obtained from no interpolated image
        width = displacement; 
        height = displacement;

        search_area_xmin = rect(1) - width;
        search_area_ymin = rect(2)- height;
        search_area_width = 2*width+rect(3);
        search_area_height = 2*height+rect(4);
        [search_area, search_area_rect] = imcrop(img,[search_area_xmin search_area_ymin search_area_width search_area_height]); 
        %draw_rect(img, search_area_width, search_area_height, search_area, axes, vid_height, vid_width);
       
        %PERFORM NORMALIZED CROSS-CORRELATION
        %Note: Jessica tried to perform Gradient Descent NCC Surface but
        %the timing was problematic.  The NCC Surface algorithm only
        %accepted entire images, and was subsequently too slow.
         c = normxcorr2(template, search_area);
             
        %FIND PEAK CROSS-CORRELATION
        [ypeak, xpeak] = find(c==max(c(:)));   
        xpeak = xpeak+round(search_area_rect(1))-1;
        ypeak = ypeak+round(search_area_rect(2))-1;

        
%% ************************** SUBPIXEL PRECISION COORDINATES *************************
        
        %GENERATE MOVED TEMPLATE
        new_xmin= (xpeak-rect(3)); 
        new_ymin = (ypeak-rect(4)); 
        [moved_template, displaced_rect] = imcrop(img,[new_xmin new_ymin rect(3) rect(4)]);

        %GENERATE NEW SEARCH AREA (BASED IN MOVED TEMPLATE)
        width1 = min_displacement;
        height1 = min_displacement;
        new_search_area_xmin = displaced_rect(1) - width1;
        new_search_area_ymin = displaced_rect(2)- height1;
        new_search_area_width = 2*width1+displaced_rect(3);
        new_search_area_height = 2*height1+displaced_rect(4);
        [new_search_area, new_search_area_rect] = imcrop(img,[new_search_area_xmin new_search_area_ymin new_search_area_width new_search_area_height]);
        
        %Interpolate both the new object area and the old and then compare
        %those that have subpixel precision in a normalized cross
        %correlation
        % BICUBIC INTERPOLATION - TEMPLATE
        interp_template = im2double(template);
        [numRows,numCols,dim] = size(interp_template);
        [X,Y] = meshgrid(1:numCols,1:numRows);
        [Xq,Yq]= meshgrid(1:precision:numCols,1:precision:numRows);
        V=interp_template;
        interp_template = interp2(X,Y,V,Xq,Yq, 'cubic'); 
        
        % BICUBIC INTERPOLATION - SEARCH AREA (FROM MOVED TEMPLATE
        interp_search_area = im2double(new_search_area);
        [numRows,numCols,dim] = size(interp_search_area);
        [X,Y] = meshgrid(1:numCols,1:numRows);
        [Xq,Yq]= meshgrid(1:precision:numCols,1:precision:numRows);
        V=interp_search_area;
        interp_search_area = interp2(X,Y,V,Xq,Yq, 'cubic');   
        
        
         %PERFORM NORMALIZED CROSS-CORRELATION
         c1 = normxcorr2(interp_template,interp_search_area);
         
        %FIND PEAK CROSS-CORRELATION
        [new_ypeak, new_xpeak] = find(c1==max(c1(:)));  

        new_xpeak = new_xpeak/(1/precision);
        new_ypeak = new_ypeak/(1/precision);
        new_xpeak = new_xpeak+round(new_search_area_rect(1));
        new_ypeak = new_ypeak+round(new_search_area_rect(2));
        disp('(xpeak,ypeak) =');
        disp([new_xpeak, new_ypeak]);

    disp('__ __ __ __ __ __ __ __ __ __ __ __');

  
    
    yoffSet = new_ypeak-(size(template,1));
    xoffSet = new_xpeak-(size(template,2));

    %DISPLACEMENT IN PIXELS
    y = new_ypeak-ytemp;
    x = new_xpeak-xtemp;
    
    %DISPLACEMENT IN MICRONS
    dispx = Xm*x/Xp;
    dispy = Xm*y/Xp;
    

end


