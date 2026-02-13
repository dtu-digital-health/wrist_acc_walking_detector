function acti_counts_r = acc2count(acc, fs, des_fs)
Hd = hp_filter_acc();
round_thresh = 0.1;
acti_counts = actiCount(acc, fs, des_fs);
if length(acti_counts) > 21
    acti_counts_f = filtfilt(Hd.sosMatrix, Hd.ScaleValues, acti_counts);
else
    acti_counts_f = acti_counts;
end
% Round off
acti_counts_r = acti_counts_f .* (acti_counts_f > round_thresh);
end