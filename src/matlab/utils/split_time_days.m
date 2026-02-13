function [t_start, t_stop] = split_time_days(t1, t2, opts)
%SPLIT_TIME_DAYS finds the time points to split an actigraphy recroding.
%   SPLIT_TIME_DAYS(t1, t2, opts) finds each "day" corresponding to input
%   options and returns a vector of start and end points.
%
%   Author: Andreas Brink-Kjaer.
%   Date: 14. August 2023
%
%   Input:  t1, recording start time
%           t2, recording end time
%           opts, settings to splits days 
%                 [min start time, min end time, default day start]
%
%   Output: t_start, vector of start times for each day
%           t_stop, vector of stop times for each day

% Options for cropping days
if exist('opts', 'var')
    if length(opts) == 3
        t_start_min = opts(1);
        t_end_min = opts(2);
        t_start_base = opts(3);
        opts_set = true;
    else
        opts_set = false;
    end
else
    opts_set = false;
end
if ~opts_set
    t_start_min = 20/24;
    t_end_min = 6/24;
    t_start_base = 12/24;
end

% Adjust start time
if rem(t1, 1) > t_start_min
    t1 = ceil(t1) + t_start_base;
elseif rem(t1, 1) < t_start_base
    t1 = floor(t1) + t_start_base;
end

% Adjust end time
if rem(t2, 1) < t_end_min
    t2 = floor(t2) - t_start_base;
elseif rem(t2, 1) > t_start_base
    t2 = floor(t2) + t_start_base;
end

% Number of days
N = floor(t2) - floor(t1);
t_start = zeros(N, 1);
t_stop = zeros(N, 1);

% Get day times
for i = 1:N
    if i == 1
        t_start(i) = t1;
    else
        t_start(i) = floor(t1) + i - 1 + t_start_base;
    end
    if i < N
        t_stop(i) = ceil(t_start(i)) + t_start_base;
    else
        t_stop(i) = t2;
    end
end
end