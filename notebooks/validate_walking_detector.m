%% Actigraphy walking behavior detector
%  Author: Andreas Brink-Kjaer
%  Date: 24/04/2023

clear all; close all;
addpath(genpath('actigraphy_gait-main'));

%% Initialize paths
p_labels = 'C:\Users\andre\Dropbox\Phd\actigraphy_irbd\Scripts\data\walking_labels';
p_labels_good = 'C:\Users\andre\Dropbox\Phd\actigraphy_irbd\Scripts\data\walking_labels_good';
f_labels = dir(filepath(p_labels, '*.txt'));
f_labels_good = dir(filepath(p_labels_good, '*.txt'));
p_data = 'C:\Users\andre\Dropbox\Andreas actigraphy';
f_data_cwa = dir(filepath(p_data, '*.CWA'));
f_data_csv = dir(filepath(p_data, '*.csv'));
f_data = [f_data_cwa; f_data_csv];
IDs = cellfun(@(x) x(1:end-4), {f_data.name}, 'UniformOutput', 0);
f_ext = cellfun(@(x) x(end-3:end), {f_data.name}, 'UniformOutput', 0);
N_subjects = length(IDs);

% Sampling frequency
fs = 25;
epoch_size = fs;
window_size = fs*10;
Hd = hp_filter_acc(fs);

% Post processing options
t_nacf = 0.5;
t_post = 0.0173;
t_p_acf = 0.25;
w_p_acf = 0.5;
w_post_len = round(window_size/2);

% Plotting
plot_opt = true;
plot_save = true;
plot_zoom_save = true;

%% Pre-allocate result variables
F_all = cell(N_subjects, 1);
B_all = cell(N_subjects, 1);
P_all = cell(N_subjects, 1);
L_all = cell(N_subjects, 1);
Lg_all = cell(N_subjects, 1);
Lc_all = cell(N_subjects, 1);

%% Iterate data

% Iterate subjects
% parpool(4);
%parfor i = 1:N_subjects
for i = 1:N_subjects
    fprintf('Subject %.0f/%.0f\n', i, N_subjects);

    % Get nights of subject
    ID = IDs{i};

    % file
    file_i = filepath(p_data, [ID f_ext{i}]);
    if exist(file_i, 'file')
        % CSV
        if strcmp(f_ext{i}, '.csv')
            ftype = 'csv';

            % Read data info
            csv_raw_i = readtable(file_i);
            csv_raw_i.Properties.VariableNames = {'time', 'x', 'y', 'z'};
            csv_raw_i.time = datenum(csv_raw_i.time);
            [t_start, t_stop] = split_time_days(csv_raw_i.time(1), csv_raw_i.time(end), [22/24, 0, 3/24]);
            if t_start(1) ~= csv_raw_i.time(1)
                t_stop = [t_start(1); t_stop];
                t_start = [csv_raw_i.time(1); t_start];
            end
            if t_stop(end) ~= csv_raw_i.time(end)
                t_start = [t_start; t_stop(end)];
                t_stop = [t_stop; csv_raw_i.time(end)];
            end
        elseif strcmp(f_ext{i}, '.CWA')
            ftype = 'cwa';

            % Read data info
            cwa_raw_i = CWA_readFile(file_i, 'info', 1);
            [t_start, t_stop] = split_time_days(cwa_raw_i.start.mtime, cwa_raw_i.stop.mtime, [22/24, 0, 3/24]);
            if t_start(1) ~= cwa_raw_i.start.mtime
                t_stop = [t_start(1); t_stop];
                t_start = [cwa_raw_i.start.mtime; t_start];
            end
            if t_stop(end) ~= cwa_raw_i.stop.mtime
                t_start = [t_start; t_stop(end)];
                t_stop = [t_stop; cwa_raw_i.stop.mtime];
            end
        end
        N_nights = size(t_start, 1);

    else
        fprintf('%s skipped due to missing actigraphy data.\n', ID);
        continue;
    end

    % Load labels
    labels_i = filepath(p_labels, [ID '.txt']);
    labels = readtable(labels_i, 'Delimiter', ',');
    labels.Start = datetime(labels.Start, 'InputFormat', "HH:mm dd/MM/yyyy");
    labels.Stop = datetime(labels.Stop, 'InputFormat', "HH:mm dd/MM/yyyy");

    % Load good labels
    labels_i = filepath(p_labels_good, [ID '.txt']);
    good_labels_exist = exist(labels_i, 'file');
    if good_labels_exist
        labels_good = readtable(labels_i, 'Delimiter', ',');
        labels_good.Start = datetime(labels_good.Start, 'InputFormat', "HH:mm:ss dd/MM/yyyy");
        labels_good.Stop = datetime(labels_good.Stop, 'InputFormat', "HH:mm:ss dd/MM/yyyy");
    end
    
    % Result var
    F_i = cell(N_nights, 1);
    B_i = cell(N_nights, 1);
    L_i = cell(N_nights, 1);
    Lg_i = cell(N_nights, 1);
    Lc_i = cell(N_nights, 1);
    P_i = cell(N_nights, 1);

    for j = 1:N_nights
        
        % Path to data for night j
        if strcmp(ftype, 'csv')
            data_raw = csv_raw_i(csv_raw_i.time >= t_start(j) & csv_raw_i.time < t_stop(j), :);
            data_raw = struct('AXES', data_raw{:, :}, 'TEMP', [data_raw{:, 1} rand(size(data_raw,1),1)],'LIGHT', [data_raw{:, 1} rand(size(data_raw,1),1)]);
        elseif strcmp(ftype, 'cwa')
            data_raw = CWA_readFile(file_i, 'packetInfo', cwa_raw_i.packetInfo, 'startTime', t_start(j), 'stopTime', t_stop(j), 'modality', [1 1 1]);
        end
        data = format_cwa_data(data_raw, fs);
        start_time = datetime(data.t(1), 'ConvertFrom', 'datenum');

        % Get resultant
        acti_counts = sqrt(sum(data.acc.^2, 2)) - 1;
        acti_counts = filtfilt(Hd.sosMatrix, Hd.ScaleValues, acti_counts);
        M = floor(length(acti_counts)/(epoch_size/fs));
        t_acti = data.t(1:(fs/epoch_size):M);

        % Run DETOKS
