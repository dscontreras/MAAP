% VelocityScript 
% Given a video, finds the location of the a template image within the
% video and finds the displacement & velocity between the first frame and every
% frame within the video and puts it into a csv file titled 'velocity.csv'.
%   CSV format: 
%       Row 1: X displacement
%       Row 2: Y displacement
%       Row 3: Instantenous Velocity
%       Row 4: Time elapsed
%
% VelocityScript does not use the GUI
% To use the GUI, see run data_gui.m and select the "Velocity" option
%
% *Required parameters: videopath and templatepath
%   All other parameters are optional