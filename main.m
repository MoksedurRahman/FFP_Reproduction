clc;
clear;
close all;

%% Paths

addpath(genpath('src'));

%% Dataset path

dataFolder = fullfile( ...
    'data', ...
    'GAMEEMO', ...
    '(S01)', ...
    'Preprocessed EEG Data', ...
    '.mat format');

%% Check folder

if ~isfolder(dataFolder)
    error('Data folder does not exist:\n%s', dataFolder);
end

%% Find MAT files

files = dir(fullfile(dataFolder, '*.mat'));

fprintf('============================================\n');
fprintf('GAMEEMO MAT FILE INSPECTION\n');
fprintf('============================================\n\n');

fprintf('Folder:\n%s\n\n', dataFolder);

fprintf('Number of MAT files: %d\n\n', numel(files));

%% Inspect every MAT file

for k = 1:numel(files)

    filePath = fullfile(files(k).folder, files(k).name);

    fprintf('--------------------------------------------\n');
    fprintf('File %d: %s\n', k, files(k).name);
    fprintf('--------------------------------------------\n');

    info = whos('-file', filePath);

    for v = 1:numel(info)

        fprintf('Variable: %s\n', info(v).name);
        fprintf('Size:     ');

        fprintf('%d ', info(v).size);

        fprintf('\n');

        fprintf('Class:    %s\n', info(v).class);
        fprintf('Bytes:    %d\n\n', info(v).bytes);

    end

end

fprintf('============================================\n');
fprintf('Inspection completed.\n');
fprintf('============================================\n');