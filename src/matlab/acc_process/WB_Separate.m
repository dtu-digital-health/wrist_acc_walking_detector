function [WB_walking, WB_jogging] = WB_Separate(WB, Cadence, Cadence_window, fs, dur_min)

WB = WB(:);
Cadence = Cadence(:);

if ~exist('Cadence_window', 'var')
    Cadence_window = 1;
end
if ~exist('fs', 'var')
    fs = 25;
end
if ~exist('dur_min', 'var')
    dur_min = 30;
end

Cadence = repelem(Cadence, Cadence_window);

if length(Cadence) > length(WB)
    Cadence = Cadence(1:length(WB));
elseif length(Cadence) < length(WB)
    Cadence = [Cadence; zeros(length(WB) - length(Cadence), 1)];
end

WB_BW = bwlabel(WB);
n_WB = max(WB_BW);

WB_walking = zeros(size(WB));
WB_jogging = zeros(size(WB));

for i = 1:n_WB
    idx = (WB_BW == i);
    
    % Check if longer than 30 sec
    dur_i = sum(idx)/fs;
    if dur_i < dur_min
        continue
    end
    
    % Get cadence
    cadence_i = mean(Cadence(idx));
    
    if cadence_i > 1 && cadence_i < 120/60
        WB_walking(idx) = 1;
    elseif cadence_i > 120/60 && cadence_i < 200/60
        WB_jogging(idx) = 1;
    end
end

end
