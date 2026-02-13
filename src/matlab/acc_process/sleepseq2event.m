function data = sleepseq2event(W, t)
%SLEEPSEQ2EVENT transforms sleep predictions as a sequence to events.
%   SLEEPSEQ2EVENT(W, t) sleep predictions and timing in datetime to
%   compute onset and offset of all sleep periods.
%
%   Input:  W, sleep predictions as an array
%           t, time of each prediction
%
%   Output: data, structure of all onset and offsets

bw = bwlabel(W);
sleep_onset = NaT(max(bw),1);
sleep_offset = NaT(max(bw),1);
for i = 1:max(bw)
    sleep_onset(i) = t(find(bw == i, 1, 'first'));
    sleep_offset(i) = t(find(bw == i, 1, 'last'));
end

data = struct('annotation_start', sleep_onset, 'annotation_end', sleep_offset);

end