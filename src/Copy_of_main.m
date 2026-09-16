clc;
clear;
close all;

%% Paths
addpath(genpath('src'));

dataFolder = fullfile( ...
    'data', ...
    'GAMEEMO', ...
    '(S01)', ...
    'Preprocessed EEG Data', ...
    '.mat format');

%% Load dataset
[signals, labels] = loadEEGDataset(dataFolder);

fprintf('Samples : %d\n', numel(signals));
fprintf('Classes : %d\n', numel(unique(labels)));

%% Feature extraction
features = extractFeatures(signals);

%% Train/Test split (80/20)
cv = cvpartition(labels,'HoldOut',0.2);

Xtrain = features(training(cv),:);
Ytrain = labels(training(cv));

Xtest  = features(test(cv),:);
Ytest  = labels(test(cv));

%% Train classifier
model = fitcecoc(Xtrain,Ytrain);

%% Validation
evaluateModel(model,Xtest,Ytest);