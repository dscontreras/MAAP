# README

MAAP is a set of tools used for tracking the movement of objects. 

## Getting Started

Download the source files. 

~~~
git clone https://github.com/wfehrnstrom/MAAP
~~~

Add the directory to your Matlab Path. Make sure to `Add with Subfolders…` when you do so.  
Click on the `Home` tab, and the `Set Path` button will be in the `Environment` section. 

## Sources

Sources is how MAAP interacts with videos. There are currently 2 types of sources: `FileSource`, `StreamSource`

To use the StreamSource will require the installation of an addon. 

1. Image Acquisition Toolbox Support Package for OS Generic Video Interface
2. MATLAB Support Package for USB Webcams

~~~MATLAB
% Initialize Source
stream  = StreamSource(camname);
video   = FileSource(file_path, resolution);

% Is it done? 
stream.finished();
video.finished();

% Get a frame
stream.extractFrame();
video.extractFrame();
~~~

* Notes
    * The resolution in FileSource doesn't really matter. 
    * Streams will stop if an image isn't captured by the user in some set amount of time. 
    * To end a stream without ending, `delete(stream.inputcam)`

## Template Matching

To track movement, MAAP uses a template matching algorithm. The `TemplateMatcher` does the work for you.

1. Take a frame
2. Crop a part of the image. 
3. Perform normalized cross correlation
4. Crop a smaller part of the image using the result of step 3
5. Interpolate the crop to the desired pixel_precision (bicubic)
6. Perform normalized cross correlation

A quick example using TemplateMatcher

~~~
video   = FileSource('videos/30V_1.avi', resolution); 
temp    = imread('images/template.png');
tm      = TemplateMatcher(video, pixel_precision, m_d_x, m_d_y, temp, min_d, video.extractFrame());
while ~video.finished()
    [y_peak, x_peak, disp_y_pixel, disp_x_pixel] = tm.meas_displacement(video.extractFrame()); 
end
~~~

`m_d_x` and `m_d_y` are the "maximum\_displacement" properties. They determine the size of the first crop. If you believe the object will move in the y direction but not the x, set `m_d_x = 0` and `m_d_y = k` where `k` is some non-zero value. 

`min_d` determines the size of the second crop. It should be a small value. We recommend using `2`. 

Note that TemplateMatcher does not know the resolution of the image. You have to take that into account when looking at the final output. 

`y_peak`: The y value of the template  
`x_peak`: The x value of the template  
`disp_y_pixel`: the displacement in the y direction in terms of pixels from the original location  
`disp_x_pixel`: the displacement in the x direction in terms of pixels from the original location  

## Operations

Operations is what the GUI does. When adding to or using the code, we suggest wrapping what you're doing as an Operation type. 

Operations have 3 functions that must be filled (`execute(obj)`, `startup(obj)`, `valid(obj)`) and must have a `source`. 

In general, the `valid` checks the validity of the operation. Here is where you should check if all the properties passed in makes sense. The `startup` is generally not needed as much of it can be done in the constructor. However, if a variable needs to be lazily instantiated, here is where to do that. 

`execute` is where the bulk of the work will go. You should continue the execution until the source runs out. 

~~~MATLAB
function [output] = execute(obj)
    output = [-5000:-1];
    i = 1;
    while ~obj.source.finished()
        img = obj.source.extractFrame();
        [y_peak, x_peak, disp_y_pixel, disp_x_pixel] = obj.tm.meas_displacement(img); 
        output(i) = disp_y_pixel * disp_x_pixel;
        i = i + 1;
    end 
end
~~~

The above code simply saves the product of the displacement in y and the displacement in x across all the frames. Do what you want after getting the output of displacement.  

## Main Functions

The two main operations supported by the GUI are `DisplacementOperation.m` and `Velocity.m`. 
Displacement simply tracks the x and y displacement of a template. Velocity finds the instantaneous velocity of a template in microns per second and plots two graphs: X displacement over time and velocity over time.
For both operations, you can select you want to track by passing in an image template in `settings_gui.m` or by manually drawing a rectangle over the region of interest. 
Passing in a template image generally causes the main algorithm to run faster, but if you do decide to use to manually select the template, make sure to double click the region bounded by the blue rectangle to start the algorithm.
Both `DisplacementOperation.m` and `Velocity.m` should reliably track most templates in a video. However, if the template blends into the background or isn't very distnct, you may get incorrect results. To test if the algorithm is working correctly, use the `Enable rectangle` option, which will show you at each frame where the program finds your template.

If it turns out that the algorithm isn't correctly tracking your template, then the next section will explain how to remedy this problem.

## The GUI vs Scripting

A lot of work went into making this scriptable. Mostly because the GUI is cumbersome to work with and isn't very scalable. 

To start the gui, run the `data_gui.m` file. Make sure to run `settings_gui.m` to set some necessary values. 

### Scripting

When scripting using MAAP, follow these steps

1. Create a Source
2. Create an Operation
3. Execute the Operation

We suggest creating a new operation for each type of thing you want to do. This way, you can customize the operation to your needs and make assumptions about the image you're analyzing for ease of use. 

## More Operations

Suppose you want to add more operations. What are some of the relevant functions you should know about. 

`locate_rectangles`

This does exactly as it sounds like. It will give you a list of rectangles

~~~MATLAB
stat = locate_rectangles;
bb = stat(1).BoundingBox; % [xmin ymin width height]
~~~

`find_rect`

Give it an image and a template and it'll tell you the y, x location of that template in the image. 

