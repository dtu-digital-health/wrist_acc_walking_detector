function config = Config(DirIndex)
%CONFIG sets paths for relevant files and paths.
%   config = CONFIG() sets relevant paths.
%
%   Author: Andreas Brink-Kjaer.
%   Date: 24-Oct-2022
%
%   Input:  dirIndex, a struct containing directories of commonly used
%           folders
%   Output: config, a struct containing most relevant paths for data
%   anaylsis


pthConfig = struct;

% Base paths
pthConfig.base = DirIndex.base;
pthConfig.matlabCode = DirIndex.matlabCode;
pthConfig.Data = DirIndex.Data;
pthConfig.CWA = DirIndex.CWA;

% Declare annotation paths
pthConfig.hypnograms = filepath(DirIndex.CWA, 'Hypnograms vs actigrams');
pthConfig.auto_sleep = filepath(DirIndex.CWA, 'auto_sleep');
pthConfig.annotation_path_bbacca = filepath(pthConfig.auto_sleep, 'bbacca');
pthConfig.annotation_path_manual = filepath(DirIndex.CWA, 'agg_manual_anns_may19.csv');
pthConfig.walking_bouts = filepath(DirIndex.CWA, 'walking_bouts');

% Read annotations bbacca
pthConfig.annotation_path_bbacca = filepath(pthConfig.auto_sleep, 'bbacca');
p_bbacca = dir(filepath(pthConfig.annotation_path_bbacca, '*-timeSeries.csv.gz'));
pthConfig.f_bbacca = {p_bbacca.name};
pthConfig.f_bbacca_csv = cellfun(@(x) x(1:end-3),pthConfig. f_bbacca, 'Un', 0);

% Read annotation borazio
pthConfig.annotation_path_borazio = filepath(pthConfig.auto_sleep, 'borazio');
p_borazio = dir(filepath(pthConfig.annotation_path_borazio, '*.sleep.csv'));
pthConfig.f_borazio = {p_borazio.name};

% Read annotations webster
pthConfig.annotation_path_webster = filepath(pthConfig.auto_sleep, 'webster');

% Read annotations cole
pthConfig.annotation_path_cole = filepath(pthConfig.auto_sleep, 'cole');

% Read annotations abk
pthConfig.annotation_path_abk = filepath(pthConfig.auto_sleep, 'abk');
p_abk = dir(filepath(pthConfig.annotation_path_abk, '*.csv'));
pthConfig.f_abk = {p_abk.name};

% Read annotations abk60
pthConfig.annotation_path_abk60 = filepath(pthConfig.auto_sleep, 'abk60');
p_abk60 = dir(filepath(pthConfig.annotation_path_abk60, '*.csv'));
pthConfig.f_abk60 = {p_abk60.name};

config = pthConfig;

end