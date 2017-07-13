classdef GapCloserArrayPullInTimeMeasurer < Operation
    % Measures how long it takes for the fingers in a Gap Closer Array to pull in and pull out

    % The following assumption is made about the image.
    % The following code assumes that the top 3 corners found by the Harris algorithm are located
    % only in the marked location. The bottom-left x is the "anchor"
    % The x on the right is the relevant corner. This is the one we want to
    % track
    %
    %
    %   *   *               *   *
    %   *   *               *   *
    %   *   *               x***2
    %   *   *
    %   *   1
    % **x   **************************           
    %    3

properties
    source
end

methods
    function obj = GapCloserArrayPullInTimeMeasurer(src)
        obj.source = src;
    end

    % TIMES represents all the times in which the array is either fully pulled in or fully pulled out
    % Only markes the times in which it moves from one to the other. 
    % Assumes that it is first pulled out all the way
    % WANTED: For testing purposes only; Ignore for use;
    function [times] = execute(obj, wanted)
        pulled_out = true;
        prev_location_x = -1;
        prev_diff = -100; % Assumes that it can't be this large
        frame = rgb2gray(obj.source.extractFrame());
        [height, width ] = size(frame);
        i = 0;
        if nargin < 2
            wanted = -1;
        end
        while i < wanted
            obj.source.extractFrame();
            i = i + 1;
        end
        times = [-10:-1];
        count = 0;
        while ~obj.source.finished() & (wanted < 0 | i < wanted + 5)
            % Determine set of fingers
            % TODO: Find a better way to get this
            rect = [ceil(width/3)+20, ceil(height/3)+50, 40, 160];

            cropped = imcrop(frame, rect);
            corners = detectHarrisFeatures(cropped);

            top_3_corners = corners.selectStrongest(3);
            c1 = top_3_corners(1);
            x1 = c1.Location(1);
            c2 = top_3_corners(2);
            x2 = c2.Location(1);
            c3 = top_3_corners(3);
            x3 = c3.Location(1);

            % Get the relevant corner with above assumption
            minimum_x = min([x1, x2, x3]);
            if minimum_x == x1 
                rel_corner = obj.filter_relevant_corner(c1, c2, c3);
            elseif minimum_x == x2 
                rel_corner = obj.filter_relevant_corner(c2, c1, c3);
            else
                rel_corner = obj.filter_relevant_corner(c3, c1, c2);
            end

            location = rel_corner.Location;
            
            % Find difference from last location
            if prev_location_x ~= -1
                diff = location(1) - prev_location_x
                if abs(diff) >= 0.3
                    if prev_diff ~= 100 & prev_diff * diff < 0
                        % prev_diff * diff < 0 iff the sign is different it
                        % changed state
                        count = count + 1;
                        times(count) = i;
                    end
                end
                prev_diff = diff;
            end
            prev_location_x = location(1);
            
            % For testing
            if wanted > 0
                figure; imshow(cropped); hold on; plot(rel_corner);
            end
            %
            
            frame = rgb2gray(obj.source.extractFrame());
            i = i + 1;
        end
        %[times, i]
    end

    function [rel_corner] = filter_relevant_corner(obj, anchor, c1, c2)
        y1 = c1.Location(2);
        y2 = c2.Location(2);
        x1 = c1.Location(1);
        x2 = c2.Location(1);

        x_anchor = anchor.Location(1);
        y_anchor = anchor.Location(2);

        if abs(y1 - y_anchor) < 5
            rel_corner = c2;
            return
        end
        if abs(y2 - y_anchor) < 5
            rel_corner = c1;
            return
        end

        if abs(y1 - y2) < 5
            if x1 < x2
                rel_corner = c1;
            else
                rel_corner = c2;
            end
            return
        end

        delta_x_1 = abs(x_anchor - x1);
        delta_x_2 = abs(x_anchor - x2);

        if delta_x_2 > delta_x_1
            rel_corner = c2;
        else
            rel_corner = c1;
        end
    end

    function startup(obj)
    end
end
end