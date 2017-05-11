% GPIB control for piezoresistive strain measurements 
% Joey Greenspun April 2017
% Adapted from David Burnett Sept 2016 who Adapted from Andrew Townley and Amy Liao

close all; clear all;

%% set up voltage sweep
v_min = 20;
v_max = 20;
n_steps = 5;

constant_v = 1;     


%% kill open instruments

openInst = instrfindall;
if ~isempty(openInst)
    fclose(openInst);
    delete(openInst)
end
clear openInst Instruments

%% OPEN EQUIPMENT CONNECTIONS

% set up Keithley 2643b source measurement unit
keithley = visa('agilent','GPIB0::26::INSTR');  %26 is the address of the Keithley
fopen(keithley);
%data = query(keithley, '*IDN?'); % get keithley's ID string.

%-- Restore Series 2600B defaults.
fprintf(keithley,'smua.reset()')
fprintf(keithley,'errorqueue.clear()')

%-- Select measure I autorange.
fprintf(keithley,'smua.measure.autorangei = smua.AUTORANGE_ON')
%-- Select single point precision data format.
%fprintf(keithley,'format.data = format.REAL32')
%fprintf(keithley,'format.byteorder = format.BIGENDIAN')
fprintf(keithley,'format.data = format.ASCII')
fprintf(keithley,'format.asciiprecision = 6')

%-- Clear buffer 1.
fprintf(keithley,'smua.nvbuffer1.clear()')
%-- Enable append buffer mode.
fprintf(keithley,'smua.nvbuffer1.appendmode = 1')
%-- Enable source value storage.
fprintf(keithley,'smua.nvbuffer1.collectsourcevalues = 1')
fprintf(keithley,'smua.nvbuffer1.collecttimestamps = 1')

smua.nvbuffer1.collectsourcevalues = 1
%-- Collect Time stamps
%fprintf(keithley,'smua.nvbuffer1.collectimestamps = 1')



%-- Select source voltage function.
fprintf(keithley,'smua.source.func = smua.OUTPUT_DCVOLTS')
%-- Set bias voltage to 0 V.
fprintf(keithley,'smua.source.levelv = 0.0')
%-- Turn on output.
fprintf(keithley,'smua.source.output = smua.OUTPUT_ON')

if constant_v == 1  %keep a constant voltage for Piezo measurement
    step_size = (v_max-v_min)/n_steps;
    fprintf(keithley,['smua.source.levelv = ' num2str(v_max)])
    fprintf(keithley,['for v = 1, ' num2str(n_steps) ' do\n ' ...
                      'smua.measure.i(smua.nvbuffer1)\n '...
                      'end'])  
else
    step_size = (v_max-v_min)/n_steps;
    %-- Loop for voltages from 0.1 V to 1 V.
    fprintf(keithley,['for v = 1, ' num2str(n_steps) ' do\n ' ...
                      'smua.source.levelv = ' num2str(v_min) ' + v*' num2str(step_size) '\n ' ...
                      'smua.measure.i(smua.nvbuffer1)\n '...
                      'end'])
end


%Turn off Output
fprintf(keithley,'smua.source.output = smua.OUTPUT_OFF')

%% Read from buffer
%-- Output current readings

current = [];
voltage = [];
time_stamp = [];

max_values_to_read = 20;
current_val_to_read = 1;
values_left_to_read = n_steps;

for i = 1:ceil(n_steps/max_values_to_read)
    min_ind = current_val_to_read;
    max_ind = min_ind + min([values_left_to_read max_values_to_read]) - 1;
    
    %-- Output current values
    fprintf(keithley,[' printbuffer(' num2str(min_ind)  ', ' num2str(max_ind) ', smua.nvbuffer1.readings)'])
    current_line = fgetl(keithley);
    current = [current str2num(current_line)];
    
    %-- Output source values
    fprintf(keithley,[' printbuffer(' num2str(min_ind)  ', ' num2str(max_ind) ', smua.nvbuffer1.sourcevalues)'])
    voltage_line = fgetl(keithley);
    voltage = [voltage str2num(voltage_line)];
    
    %-- time stamps
    fprintf(keithley,[' printbuffer(' num2str(min_ind)  ', ' num2str(max_ind) ', smua.nvbuffer1.timestamps)'])
    time_line = fgetl(keithley);
    time_stamp = [time_stamp str2num(time_line)];
    
    
    %Doesn't matter if it read fewer than max_values_to_read b/c it'll be
    %done
    
    values_left_to_read = values_left_to_read - max_values_to_read;
    current_val_to_read = current_val_to_read + max_values_to_read;
end

fclose(keithley);
delete(keithley);

%% Plot data
plot(time_stamp*1000,1e-6*voltage./current)
xlabel('TimeStamp [ms]')
ylabel('Resistance [M-Ohm]')

%Coeffs(1) = m 
%coeffs(2) = b
if constant_v == 0
    coeffs = polyfit(voltage, current, 1);
    title(['Measured Resistance = ' num2str(1e-6/coeffs(1)) ' Mohms'])
else
    title(['Measured Resistance = ' num2str(mean(voltage)/mean(current)/1e6) ' Mohms'])
end

set(gca,'FontSize',28)
