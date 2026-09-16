clc;
clear;
close all;

%% ============================================================
% FFP TEST - ALL 14 CHANNELS
% S01G1
% =============================================================

addpath(genpath('../src'));

%% Load recording

filePath = fullfile( ...
    'data', ...
    'GAMEEMO', ...
    '(S01)', ...
    'Preprocessed EEG Data', ...
    '.mat format', ...
    'S01G1AllChannels.mat');

data = load(filePath);

%% Channel names

channels = { ...
    'AF3', 'AF4', 'F3', 'F4', ...
    'F7', 'F8', 'FC5', 'FC6', ...
    'O1', 'O2', 'P7', 'P8', ...
    'T7', 'T8'};

%% Storage

numChannels = length(channels);

features = zeros(numChannels, 1024);

%% ============================================================
% Apply FFP to every channel
% =============================================================

fprintf('\n');
fprintf('============================================\n');
fprintf('FFP TEST - ALL 14 CHANNELS\n');
fprintf('S01G1\n');
fprintf('============================================\n');

for c = 1:numChannels

    channelName = channels{c};

    EEG = data.(channelName);

    fprintf('\nProcessing %-4s ... ', channelName);

    [featureVector, mapValues] = FFP(EEG);

    features(c,:) = featureVector;

    fprintf('Done');

    fprintf('\n   Samples  : %d', length(EEG));
    fprintf('\n   Windows  : %d', size(mapValues,1));
    fprintf('\n   Features : %d\n', length(featureVector));

end

%% ============================================================
% Final validation
% =============================================================

fprintf('\n');
fprintf('============================================\n');
fprintf('FINAL VALIDATION\n');
fprintf('============================================\n');

fprintf('Feature matrix size: %d x %d\n', ...
    size(features,1), size(features,2));

fprintf('\nExpected:\n');
fprintf('14 channels × 1024 features\n');

%% Check dimensions

assert(size(features,1) == 14, ...
    'Unexpected number of channels.');

assert(size(features,2) == 1024, ...
    'Unexpected FFP feature length.');

fprintf('\nDimension check: PASSED\n');

%% Check feature values

assert(all(isfinite(features(:))), ...
    'FFP contains NaN or Inf.');

fprintf('Finite-value check: PASSED\n');

%% Display feature matrix

fprintf('\nFirst 10 features of each channel:\n');
fprintf('--------------------------------------------\n');

for c = 1:numChannels

    fprintf('%-4s : ', channels{c});

    fprintf('%.0f ', features(c,1:10));

    fprintf('\n');

end

fprintf('\n============================================\n');
fprintf('FFP ALL-CHANNEL TEST COMPLETED\n');
fprintf('============================================\n');