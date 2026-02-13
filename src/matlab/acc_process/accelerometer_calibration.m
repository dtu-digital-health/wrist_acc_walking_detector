function x_calibrated = accelerometer_calibration(X, FS, plot_flag)
%ACCELERMETER_CALIBRATION calibrates the 3D accelerometer signal.
%   Calibration of a 3D accelerometer signal using. Iterative closest point
%   fitting process (ICP).
% Inputs: X     triaxial accelerometer data, where rows are observations 
%               and columns are orthoganal acceleration vectors. 
%         FS    sampling frequency
%         plot_flag boolean option to plot
%
% Output: X_cal calibrated 3D accelerometer vectors.
%

% params
cal_threshold = 0.013;
if ~exist('plot_flag','var')
    plot_flag = 0;
end

% Feature extraction
% -------------------------------------------------------------------------
X_win = buffer(X(:, 1), 10*FS, 0, 'nodelay'); X_win(:, end) = [];
Y_win = buffer(X(:, 2), 10*FS, 0, 'nodelay'); Y_win(:, end) = [];
Z_win = buffer(X(:, 3), 10*FS, 0, 'nodelay'); Z_win(:, end) = [];

% features
x_ave = mean(X_win, 1);
y_ave = mean(Y_win, 1);
z_ave = mean(Z_win, 1);
x_std = std(X_win, [], 1);
y_std = std(Y_win, [], 1);
z_std = std(Z_win, [], 1);

axesVals = ([x_ave; y_ave; z_ave])';
[AxesVals_min] = min(axesVals, [], 1);
[AxesVals_max] = max(axesVals, [], 1);
% TODO - Check that these are >300 mg and < -300 mg when you know the unit.

% Delete repeated data examples
[~, firstIndices] = unique(axesVals, 'rows', 'stable');
unique_points = false(size(axesVals, 1), 1);
unique_points(firstIndices) = true;

% remove outliers using cal_threshold = 0.013 parameter
valid_win_IDX = (x_std < cal_threshold) & ...
    (y_std < cal_threshold) & ...
    (z_std < cal_threshold) & ...
    (sqrt(sum(axesVals.^2, 2)) ~= 0 & ...
    unique_points)';
axesVals = axesVals(valid_win_IDX, :);

% assert(sum(valid_win_IDX) > 0)
% this assertion fails if there are no vailid indexes. 
if sum(valid_win_IDX) > 6

if plot_flag
    
    % helper function
    t = (1:size(X, 1)) / FS; % time vector 
    t_win = buffer(t, 10*FS, 0, 'nodelay'); t_win(:, end) = [];
    t_new = mean(t_win, 1);
    
    ax(1) = subplot(311);
    plot(t, X)
    
    ax(2) = subplot(312);
    plot(t_new, [x_ave; y_ave; z_ave])
    
    ax(3) = subplot(313);
    plot(t_new, (x_std+y_std+z_std), 'LineWidth', 1.5); hold on;
    plot([t(1) t(end)], [cal_threshold cal_threshold], 'k--')
    
    linkaxes(ax, 'x')
    
end

% Iterative closest point fitting process (ICP)
% -------------------------------------------------------------------------

% learning/research parameters
maxIter = 1000; 
minIter = 5;
minIterImprovement = 0.0001; % 0.1 mg
% initialise intercep/slope variables to assume no error initially present
intercept = [0, 0, 0];
slope = [1.0, 1.0, 1.0];
% record initial uncalibrated error
curr = intercept + axesVals.*slope;
target = curr ./ sqrt(sum(axesVals.^2, 2));
% initError = sqrt(mean((curr-target).^2, 1));

[R1, T1, data1] = icp(target', curr', maxIter, minIter, 0, minIterImprovement);

x_calibrated = R1*X' + T1;
x_calibrated = x_calibrated';

else
    % TODO: Create warning
    x_calibrated = X;

end


