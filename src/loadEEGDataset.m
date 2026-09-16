function [signals, labels] = loadEEGDataset(dataFolder)
% loadEEGDataset
%
% Diagnostic GAMEEMO MAT-file loader.
%
% This function currently inspects the MAT files and reports
% their contents. We will finalise the data extraction after
% inspecting the actual MAT-file structure.
%
% Input:
%   dataFolder - folder containing GAMEEMO MAT files
%
% Output:
%   signals - EEG data
%   labels  - class labels

    %% Check folder

    if ~isfolder(dataFolder)
        error('Data folder does not exist:\n%s', dataFolder);
    end

    %% Find MAT files

    files = dir(fullfile(dataFolder, '*.mat'));

    if isempty(files)
        error('No MAT files found in:\n%s', dataFolder);
    end

    fprintf('\nFound %d MAT files.\n\n', numel(files));

    %% Display files

    for k = 1:numel(files)

        fprintf('File %d: %s\n', k, files(k).name);

        filePath = fullfile(files(k).folder, files(k).name);

        fprintf('Variables contained in this file:\n');

        whos('-file', filePath);

        fprintf('\n');

    end

    %% Stop here for structural inspection

    signals = [];
    labels = [];

    error(['Dataset structure inspection completed. ' ...
           'We now need to inspect one MAT file before implementing ' ...
           'the final loader.']);

end