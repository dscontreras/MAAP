function [time_to_run, gains] = Tester(gpufunc, func)
%TESTER Summary of this function goes here
%   Detailed explanation goes here
time_to_run = [];
disp('GPU TIME:');
time_to_run(1) = gputimeit(gpufunc);
disp(time_to_run(1));
disp('NON-GPU TIME:');
time_to_run(2) = timeit(func);
disp(time_to_run(2));
disp('GPU GAIN:');
gains = time_to_run(2)/time_to_run(1);
disp(gains);
end

