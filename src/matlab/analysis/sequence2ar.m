function ar = sequence2ar(sequence,fs)
%ANALYSIS.SEQUENCE2AR converts arousal vector to arousal structure.
%   ar = ANALYSIS.SEQUENCE2AR(sequence,fs) inputs an arousal sequence  and
%   iterates the array to generate a arousal structure.
%
%   Input:  sequence, arousal array
%           fs, arousal sampling frequency
%   Output: ar, arousal structure

if ~exist('fs','var')
    fs = 1;
end
% 4. Events
arousals = bwlabel(sequence);
N = max(arousals);
if N == 0
    ar = [];
else
    ar = struct;
    ar.N = N;
    for i = 1:N
        idx = find(arousals==i); 
        idx = idx(:)';
        ar.start(i) = (idx(1) - 1)/fs;
        ar.duration(i) = (idx(end) + 1 - idx(1))/fs;
        ar.range(:,i) = [ar.start(i); ar.start(i) + ar.duration(i) - 1/fs];
    end
end
end