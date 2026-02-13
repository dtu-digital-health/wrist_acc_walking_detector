%% Gait Analysis of WearGait-PD
%   This script iteratively reads data, runs the walking detector,
%   characterizes ambulatory bouts, and saves these in a table.
%
%   Author: Andreas Brink-Kjaer.
%   Date: 5. January 2026

clear all; close all;
startup;

%% Initialize paths

% Declare paths
path_weargait = 'H:\pd_gait';
path_walkway_metrics = filepath(path_weargait, 'Walkway-derived metrics', 'pkmas walkway gait metrics - hp+sp.csv');
path_clinical_data_controls = filepath(path_weargait, 'controls - demographic+clinical - datasetv1.csv');
path_clinical_data_pd = filepath(path_weargait, 'pd - demographic+clinical - datasetv1.csv');
path_freewalk_controls = filepath(path_weargait, 'Real-world context tasks', 'FreeWalk', 'CONTROL PARTICIPANTS', 'MAT files');
path_freewalk_pd = filepath(path_weargait, 'Real-world context tasks', 'FreeWalk', 'PD PARTICIPANTS', 'MAT files');
path_matwalk_controls = filepath(path_weargait, 'CONTROL PARTICIPANTS', 'MAT files');
path_matwalk_pd = filepath(path_weargait, 'PD PARTICIPANTS', 'MAT file');

% Get file locations
files_freewalk_controls = dir(filepath(path_freewalk_controls, '*.mat'));
files_freewalk_pd = dir(filepath(path_freewalk_pd, '*.mat'));
files_matwalk_controls = dir(filepath(path_matwalk_controls, '*.mat'));
files_matwalk_pd = dir(filepath(path_matwalk_pd, '*.mat'));

% Get clinical datasets
T_clinical = readWearGaitClinicalData(path_clinical_data_pd, path_clinical_data_controls);

% Get walkway dataset
T_walkway = readWearGaitWalkwayData(path_walkway_metrics);
T_walkway.ParticipantID = cellfun(@(x) x(1:min(length(x), 6)), T_walkway.ParticipantID, 'Un', 0);

% Sampling frequency & hyperparameters
fs = 25;
epoch_size = fs;
window_size = fs*10;
resolution = fs*1;
Hd = hp_filter_acc(fs);

%% Dataset table
%% Dataset summary based on T_clinical
T = T_clinical;

% Ensure strings
T.Group = string(T.Group);
T.Sex   = string(T.Sex);

groups = ["Overall","PD","Control"];

summaryTbl = table;

for g = groups
    if g == "Overall"
        idx = true(height(T),1);
    else
        idx = T.Group == g;
    end

    Tg = T(idx,:);

    % Basic counts
    N = height(Tg);
    N_male   = sum(Tg.Sex == "Male");
    N_female = sum(Tg.Sex == "Female");

    % Demographics
    age_mu = mean(Tg.Age, 'omitnan');
    age_sd = std( Tg.Age, 'omitnan');

    h_mu = mean(Tg.Heightin, 'omitnan');
    h_sd = std( Tg.Heightin, 'omitnan');

    w_mu = mean(Tg.Weightkg, 'omitnan');
    w_sd = std( Tg.Weightkg, 'omitnan');

    % Assistive device usage
    if ismember("AssistiveDeviceUsedDuringTesting", Tg.Properties.VariableNames)
        n_device = sum(Tg.AssistiveDeviceUsedDuringTesting ~= 'No', 'omitnan');
    else
        n_device = NaN;
    end

    % PD-specific severity (NaN-safe for controls)
    hy_mu = mean(Tg.ModifiedHoehnYahrScore, 'omitnan');
    hy_sd = std( Tg.ModifiedHoehnYahrScore, 'omitnan');

    updrs3_mu = mean(Tg.MDS_Part3, 'omitnan');
    updrs3_sd = std( Tg.MDS_Part3, 'omitnan');

    updrsT_mu = mean(Tg.MDS_Total, 'omitnan');
    updrsT_sd = std( Tg.MDS_Total, 'omitnan');

    % Availability of walking detection results
    n_walk_eval = sum(~isnan(Tg.recall_walk_L) | ~isnan(Tg.recall_walk_R));

    % Assemble row
    row = table( ...
        g, N, ...
        N_male, N_female, ...
        age_mu, age_sd, ...
        h_mu, h_sd, ...
        w_mu, w_sd, ...
        n_device, ...
        hy_mu, hy_sd, ...
        updrs3_mu, updrs3_sd, ...
        updrsT_mu, updrsT_sd, ...
        n_walk_eval, ...
        'VariableNames', { ...
            'Group','N', ...
            'N_male','N_female', ...
            'Age_mean','Age_sd', ...
            'Height_mean_in','Height_sd_in', ...
            'Weight_mean_kg','Weight_sd_kg', ...
            'N_assistive_device', ...
            'HY_mean','HY_sd', ...
            'UPDRS3_mean','UPDRS3_sd', ...
            'UPDRS_total_mean','UPDRS_total_sd', ...
            'N_with_walking_eval' ...
        });

    summaryTbl = [summaryTbl; row];
end

disp(summaryTbl)

