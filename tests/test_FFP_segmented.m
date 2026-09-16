clc;
clear;
close all;

addpath(genpath('../src'));

config = getConfig();

fprintf('\n');
fprintf('============================================\n');
fprintf('SEGMENTED EEG + FFP TEST\n');
fprintf('============================================\n');

%% Load GAMEEMO dataset

dataset = loadGAMEEMO(config);

%% Select one recording

subjectIndex = 1;       % S01
gameIndex = 1;          % G1
channelName = 'AF3';

signal = dataset.subjects(subjectIndex) ...
    .games(gameIndex) ...
    .channels.(channelName);

fprintf('\nSelected recording\n');
fprintf('--------------------------------------------\n');
fprintf('Subject : S01\n');
fprintf('Game    : G1\n');
fprintf('Channel : %s\n', channelName);
fprintf('Samples : %d\n', length(signal));

%% Segment EEG into 5 blocks

numBlocks = 5;

blocks = segmentEEG(signal, numBlocks);

fprintf('\nSegmentation\n');
fprintf('--------------------------------------------\n');

[numBlocksActual, blockLength] = size(blocks);

fprintf('Number of blocks : %d\n', numBlocksActual);
fprintf('Block length     : %d samples\n', blockLength);
fprintf('Total used       : %d samples\n', ...
    numBlocksActual * blockLength);
fprintf('Samples ignored  : %d\n', ...
    length(signal) - numBlocksActual * blockLength);

%% Validate segmentation

assert(numBlocksActual == 5);
assert(blockLength == 7650);

fprintf('\nSegmentation validation : PASSED\n');

%% Extract FFP features from each block

features = zeros(numBlocksActual, 1024);

fprintf('\nFFP feature extraction\n');
fprintf('--------------------------------------------\n');

for b = 1:numBlocksActual

    block = blocks(b,:);

    [featureVector, mapValues] = FFP(block);

    features(b,:) = featureVector;

    fprintf( ...
        'Block %d : %d samples -> %d windows -> %d features\n', ...
        b, ...
        length(block), ...
        size(mapValues,1), ...
        length(featureVector));

end

%% Validate FFP output

assert(size(features,1) == 5);
assert(size(features,2) == 1024);

assert(all(isfinite(features(:))));

fprintf('\n');
fprintf('============================================\n');
fprintf('FFP VALIDATION\n');
fprintf('============================================\n');

fprintf('5 blocks check       : PASSED\n');
fprintf('1024 features check  : PASSED\n');
fprintf('Finite values check  : PASSED\n');

%% Display feature matrix

fprintf('\nFeature matrix size:\n');
fprintf('%d x %d\n', size(features,1), size(features,2));

fprintf('\nFirst 10 features of each block:\n');
disp(features(:,1:10));

fprintf('\n');
fprintf('============================================\n');
fprintf('SEGMENTED FFP TEST COMPLETED\n');
fprintf('============================================\n');