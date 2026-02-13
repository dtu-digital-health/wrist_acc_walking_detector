function step_statistics = get_step_stats(acti_counts, acc, fs)
%GET_STEP_STATS computes walking stats for a given window.
%   GET_STEP_STATS(acti_counts, fs) inputs acceleration magnitude and 
%   sampling frequency to compute walking stats for the full segment.
%
%   Author: Andreas Brink-Kjaer.
%   Date: 14. August 2023
%
%   Input:  acti_counts, accleration resultant with sampling frequency fs
%           acc, triaxial acceleration with sampling frequency fs
%           fs, sampling frequency
%
%   Output: step_statistics, struct of walking statistics

% Min lag (max cadence = 200 steps per min = 0.3 sec per step)
min_lag = ceil(fs * 0.3);

% Autocorrelation
[normalizedACF, ~] = autocorr(acti_counts, 'NumLags', min(fs * 4, length(acti_counts) - 1));

% FFT of autocorrelation
% Find dominant frequency
y = fftshift(fft(normalizedACF, 2^10)); % y = fftshift(fft(normalizedACF));
n = 2^10; % n = length(normalizedACF);
fy = (-n/2:n/2-1)*(fs/n);
py = abs(y(fy >=0)).^2/n;
fy = fy(fy >= 0);
[dominant_amp, dominant_lag] = max(py);
dominant_freq = fy(dominant_lag);

% Find peak
ACF_max = max(normalizedACF(min_lag:end));

% Signal Power
acti_power = mean(acti_counts.^2);

% Find cadence (do not multiply with 2 as only the top part signals
% acceleration both forward and backwards).
cadence = dominant_freq;

% Find step peaks
[step_pks_pos, step_idx_pos] = findpeaks(acti_counts, fs, 'MinPeakDistance', 1 / dominant_freq * 0.75);
[step_pks_neg, step_idx_neg] = findpeaks(-acti_counts, fs, 'MinPeakDistance', 1 / dominant_freq * 0.75);

% Cadence var
cadence_std = std(1 ./ diff(step_idx_pos));

% Jerks
step_idx_pos_sample = round(step_idx_pos*fs) + 1;
step_acti_counts = arrayfun(@(x) acti_counts(step_idx_pos_sample(x):step_idx_pos_sample(x+1)), 1:length(step_idx_pos_sample)-1, 'Un', 0);
step_jerks = (cellfun(@(x) sum(abs(diff(sign(diff(x)))) == 2), step_acti_counts) - 1) / 2;
jerks_mean = mean(step_jerks);
jerks_std = std(step_jerks);

% arm swing amplitude
arm_swing_amplitude = median(step_pks_pos) - median(-step_pks_neg);

% Orientation data (normal walking = abs(x) > abs(y) > abs(z))
amp_x = mean(abs(acc(:, 1)));
amp_y = mean(abs(acc(:, 2)));
amp_z = mean(abs(acc(:, 3)));
rel_amp_x = amp_x / (amp_x + amp_y + amp_z);
rel_amp_y = amp_y / (amp_x + amp_y + amp_z);
rel_amp_z = amp_z / (amp_x + amp_y + amp_z);

% Gather stats
step_statistics = struct('arm_swing_amp', arm_swing_amplitude, ...
                        'cadence', cadence, ...
                        'cadence_std', cadence_std, ...
                        'jerks', jerks_mean, ...
                        'jerks_std', jerks_std, ...
                        'ACF_max', ACF_max, ...
                        'power', acti_power, ...
                        'ACF_max_power', ACF_max*acti_power, ...
                        'dominant_freq_amp', dominant_amp, ...
                        'rel_amp_x', rel_amp_x, ...
                        'rel_amp_y', rel_amp_y, ...
                        'rel_amp_z', rel_amp_z);

end