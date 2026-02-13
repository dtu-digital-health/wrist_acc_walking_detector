function [acc_c, t_r] = raw2acc(raw, t, fs)
%RAW2ACC process raw accelerometer data
%   RAW2ACC(raw, t) inputs acceleration in x,y,z and time in seconds,
%   which is processed to resample and calibrate the signal.
%
%   Author: Andreas Brink-Kjaer.
%   Date: 18. October 2022
%
%   Input:  acc, raw acceleration in shape [N,3]
%           t, time in seconds from start in shape [N,1]
%

% Consider changing filtering (?)
[acc_r, t_r] = resample(raw, t, fs, 'spline');
acc_c = accelerometer_calibration(acc_r, fs);
end