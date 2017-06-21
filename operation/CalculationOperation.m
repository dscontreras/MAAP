classdef (Abstract) CalculationOperation < Operation
    %CalculationOperation
    %An abstract type to represent operations that do a series of
    %calculatons. Does not collect or save the data in any way.

    properties(Access = private, Abstract)
        % Source from which the data is to be extracted. This can be
        % anything, a video file, livestream, etc.
        % TODO: In the future, force this to be of a certain SourceType.
        source;
        % A list of operation to complete. This may be useful for
        % operations that would like to use an existing operation.
    end

    properties(Access = private)
        operation = Operation.empty()
    end
end
