function nonwear = acti_nonwear(acc, fs)
%ACTI_NONWEAR estimates hours of nonwear
%   ACTI_NONWEAR(acc, fs) inputs acceleration in x,y,z and sampling
%   frequency to compute nonwear time.
%
%   Author: Andreas Brink-Kjaer.
%   Date: 19. May 2022
%
%   Input:  acc, raw acceleration in shape [N,3]
%           t, time in seconds from start in shape [N,1]
%
%   Output: nonwear, binary nonwear vector for each 1-hour epoch
%
%   Notes:  The algorithm is implemented from https://doi.org/10.1371/journal.pone.0022922
%           

% Hyperparameters
epoch_size = fs*60*30;
T_sd = 3*10^(-3);
T_r = 50*10^(-3);

% Roud actigraphy to match epoch size
M = floor(size(acc, 1) / epoch_size) * epoch_size;
acc_e = arrayfun(@(x) reshape(acc(1:M, x), epoch_size, []), 1:size(acc, 2), 'Un', 0);

% Compute features
acc_std = cell2mat(cellfun(@(x) std(x), acc_e, 'Un', 0)')';
acc_max = cell2mat(cellfun(@(x) max(x), acc_e, 'Un', 0)')';
acc_min = cell2mat(cellfun(@(x) min(x), acc_e, 'Un', 0)')';

% Check thresholds
nonwear_std = sum(acc_std < T_sd, 2) >= 2;
nonwear_range = sum((acc_max - acc_min) < T_r, 2) >= 2;
nonwear = nonwear_std | nonwear_range;

end