%% Experiments 
%  (1) Free-walk detection in PD and Controls.
%  Run 1-second resolution walking bout detector.

%  (2) Walkway-derived gait metrics.
%  Run 1-second resolution walking bout detector in Self- and HurriedPace.

%% (1) Freewalk

files_freewalk = [files_freewalk_controls; files_freewalk_pd];
IDs = cellfun(@(x) lower(x(1:6)), {files_freewalk.name}', 'Un', 0);
N_freewalk = size(files_freewalk, 1);
perf_freewalk = cell(N_freewalk, 1);
stats_freewalk = cell(N_freewalk, 1);

% Iterate files
for i = 1:N_freewalk
    fprintf('File %.0f/%.0f\n', i, N_freewalk);

    % Get nights of subject
    ID = IDs{i};
    path_i = filepath(files_freewalk(i).folder, files_freewalk(i).name);

    % Read data
    freewalk_data_i = load(path_i);

    % Get annotations & data
    freewalk_annotations_i = freewalk_data_i.FreeWalk.Annotation;
    freewalk_accL_i = [freewalk_data_i.FreeWalk.IMU_acc.L_Wrist_Acc_X, ...
                       freewalk_data_i.FreeWalk.IMU_acc.L_Wrist_Acc_Y, ...
                       freewalk_data_i.FreeWalk.IMU_acc.L_Wrist_Acc_Z];
    freewalk_accR_i = [freewalk_data_i.FreeWalk.IMU_acc.R_Wrist_Acc_X, ...
                       freewalk_data_i.FreeWalk.IMU_acc.R_Wrist_Acc_Y, ...
                       freewalk_data_i.FreeWalk.IMU_acc.R_Wrist_Acc_Z];

    % Check case of NaN data
    if mean(isnan(freewalk_accL_i), "all") > 0.50 || mean(isnan(freewalk_accR_i), "all") > 0.50
        continue;
    end
    
    % To gravity units - Already done?
    freewalk_accL_i = freewalk_accL_i / 9.82;
    freewalk_accR_i = freewalk_accR_i / 9.82;

    % Time axis in datenum
    t_acc = (0:0.01:(size(freewalk_accR_i, 1)*0.01) - 0.01)';
    t_acc = t_acc / (60 * 60 * 24);

    % Formatting for pipeline
    freewalk_accL_i = struct('time', t_acc, ... 
                    'x', freewalk_accL_i(:, 1), ... 
                    'y', freewalk_accL_i(:, 2), ... 
                    'z', freewalk_accL_i(:, 3));
    freewalk_accR_i = struct('time', t_acc, ... 
                    'x', freewalk_accR_i(:, 1), ... 
                    'y', freewalk_accR_i(:, 2), ... 
                    'z', freewalk_accR_i(:, 3));

    freewalk_accL_i = format_csv_as_cwa(freewalk_accL_i, t_acc(1), t_acc(end));
    freewalk_accR_i = format_csv_as_cwa(freewalk_accR_i, t_acc(1), t_acc(end));

    % Preprocessing
    freewalk_accL_i = format_cwa_data(freewalk_accL_i, fs);
    freewalk_accR_i = format_cwa_data(freewalk_accR_i, fs);

    % Get resultant
    acti_countsL = sqrt(sum(freewalk_accL_i.acc.^2, 2)) - 1;
    acti_countsL = filtfilt(Hd.sosMatrix, Hd.ScaleValues, acti_countsL);
    acti_countsR = sqrt(sum(freewalk_accR_i.acc.^2, 2)) - 1;
    acti_countsR = filtfilt(Hd.sosMatrix, Hd.ScaleValues, acti_countsR);
    M = floor(length(acti_countsR)/(epoch_size/fs));

    t_acti = freewalk_accL_i.t(1:(fs/epoch_size):M);

    % Evaluate detector
    [FL_i, WB_L, WS_L] = run_walking_detector_sliding(acti_countsL, freewalk_accL_i.acc, fs, t_acti, resolution);
    [FR_i, WB_R, WS_R] = run_walking_detector_sliding(acti_countsR, freewalk_accR_i.acc, fs, t_acti, resolution);

    % Filter out bad detections (low cadence / arm swing?)
    idx_ok_L = WS_L.cadence < 200/60 & WS_L.cadence > 1 & WS_L.walk_b;
    idx_ok_R = WS_R.cadence < 200/60 & WS_R.cadence > 1 & WS_R.walk_b;
    stats_freewalk{i} = struct('arm_swing_ampL', mean(WS_L.arm_swing_amp(idx_ok_L)), ...
        'arm_swing_ampR', mean(WS_R.arm_swing_amp(idx_ok_R)), ...
        'cadenceL', mean(WS_L.cadence(idx_ok_L)), ...
        'cadenceR', mean(WS_R.cadence(idx_ok_R)), ...
        'jerksL', mean(WS_L.jerks(idx_ok_L)), ...
        'jerksR', mean(WS_R.jerks(idx_ok_R)), ...
        'arm_swing_ampL_std', std(WS_L.arm_swing_amp(idx_ok_L)), ...
        'arm_swing_ampR_std', std(WS_R.arm_swing_amp(idx_ok_R)), ...
        'cadenceL_std', std(WS_L.cadence(idx_ok_L)), ...
        'cadenceR_std', std(WS_R.cadence(idx_ok_R)), ...
        'jerksL_std', std(WS_L.jerks(idx_ok_L)), ...
        'jerksR_std', std(WS_R.jerks(idx_ok_R)), ...
        'freewalk_loc', contains(ID, 'nls'));

    % High-rest WB
    WB_L_100 = repelem(WB_L, round(100 / fs));
    WB_L_100 = WB_L_100(1:size(freewalk_annotations_i.GeneralEvent, 1));
    WB_R_100 = repelem(WB_R, round(100 / fs));
    WB_R_100 = WB_R_100(1:size(freewalk_annotations_i.GeneralEvent, 1));

    % Optionally: Visualize results
    % acti_countsL_walk = acti_countsL;
    % acti_countsL_walk(~WB_L) = nan;
    % acti_countsR_walk = acti_countsR;
    % acti_countsR_walk(~WB_R) = nan;
    % annotation_walk = nan(size(freewalk_annotations_i.GeneralEvent));
    % annotation_walk(freewalk_annotations_i.GeneralEvent == "Walk") = 2;

    % h = figure;
    % h.Position(3:4) = [800 400];
    % centerfig(h);
    % ax1 = subplot(3,1,1);
    % hold all;
    % stairs(freewalk_annotations_i.Time, freewalk_annotations_i.GeneralEvent)
    % plot(freewalk_annotations_i.Time, annotation_walk)
    % grid;
    % xlim([0 freewalk_annotations_i.Time(end)])
    % set(gca, 'XTickLabel', []);
    % ax2 = subplot(3,1,2);
    % hold all;
    % plot(t_acti * (60 * 60 * 24), acti_countsL)
    % plot(t_acti * (60 * 60 * 24), acti_countsL_walk)
    % grid;
    % xlim([0 seconds(freewalk_annotations_i.Time(end))])
    % ylabel('|Acc| [g]')
    % title('Left wrist', '')
    % set(gca, 'XTickLabel', []);
    % set(gca, 'TitleHorizontalAlignment', 'left')
    % ax3 = subplot(3,1,3);
    % hold all;
    % plot(t_acti * (60 * 60 * 24), acti_countsR)
    % plot(t_acti * (60 * 60 * 24), acti_countsR_walk)
    % grid;
    % xlim([0 seconds(freewalk_annotations_i.Time(end))])
    % ylabel('|Acc| [g]')
    % title('Right wrist')
    % set(gca, 'TitleHorizontalAlignment', 'left')
    % xlabel('Time [s]')
    % set(gcf,'Color',[1 1 1]);
    % set( findall(h, '-property', 'fontsize'), 'fontsize', 10);
    % export_fig(gcf, ['C:\Users\andre\Dropbox\Phd\actigraphy_irbd\Scripts\figures\walking_data_plots\WearGait-PD\freewalk_' ID], '-m4', '-dpng', '-transparent');

    % Compute performance: 
    % TP Walk:
    TP_walkL = sum((freewalk_annotations_i.GeneralEvent == 'Walk') & (WB_L_100 == 1));
    TP_walkR = sum((freewalk_annotations_i.GeneralEvent == 'Walk') & (WB_R_100 == 1));
    % FN Walk: 
    FN_walkL = sum((freewalk_annotations_i.GeneralEvent == 'Walk') & (WB_L_100 == 0));
    FN_walkR = sum((freewalk_annotations_i.GeneralEvent == 'Walk') & (WB_R_100 == 0));
    % TP Mixed:
    TP_mixedL = sum(ismember(freewalk_annotations_i.GeneralEvent, ["OpenDoor", "Stairs", "Turn"]) & (WB_L_100 == 1));
    TP_mixedR = sum(ismember(freewalk_annotations_i.GeneralEvent, ["OpenDoor", "Stairs", "Turn"]) & (WB_R_100 == 1));
    % FN Mixed: 
    FN_mixedL = sum(ismember(freewalk_annotations_i.GeneralEvent, ["OpenDoor", "Stairs", "Turn"]) & (WB_L_100 == 0));
    FN_mixedR = sum(ismember(freewalk_annotations_i.GeneralEvent, ["OpenDoor", "Stairs", "Turn"]) & (WB_R_100 == 0));
    % TN Standing: 
    TN_passiveL = sum(ismember(freewalk_annotations_i.GeneralEvent, ["Standing", "Chair"]) & (WB_L_100 == 0));
    TN_passiveR = sum(ismember(freewalk_annotations_i.GeneralEvent, ["Standing", "Chair"]) & (WB_R_100 == 0));
    % FP Standing
    FP_passiveL = sum(ismember(freewalk_annotations_i.GeneralEvent, ["Standing", "Chair"]) & (WB_L_100 == 1));
    FP_passiveR = sum(ismember(freewalk_annotations_i.GeneralEvent, ["Standing", "Chair"]) & (WB_R_100 == 1));
    % Performance Walking
    recall_walkL = sum(TP_walkL) / (sum(TP_walkL) + sum(FN_walkL));
    recall_walkR = sum(TP_walkR) / (sum(TP_walkR) + sum(FN_walkR));
    recall_mixedL = sum(TP_mixedL) / (sum(TP_mixedL) + sum(FN_mixedL));
    recall_mixedR = sum(TP_mixedR) / (sum(TP_mixedR) + sum(FN_mixedR));
    specificity_L = sum(TN_passiveL) / (sum(TN_passiveL) + sum(FP_passiveL));
    specificity_R = sum(TN_passiveR) / (sum(TN_passiveR) + sum(FP_passiveR));
    precision_walkL = sum(TP_walkL) / (sum(TP_walkL) + sum(FP_passiveL));
    precision_walkR = sum(TP_walkR) / (sum(TP_walkR) + sum(FP_passiveR));
    precision_mixedL = sum(TP_mixedL) / (sum(TP_mixedL) + sum(FP_passiveL));
    precision_mixedR = sum(TP_mixedR) / (sum(TP_mixedR) + sum(FP_passiveR));
    perf_i = struct('recall_walk_L', recall_walkL, 'recall_walk_R', recall_walkR, ...
        'recall_mixed_L', recall_mixedL, 'recall_mixed_R', recall_mixedR, ...
        'specificity_L', specificity_L, 'specificity_R', specificity_R, ...
        'precision_walk_L', precision_walkL, 'precision_walk_R', precision_walkR, ...
        'precision_mixed_L', precision_mixedL, 'precision_mixed_R', precision_mixedR);
    perf_freewalk{i} = perf_i;
end

%% Save metrics in table

stats_fields = fieldnames(stats_freewalk{1});

for f = 1:length(stats_fields)
    stats_array = nan(size(T_clinical, 1), 1);
    for i = 1:size(T_clinical, 1)
        idx_id = find(strcmpi(IDs, T_clinical.SubjectID{i}));
        if ~isempty(idx_id)
            if ~isempty(stats_freewalk{idx_id})
                stats_array(i) = stats_freewalk{idx_id}.(stats_fields{f});
            end
        end
    end
    T_clinical.(stats_fields{f}) = stats_array;
end

%% Save performance in table

perf_fields = fieldnames(perf_freewalk{1});

for f = 1:length(perf_fields)
    perf_array = nan(size(T_clinical, 1), 1);
    for i = 1:size(T_clinical, 1)
        idx_id = find(strcmpi(IDs, T_clinical.SubjectID{i}));
        if ~isempty(idx_id)
            if ~isempty(perf_freewalk{idx_id})
                perf_array(i) = perf_freewalk{idx_id}.(perf_fields{f});
            end
        end
    end
    T_clinical.(perf_fields{f}) = perf_array;
end

%% Performance overview

% Average and Standard Deviation for each group excluding assistedDevice
% idx_pd = ismember(T_clinical.Group, 'PD') & (T_clinical.AssistiveDeviceUsedDuringTesting == 'No');
% idx_control = ismember(T_clinical.Group, 'Control') & (T_clinical.AssistiveDeviceUsedDuringTesting == 'No');

T = T_clinical;

% --- Keep PD only ---
T = T(T.Group ~= "PD" & T.AssistiveDeviceUsedDuringTesting == "No", :);

% --- Metrics to summarise ---
metrics = [ ...
    "recall_walk_L","recall_walk_R", ...
    "recall_mixed_L","recall_mixed_R", ...
    "precision_walk_L","precision_walk_R", ...
    "precision_mixed_L","precision_mixed_R", ...
    "specificity_L","specificity_R" ...
];

% Safety check
missing = metrics(~ismember(metrics, string(T.Properties.VariableNames)));
if ~isempty(missing)
    error("Missing columns: %s", strjoin(missing, ", "));
end
if ~ismember("Sex", string(T.Properties.VariableNames))
    error("Missing column: Sex");
end

% --- Ensure Sex is only Male/Female (and drop missing/other if any) ---
sexStr = string(T.Sex);
keepSex = ismember(sexStr, ["Male","Female"]);
T = T(keepSex, :);

% --- Define groups: Overall + by Sex ---
T.SexGroup = categorical(sexStr); % Male/Female

groups = ["Overall"; "Male"; "Female"];

out = table;

for gi = 1:numel(groups)
    g = groups(gi);

    if g == "Overall"
        idx = true(height(T),1);
    else
        idx = string(T.SexGroup) == g;
    end

    row = table(string(g), sum(idx), 'VariableNames', ["Group","Nsubjects"]);

    for m = metrics
        x = T{idx, m};
        row.("mean_" + m) = mean(x, 'omitnan');
        row.("sd_"   + m) = std(x,  'omitnan');
        row.("n_"    + m) = sum(~isnan(x));
    end

    out = [out; row]; %#ok<AGROW>
end

disp(out)

%% Pretty table: mean ± SD
pretty = table(out.Group, out.Nsubjects, 'VariableNames', ["Group","N"]);

for m = metrics
    mu = out.("mean_" + m);
    sd = out.("sd_" + m);
    pretty.(m) = compose("%.3f ± %.3f", mu, sd);
end

disp(pretty)

%% Walking mat analyses
%  (2) Walkway-derived gait metrics.


files_matwalk = [files_matwalk_controls; files_matwalk_pd];

% Robust IDs: use first 6 chars of filename (your current convention)
IDs = cellfun(@(x) lower(x(1:min(6,numel(x)))), {files_matwalk.name}', 'UniformOutput', false);

N = numel(files_matwalk);

% Preallocate containers
matwalk_rows = cell(N,1);  % each will become a 1-row table (or empty)

% ---- configuration ----
minSamples = 100;
maxNaNFrac = 0.50;

% cadence limits (Hz). 200 steps/min = 200/60 Hz
cadMinHz = 1.0;
cadMaxHz = 200/60;

wristLoc = ["L","R"];
paces    = ["selfpace","hurrpace"];

% Output variable names: aggregated across walk bouts
outVars = strings(0,1);
for w = wristLoc
    for p = paces
        % aggregated across bouts
        outVars(end+1,1) = "arm_swing_amp_mean_" + w + "_" + p;
        outVars(end+1,1) = "arm_swing_amp_std_"  + w + "_" + p;
        outVars(end+1,1) = "cadence_mean_"       + w + "_" + p;
        outVars(end+1,1) = "cadence_std_"        + w + "_" + p;
        outVars(end+1,1) = "jerks_mean_"         + w + "_" + p;
        outVars(end+1,1) = "jerks_std_"          + w + "_" + p;
        % number of bouts used
        outVars(end+1,1) = "nwalkbouts_"         + w + "_" + p;
    end
end

for i = 1:N
    fprintf('MatWalk file %d/%d\n', i, N);

    subjID = string(IDs{i});
    path_i = fullfile(files_matwalk(i).folder, files_matwalk(i).name);

    try
        S = load(path_i);
    catch ME
        warning('Could not load %s: %s', path_i, ME.message);
        continue;
    end

    % Validate expected fields
    if ~isfield(S,"SelfPace") || ~isfield(S,"HurriedPace") || ...
       ~isfield(S.SelfPace,"Annotation") || ~isfield(S.HurriedPace,"Annotation") || ...
       ~isfield(S.SelfPace,"IMU_acc") || ~isfield(S.HurriedPace,"IMU_acc")
        warning('Missing required fields in %s', path_i);
        continue;
    end

    % Extract ALL walk intervals for each pace
    segs_self = getAllWalkIntervals(S.SelfPace.Annotation);
    segs_hurr = getAllWalkIntervals(S.HurriedPace.Annotation);

    if isempty(segs_self) || isempty(segs_hurr)
        warning('No Walk intervals found in one/both paces for %s', path_i);
        continue;
    end

    % Compute per-bout stats and aggregate
    vals = nan(1, numel(outVars));

    % SELF pace
    vals = processAllSegments(vals, outVars, S.SelfPace.IMU_acc, segs_self, ...
        fs, epoch_size, Hd, resolution, minSamples, maxNaNFrac, g0, "selfpace", cadMinHz, cadMaxHz);

    % HURR pace
    vals = processAllSegments(vals, outVars, S.HurriedPace.IMU_acc, segs_hurr, ...
        fs, epoch_size, Hd, resolution, minSamples, maxNaNFrac, g0, "hurrpace", cadMinHz, cadMaxHz);

    % If nothing usable, skip
    if all(isnan(vals))
        continue;
    end

    row = array2table(vals, 'VariableNames', cellstr(outVars));
    row.SubjectID = subjID;
    matwalk_rows{i} = movevars(row, "SubjectID", "Before", 1);
end

matwalk_tbl = vertcat(matwalk_rows{~cellfun(@isempty, matwalk_rows)});


%% ===========================
% Local helper functions
% ===========================
function segs = getAllWalkIntervals(ann)
    % Return Nx2 [startIdx, stopIdx] for all contiguous runs where GeneralEvent=="Walk"
    ge = string(ann.GeneralEvent);
    isWalk = (ge == "Walk");

    if ~any(isWalk)
        segs = zeros(0,2);
        return;
    end

    d = diff([false; isWalk; false]);
    starts = find(d == 1);
    stops  = find(d == -1) - 1;
    segs = [starts, stops];
end

function tf = badAcc(acc, maxNaNFrac, minSamples)
    tf = (mean(isnan(acc), "all") > maxNaNFrac) || (size(acc,1) < minSamples);
end

function [accL, accR] = getWristAccSegment(IMU_acc, i1, i2)
    accL = [IMU_acc.L_Wrist_Acc_X(i1:i2), IMU_acc.L_Wrist_Acc_Y(i1:i2), IMU_acc.L_Wrist_Acc_Z(i1:i2)];
    accR = [IMU_acc.R_Wrist_Acc_X(i1:i2), IMU_acc.R_Wrist_Acc_Y(i1:i2), IMU_acc.R_Wrist_Acc_Z(i1:i2)];
end

function vals = processAllSegments(vals, outVars, IMU_acc, segs, ...
        fs, epoch_size, Hd, resolution, minSamples, maxNaNFrac, g0, paceName, cadMinHz, cadMaxHz)

    % Collect per-bout outputs for L and R
    armAmp_L = []; cad_L = []; jerks_L = [];
    armAmp_R = []; cad_R = []; jerks_R = [];

    for k = 1:size(segs,1)
        i1 = segs(k,1); i2 = segs(k,2);

        [accL, accR] = getWristAccSegment(IMU_acc, i1, i2);

        if badAcc(accL, maxNaNFrac, minSamples) || badAcc(accR, maxNaNFrac, minSamples)
            continue;
        end

        accL = accL / g0;
        accR = accR / g0;

        t = (0:size(accL,1)-1)'/100 / (60*60*24);

        L = format_csv_as_cwa(struct('time',t,'x',accL(:,1),'y',accL(:,2),'z',accL(:,3)), t(1), t(end));
        R = format_csv_as_cwa(struct('time',t,'x',accR(:,1),'y',accR(:,2),'z',accR(:,3)), t(1), t(end));

        L = format_cwa_data(L, fs);
        R = format_cwa_data(R, fs);

        actL = filtfilt(Hd.sosMatrix, Hd.ScaleValues, sqrt(sum(L.acc.^2,2)) - 1);
        actR = filtfilt(Hd.sosMatrix, Hd.ScaleValues, sqrt(sum(R.acc.^2,2)) - 1);

        step = round(fs/epoch_size);
        if step < 1
            error('epoch_size/fs must be <= 1. Check epoch_size and fs.');
        end
        t_act = R.t(1:step:numel(R.t));

        try
            WS_L = get_step_stats(actL, accL, fs);
            WS_R = get_step_stats(actR, accR, fs);
        catch
            continue;
        end

        % Bout-level summary (mean across steps/epochs inside the bout)
        cadBout_L = mean(WS_L.cadence, 'omitnan');
        cadBout_R = mean(WS_R.cadence, 'omitnan');

        % Filter bout based on cadence bounds (Hz)
        okL = isfinite(cadBout_L) && cadBout_L >= cadMinHz && cadBout_L <= cadMaxHz;
        okR = isfinite(cadBout_R) && cadBout_R >= cadMinHz && cadBout_R <= cadMaxHz;

        if okL
            armAmp_L(end+1,1) = mean(WS_L.arm_swing_amp, 'omitnan');
            cad_L(end+1,1)    = cadBout_L;
            jerks_L(end+1,1)  = mean(WS_L.jerks, 'omitnan');
        end
        if okR
            armAmp_R(end+1,1) = mean(WS_R.arm_swing_amp, 'omitnan');
            cad_R(end+1,1)    = cadBout_R;
            jerks_R(end+1,1)  = mean(WS_R.jerks, 'omitnan');
        end
    end


    % Aggregate across bouts (per pace & wrist)
    w = "L";
    vals(outVars=="arm_swing_amp_mean_"+w+"_"+paceName) = median(armAmp_L, 'omitnan');
    vals(outVars=="arm_swing_amp_std_" +w+"_"+paceName) = std( armAmp_L, 'omitnan');
    vals(outVars=="cadence_mean_"      +w+"_"+paceName) = median(cad_L,    'omitnan');
    vals(outVars=="cadence_std_"       +w+"_"+paceName) = std( cad_L,    'omitnan');
    vals(outVars=="jerks_mean_"        +w+"_"+paceName) = median(jerks_L,  'omitnan');
    vals(outVars=="jerks_std_"         +w+"_"+paceName) = std( jerks_L,  'omitnan');
    vals(outVars=="nwalkbouts_"        +w+"_"+paceName) = numel(armAmp_L);

    w = "R";
    vals(outVars=="arm_swing_amp_mean_"+w+"_"+paceName) = median(armAmp_R, 'omitnan');
    vals(outVars=="arm_swing_amp_std_" +w+"_"+paceName) = std( armAmp_R, 'omitnan');
    vals(outVars=="cadence_mean_"      +w+"_"+paceName) = median(cad_R,    'omitnan');
    vals(outVars=="cadence_std_"       +w+"_"+paceName) = std( cad_R,    'omitnan');
    vals(outVars=="jerks_mean_"        +w+"_"+paceName) = median(jerks_R,  'omitnan');
    vals(outVars=="jerks_std_"         +w+"_"+paceName) = std( jerks_R,  'omitnan');
    vals(outVars=="nwalkbouts_"        +w+"_"+paceName) = numel(armAmp_R);

    okCounts = [numel(armAmp_L), numel(armAmp_R)];
end

%%
% Ensure keys are comparable
matwalk_tbl.SubjectID = arrayfun(@(x) upper(char(x)), matwalk_tbl.SubjectID, 'Un', 0);
matwalk_tbl.SubjectID = cellfun(@(x) strrep(x(1:min(length(x), 6)), '.', ''), matwalk_tbl.SubjectID, 'Un', 0);

% Left join: keep all clinical rows, add mat-walk columns where available
T_clinical = outerjoin(T_clinical, matwalk_tbl, ...
    "Keys", "SubjectID", ...
    "MergeKeys", true, ...
    "Type", "left");

%% Compare to walkway stats

paceTypes = {'SelfPace', 'HurriedPace'};

for p = 1:2
    walkway_stats = nan(size(T_clinical, 1), 4);
    for i = 1:size(T_clinical, 1)

        % Skipping if issue
        if ismember(T_clinical.SubjectID{i}, {'HC100', 'HC106', 'NLS141'}) || ...
                T_clinical.AssistiveDeviceUsedDuringTesting(i) ~= "No"
            disp(T_clinical.SubjectID{i});
            continue
        end

        idx_match = find(strcmp(T_walkway.ParticipantID, T_clinical.SubjectID{i}) & ...
            (T_walkway.Task == paceTypes{p}));

        if ~isempty(idx_match)
            idx_match = idx_match(1);
        else
            continue;
        end

        walkway_cadence_mean = 1 / T_walkway.StepTimesec1(idx_match);
        walkway_cadence_std = 1 / T_walkway.StepTimesec4(idx_match);
        arm_swing_mean = T_walkway.Swing1(idx_match);
        arm_swing_std = T_walkway.Swing4(idx_match);

        walkway_stats(i, 1) = walkway_cadence_mean;
        walkway_stats(i, 2) = walkway_cadence_std;
        walkway_stats(i, 3) = arm_swing_mean;
        walkway_stats(i, 4) = arm_swing_std;


    end
    T_clinical.(['Walkway_' paceTypes{p} '_Cadence_Mean']) = walkway_stats(:, 1);
    T_clinical.(['Walkway_' paceTypes{p} '_Cadence_Std']) = walkway_stats(:, 2);
    T_clinical.(['Walkway_' paceTypes{p} '_ArmSwing_Mean']) = walkway_stats(:, 3);
    T_clinical.(['Walkway_' paceTypes{p} '_ArmSwing_Std']) = walkway_stats(:, 4);

end


%% Linear model analysis

T_clinical.cadence_selfpace = mean([T_clinical.cadence_mean_L_selfpace, T_clinical.cadence_mean_R_selfpace], 2, 'omitnan');
T_clinical.cadence_hurrpace = mean([T_clinical.cadence_mean_L_hurrpace, T_clinical.cadence_mean_R_hurrpace], 2, 'omitnan');

T_clinical.arm_swing_amp = mean([T_clinical.arm_swing_ampL, T_clinical.arm_swing_ampR], 2, 'omitnan');
T_clinical.cadence = mean([T_clinical.cadenceL, T_clinical.cadenceR], 2, 'omitnan');
T_clinical.jerks = mean([T_clinical.jerksL, T_clinical.jerksR], 2, 'omitnan');

outcomes = {'MDSUPDRS_310','MDSUPDRS_33RUE', 'MDSUPDRS_33LUE', 'MDSUPDRS_33RLE', 'MDSUPDRS_33LLE','MDSUPDRS_36R', 'MDSUPDRS_36L','MDSUPDRS_314','MDS_Part3'};
gait_vars = {'arm_swing_amp', 'cadence_selfpace', 'jerks'};

b = nan(length(outcomes), length(gait_vars));
p = nan(length(outcomes), length(gait_vars));

for o = 1:length(outcomes)
    for v = 1:length(gait_vars)
        
        gait_var = gait_vars{v};
        outcome = outcomes{o};
        if ismember(outcomes, {'MDSUPDRS_33RUE', 'MDSUPDRS_33RLE', 'MDSUPDRS_36R'})
            gait_var = [gait_var 'R'];
        elseif ismember(outcomes, {'MDSUPDRS_33LUE', 'MDSUPDRS_33LLE', 'MDSUPDRS_36L'})
            gait_var = [gait_var 'L'];
        end

        mdl = fitlm(T_clinical(T_clinical.AssistiveDeviceUsedDuringTesting == "No", :), [gait_vars{v} '~Age+Sex+Group+' outcomes{o}]);
        disp(mdl);
        % Collect results
        idx_mdl_g = cellfun(@(x) find(ismember(mdl.Coefficients.Row, x)), cellfun(@(x) x, outcomes(o), 'Un', 0));
        b(o, v) = mdl.Coefficients.Estimate(idx_mdl_g);
        p(o, v) = mdl.Coefficients.pValue(idx_mdl_g);
    end
end

fprintf('\n\n\t%s\t\n', outcomes{1});
fprintf('Independent Variable\tb\tp\n');
% Baseline
for i = 1:length(outcomes)
    fprintf('%s', outcomes{i});
    for j = 1:length(gait_vars)
        fprintf('\t%.2f\t%.2g', b(i, j), p(i, j));
    end
    fprintf('\n');
end


%% Figures

idx_PD = T_clinical.Group == "PD";

h = figure;
h.Position(3:4) = [1000 400];
centerfig(h);
ax1 = subplot(1,2,1);
hold all;
plot(T_clinical.cadence_selfpace * 60, T_clinical.Walkway_SelfPace_Cadence_Mean * 60, 'ko')
% plot_c = plot(T_clinical.cadence_selfpace(~idx_PD) * 60, T_clinical.Walkway_SelfPace_Cadence_Mean(~idx_PD) * 60, 'o');
% plot_pd = plot(T_clinical.cadence_selfpace(idx_PD) * 60, T_clinical.Walkway_SelfPace_Cadence_Mean(idx_PD) * 60, 'o');
xylim = [min([T_clinical.cadence_selfpace; T_clinical.Walkway_SelfPace_Cadence_Mean] * 60) max([T_clinical.cadence_selfpace; T_clinical.Walkway_SelfPace_Cadence_Mean] * 60)];
xylim = [xylim(1) - diff(xylim) * 0.05 xylim(2) + diff(xylim) * 0.05];
xlim(xylim)
ylim(xylim)
plot(xylim, xylim, 'r--');
[r,p] = corr(T_clinical.cadence_selfpace, T_clinical.Walkway_SelfPace_Cadence_Mean, 'Type', 'Spearman', 'Rows', 'pairwise');
[r_c,p_c] = corr(T_clinical.cadence_selfpace(~idx_PD), T_clinical.Walkway_SelfPace_Cadence_Mean(~idx_PD), 'Type', 'Spearman', 'Rows', 'pairwise');
[r_pd,p_pd] = corr(T_clinical.cadence_selfpace(idx_PD), T_clinical.Walkway_SelfPace_Cadence_Mean(idx_PD), 'Type', 'Spearman', 'Rows', 'pairwise');
text(xylim(1) + diff(xylim) * 0.05, xylim(1) + diff(xylim) * 0.9, sprintf('r = %.3f (p = %.3g)', r, p))
% text(xylim(1) + diff(xylim) * 0.05, xylim(1) + diff(xylim) * 0.9, sprintf('HC: r = %.3f (p = %.3g)', r_c, p_c))
% text(xylim(1) + diff(xylim) * 0.05, xylim(1) + diff(xylim) * 0.8, sprintf('PD: r = %.3f (p = %.3g)', r_pd, p_pd))
grid;
title('Self Pace')
xlabel({'Cadence [steps/min]', '(Wrist IMU)'})
ylabel({'Cadence [steps/min]', '(Walkway)'})
% legend(vertcat(plot_c, plot_pd), {'Healthy Control', 'PD'})
ax2 = subplot(1,2,2);
hold all;
plot(T_clinical.cadence_hurrpace * 60, T_clinical.Walkway_HurriedPace_Cadence_Mean * 60, 'ko')
xylim = [min([T_clinical.cadence_hurrpace; T_clinical.Walkway_HurriedPace_Cadence_Mean] * 60) max([T_clinical.cadence_hurrpace; T_clinical.Walkway_HurriedPace_Cadence_Mean] * 60)];
xylim = [xylim(1) - diff(xylim) * 0.05 xylim(2) + diff(xylim) * 0.05];
xlim(xylim)
ylim(xylim)
plot(xylim, xylim, 'r--');
[r,p] = corr(T_clinical.cadence_hurrpace, T_clinical.Walkway_HurriedPace_Cadence_Mean, 'Type', 'Spearman', 'Rows', 'pairwise');
text(xylim(1) + diff(xylim) * 0.05, xylim(1) + diff(xylim) * 0.9, sprintf('r = %.3f (p = %.3g)', r, p))
grid;
title('Hurried Pace')
xlabel({'Cadence [steps/min]', '(Wrist IMU)'})
ylabel({'Cadence [steps/min]', '(Walkway)'})
set(gcf,'Color',[1 1 1]);
set( findall(h, '-property', 'fontsize'), 'fontsize', 10);
export_fig(gcf, 'C:\Users\andre\Dropbox\Phd\actigraphy_irbd\Scripts\figures\walking_data_plots\WearGait-PD\cadence_walkway_scatter', '-m4', '-dpng', '-transparent');


h = figure;
h.Position(3:4) = [500 400];
centerfig(h);
hold all;
plot(T_clinical.cadence * 60, T_clinical.Walkway_SelfPace_Cadence_Mean * 60, 'ko')
xylim = [min([T_clinical.cadence; T_clinical.Walkway_SelfPace_Cadence_Mean] * 60) max([T_clinical.cadence; T_clinical.Walkway_SelfPace_Cadence_Mean] * 60)];
xylim = [xylim(1) - diff(xylim) * 0.05 xylim(2) + diff(xylim) * 0.05];
xlim(xylim)
ylim(xylim)
plot(xylim, xylim, 'r--');
[r,p] = corr(T_clinical.cadence, T_clinical.Walkway_SelfPace_Cadence_Mean, 'Type', 'Spearman', 'Rows', 'pairwise');
text(xylim(1) + diff(xylim) * 0.05, xylim(1) + diff(xylim) * 0.9, sprintf('r = %.3f (p = %.3g)', r, p))
grid;
xlabel({'Cadence [steps/min]', '(Freewalk Wrist IMU)'})
ylabel({'Cadence [steps/min]', '(Walkway SelfPace)'})
set(gcf,'Color',[1 1 1]);
set( findall(h, '-property', 'fontsize'), 'fontsize', 10);
% export_fig(gcf, 'C:\Users\andre\Dropbox\Phd\actigraphy_irbd\Scripts\figures\walking_data_plots\WearGait-PD\cadence_walkway_freewalk_scatter', '-m4', '-dpng', '-transparent');
