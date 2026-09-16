clc;
clear;
close all;

%% ============================================================
% GAMEEMO SEGMENTATION TEST
% S01G1 - AF3
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

AF3 = data.AF3;

%% Parameters

numBlocks = 5;
blockLength = floor(length(AF3) / numBlocks);

%% Display information

fprintf('\n');
fprintf('============================================\n');
fprintf('GAMEEMO SEGMENTATION TEST\n');
fprintf('============================================\n');

fprintf('Original samples : %d\n', length(AF3));
fprintf('Number of blocks : %d\n', numBlocks);
fprintf('Block length     : %d\n', blockLength);

fprintf('Samples used     : %d\n', ...
    numBlocks * blockLength);

fprintf('Samples remaining: %d\n', ...
    length(AF3) - numBlocks * blockLength);

%% ============================================================
% Segment signal
% =============================================================

blocks = zeros(numBlocks, blockLength);

for b = 1:numBlocks

    startIndex = (b-1)*blockLength + 1;
    endIndex   = b*blockLength;

    blocks(b,:) = AF3(startIndex:endIndex);

    fprintf('\nBlock %d\n', b);
    fprintf('  Start sample : %d\n', startIndex);
    fprintf('  End sample   : %d\n', endIndex);
    fprintf('  Length       : %d\n', ...
        length(blocks(b,:)));

end

%% ============================================================
% Validation
% =============================================================

fprintf('\n');
fprintf('============================================\n');
fprintf('VALIDATION\n');
fprintf('============================================\n');

assert(size(blocks,1) == 5);
assert(size(blocks,2) == 7650);

fprintf('Segmentation dimension check: PASSED\n');

%% ============================================================
% Apply FFP to each block
% =============================================================

fprintf('\n');
fprintf('FFP PER BLOCK\n');
fprintf('--------------------------------------------\n');

blockFeatures = zeros(numBlocks,1024);

for b = 1:numBlocks

    [blockFeatures(b,:), mapValues] = FFP(blocks(b,:));

    fprintf('Block %d: %d samples → %d windows → %d features\n', ...
        b, ...
        size(blocks,2), ...
        size(mapValues,1), ...
        size(blockFeatures,2));

end

%% ============================================================
% Final validation
% =============================================================

fprintf('\n');
fprintf('============================================\n');
fprintf('FINAL RESULT\n');
fprintf('============================================\n');

fprintf('Block feature matrix: %d x %d\n', ...
    size(blockFeatures,1), ...
    size(blockFeatures,2));

fprintf('\nExpected:\n');
fprintf('5 blocks × 1024 FFP features\n');

assert(size(blockFeatures,1) == 5);
assert(size(blockFeatures,2) == 1024);

fprintf('\nBlock FFP validation: PASSED\n');

fprintf('============================================\n');