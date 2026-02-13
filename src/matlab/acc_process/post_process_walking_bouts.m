function walking_bouts = post_process_walking_bouts(acti_counts, stats_w, fs, window_size, w_post_len, w_p_acf, t_p_acf)
%POST_PROCESS_WALKING_BOUTS adjusts borders of detected walknig bouts.
%   POST_PROCESS_WALKING_BOUTS(acti_counts, stats_w, fs, window_size, w_post_len, w_p_acf, t_p_acf)
%   corrects border of detected bouts to match a decrease in power of the
%   actigraphy frequency corresponding to the walking cadence.
%
%   Author: Andreas Brink-Kjaer.
%   Date: 14. August 2023
%
%   Input:  acti_counts, accleration resultant with sampling frequency fs
%           stats_w, walking stats as computed by "get_step_stats.m"
%           fs, sampling frequency
%           window_size, number of samples per window
%           w_post_len, length beyond window to explore
%           w_p_acf, frequency window to consider around cadence
%           t_p_acf, threshold for ACF function
%
%   Output: walking_bouts, with sampling frequnecy fs

% Find onsets and offsets
walking_cadence_on = stats_w.cadence(diff([0; stats_w.walk_b]) == 1);
walking_cadence_off = stats_w.cadence(diff([stats_w.walk_b; 0]) == -1);
walking_bout_on = find(diff([0; stats_w.walk_b; 0]) == 1) * window_size - window_size + 1;
walking_bout_off = find(diff([0; stats_w.walk_b; 0]) == -1) * window_size - window_size;
walking_bouts = zeros(size(acti_counts));

% Iterate bouts
N_bouts = length(walking_bout_on);
for b = 1:N_bouts
    % Index for window around transitions
    idx_on = (walking_bout_on(b) - w_post_len):(walking_bout_on(b) + w_post_len - 1);
    idx_off = (walking_bout_off(b) - w_post_len):(walking_bout_off(b) + w_post_len - 1);
    
    if any(idx_on < 1)
        walking_bout_on_adj = w_post_len + 1;
    else
        % Finding low power related to cadence for onset
        [~, fp_on, tp_on, P_on] = spectrogram(acti_counts(idx_on), 3*fs, 2*fs, 0:0.1:(fs/2), fs);
        fp_on_idx = fp_on > walking_cadence_on(b) - w_p_acf & fp_on < walking_cadence_on(b) + w_p_acf;
        PB_on = mean(P_on(fp_on_idx, :), 1);
        PB_on_T = mean(P_on(fp_on_idx, tp_on >= window_size / (fs*2)), [1 2]);
        walking_bout_on_adj = find(PB_on < t_p_acf*PB_on_T, 1, 'last') * fs + 1;
        if isempty(walking_bout_on_adj)
            walking_bout_on_adj = fs + 1;
        end
    end
    
    if any(idx_off > length(acti_counts))
        walking_bout_off_adj = w_post_len + 1;
    else
        % Finding low power related to cadence for offset
        [~, fp_off, tp_off, P_off] = spectrogram(acti_counts(idx_off), 3*fs, 2*fs, 0:0.1:(fs/2), fs);
        fp_off_idx = fp_off > walking_cadence_off(b) - w_p_acf & fp_off < walking_cadence_off(b) + w_p_acf;
        PB_off = mean(P_off(fp_off_idx, :), 1);
        PB_off_T = mean(P_off(fp_off_idx, tp_off < window_size / (fs*2)), [1 2]);
        walking_bout_off_adj = find(PB_off < t_p_acf*PB_off_T, 1, 'last') * fs;
        if isempty(walking_bout_off_adj)
            walking_bout_off_adj = 2*w_post_len - fs;
        end
    end
    
    % Setting walking bouts in binary format
    walking_bout_on(b) = walking_bout_on(b) + walking_bout_on_adj - w_post_len - 1;
    walking_bout_off(b) = walking_bout_off(b) + walking_bout_off_adj - w_post_len;
    walking_bouts(walking_bout_on(b):walking_bout_off(b)) = 1;
end
end
