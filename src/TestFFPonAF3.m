clc;
clear;
close all;

%% Load EEG

filePath = fullfile( ...
    'data', ...
    'GAMEEMO', ...
    '(S01)', ...
    'Preprocessed EEG Data', ...
    '.mat format', ...
    'S01G1AllChannels.mat');

data = load(filePath);

AF3 = data.AF3;

%% Apply FFP

[features, mapValues] = FFP(AF3);

%% Display results

fprintf('\n====================================\n');
fprintf('FFP TEST\n');
fprintf('====================================\n');

fprintf('Input samples       : %d\n', length(AF3));
fprintf('Number of windows   : %d\n', size(mapValues,1));
fprintf('Map streams         : %d\n', size(mapValues,2));
fprintf('Feature vector size : %d\n', length(features));

fprintf('====================================\n');