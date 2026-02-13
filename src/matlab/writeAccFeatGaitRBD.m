function writeAccFeatGaitRBD(path_feat, data_subjects, fs, config)
%WRITEACCFEATGAITRBD extracts gait features for actigraphy data.
%   WRITEACCFEATGAITRBD(path_feat, data_subjects, fs)
%   This function iteratively reads data, runs the walking detector,
%   characterizes ambulatory bouts, and saves these in a table. The
%   function also saves the time of each detected walking bout according
%   the config file location.
%
%   Author: Andreas Brink-Kjaer.
%   Date: 10. April 2024
%
%   Input:  path_feat, path to save features as a csv file
%           data_subjects, list of files using the "dir" function
%           fs, sampling frequency [25]
%           config, config variable

% Default arguments
if ~exist('fs','var')
    fs = 25;
end

% Cell array for each subject
N_subjects = size(data_subjects,1);
F_subjects = cell(N_subjects, 1); 
IDs = cell(N_subjects, 1);

% Sampling frequency & hyperparameters
epoch_size = fs;
window_size = fs*10;
Hd = hp_filter_acc(fs);

% Pre-allocate result variables
N_feat = 23;
F_days = nan(N_subjects, 1);
F_walking = nan(N_subjects, N_feat);
F_jogging = nan(N_subjects, N_feat);

% Check input data subjects style (flat or folders)
if all(endsWith({data_subjects.name}, '.csv', 'IgnoreCase', true))
    opt_ds = 'capture24';
elseif all(endsWith({data_subjects.name}, '.cwa', 'IgnoreCase', true))
    opt_ds = 'files';
elseif all(~endsWith({data_subjects.name}, '.cwa', 'IgnoreCase', true))
    opt_ds = 'folders';
else
    error('data subjects argument should either list folder containing files or the files themselves.');
end

