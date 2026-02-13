function idx = detect_time_outliers(t)

% Correct dimension
t = t(:);

% Get median time step
ts_m = median(diff(t));

% Find iregular time steps
t_step_max = 60 / (24*60*60);
idx_step = [0; abs(diff(t))] > t_step_max;

% Expected timing
t_expected = (t(1):ts_m:(t(1) + length(t)*ts_m-ts_m))';

% Crop
L = length(t);
if length(t_expected) > L
    t_expected = t_expected(1:L);
elseif length(t_expected) < L
    t_expected = [t_expected; t(1+length(t_expected):end)];
end

% Find deviations from expected time window
t_deviation_max = 1;
idx_dev = abs(t - t_expected) > t_deviation_max;

idx = idx_dev | idx_step;

end