%         [tranVec, xVec, fVec, ~, SpVec, binS, binK2, ~] = detoks(zscore(acti_counts), fs, fc, lam0, lam1, lam2, c1, c2);
%         acti_detoks = fVec + SpVec;

        % Iterate windows
        N_windows = floor(length(acti_counts)/(window_size));
        stats_w = struct();
%         stats_w_detoks = struct();
        L_j = nan(N_windows, 1);
        if good_labels_exist
            Lg_j = any(cell2mat(arrayfun(@(x) datetime(t_acti, 'ConvertFrom', 'datenum') >= labels_good.Start(x) & datetime(t_acti, 'ConvertFrom', 'datenum') <= labels_good.Stop(x), 1:size(labels_good, 1), 'Un', 0)),2);
            Lc_j = any(cell2mat(arrayfun(@(x) datetime(t_acti, 'ConvertFrom', 'datenum') >= labels_good.Start(x) & datetime(t_acti, 'ConvertFrom', 'datenum') <= labels_good.Stop(x), find(labels_good.Certain == 1)', 'Un', 0)),2);
        else
            Lg_j = nan(size(t_acti));
            Lc_j = nan(size(t_acti));
        end
        for w = 1:N_windows
            step_statistics_w = get_step_stats(acti_counts((window_size)*(w - 1) + 1:(window_size)*w), fs);
%             step_statistics_w_detoks = get_step_stats(acti_detoks((window_size)*(w - 1) + 1:(window_size)*w), fs);
            fnames = fieldnames(step_statistics_w);
            for f = 1:length(fnames)
                if w == 1
                    stats_w.(fnames{f}) = nan(N_windows, 1);
%                     stats_w_detoks.(fnames{f}) = nan(N_windows, 1);
                end
                stats_w.(fnames{f})(w) = step_statistics_w.(fnames{f});
%                 stats_w_detoks.(fnames{f})(w) = step_statistics_w_detoks.(fnames{f});
            end
            t_window = datetime(t_acti((window_size)*(w - 1) + 1:(window_size)*w), 'ConvertFrom', 'datenum');
            L_j(w) = any(arrayfun(@(x) any(t_window >= labels.Start(x) & t_window <= labels.Stop(x)), 1:size(labels, 1)));
        end
        
        % Rule-based prediction
        stats_w.walk = (stats_w.ACF_max > t_nacf) .* stats_w.ACF_max_power;
%         stats_w_detoks.walk = (stats_w_detoks.ACF_max > 0.5) .* stats_w_detoks.ACF_max_power;
        
        % Postprocessing - Finding precise onset and offset
        % Threshold power corresponding to autocorrelation peak to find
        % initiation of movement
        stats_w.walk_b = stats_w.walk > t_post;
        walking_bouts = post_process_walking_bouts(acti_counts, stats_w, fs, window_size, w_post_len, w_p_acf, t_p_acf);

        % Extract walking bout features
        stats_b = get_walking_bouts_stats(acti_counts, t_acti, stats_w, walking_bouts, fs);
        
        % Store results
        F_i{j} = struct2table(stats_w);
        B_i{j} = struct2table(stats_b);
        L_i{j} = L_j;
        Lg_i{j} = Lg_j;
        Lc_i{j} = Lc_j;
        P_i{j} = walking_bouts;
        
        % Plot results
        if plot_opt
            if good_labels_exist
                plot_labels = labels_good;
            else
                plot_labels = labels;
            end
            xtickat = datetime(ceil(t_acti(1)*24)/24, 'ConvertFrom', 'datenum'):hours(2):datetime(floor(t_acti(end)*24)/24, 'ConvertFrom', 'datenum');

            h = figure;
            h.Position(3:4) = [1000 500];
            centerfig(h);
            ax1 = subplot(3,1,1);
            hold all
            p_walk = stairs(datetime(t_acti(1:window_size:N_windows*window_size), 'ConvertFrom', 'datenum'), stats_w.walk);
%             p_walk_post = stairs(datetime(t_acti, 'ConvertFrom', 'datenum'), walking_bouts);
            yl = get(gca,'YLim');
            for l = 1:size(plot_labels, 1)
                p_label = area([plot_labels.Start(l) plot_labels.Stop(l)], [yl(2) yl(2)], 'BaseValue', yl(1), 'EdgeColor' ,'none', 'FaceColor', [0.8 0.5 0.5], 'FaceAlpha', 0.3);
            end
            xlim(datetime([t_acti(1) t_acti(N_windows*window_size)], 'ConvertFrom', 'datenum'));
            set(gca, 'XTick', xtickat);
            set(gca, 'XTickLabel', datestr(xtickat, 'HH:MM:SS'));
            set(gca,'XTickLabel', {});
            set(gca,'YLim', yl);
%             legend([p_walk p_walk_post p_label],{'Prediction Score', 'Prediction', 'Walking'},'Location','north','NumColumns',3);
            legend([p_walk p_label],{'Walking Score', 'Walking'},'Location','northeast','NumColumns',2);
            grid minor
            
            ax2 = subplot(3,1,2);
            hold all
            p_acf_1 = stairs(datetime(t_acti(1:window_size:N_windows*window_size), 'ConvertFrom', 'datenum'), stats_w.ACF_max);
            p_acf_2 = stairs(datetime(t_acti(1:window_size:N_windows*window_size), 'ConvertFrom', 'datenum'), stats_w.ACF_max_power);
            yl = get(gca,'YLim');
            for l = 1:size(plot_labels, 1)
                p_label = area([plot_labels.Start(l) plot_labels.Stop(l)], [yl(2) yl(2)], 'BaseValue', yl(1), 'EdgeColor' ,'none', 'FaceColor', [0.8 0.5 0.5], 'FaceAlpha', 0.3);
            end
            xlim(datetime([t_acti(1) t_acti(N_windows*window_size)], 'ConvertFrom', 'datenum'));
            set(gca, 'XTick', xtickat);
            set(gca, 'XTickLabel', datestr(xtickat, 'HH:MM:SS'));
            set(gca,'XTickLabel', {});
            set(gca,'YLim', yl);
            legend([p_acf_1 p_acf_2 p_label],{'ACF max (normalized)', 'ACF max', 'Walking'},'Location','northeast','NumColumns',3);
            grid minor
            
            ax3 = subplot(3,1,3);
            hold all
%             for l = 1:3
%                  plot(datetime(t_acti, 'ConvertFrom', 'datenum'), data.acc(:,l));
%             end
            p_acti = plot(datetime(t_acti, 'ConvertFrom', 'datenum'), acti_counts, '-k');
            yl = get(gca,'YLim');
            for l = 1:size(plot_labels, 1)
                p_label = area([plot_labels.Start(l) plot_labels.Stop(l)], [yl(2) yl(2)], 'BaseValue', yl(1), 'EdgeColor' ,'none', 'FaceColor', [0.8 0.5 0.5], 'FaceAlpha', 0.3);
            end
            xlim(datetime([t_acti(1) t_acti(N_windows*window_size)], 'ConvertFrom', 'datenum'));
            set(gca, 'XTick', xtickat);
            set(gca, 'XTickLabel', datestr(xtickat, 'HH:MM:SS'));
            set(gca,'YLim', yl);
            ylabel('Resultant [g]')
            grid minor
            legend([p_acti p_label],{'Resultant', 'Walking'},'Location','northeast','NumColumns',2);
            linkaxes([ax1, ax2, ax3], 'x');
            set(gcf,'Color',[1 1 1]);
            set( findall(h, '-property', 'fontsize'), 'fontsize', 10);
            plot_name = ['C:\Users\andre\Dropbox\Phd\actigraphy_irbd\Scripts\figures\walking_data_plots\Walking_Prediction_' ID '_' num2str(day(start_time)) '_' num2str(month(start_time)) '_' num2str(hour(start_time))];
            if plot_save
                export_fig(gcf, plot_name, '-m4', '-png', '-transparent');
            end
            if plot_zoom_save
%                 first_label = find(datetime(t_acti(1), 'ConvertFrom', 'datenum') < plot_labels.Start, 1, 'first');
                first_label = find(datetime(t_acti(1), 'ConvertFrom', 'datenum') < plot_labels.Start);
                first_label = first_label(4);
                if ~isempty(first_label)
                    x_zoom = [datenum(plot_labels.Start(first_label)) - 15/(60*60*24), datenum(plot_labels.Start(first_label)) + 45/(60*60*24)];
                    t_zoom = find(t_acti > x_zoom(1) & t_acti < x_zoom(2));
                    acti_counts_range = [min(acti_counts(t_zoom)) max(acti_counts(t_zoom))];
                    xlim([datetime(x_zoom(1), 'ConvertFrom', 'datenum'), datetime(x_zoom(2), 'ConvertFrom', 'datenum')]);
                    set(ax3, 'YLim', [acti_counts_range(1) - 0.05*diff(acti_counts_range) acti_counts_range(2) + 0.05*diff(acti_counts_range)]);
                    set(ax3, 'XTickMode', 'auto', 'XTickLabelMode', 'auto')
                    set(ax3, 'XTickLabel', datestr(get(ax3, 'XTick'), 'HH:MM:SS'));
                    plot_name = ['C:\Users\andre\Dropbox\Phd\actigraphy_irbd\Scripts\figures\walking_data_plots\Walking_Prediction_Zoom_' ID '_' num2str(day(start_time)) '_' num2str(month(start_time)) '_' num2str(hour(start_time))];
                    export_fig(gcf, plot_name, '-m4', '-png', '-transparent');
                end
            end
            close all;
        end
    end
    
    % Store results
    F_all{i} = F_i;
    B_all{i} = B_i;
    L_all{i} = L_i;
    Lg_all{i} = Lg_i;
    Lc_all{i} = Lc_i;
    P_all{i} = P_i;
    
end
%% Combine nights of the same subjects stored in different files
names = {'pauline','nikolas','stephen','emmanuel','lisa','mari','mehrdad','ryan'};
L_all_s = cellfun(@(x) vertcat(L_all{contains(IDs, x, 'IgnoreCase',true)}), names, 'Un', 0);
B_all_s = cellfun(@(x) vertcat(B_all{contains(IDs, x, 'IgnoreCase',true)}), names, 'Un', 0);
Lg_all_s = cellfun(@(x) vertcat(Lg_all{contains(IDs, x, 'IgnoreCase',true)}), names, 'Un', 0);
Lc_all_s = cellfun(@(x) vertcat(Lc_all{contains(IDs, x, 'IgnoreCase',true)}), names, 'Un', 0);
F_all_s = cellfun(@(x) vertcat(F_all{contains(IDs, x, 'IgnoreCase',true)}), names, 'Un', 0);
% F_all_detoks_s = cellfun(@(x) vertcat(F_all_detoks{contains(IDs, x, 'IgnoreCase',true)}), names, 'Un', 0);
P_all_s = cellfun(@(x) vertcat(P_all{contains(IDs, x, 'IgnoreCase',true)}), names, 'Un', 0);
N_subjects = length(names);
idx_train = ~contains(names, {'lisa'});

%% Performance

% Gather all data flattened
scores = cellfun(@(x) vertcat(x{:}).walk, F_all_s, 'Un', 0);
pred_binary = cellfun(@(x) vertcat(x{:}), P_all_s, 'Un', 0);
labels = cellfun(@(x) vertcat(x{:}), L_all_s, 'Un', 0);

% Postprocess
N_T = 1000;
eps = 10^(-9);
T = linspace(min(cell2mat(scores'))+eps, max(cell2mat(scores'))-eps, N_T);

% Performance
perf_all = struct('accuracy', nan(N_T, N_subjects), 'specificity', nan(N_T, N_subjects), ...
    'precision', nan(N_T, N_subjects), 'recall', nan(N_T, N_subjects), 'F1', nan(N_T, N_subjects));
perf_event_all = struct('precision', nan(N_T, N_subjects), 'recall', nan(N_T, N_subjects), 'F1', nan(N_T, N_subjects));

for t = 1:N_T
    pred = cellfun(@(x) x > T(t), scores, 'Un', 0);
    pred_c = cellfun(@(x) imclose(x, ones(60 * fs / window_size + 1, 1)), pred, 'Un', 0);
    for i = 1:N_subjects
        perf = getPerf(labels{i}, pred_c{i});
        fnames = fieldnames(perf);
        for f = 1:length(fnames)
            perf_all.(fnames{f})(t, i) = perf.(fnames{f});
        end
        perf_event = get_ar_perf(sequence2ar(pred_c{i}, fs/window_size), sequence2ar(labels{i}, fs/window_size), 0);
        fnames = fieldnames(perf_event);
        for f = 1:length(fnames)
            perf_event_all.(fnames{f})(t, i) = perf_event.(fnames{f});
        end
    end
end

% Print perf for each subject
% Fixed prediction postprocessing T = 0.05, T_C = 60
% t = 15; c = 4;
% Get optimal threshold with T_C = 60
% c = 4;
[~,t] = max(mean(perf_all.F1(:, idx_train), 2));
% [f1_max, idx_t] = max(mean(perf_all.F1,3), [], 'all', 'linear');
% [t, c] = ind2sub(size(mean(perf_all.F1,3)), idx_t);

fprintf('\n');
fprintf('Optimal threshold: %.5f.\n', T(t));
fprintf('\n');

fnames = fieldnames(perf_all);

fprintf('\n');
fprintf(repmat('\t%s', 1, length(fnames)), fnames{:});
fprintf('\n');
fprintf('Overall');
for f = 1:length(fnames)
    fprintf('\t%.2f \x00B1 %.2f', mean(perf_all.(fnames{f})(t, idx_train)), std(perf_all.(fnames{f})(t, idx_train)));
end
fprintf('\n');
for i = 1:N_subjects
    fprintf('%s', names{i});
    for f = 1:length(fnames)
        fprintf('\t%.2f', perf_all.(fnames{f})(t,i))
    end
    fprintf('\n');
end

%% Performance good labels

pred_binary = cellfun(@(x) vertcat(x{:}), P_all_s, 'Un', 0);
labels_good = cellfun(@(x) vertcat(x{:}), Lc_all_s, 'Un', 0);

% Performance
perf_all = struct('accuracy', nan(N_subjects, 1), 'specificity', nan(N_subjects, 1), ...
    'precision', nan(N_subjects, 1), 'recall', nan(N_subjects, 1), 'F1', nan(N_subjects, 1));
perf_event_all = struct('precision', nan(N_subjects, 1), 'recall', nan(N_subjects, 1), 'F1', nan(N_subjects, 1));

for i = 1:N_subjects
    perf = getPerf(labels_good{i}, pred_binary{i});
    fnames = fieldnames(perf);
    for f = 1:length(fnames)
        perf_all.(fnames{f})(i) = perf.(fnames{f});
    end
    perf_event = get_ar_perf(sequence2ar(pred_binary{i}, fs), sequence2ar(labels_good{i}, fs), 0);
    fnames = fieldnames(perf_event);
    for f = 1:length(fnames)
        perf_event_all.(fnames{f})(i) = perf_event.(fnames{f});
    end
end

fnames = fieldnames(perf_all);
fprintf('\n');
fprintf(repmat('\t%s', 1, length(fnames)), fnames{:});
fprintf('\n');
fprintf('Overall');
for f = 1:length(fnames)
    fprintf('\t%.2f \x00B1 %.2f', mean(perf_all.(fnames{f}), 'omitnan'), std(perf_all.(fnames{f}), 'omitnan'));
end
fprintf('\n');
for i = 1:N_subjects
    fprintf('%s', names{i});
    for f = 1:length(fnames)
        fprintf('\t%.2f', perf_all.(fnames{f})(i))
    end
    fprintf('\n');
end

fnames = fieldnames(perf_event_all);
fprintf('\n');
fprintf(repmat('\t%s', 1, length(fnames)), fnames{:});
fprintf('\n');
fprintf('Overall');
for f = 1:length(fnames)
    fprintf('\t%.2f \x00B1 %.2f', mean(perf_event_all.(fnames{f})), std(perf_event_all.(fnames{f})));
end
fprintf('\n');
for i = 1:N_subjects
    fprintf('%s', names{i});
    for f = 1:length(fnames)
        fprintf('\t%.2f', perf_event_all.(fnames{f})(i))
    end
    fprintf('\n');
end

%% Walking bout metrics

% Boxplot function
col=@(x)reshape(x,numel(x),1);
boxplot2=@(C,varargin)boxplot(cell2mat(cellfun(col,col(C),'uni',0)),cell2mat(arrayfun(@(I)I*ones(numel(C{I}),1),col(1:numel(C)),'uni',0)),varargin{:});

B_all_s_c = cellfun(@(x) vertcat(x{:}), B_all_s, 'Un', 0);

arm_swing_amp_mean_all = cellfun(@(x) x.arm_swing_amplitude_mean, B_all_s_c, 'Un', 0);
arm_swing_amp_var_all = cellfun(@(x) x.arm_swing_amplitude_var, B_all_s_c, 'Un', 0);
cadence_mean_all = cellfun(@(x) x.cadence_mean, B_all_s_c, 'Un', 0);
cadence_var_all = cellfun(@(x) x.cadence_var, B_all_s_c, 'Un', 0);
dur_all = cellfun(@(x) x.dur, B_all_s_c, 'Un', 0);

% Inclusion:
% 1) Cadence walking & running: 60 - 199 steps per min
% 2) Duration: >= 60 seconds.
idx_include = arrayfun(@(x) dur_all{x} >= 60 & cadence_mean_all{x} > 1 & cadence_mean_all{x} < 200/60, 1:length(dur_all), 'Un', 0);

cadence_mean_all_i = arrayfun(@(x) 60*cadence_mean_all{x}(idx_include{x}), 1:length(dur_all), 'Un', 0);
cadence_var_all_i = arrayfun(@(x) 60*cadence_var_all{x}(idx_include{x}), 1:length(dur_all), 'Un', 0);
arm_swing_amp_mean_all_i = arrayfun(@(x) arm_swing_amp_mean_all{x}(idx_include{x}), 1:length(dur_all), 'Un', 0);
arm_swing_amp_var_all_i = arrayfun(@(x) arm_swing_amp_var_all{x}(idx_include{x}), 1:length(dur_all), 'Un', 0);

id_vector = arrayfun(@(x) x*ones(size(cadence_mean_all_i{x})), 1:length(names), 'Un', 0);
id_vector = vertcat(id_vector{:});

h = figure;
h.Position(3:4) = [1000 500];
centerfig(h);
% Cadence mean
subplot(2,2,1);
boxplot2(cadence_mean_all_i)
ylabel({'Within bout mean', 'Cadence [steps/min]'});
xlabel('Participants');
title('(a)');
grid minor

% Cadence var
subplot(2,2,2);
boxplot2(cadence_var_all_i)
ylabel({'Within bout std', 'Cadence [steps/min]'});
xlabel('Participants');
title('(b)');
grid minor

% Arm swing amp mean
subplot(2,2,3);
boxplot2(arm_swing_amp_mean_all_i)
ylabel({'Within bout mean', 'Arm Swing Amplitude [g]'});
xlabel('Participants');
title('(c)');
grid minor

% Arm swing amp var
subplot(2,2,4);
boxplot2(arm_swing_amp_var_all_i)
ylabel({'Within bout std', 'Arm Swing Amplitude [g]'});
xlabel('Participants');
title('(d)');
grid minor

set(gcf,'Color',[1 1 1]);
set( findall(h, '-property', 'fontsize'), 'fontsize', 10);
plot_name = 'C:\Users\andre\Dropbox\Phd\actigraphy_irbd\Scripts\figures\walking_data_plots\walking_bout_stats_all';
% export_fig(gcf, plot_name, '-m4', '-png', '-transparent');

%% Figures
% h = figure;
% h.Position(3:4) = [600 500];
% centerfig(h);
% ax1 = subplot(1,2,1);
% hold all
% for c = 1:N_TC
%     plot(mean(perf_event_all.recall(:,c,:), 3, 'omitnan'), mean(perf_event_all.precision(:,c,:), 3, 'omitnan'));
% end
% legend(arrayfun(@(x) sprintf('Remove/Combine Threshold = %.0f', x), T_close, 'Un', 0));
% title('Precision Recall Curve');
% xlabel('Recall')
% ylabel('Precision')
% ax2 = subplot(1,2,2);
% hold all
% for c = 1:N_TC
%     plot(T, mean(perf_event_all.F1(:,c,:), 3, 'omitnan'));
% end
% legend(arrayfun(@(x) sprintf('Remove/Combine Threshold = %.0f', x), T_close, 'Un', 0));
% title('F1 Curve');

% Colormap
cmap = copper(N_nacf);

h = figure;
h.Position(3:4) = [1200 500];
centerfig(h);
ax1 = subplot(1,2,1);
hold all
for c = 1:N_nacf
    plot(mean(perf_all.recall(:,c,:), 3), mean(perf_all.precision(:,c,:), 3), 'color', cmap(c,:));
end
% leg = legend(arrayfun(@(x) sprintf('T = %.0f', x), T_close, 'Un', 0));
% title(leg, 'Threshold for removing and combinding');
xlabel('Recall')
ylabel('Precision')
grid minor
axis([0 1 0 1]);
ax2 = subplot(1,2,2);
hold all
for c = 1:N_nacf
    plot(T, mean(perf_all.F1(:,c,:), 3), 'color', cmap(c,:));
end
leg = legend(arrayfun(@(x) sprintf('T = %.0f', x), T_nacf, 'Un', 0));
title(leg, 'Threshold for removing and combinding');
ylabel('F1 Score');
xlabel('Threshold');
grid minor
ylim([0 1]);
set(gcf,'Color',[1 1 1]);
set( findall(h, '-property', 'fontsize'), 'fontsize', 10);
plot_name = 'C:\Users\andre\Dropbox\Phd\actigraphy_irbd\Scripts\figures\walking_data_plots\pr_curve_windows';
% export_fig(gcf, plot_name, '-m4', '-png', '-transparent');


% h = figure;
% h.Position(3:4) = [1000 500];
% centerfig(h);
% hold all
% for c = 1:N_TC
%     plot(1 - mean(perf_all.specificity(:,c,:), 3), mean(perf_all.recall(:,c,:), 3));
% end
% legend(arrayfun(@(x) sprintf('Remove/Combine Threshold = %.0f', x), T_close, 'Un', 0));
% title('Walk window scoring');
