function data = format_cwa_data(data, fs, des_fs)
%FORMAT_CWA_DATA resamples data and computes actigraphy counts.
%   FORMAT_CWA_DATA(data, fs, des_fs) inputs acceleration data from a CWA
%   file, resamples to fs, and computes activity counts in des_fs size
%   epochs.
%
%   Author: Andreas Brink-Kjaer.
%   Date: 19. May 2022
%
%   Input:  data, struct containing triaxial acceleration, light, and
%   temperature.
%           fs, sampling frequency
%           des_fs, frequency to compute activity counts
%
%   Output: data, struct containing resampled acceleration, light,
%   temperature, and activity counts.

if ~exist('des_fs', 'var')
    des_fs = 1;
end

% Detect outliers
idx_outliers_acc = detect_time_outliers(data.AXES(:, 1));
idx_outliers_light = detect_time_outliers(data.LIGHT(:, 1));
idx_outliers_temp = detect_time_outliers(data.TEMP(:, 1));

% Process accelerometer data
[acc_c, t_r] = raw2acc(data.AXES(~idx_outliers_acc, 2:4), 24*60*60 * data.AXES(~idx_outliers_acc, 1), fs);
acti_counts = acc2count(acc_c, fs, des_fs);
M = floor(length(acti_counts)/(des_fs/fs));
t_acti = t_r(1:(fs/des_fs):M);

% Process Light
light = resample(data.LIGHT(~idx_outliers_light, 2), 24*60*60 * data.LIGHT(~idx_outliers_light, 1), des_fs, 'spline');

% Process Tempreature
temp = resample(data.TEMP(~idx_outliers_temp, 2), 24*60*60 * data.TEMP(~idx_outliers_temp, 1), des_fs, 'spline');

% Add samples to temp and light
if length(temp) > length(acti_counts)
    temp = temp(1:length(acti_counts));
elseif length(temp) < length(acti_counts)
    temp = [temp; ones(length(acti_counts) - length(temp), 1)*temp(end)];
end
if length(light) > length(acti_counts)
    light = light(1:length(acti_counts));
elseif length(light) < length(acti_counts)
    light = [light; ones(length(acti_counts) - length(light), 1)*light(end)];
end

data = struct('t', t_r / (24*60*60), 'acc', acc_c, 'light', light, 'temp', temp, ...
              't_acti', t_acti / (24*60*60), 'acti_counts', acti_counts);

end