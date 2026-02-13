function counts = actiCount(acc, fs, des_fs)
if isempty(fs) || isempty(des_fs)
    fs = 1;
    des_fs = 1;
elseif mod(fs, des_fs) ~= 0
    error('des_fs has to be a multiplicative factor of fs.');
end
counts = abs(sqrt(sum(acc.^2 ,2)) - 1);
if fs ~= des_fs
    M = floor(length(counts)/(fs/des_fs))*(fs/des_fs);
    counts = counts(1:M);
    counts = sum(reshape(counts',fs / des_fs, [])',2);
end
end