% Iterate subjects
for i = 1:N_subjects
    fprintf('Subject %.0f/%.0f\n', i, N_subjects);

    % Get nights of subject
    path_i = filepath(data_subjects(i).folder, data_subjects(i).name);
    
    % Get ID
    [~, ID, ~] = fileparts(path_i);
    IDs{i} = ID;
    
    % CWA file
    if strcmp(opt_ds, 'folders')
        cwa_i = dir(filepath(path_i, '*.cwa'));
    elseif strcmp(opt_ds, 'files') || strcmp(opt_ds, 'capture24')
        cwa_i = path_i;
    end
    
    % Check if CWA file exists
    if ~isempty(cwa_i)
        
        % Get file
        if strcmp(opt_ds, 'folders')
            file_i = filepath(cwa_i(1).folder, cwa_i(1).name);
        elseif strcmp(opt_ds, 'files') || strcmp(opt_ds, 'capture24')
            file_i = path_i;
        end
        
        % Read data
        if strcmp(opt_ds, 'folders') || strcmp(opt_ds, 'files')
            cwa_raw_i = CWA_readFile(file_i, 'info', 1);
            start_i = cwa_raw_i.start.mtime;
            stop_i = cwa_raw_i.stop.mtime;
        elseif strcmp(opt_ds, 'capture24')
            csv_raw_i = readtable(file_i);
            start_i = datenum(csv_raw_i.time(1));
            stop_i = datenum(csv_raw_i.time(end));
        end
        
        % Split into "days"
        [t_start, t_stop] = split_time_days(start_i, stop_i, [22/24, 0, 3/24]);
        if isempty(t_start)
            continue;
        end
        if t_start(1) ~= start_i
            t_stop = [t_start(1); t_stop];
            t_start = [start_i; t_start];
        end
        if t_stop(end) ~= stop_i
            t_start = [t_start; t_stop(end)];
            t_stop = [t_stop; stop_i];
        end
        N_nights = size(t_start, 1);
        
    else
        fprintf('%s skipped due to missing actigraphy data.\n', ID);
        continue;
    end

    % Result var
    F_i = cell(N_nights, 1);
    WB_i = cell(N_nights, 1);
    
    % Iterate each "day" in each file (insert parfor for higher efficiency)
    for j = 1:N_nights
        
        % Path to data for night j
        try
            if strcmp(opt_ds, 'folders') || strcmp(opt_ds, 'files')
                data_raw = CWA_readFile(file_i, 'packetInfo', cwa_raw_i.packetInfo, 'startTime', t_start(j), 'stopTime', t_stop(j), 'modality', [1 1 1]);
            elseif strcmp(opt_ds, 'capture24')
                data_raw = format_csv_as_cwa(csv_raw_i, t_start(j), t_stop(j));
            end
        catch me
            disp([num2str(me.stack(1).line), ': ', me.message]);
            continue
        end
        data = format_cwa_data(data_raw, fs);
        start_time = datetime(data.t(1), 'ConvertFrom', 'datenum');

        % Get resultant
        acti_counts = sqrt(sum(data.acc.^2, 2)) - 1;
        acti_counts = filtfilt(Hd.sosMatrix, Hd.ScaleValues, acti_counts);
        M = floor(length(acti_counts)/(epoch_size/fs));
        t_acti = data.t(1:(fs/epoch_size):M);

        % Get non-wear
        wear_time_hours = sum(~double(acti_nonwear(data.acc, fs)))/2;
        
        try
            % Walking detector
            [F_j, WB_j, ~] = run_walking_detector(acti_counts, data.acc, fs, t_acti);
            
            % Add results
            F_j.wear_time = ones(size(F_j, 1), 1) * wear_time_hours;
            
            % Add day
            F_j.day_count = j * ones(size(F_j, 1), 1);
            
            % Get WB as events
            wb_events = sequence2ar(WB_j);
            if ~isempty(wb_events)
                wb_events = datetime(t_acti(1 + wb_events.range)', 'ConvertFrom', 'datenum');
            end

            % Store results
            F_i{j} = F_j;
            WB_i{j} = wb_events;
            
        catch me
            disp([num2str(me.stack(1).line), ': ', me.message]);
        end
        
    end
    
    % Process stats
    F_i_c = vertcat(F_i{:});
    WB_i_c = vertcat(WB_i{:});
    
    % Export walking bouts to file
    if ~isempty(WB_i_c)
        T_WB_i = array2table(WB_i_c);
        T_WB_i.Properties.VariableNames = {'Start', 'End'};
        T_WB_i.Duration = seconds(T_WB_i.End - T_WB_i.Start);
        T_WB_i = [T_WB_i, F_i_c(:, ismember(F_i_c.Properties.VariableNames, ...
            {'arm_swing_amplitude_mean', 'arm_swing_amplitude_var', ...
                  'cadence_mean', 'cadence_var', 'cadence_p_var', 'jerks_mean', ...
                  'jerks_var', 'jerks_p_var', 'x_amp_mean', 'x_amp_var', ...
                'y_amp_mean', 'y_amp_var', 'z_amp_mean', 'z_amp_var'}))];
        writetable(T_WB_i, filepath(config.walking_bouts, [ID '.csv']));
    end
    
    % Indexing for behavior
    idx_wear = F_i_c.wear_time > 12;
    idx_walking = F_i_c.dur >= 30 & F_i_c.cadence_mean > 1 & F_i_c.cadence_mean < 120/60 & idx_wear;
    idx_jogging = F_i_c.dur >= 30 & F_i_c.cadence_mean > 120/60 & F_i_c.cadence_mean < 200/60 & idx_wear;
    
    n_days = length(unique(F_i_c.day_count(idx_wear)));
    F_days(i) = n_days;
    
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

% Aggregate all results
F_days_c = array2table(F_days);
F_days_c.Properties.VariableNames = {'n_days'};

F_walking_c = array2table(F_walking);
F_walking_c.Properties.VariableNames = cellfun(@(x) [x '_w'], F_i_c.Properties.VariableNames(1:end-2), 'Un', 0);

F_jogging_c = array2table(F_jogging);
F_jogging_c.Properties.VariableNames = cellfun(@(x) [x '_j'], F_i_c.Properties.VariableNames(1:end-2), 'Un', 0);

F_all_c = [F_days_c, F_walking_c, F_jogging_c];
F_all_c.ID = IDs;

% Save all results
writetable(F_all_c, path_feat);
