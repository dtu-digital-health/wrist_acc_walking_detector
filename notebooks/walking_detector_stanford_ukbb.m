%% Gait Analysis of UKBB and Stanford Sleep Clinic Data
%   This script iteratively reads data, runs the walking detector,
%   characterizes ambulatory bouts, and saves these in a table.
%
%   Author: Andreas Brink-Kjaer.
%   Date: 14. August 2023

clear all; close all;
startup;

%% Initialize paths

% Declare paths
path_feat = 'C:\Users\andre\Dropbox\Phd\actigraphy_irbd\Scripts\data\F_subjects_gait.csv';
data_case = dir(filepath(dirIndex.CWA, 'case', 'AX*'));
data_control = dir(filepath(dirIndex.CWA, 'control', 'AX*'));
data_control_ukbb = dir(filepath(dirIndex.CWA, 'control_biobank', '*_0_0'));
data_subjects = [data_case; vertcat(data_control, data_control_ukbb)];

% Cell array for each subject
IDs = {data_subjects.name};
N_subjects = size(data_subjects,1);
F_subjects = cell(N_subjects, 1); 

% Sampling frequency & hyperparameters
fs = 25;
epoch_size = fs;
window_size = fs*10;
Hd = hp_filter_acc(fs);

%% Pre-allocate result variables
N_feat = 17;
F_walking = nan(N_subjects, N_feat);
F_jogging = nan(N_subjects, N_feat);
hours_data = nan(N_subjects, 1);
days_worn = nan(N_subjects, 1);

%% Iterate data

% Iterate subjects
for i = 1:N_subjects
    fprintf('Subject %.0f/%.0f\n', i, N_subjects);

    % Get nights of subject
    ID = IDs{i};
    path_i = filepath(data_subjects(i).folder, ID);
    cwa_i = dir(filepath(path_i, '*.cwa'));
    
    % Check if CWA file exists
    if ~isempty(cwa_i)
        
        % Read data info
        file_i = filepath(cwa_i(1).folder, cwa_i(1).name);
        cwa_raw_i = CWA_readFile(file_i, 'info', 1);
        
        % Split into "days"
        [t_start, t_stop] = split_time_days(cwa_raw_i.start.mtime, cwa_raw_i.stop.mtime, [22/24, 0, 3/24]);
        if isempty(t_start)
            continue;
        end
        if t_start(1) ~= cwa_raw_i.start.mtime
            t_stop = [t_start(1); t_stop];
            t_start = [cwa_raw_i.start.mtime; t_start];
        end
        if t_stop(end) ~= cwa_raw_i.stop.mtime
            t_start = [t_start; t_stop(end)];
            t_stop = [t_stop; cwa_raw_i.stop.mtime];
        end
        N_nights = size(t_start, 1);
        
    else
        fprintf('%s skipped due to missing actigraphy data.\n', ID);
        continue;
    end

    % Result var
    F_i = cell(N_nights, 1);
    hours_data_i = nan(N_nights, 1);
    days_worn_i = nan(N_nights, 1);
    
    % Iterate each "day" in each file
    parfor j = 1:N_nights
        
        % Path to data for night j
        data_raw = CWA_readFile(file_i, 'packetInfo', cwa_raw_i.packetInfo, 'startTime', t_start(j), 'stopTime', t_stop(j), 'modality', [1 1 1]);
        data = format_cwa_data(data_raw, fs);
        start_time = datetime(data.t(1), 'ConvertFrom', 'datenum');

        % Get resultant
        acti_counts = sqrt(sum(data.acc.^2, 2)) - 1;
        acti_counts = filtfilt(Hd.sosMatrix, Hd.ScaleValues, acti_counts);
        M = floor(length(acti_counts)/(epoch_size/fs));
        t_acti = data.t(1:(fs/epoch_size):M);

        % Get non-wear
        wear_time_hours = sum(~double(acti_nonwear(data.acc, fs)))/2;
        hours_data_i(j) = 24*(t_acti(end) - t_acti(1))
        days_worn_i(j) = wear_time_hours;
        
        try
            % Walking detector
            [F_j, WB, WS] = run_walking_detector(acti_counts, fs, t_acti);
            
            % Add results
            F_j.wear_time = ones(size(F_j, 1), 1) * wear_time_hours;
            
            % Add day
            F_j.day_count = j * ones(size(F_j, 1), 1);

            % Store results
            F_i{j} = F_j;
            
        catch me
            disp([num2str(me.stack(1).line), ': ', me.message]);
        end
        
    end
    
    % Hours of data
    hours_data(i) = sum(hours_data_i, 'omitnan');
    days_worn(i) = sum(days_worn_i > 12, 'omitnan');
    
    % Process stats
    F_i_c = vertcat(F_i{:});
    
    % Indexing for behavior
    idx_wear = F_i_c.wear_time > 12;
    idx_walking = F_i_c.dur >= 30 & F_i_c.cadence_mean > 1 & F_i_c.cadence_mean < 120/60 & idx_wear;
    idx_jogging = F_i_c.dur >= 30 & F_i_c.cadence_mean > 120/60 & F_i_c.cadence_mean < 200/60 & idx_wear;
    
    n_days = length(unique(F_i_c.day_count(idx_wear)));
    
    % Walking features
    if sum(idx_walking) > 0
        F_i_c_w = F_i_c(idx_walking, :);
        dur_w = sum(F_i_c_w.dur);
        F_i_c_w_summary = F_i_c_w.dur' * F_i_c_w{:, 2:end-2} / dur_w';
        
        % Store results
        F_walking(i, :) = [dur_w / n_days, F_i_c_w_summary];
    else
        F_walking(i, 1) = 0;
    end
    
    % Running features
    if sum(idx_jogging) > 0
        F_i_c_j = F_i_c(idx_jogging, :);
        dur_j = sum(F_i_c_j.dur);
        F_i_c_j_summary = F_i_c_j.dur' * F_i_c_j{:, 2:end-2} / dur_j';
        
        % Store results
        F_jogging(i, :) = [dur_j / n_days, F_i_c_j_summary];
    else
        F_jogging(i, 1) = 0;
    end
end

%% Aggregate all results

F_walking_c = array2table(F_walking);
F_walking_c.Properties.VariableNames = cellfun(@(x) [x '_w'], F_i_c_w.Properties.VariableNames(1:end-2), 'Un', 0);

F_jogging_c = array2table(F_jogging);
F_jogging_c.Properties.VariableNames = cellfun(@(x) [x '_j'], F_i_c_w.Properties.VariableNames(1:end-2), 'Un', 0);

F_all_c = [F_walking_c, F_jogging_c];
F_all_c.ID = IDs';

% Save all results
% writetable(F_all_c, path_feat);
