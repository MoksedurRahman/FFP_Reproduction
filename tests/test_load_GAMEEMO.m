%% Test GAMEEMO MAT-file loading

clear;
clc;

%% File path

file = fullfile( ...
    'data', ...
    'GAMEEMO', ...
    '(S01)', ...
    'Preprocessed EEG Data', ...
    '.mat format', ...
    'S01G1AllChannels.mat');

%% Check that file exists

if ~isfile(file)
    error('MAT file not found:\n%s', file);
end

fprintf('MAT file found:\n%s\n\n', file);

%% Display variables stored in MAT file

whos('-file', file);

%% Load MAT file

data = load(file);

%% Display loaded variables

disp('Variables loaded from MAT file:');
disp(data);