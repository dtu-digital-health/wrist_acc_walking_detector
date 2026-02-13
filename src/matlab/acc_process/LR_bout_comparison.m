function stats_b = LR_bout_comparison(acti_counts_L, acti_counts_R, WB, fs)

% Number of bouts
WB_bw = bwlabel(WB);
N_bouts = max(WB_bw);

% Preallocation of variables
dur = nan(N_bouts, 1);
corr_LR = nan(N_bouts, 1);
amp_LR = nan(N_bouts, 1);
cross_corr_max_LR = nan(N_bouts, 1);
cross_corr_shift_LR = nan(N_bouts, 1);
dtw_dist_LR = nan(N_bouts, 1);

for i = 1:N_bouts
    
    % Duration
    dur(i) = sum(WB_bw == i) / (fs);
    
    % Actigraphy in bouts
    x = acti_counts_L(WB_bw == i);
    y = acti_counts_R(WB_bw == i);
   
    % Get correlation
    corr_LR(i) = corr(x,y);
    
    % Amplitude diff
    amp_LR(i) = abs(mean(abs(x)) - mean(abs(y)));
    
    % cross correlation
    [c_xy, c_lags] = xcorr(x, y, round(fs*2), 'unbiased');
    c_xy = c_xy * length(x) / sqrt(sum(x.^2) * sum(y.^2));
    [cross_corr_max_LR(i), c_lags_max] = max(c_xy);
    cross_corr_shift_LR(i) = abs(c_lags(c_lags_max))/fs;
    
    % DTW
    dtw_dist_LR(i) = dtw(x,y) / (length(x) + length(y));
end


stats_b = struct('dur', dur, ...
                'corr_LR', corr_LR, ...
                'amp_LR', amp_LR, ...
                'cross_corr_max_LR', cross_corr_max_LR, ...
                'cross_corr_shift_LR', cross_corr_shift_LR, ...
                'dtw_dist_LR', dtw_dist_LR);
end