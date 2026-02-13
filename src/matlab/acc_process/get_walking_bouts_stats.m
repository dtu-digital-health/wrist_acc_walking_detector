function stats_b = get_walking_bouts_stats(acti_counts, t_acti, stats_w, walking_bouts, fs)
%GET_WALKING_BOUTS_STATS stats for all predicted walking bouts.
%   GET_WALKING_BOUTS_STATS(acti_counts, fs, t_acti) acceleration magnitude,
%   sampling frequency, and timing to predict and score walking bouts.
%
%   Author: Andreas Brink-Kjaer.
%   Date: 14. August 2023
%
%   Input:  acti_counts, accleration resultant with sampling frequency fs
%           t_acti, time for activity counts
%           stats_w, walking stats as computed by "get_step_stats.m"
%           walking_bouts, with sampling frequnecy fs after postprocessing
%           fs, sampling frequency
%
%   Output: stats_b, walking bout features

% Get transitions
walking_bouts_bw = bwlabel(double(stats_w.walk_b));
walking_bout_on = find(diff([0; walking_bouts; 0]) == 1);
walking_bout_off = find(diff([0; walking_bouts; 0]) == -1);
N_bouts = max(walking_bouts_bw);

% Preallocate features
dur = nan(N_bouts, 1);
arm_swing_amplitude_mean = nan(N_bouts, 1);
arm_swing_amplitude_var = nan(N_bouts, 1);
cadence_mean = nan(N_bouts, 1);
cadence_var = nan(N_bouts, 1);
cadence_p_var = nan(N_bouts, 1);
ACF_max_mean = nan(N_bouts, 1);
ACF_max_var = nan(N_bouts, 1);
acti_power_mean = nan(N_bouts, 1);
acti_power_var = nan(N_bouts, 1);
ACF_max_power_mean = nan(N_bouts, 1);
ACF_max_power_var = nan(N_bouts, 1);
dominant_freq_amp_mean = nan(N_bouts, 1);
dominant_freq_amp_var = nan(N_bouts, 1);
jerks_mean = nan(N_bouts, 1);
jerks_var = nan(N_bouts, 1);
jerks_p_var = nan(N_bouts, 1);
x_amp_mean = nan(N_bouts, 1);
x_amp_var = nan(N_bouts, 1);
y_amp_mean = nan(N_bouts, 1);
y_amp_var = nan(N_bouts, 1);
z_amp_mean = nan(N_bouts, 1);
z_amp_var = nan(N_bouts, 1);

% Iterate bouts
for b = 1:N_bouts
    idx_w = walking_bouts_bw == b;
    
    if ~(b > length(walking_bout_off)) % Avoid for sliding windows
        dur(b) = (walking_bout_off(b) - walking_bout_on(b)) / fs;
    end

    arm_swing_amplitude_mean(b) = mean(stats_w.arm_swing_amp(idx_w));
    arm_swing_amplitude_var(b) = std(stats_w.arm_swing_amp(idx_w));
    cadence_mean(b) = mean(stats_w.cadence(idx_w));
    cadence_var(b) = std(stats_w.cadence(idx_w));
    cadence_p_var(b) = mean(stats_w.cadence_std(idx_w));
    ACF_max_mean(b) = mean(stats_w.ACF_max(idx_w));
    ACF_max_var(b) = std(stats_w.ACF_max(idx_w));
    acti_power_mean(b) = mean(stats_w.power(idx_w));
    acti_power_var(b) = std(stats_w.power(idx_w));
    ACF_max_power_mean(b) = mean(stats_w.ACF_max_power(idx_w));
    ACF_max_power_var(b) = std(stats_w.ACF_max_power(idx_w));
    dominant_freq_amp_mean(b) = mean(stats_w.dominant_freq_amp(idx_w));
    dominant_freq_amp_var(b) = std(stats_w.dominant_freq_amp(idx_w));
    jerks_mean(b) = mean(stats_w.jerks(idx_w));
    jerks_var(b) = std(stats_w.jerks(idx_w));
    jerks_p_var(b) = mean(stats_w.jerks_std(idx_w));
    x_amp_mean(b) = mean(stats_w.rel_amp_x(idx_w));
    x_amp_var(b) = std(stats_w.rel_amp_x(idx_w));
    y_amp_mean(b) = mean(stats_w.rel_amp_y(idx_w));
    y_amp_var(b) = std(stats_w.rel_amp_y(idx_w));
    z_amp_mean(b) = mean(stats_w.rel_amp_z(idx_w));
    z_amp_var(b) = std(stats_w.rel_amp_z(idx_w));
    
end

stats_b = struct('dur', dur, ...
                'arm_swing_amplitude_mean', arm_swing_amplitude_mean, ...
                'arm_swing_amplitude_var', arm_swing_amplitude_var, ...
                'cadence_mean', cadence_mean, ...
                'cadence_var', cadence_var, ...
                'cadence_p_var', cadence_p_var, ...
                'ACF_max_mean', ACF_max_mean, ...
                'ACF_max_var', ACF_max_var, ...
                'acti_power_mean', acti_power_mean, ...
                'acti_power_var', acti_power_var, ...
                'ACF_max_power_mean', ACF_max_power_mean, ...
                'ACF_max_power_var', ACF_max_power_var, ...
                'dominant_freq_amp_mean', dominant_freq_amp_mean, ...
                'dominant_freq_amp_var', dominant_freq_amp_var, ...
                'jerks_mean', jerks_mean, ...
                'jerks_var', jerks_var, ...
                'jerks_p_var', jerks_p_var, ...
                'x_amp_mean', x_amp_mean, ...
                'x_amp_var', x_amp_var, ...
                'y_amp_mean', y_amp_mean, ...
                'y_amp_var', y_amp_var, ...
                'z_amp_mean', z_amp_mean, ...
                'z_amp_var', z_amp_var);

end