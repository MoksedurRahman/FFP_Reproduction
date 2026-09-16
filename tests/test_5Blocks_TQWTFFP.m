clc;
clear;
close all;

addpath(genpath('../src'));
addpath(genpath('../external/TQWT'));

fprintf('\n');
fprintf('============================================\n');
fprintf('5-BLOCK TQWT + FFP TEST\n');
fprintf('============================================\n');

%% Configuration

config = getConfig();

%% Load dataset

dataset = loadGAMEEMO(config);

%% Select recording

subjectIndex = 1;
gameIndex = 1;
channelName = 'AF3';

signal = dataset.subjects(subjectIndex) ...
    .games(gameIndex) ...
    .channels.(channelName);

%% Segment into 5 blocks

blocks = segmentEEG(signal, 5);

[numBlocks, blockLength] = size(blocks);

fprintf('\nRecording\n');
fprintf('--------------------------------------------\n');
fprintf('Subject : S01\n');
fprintf('Game    : G1\n');
fprintf('Channel : %s\n', channelName);
fprintf('Samples : %d\n', length(signal));

fprintf('\nSegmentation\n');
fprintf('--------------------------------------------\n');
fprintf('Blocks : %d\n', numBlocks);
fprintf('Length : %d samples\n', blockLength);

%% Allocate feature matrix

allFeatures = zeros(numBlocks, 31744);

%% Extract features

fprintf('\n');
fprintf('TQWT + FFP feature extraction\n');
fprintf('--------------------------------------------\n');

tic;

for b = 1:numBlocks

    fprintf('Processing block %d/%d...\n', b, numBlocks);

    block = blocks(b,:);

    featureVector = extractTQWTFFP(block, config);

    allFeatures(b,:) = featureVector;

    assert(length(featureVector) == 31744);
    assert(all(isfinite(featureVector)));

end

elapsedTime = toc;

%% Validate

fprintf('\n');
fprintf('============================================\n');
fprintf('VALIDATION\n');
fprintf('============================================\n');

fprintf('Number of blocks    : %d\n', size(allFeatures,1));
fprintf('Features per block  : %d\n', size(allFeatures,2));
fprintf('Matrix size         : %d x %d\n', ...
    size(allFeatures,1), size(allFeatures,2));

fprintf('Total feature values: %d\n', numel(allFeatures));

fprintf('Processing time     : %.2f seconds\n', elapsedTime);

assert(size(allFeatures,1) == 5);
assert(size(allFeatures,2) == 31744);
assert(all(isfinite(allFeatures(:))));

fprintf('\n5-block check       : PASSED\n');
fprintf('31,744 feature check: PASSED\n');
fprintf('Finite-value check  : PASSED\n');

fprintf('\n');
fprintf('============================================\n');
fprintf('5-BLOCK TEST COMPLETED\n');
fprintf('============================================\n');