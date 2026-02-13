%% Example Demo
%  For long free-living condition recordings.
%  Andreas Brink-Kjaer, PhD
%  6th of February, 2026
%  
%  This will save
%  (1) a csv per file with all detected walking bouts with associated
%  walking metrics in data/actigraphy/walking_bouts.
%  (2) a csv feature files across all data in "path_feat" defined below.

% Default arguments (should not be changed)
startup;
DirIndex = paths;
config = Config;
fs = 25; % Should not be changed (it determines resampling)

% Define input arguments
path_to_actigraphy = '';
extension_actigraphy = 'cwa';
path_feat = '';
data_subjects = dir(filepath(path_to_actigraphy, ['*.' extension_actigraphy]));
writeAccFeatGaitRBD(path_feat, data_subjects, fs, config);