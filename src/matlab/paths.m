function [dirIndex, profile] = paths()
%PATHS add required paths and file directories.
%   [dirIndex, profile] = PATHS() add paths to functions used.
%
%   Author: Andreas Brink-Kjaer.
%   Date: 24-Oct-2022
%
%   Input:  None
%   Output: dirIndex, a struct containing directories of commonly used
%           folders
%           profile, the used computing profile, e.g. local or sherlock
%           server.

persistent pthDirIndex pthProfile;

if isempty(pthDirIndex) || isempty(pthProfile)
    
    pthDirIndex = struct;
    
    if ~exist('profile', 'var')
        if exist('../profile', 'file')
            pthProfile = cellstr(fileread('../profile'));
        else
            pthProfile = 'abk';
        end
    end
    if ismember('new', pthProfile)
        pathtofile = mfilename('fullpath');
        pthDirIndex.base = pathtofile(1:end-16);
        pthDirIndex.matlabCode = [pthDirIndex.base '\src\matlab\'];
        pthDirIndex.Data = [pthDirIndex.base 'data\results\'];
        pthDirIndex.CWA = [pthDirIndex.base 'data\actigraphy\'];
        
    elseif ismember('abk', pthProfile)
        pthDirIndex.base = 'C:\Users\andre\Dropbox\Phd\actigraphy_irbd\Scripts\';
        pthDirIndex.matlabCode = 'C:\Users\andre\Dropbox\Phd\actigraphy_irbd\Scripts\matlab\';
        pthDirIndex.Data = [pthDirIndex.base 'data\'];
        pthDirIndex.CWA = 'G:\stanford_actigraphy_irbd\actigraphy_data_preprocessed';
        
    elseif ismember('sherlock', pthProfile)
        pthDirIndex.base = '';
        pthDirIndex.matlabCode = '';
        pthDirIndex.Data = '';
        pthDirIndex.CWA = '';
        error('Profile not implemented.');
        
    else
        error('Profile not found.');
    end
    
    % Add paths
    addpath(genpath(filepath(pthDirIndex.matlabCode, 'acc_process')));
    addpath(genpath(filepath(pthDirIndex.matlabCode, 'analysis')));
    addpath(genpath(filepath(pthDirIndex.matlabCode, 'export_fig')));
    addpath(genpath(filepath(pthDirIndex.matlabCode, 'data_read')));
    addpath(genpath(filepath(pthDirIndex.matlabCode, 'features')));
    addpath(genpath(filepath(pthDirIndex.matlabCode, 'icp')));
    addpath(genpath(filepath(pthDirIndex.matlabCode, 'utils')));
    
end

dirIndex = pthDirIndex;
profile = pthProfile;