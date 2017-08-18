# MAAP Documentation and Reference

This document is focused on explaining the application and its usage in detail as well as talk about the decision made when the appliation was coded. 

For documentation on the methods, functions, and variables present, refer to other documentation

## Project Overview

A quick overview of the folder structure of the project.

1. Deprecated: 	
	Functions and classes that is not to be used but kept on the offchance someone would like to go back and look at the old code. In general, ignore this folder
2. Documentation:
	Textfiles and images used to create the documentation (i.e. this document, README)
3. FileSystem:
	When using the GUI, you'll notice a panel which is used to pick which video is to be analyzed. The filesystem refers to that panel
4. Images:
	This is for use for the user. Here they can add images of the object they wish to track. This way, when analyzing multiple videos, they don't have to choose the template every time. 
	* Note: For this to take effect, the image must be chosen in settings
5. info:
	Some information relating to the code developemnt such as TODO, list of bugs, etc.
6. operation:
	The operations such as measuring displacement or velocity
7. saved\_data:
	 When an operation saves data (i.e. the location of an object throughout a video), it is automatically saved here
8. sources:
	The types of sources the gui can take (such as either a File or a Stream)
9. tests:
	Where tests would go but there aren't that many tests and the tests that do exist aren't very useful. 
10. ui:
	The code for most of the gui is located here
11. util:
	Some utility functions that may be of use
12. videos:
	A folder full of videos. Put the videos you would like to analyze here for easy access.

## Some Terms

The code has built up a bit of a vocabulary and this section will explain much of it here .

Queue: A holding place for operations. We add to the queue and the queue deals with running the operation. 
Operation: The type of analysis that the user wants done
Source: Where the images the operation is analyzing is coming from. In general, it will be a video. However, it is possible to stream the video as well. 

current\_frame: The frame of the video to be analyzed
search\_area: The location in which to search within the img. This is necessary for speed concerns as it the relevant movement may only occur in a small portion of the frame
 
## Deprecated

A lot of the code in here should be and is currently being ignored.
Although it is included, it is highly recommended that it is not included in the MATLAB path. 

## FileSystem

The FileSystem abstracts away the filesystem for individual OS. When dealing with filenames or creating filenames, use methods found in the FileSystems.

## The Operations

First a quick overview of how this program works. 

![](../img/data_gui_displacement_begin.png){width=95%}

The user picks a video from the panel on the left and picks an **operation** that they would like to perform. They then draw a blue box on the image to the right to indicate what they would like to track. 

An operation is the type of analysis the user would like done. Currently two are supporte:

- Displacement: Tracks the movement of an object
- Velocity: Tracks the velocity of an object

The other two listed (Capture Stills and Voltage) are not implemented. 

### Some GUI Elements

There are some GUI elements that generally exist for all Operations but are not included in the Operation superclass.

This was decided in order to help with implementing scripting. However, this seems to only bloat the code and as such may change in the future. Until then, here is a description of those GUI elemnents. 

- axes : The axes for the image viewer, the graphical element where each frame is displayed
- error\_tag : A graphical element where error messages are displaced (Not generally used)
- table : The graphical element table element in the lower left corner of the GUI
    - use `updateTable` to show items in the table
- img\_cover : A graphical element that hides the images shown on `axes`. This is generally set to be off in the constructor of the operation 
- table\_data : Sets the first column of the table (the header)

### Template Matcher

The TemplateMatcher is a util class that is meant to abstract away the math. There are some terms used in the TemplateMatcher that must be understood.

First: Peak vs Offset. 

If you look up `normxcorr2` function that is used in this file, the sample code provided uses Offset as the result of their algorithm. Here the code uses peak. The two are not the same. 
The peak represents where the algorithm believes the object is. Therefore, in a 100x100 image, if algorithm returns peak values of (30, 20), this means that the upper left corner of where the template was found is at column 30, row 20. The Offset is `peak - 1` and instead measures the distance from the first pixel. 

`disp_x/y` is the displacement in pixels between where the template was in the first frame to where the template is in the current frame. There is no mention of resolution here. That is an additional step that should be taken by the coder after retrieiving these values. 

Finally, a quick lesson in how the coordinates work. In traditional math, the origin is in the lower left corner and the axes increase going up and going to the right. However, when working with images this is not true. Instead, the origin is at the top left corner and increases going down and going right. This means that to a pixel at (30, 50) is at column 30 and row 50 and is higher up than (30, 70) which is at row 70. 

~~~MATLAB
% an example
A = FileSource('SomeVideoFilePath.avi', 1)
pixel_precision=0.5
m_d_x= 50
m_d_y= 0
template=imread('SomeTemplateImage.png')
min_d=2 
first_frame=A.extractFrame()

tm = TemplateMatcher(pixel_precision, m_d_x, m_d_y, template, min_d, first_frame)
while ~A.finished()
    [y_peak, x_peak, disp_y, disp_x] = tm.meas_displacement(A.extractFrame())
    % Do stuff with y_peak
end
~~~

### Displacement 

There are several types of DisplacementOperations. 

- DisplacementFiber
- DisplacementOperation
- MultipleObjectDisplacementOperation

The difference between DisplacementOperation is that it tracks 1 item while MultipleObjectDisplacementOperation tracks more than 1. For an example of how they should be used, look at where they are instantiated in `data_gui.m`

~~~MATLAB
% Example on how to add a template to MultipleObjectDisplacementOperation
mOperation = MultipleObjectDisplacementOperation( ... )
mOperation.crop_template(max_x, max_y)
mOperation.crop_template(max_x2, max_y2)
...
~~~

DisplacementFiber is unique. This was created because in order to track the movement of a very thin wire, normalized cross correlation would not work. As such, in general, this is not recommended to be used.

### Velocity



## Queue

The Queue is largely incomplete. When the applicatinon was first coded, there was hope for granular control of the operations and the Queue was supposed to give that control. However, this feature has not been implemented. 

As such, the queue is an unnecessary middlestep that should either be removed or whose features be completely implemented. Currently it's used as follows

~~~MATLAB
global q; % a global variable in data_gui.m
operation = SomeOperation( ... )
q.add_to_queue(operation)
q.run_to_finish()
~~~

## saved\_data

Here we save all the data captured in each Operation. We suggest that you add to the `saved_data` folder using the `create_csv_for_data`, `add_headers`, and `add_to_csv` functions

~~~MATLAB
file_created = create_csv_for_data('DescriptionOfOperation')

header = 'Var1,Var2,Var3' % Make sure there are no spaces
add_headers(file_created, header)

Var1 = 0
Var2 = 0
Var3 = 0
while SomeBooleanVar
    % Do some calculation 
    Var1, Var2, Var3 = some_calculation_function()
    data = [Var1, Var2, Var3]
    add_to_csv(file_created, data)
end
~~~

## sources

An abstraction to deal with either a video file or a stream.

In general, you'll only be dealing with a `FileSource`. 

While the source files have a `resolution_meters` variable, this is generally ignored. 

~~~MATLAB
src = FileSource('SomeVideoFilePath', 1);
while ~src.finished()
    img = rgb2gray(src.extractFrame());
    % Do some analysis on img
end
~~~

## ui

The important files here are `data_gui`, `ListboxOperations`, and `settings_gui`.

`data_gui` describes the main graphical interface and what each button press/button toggle does. 

`settings_gui` does the same but for the settings graphical interface

`ListboxOperations` is the file picker we see in the main graphical interface. 

## videos

A simple place to put videos that the user would want to analyze
