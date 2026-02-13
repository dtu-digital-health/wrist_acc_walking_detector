function [F, WB, WS] = run_walking_detector(acti_counts, acc, fs, t_acti)
%RUN_WALKING_DETECTOR returns walking bout predictions.
%   RUN_WALKING_DETECTOR(acti_counts, fs, t_acti) acceleration magnitude,
%   sampling frequency, and timing to predict and score walking bouts.
%
%   Author: Andreas Brink-Kjaer.
%   Date: 14. August 2023
%
%   Input:  acti_counts, accleration resultant with sampling frequency fs
%           acc, triaxial acceleration with sampling frequency fs
%           fs, sampling frequency
%           t_acti, time in datenum
%
%   Output: F, walking bout features
%           WB, walking bout predictions with sampling frequency fs
%           WS, table of stats for all windows

% Hyperparameters
window_size = fs*10;
t_nacf = 0.5;
t_post = 0.0173;
t_p_acf = 0.25;
w_p_acf = 0.5;
w_post_len = round(window_size/2);

% Iterate windows
N_windows = floor(length(acti_counts)/(window_size));
stats_w = struct();
for w = 1:N_windows
    % Window indicies
    idx_w = (window_size)*(w - 1) + 1:(window_size)*w; 
    
    % Check if power is sufficient (otherwise skip)
    % This makes everything run faster
    if (w > 1) && (mean(acti_counts(idx_w).^2) < t_post)
        stats_w.ACF_max(w) = 0;
        stats_w.ACF_max_power(w) = 0;
        continue
    end
    
    % Get stats for current window
    step_statistics_w = get_step_stats(acti_counts(idx_w), acc(idx_w, :), fs);
    fnames = fieldnames(step_statistics_w);
    for f = 1:length(fnames)
        if w == 1
            stats_w.(fnames{f}) = nan(N_windows, 1);
        end
        stats_w.(fnames{f})(w) = step_statistics_w.(fnames{f});
    end
end

% Rule-based prediction
stats_w.walk = (stats_w.ACF_max > t_nacf) .* stats_w.ACF_max_power;

% Postprocessing - Finding precise onset and offset
% Threshold power corresponding to autocorrelation peak to find
% initiation of movement
stats_w.walk_b = stats_w.walk > t_post;
walking_bouts = post_process_walking_bouts(acti_counts, stats_w, fs, window_size, w_post_len, w_p_acf, t_p_acf);

% Extract walking bout features
stats_b = get_walking_bouts_stats(acti_counts, t_acti, stats_w, walking_bouts, fs);

% Store results
WS = struct2table(stats_w);
WB = walking_bouts;
F = struct2table(stats_b);

end