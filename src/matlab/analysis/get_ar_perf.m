function [perf, eventStruct] = get_ar_perf(eventStruct,scored,margin,ssc)
%ANALYSIS.GET_AR_PERF computes the performance of matching arousal events.
%   [F1,performance,eventStruct] = ANALYSIS.GET_AR_PERF(eventStruct,
%   scored, margin) computes the performance of matching arousal events in
%   "eventStruct" to arousal events in "scored" with a margin of error by
%   "margin" seconds.
%   This function was initially written by Caspar Aleksander Bang Jespersen
%   and modified by Andreas Brink-Kjaer.
%
%   Input:  eventStruct, arousal prediction structure
%           scored, arousal annotation structure
%           margin, accepted margin of error in true positive predictions
%           ssc, sleep stages
%   Output: F1, F1 score of arousal events
%           performance, array of [true positives, false positives, false
%           negatives].
%           eventStruct, changed eventStruct with events marked as
%           predicted and/or scored.

scored_found = zeros(scored.N, 1);
% Analyze predicted arousals
if isempty(eventStruct)
    num_arousals = 0;
else
    num_arousals = eventStruct.N;
    eventStruct.pred = ones(1, num_arousals);
    eventStruct.scored = zeros(1, num_arousals);
    eventStruct.scoredLength = nan(1, num_arousals);
end
ranges = reshape([scored.range],2,[]);
ranges(1,:) = ranges(1,:) - margin;
ranges(2,:) = ranges(2,:) + margin;
for i = 1:num_arousals
    % Predicted
    eventStruct.pred(i) = 1;
    range = eventStruct.range(:,i);
    % Found in scored?'
    found = find(range(1) <= ranges(2,:) & range(2) >= ranges(1,:));
    if isempty(found)
        eventStruct.scored(i) = 0;
    else
        % Counting multiple true positives within the same true event
        % differently
        if all(scored_found(found) == 1)
            eventStruct.scored(i) = 2;
        else
            eventStruct.scored(i) = 1;
            scored_found(found) = 1;
            eventStruct.scoredLength(i) = scored.duration(found(1));
        end
    end
end

notfound = find(~scored_found);
for i = 1:length(notfound)
    if isempty(eventStruct)
        eventStruct = struct;
        ind = 1;
    else
        ind = length(eventStruct.scored) + 1;
    end
    
    %     arousal = scored(notfound(i));
    %     bin_from = arousal.range(1);
    %     bin_to = arousal.range(2);
    %     bins = bin_from:bin_to;
    %
    bins = scored.range(:,notfound(i));
    
    eventStruct.range(:,ind) = bins;
    eventStruct.duration(ind) = length(bins);
    eventStruct.pred(ind) = 0;
    eventStruct.scored(ind) = 1;
    eventStruct.scoredLength(ind) = scored.duration(notfound(i));
    
end

% Check sleep stage
if exist('ssc','var')
    ssc_lag = 30;
    for i = 1:length(eventStruct.scored)
        bin_from = eventStruct.range(1,i);
        bin_to = eventStruct.range(2,i);
        priorSleepStages = ssc(max(bin_from-ssc_lag,1):(bin_to));
        sleepStage = ssc(bin_from);
        if sleepStage == 0 && any(priorSleepStages ~= 0)
            idx = find(priorSleepStages,1,'first');
            sleepStage = priorSleepStages(idx);
        end
        eventStruct.ssc(i) = sleepStage;
    end
else
    for i = 1:length(eventStruct.scored)
        eventStruct.ssc(i) = 0;
    end
end
performance = zeros(5,3);
ssc_idx = [0 1 2 3 5];
for i = 1:5
    idx = ismember([eventStruct.ssc], ssc_idx(i)) & eventStruct.scored ~= 2;
    
    subSetpred = eventStruct.pred(idx);
    subSetscored = eventStruct.scored(idx);
    
    TP = sum(all([[subSetpred]; [subSetscored]],1));
    FP = sum(all([[subSetpred]; ~[subSetscored]],1));
    FN = sum(all([~[subSetpred]; [subSetscored]],1));
    performance(i,1) = TP;
    performance(i,2) = FP;
    performance(i,3) = FN;
end
precision = sum(performance(:,1))./(sum(performance(:,1)) + sum(performance(:,2)));
recall = sum(performance(:,1))./(sum(performance(:,1)) + sum(performance(:,3)));
F1 = 2*recall.*precision./(recall + precision);
perf = struct('precision', precision, 'recall', recall, 'F1', F1);
end