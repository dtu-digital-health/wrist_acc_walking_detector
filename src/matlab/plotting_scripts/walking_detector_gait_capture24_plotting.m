%% Plotting Walking Detection & Gait Features Capture24 Examples
%  Andreas Brink-Kjaer, PhD
%  25/08/2025

clear all; close all;
startup;

% Color definition
colors = [[0, 0.4470, 0.7410];
    [0.8500, 0.3250, 0.0980];
    [0.9290, 0.6940, 0.1250];
    [0.4940, 0.1840, 0.5560];
    [0.4660, 0.6740, 0.1880]];

%% Set paths

p_actigraphy = "H:\capture24\raw_csv_files\P001.csv";
p_annotation_dict = "C:\Users\andre\Dropbox\PostDoc\RBD_actigraphy\Gait\npjJP\Updated Capture 24 Annotation Categories (1).xlsx";

%% Read data

actigraphy = readtable(p_actigraphy);
annotation_table = readtable(p_annotation_dict);

%% Compute annotations

annotation_dict = dictionary(string(annotation_table.annotation), annotation_table.UpdatedCategories);
annotation_dict("") = {'missing'};
walking_annotation = annotation_dict(actigraphy.annotation);
walking_annotation = 2 * strcmp(walking_annotation, 'walking') + 1 * strcmp(walking_annotation, 'walking+activity');
walking_annotation(strcmp(walking_annotation, 'missing')) = nan;

%% Resample to 25 Hz
fs = 25;
epoch_size = fs;
window_size = fs*10;

% Annotations
walking_annotation = walking_annotation(1:4:end);

% Actigraphy
data_raw = format_csv_as_cwa(actigraphy(:, 1:4), datenum(actigraphy.time(1)), datenum(actigraphy.time(end)));
data = format_cwa_data(data_raw, fs);
start_time = datetime(data.t(1), 'ConvertFrom', 'datenum');

%% Compute Resultant
Hd = hp_filter_acc(fs);
acti_counts = sqrt(sum(data.acc.^2, 2)) - 1;
acti_counts = filtfilt(Hd.sosMatrix, Hd.ScaleValues, acti_counts);
M = floor(length(acti_counts)/(epoch_size/fs));
t_acti = data.t(1:(fs/epoch_size):M);

%% Walking Detection
[F, WB, WS] = run_walking_detector(acti_counts, data.acc, fs, t_acti);
            
