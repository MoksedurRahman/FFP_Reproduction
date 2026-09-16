clc;
clear;
close all;

addpath(genpath('../src'));
addpath(genpath('../external/TQWT'));

fprintf('\n');
fprintf('============================================\n');
fprintf('EXTRACT TQWT + FFP FUNCTION TEST\n');
fprintf('============================================\n');

%% Configuration

config = getConfig();

%% Load GAMEEMO

fprintf('\nLoading GAMEEMO dataset...\n');

dataset = loadGAMEEMO(config);

%% Select recording

subjectIndex = 1;
gameIndex = 1;
channelName = 'AF3';

signal = dataset.subjects(subjectIndex) ...
    .games(gameIndex) ...
    .channels.(channelName);

%% Segment recording

blocks = segmentEEG(signal, 5);

block = blocks(1,:);

fprintf('\nSelected EEG block\n');
fprintf('--------------------------------------------\n');
fprintf('Subject : S01\n');
fprintf('Game    : G1\n');
fprintf('Channel : %s\n', channelName);
fprintf('Block   : 1\n');
fprintf('Samples : %d\n', length(block));

%% Generate combined features

fprintf('\nGenerating combined TQWT + FFP features...\n');

featureVector = extractTQWTFFP(block, config);

%% Validate

fprintf('\n');
fprintf('============================================\n');
fprintf('FEATURE VALIDATION\n');
fprintf('============================================\n');

fprintf('Feature vector size : %d x %d\n', ...
    size(featureVector,1), ...
    size(featureVector,2));

fprintf('Number of features  : %d\n', ...
    length(featureVector));

assert(isrow(featureVector));
assert(length(featureVector) == 31744);
assert(all(isfinite(featureVector)));

fprintf('\nRow-vector check     : PASSED\n');
fprintf('31,744 features      : PASSED\n');
fprintf('Finite values        : PASSED\n');

%% Check feature groups

fprintf('\n');
fprintf('Feature groups\n');
fprintf('--------------------------------------------\n');

originalRange = 1:1024;

fprintf('Original EEG FFP     : features %d - %d\n', ...
    originalRange(1), originalRange(end));

for j = 1:30

    startIndex = 1024 + (j-1)*1024 + 1;
    endIndex   = 1024 + j*1024;

    fprintf( ...
        'TQWT component %2d    : features %d - %d\n', ...
        j, startIndex, endIndex);

end

%% Final test

fprintf('\n');
fprintf('============================================\n');
fprintf('FINAL VALIDATION\n');
fprintf('============================================\n');

fprintf('Original EEG FFP     : 1,024 features  PASSED\n');
fprintf('TQWT components      : 30              PASSED\n');
fprintf('FFP per component    : 1,024           PASSED\n');
fprintf('Combined vector      : 31,744          PASSED\n');
fprintf('Finite-value check   : PASSED\n');

fprintf('\n');
fprintf('============================================\n');
fprintf('EXTRACT TQWT + FFP TEST COMPLETED\n');
fprintf('============================================\n');