function [acti_counts_r, t_r] = raw2count(raw,t)
%ACC2COUNT computes activity count.
%   ACC2COUNT(acc, t) inputs acceleration in x,y,z and time in seconds,
%   which is processed to compute the activity counts.
%
%   Author: Andreas Brink-Kjaer.
%   Date: 19. May 2022
%
%   Input:  acc, raw acceleration in shape [N,3]
%           t, time in seconds from start in shape [N,1]
%

fs = 25;
des_fs = 1;
[acc_r, t_r] = resample(raw, t, fs, 'spline');
acc_c = accelerometer_calibration(acc_r, fs);
acti_counts_r = acc2count(acc_c, fs, des_fs);
end