% Get WB as events
wb_events = sequence2ar(WB);
if ~isempty(wb_events)
    wb_events = datetime(t_acti(1 + wb_events.range)', 'ConvertFrom', 'datenum');
end

%% Detection plot

t_start = datetime(t_acti(1), 'ConvertFrom', 'datenum');
t_end = datetime(t_acti(end), 'ConvertFrom', 'datenum');
% t_zoom_start = datetime(floor(t_acti(1)) + 11/24 + 48/60/24, 'ConvertFrom', 'datenum');
% t_zoom_end = datetime(floor(t_acti(1)) + 11/24 + 52/60/24, 'ConvertFrom', 'datenum');
t_zoom_start = datetime(floor(t_acti(1)) + 12/24 + 59/60/24, 'ConvertFrom', 'datenum');
t_zoom_end = datetime(floor(t_acti(1)) + 13/24 + 7/60/24, 'ConvertFrom', 'datenum');
use_zoom = true;
walk_b_nan = 1.0 * WS.walk_b;
walk_b_nan(walk_b_nan == 0) = nan;

h = figure;
h.Position(3:4) = [1000 600];
centerfig(h);
ax1 = subplot(4,1,1);
plot(datetime(data.t, 'ConvertFrom', 'datenum'), walking_annotation, '-k')
set(gca, 'XTickLabel', {});
set(gca, 'YTick', [0 1 2]);
set(gca, 'YTickLabel', {'other', 'walking + activity', 'walking'});
ylim([-0.5 2.5]);
% ylabel('Annotations')
% xlabel('Time')
title('Ground Truth')
grid minor
% legend({'Annotations'}, 'Location', 'northeast')
ax2 = subplot(4,1,2);
hold on
stairs(datetime(t_acti(1:window_size:end-1), 'ConvertFrom', 'datenum'), WS.walk, 'Color', [0.5 0.5 0.5]);
walk_b_plot = stairs(datetime(t_acti(1:window_size:end-1), 'ConvertFrom', 'datenum'), walk_b_nan .* WS.walk, '-k', 'LineWidth', 2);
box on;
set(gca, 'XTickLabel', {});
ylabel('Walking Score')
title('Detected Walking')
% xlabel('Time')
% ylim([0 0.173 * 2])
% legend(walk_b_plot, {'Detected Walking Bouts'}, 'Location', 'northeast')
grid minor
ax3 = subplot(4,1,3);
plot(datetime(data.t, 'ConvertFrom', 'datenum'), acti_counts, '-k')
set(gca, 'XTickLabel', {});
% xlabel('Time')
ylabel('[g]')
grid minor
title('Resultant')
ax4 = subplot(4,1,4);
plot(datetime(data.t, 'ConvertFrom', 'datenum'), data.acc)
xlabel('Time')
ylabel('[g]')
grid minor
% legend({'x', 'y', 'z'}, 'Location', 'north', 'NumColumns', 3)
title('Acceleration (x, y, z)')
linkaxes([ax1 ax2 ax3 ax4],'x')
if use_zoom
    xlim([t_zoom_start, t_zoom_end]);
else
    xlim([t_start, t_end]);
end
xtick_dates = get(gca,'XTick');
xtick_dates.Format = 'HH:mm';
set(gca,'XTickLabelMode', 'manual');
% set(gca, 'XTickLabel', xtick_dates);
set(gcf,'Color',[1 1 1]);
set( findall(h, '-property', 'fontsize'), 'fontsize', 12);
if use_zoom
    export_fig(gcf, 'C:\Users\andre\Dropbox\Phd\actigraphy_irbd\Scripts\figures\walking_data_plots\plotv2_capture24_zoom', '-m4', '-png', '-transparent');
else
    % export_fig(gcf, 'C:\Users\andre\Dropbox\Phd\actigraphy_irbd\Scripts\figures\walking_data_plots\plotv2_capture24_pred', '-pdf', '-transparent');
end

%% Gait Features

% Zoom time
% t_zoom_start = datetime(floor(t_acti(1)) + 11/24 + 48/60/24 + 40/60/60/24, 'ConvertFrom', 'datenum');
% t_zoom_end = datetime(floor(t_acti(1)) + 11/24 + 48/60/24 + 50/60/60/24, 'ConvertFrom', 'datenum');
t_zoom_start = datetime(floor(t_acti(1)) + 13/24 + 1/60/24 + 0/60/60/24, 'ConvertFrom', 'datenum');
t_zoom_end = datetime(floor(t_acti(1)) + 13/24 + 1/60/24 + 10/60/60/24, 'ConvertFrom', 'datenum');
idx_1 = find(datetime(t_acti, 'ConvertFrom', 'datenum') > t_zoom_start, 1, 'first');
idx_2 = find(datetime(t_acti, 'ConvertFrom', 'datenum') < t_zoom_end, 1, 'last');

% Get window
t_zoom = data.t(idx_1:idx_2);
acti_counts_zoom = acti_counts(idx_1:idx_2);

% Min lag (max cadence = 200 steps per min = 0.3 sec per step)
min_lag = ceil(fs * 0.3);

% Autocorrelation
[normalizedACF, ~] = autocorr(acti_counts_zoom, 'NumLags', fs * 4);

% FFT of autocorrelation
% Find dominant frequency
y = fftshift(fft(normalizedACF, 2^10)); % y = fftshift(fft(normalizedACF));
n = 2^10; % n = length(normalizedACF);
fy = (-n/2:n/2-1)*(fs/n);
py = abs(y(fy >=0)).^2/n;
fy = fy(fy >= 0);
[dominant_amp, dominant_lag] = max(py);
dominant_freq = fy(dominant_lag);

% Find peak
ACF_max = max(normalizedACF(min_lag:end));

% Signal Power
acti_power = mean(acti_counts_zoom.^2);

% Find cadence (do not multiply with 2 as only the top part signals
% acceleration both forward and backwards).
cadence = dominant_freq;

% Find step peaks
[step_pks_pos, step_idx_pos] = findpeaks(acti_counts_zoom, fs, 'MinPeakDistance', 1 / dominant_freq * 0.75);
[step_pks_neg, step_idx_neg] = findpeaks(-acti_counts_zoom, fs, 'MinPeakDistance', 1 / dominant_freq * 0.75);

% Cadence var
cadence_std = std(1 ./ diff(step_idx_pos));

% Jerks
step_idx_pos_sample = round(step_idx_pos*fs) + 1;
step_idx_neg_sample = round(step_idx_neg*fs) + 1;
step_acti_counts = arrayfun(@(x) acti_counts_zoom(step_idx_pos_sample(x):step_idx_pos_sample(x+1)), 1:length(step_idx_pos_sample)-1, 'Un', 0);
step_jerks = (cellfun(@(x) sum(abs(diff(sign(diff(x)))) == 2), step_acti_counts) - 1) / 2;
jerks_mean = mean(step_jerks);
jerks_std = std(step_jerks);

% arm swing amplitude
arm_swing_amplitude = median(step_pks_pos) - median(-step_pks_neg);

% Plot
h = figure;
h.Position(3:4) = [1000 400];
centerfig(h);
ax1 = subplot(1,4,1:3);
hold on
plot(datetime(t_zoom(step_idx_pos_sample), 'ConvertFrom', 'datenum'), acti_counts_zoom(step_idx_pos_sample), 'x', 'Color', colors(2,:))
plot(datetime(t_zoom(step_idx_neg_sample), 'ConvertFrom', 'datenum'), acti_counts_zoom(step_idx_neg_sample), 'x', 'Color', colors(1,:))
plot(datetime(t_zoom([1 end]), 'ConvertFrom', 'datenum'), median(step_pks_pos) * [1 1], '--', 'Color', colors(2,:));
plot(datetime(t_zoom([1 end]), 'ConvertFrom', 'datenum'), median(-step_pks_neg) * [1 1], '--', 'Color', colors(1,:));
plot(datetime(t_zoom, 'ConvertFrom', 'datenum'), acti_counts_zoom, '-k')
text(datetime((t_zoom(step_idx_pos_sample(2:end)) - t_zoom(step_idx_pos_sample(1:end - 1)))/2 + t_zoom(step_idx_pos_sample(1:end - 1)), 'ConvertFrom', 'datenum'), ...
    acti_counts_zoom(step_idx_pos_sample(2:end)) + 0.1, arrayfun(@(x) num2str(x), step_jerks, 'Un', 0), 'HorizontalAlignment', 'center');
% set(gca, 'XTickLabel', {});
xlabel('Time')
ylabel('[g]')
grid minor
ylim_ax1 = get(gca, 'YLim');
ylim([ylim_ax1(1), ylim_ax1(2) + 0.1])
xtick_dates = get(gca,'XTick');
xtick_dates.Format = 'HH:mm';
set(gca,'XTickLabelMode', 'manual');
ax2 = subplot(1,4,4);
hold on
plot(fy, py, 'k');
[dominant_amp, dominant_lag] = max(py);
dominant_freq = fy(dominant_lag);
text(dominant_freq, dominant_amp * 1.05, [num2str(dominant_freq * 60, 3) ' steps/min']);
xlabel('Frequency [Hz]')
ylabel('g^2/Hz')
grid minor
box off
% linkaxes([ax1 ax2],'x')
set(gcf,'Color',[1 1 1]);
set( findall(h, '-property', 'fontsize'), 'fontsize', 12);
export_fig(gcf, 'C:\Users\andre\Dropbox\Phd\actigraphy_irbd\Scripts\figures\walking_data_plots\gait_analysis_figure_v2', '-m4', '-png', '-transparent');

