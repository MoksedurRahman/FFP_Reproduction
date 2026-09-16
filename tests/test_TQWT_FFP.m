clc;
clear;
close all;

addpath(genpath('../src'));
addpath(genpath('../external/TQWT'));

fprintf('\n');
fprintf('============================================\n');
fprintf('TQWT + FFP FEATURE GENERATION TEST\n');
fprintf('============================================\n');

%% Load configuration

config = getConfig();

%% Load GAMEEMO

fprintf('\nLoading GAMEEMO dataset...\n');

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

%% Segment EEG

numBlocks = 5;

blocks = segmentEEG(signal, numBlocks);

block = blocks(1,:);

fprintf('\nSelected block\n');
fprintf('--------------------------------------------\n');
fprintf('Block number : 1\n');
fprintf('Block length : %d samples\n', length(block));

%% TQWT parameters

Q = config.TQWT.Q;
r = config.TQWT.r;
J = config.TQWT.J;

fprintf('\nTQWT parameters\n');
fprintf('--------------------------------------------\n');
fprintf('Q : %.1f\n', Q);
fprintf('r : %.1f\n', r);
fprintf('J : %d\n', J);

%% ---------------------------------------------------------
%  PART 1: FFP on original EEG
% ----------------------------------------------------------

fprintf('\n');
fprintf('============================================\n');
fprintf('PART 1: FFP ON ORIGINAL EEG\n');
fprintf('============================================\n');

[originalFeatures, originalMaps] = FFP(block);

fprintf('Original EEG samples : %d\n', length(block));
fprintf('FFP windows          : %d\n', size(originalMaps,1));
fprintf('FFP features         : %d\n', length(originalFeatures));

assert(length(originalFeatures) == 1024);
assert(all(isfinite(originalFeatures)));

fprintf('Original EEG FFP : PASSED\n');

%% ---------------------------------------------------------
%  PART 2: TQWT
% ----------------------------------------------------------

fprintf('\n');
fprintf('============================================\n');
fprintf('PART 2: TQWT\n');
fprintf('============================================\n');

w = tqwt(block, Q, r, J);

numSubbands = length(w);

fprintf('TQWT components : %d\n', numSubbands);

assert(numSubbands == J + 1);

fprintf('30-component TQWT : PASSED\n');

%% ---------------------------------------------------------
%  PART 3: FFP ON TQWT SUBBANDS
% ----------------------------------------------------------

fprintf('\n');
fprintf('============================================\n');
fprintf('PART 3: FFP ON TQWT SUBBANDS\n');
fprintf('============================================\n');

subbandFeatures = zeros(numSubbands, 1024);

for j = 1:numSubbands

    subband = w{j};

    [featureVector, mapValues] = FFP(subband);

    subbandFeatures(j,:) = featureVector;

    fprintf( ...
        'Subband %2d : %4d samples -> %4d windows -> %4d features\n', ...
        j, ...
        length(subband), ...
        size(mapValues,1), ...
        length(featureVector));

    assert(length(featureVector) == 1024);

    assert(all(isfinite(featureVector)));

end

fprintf('\nAll TQWT subbands passed FFP validation.\n');

%% ---------------------------------------------------------
%  PART 4: COMBINE FEATURES
% ----------------------------------------------------------

fprintf('\n');
fprintf('============================================\n');
fprintf('PART 4: FEATURE COMBINATION\n');
fprintf('============================================\n');

allFeatures = [originalFeatures; subbandFeatures];

fprintf('Original EEG features : %d\n', ...
    size(originalFeatures,2));

fprintf('TQWT subbands         : %d\n', ...
    size(subbandFeatures,1));

fprintf('Features per signal   : %d\n', ...
    size(allFeatures,2));

fprintf('Feature matrix size   : %d x %d\n', ...
    size(allFeatures,1), ...
    size(allFeatures,2));

%% Validate final dimensions

assert(size(originalFeatures,2) == 1024);

assert(size(subbandFeatures,1) == 30);
assert(size(subbandFeatures,2) == 1024);

assert(size(allFeatures,1) == 31);
assert(size(allFeatures,2) == 1024);

assert(all(isfinite(allFeatures(:))));

fprintf('\n');
fprintf('============================================\n');
fprintf('FINAL VALIDATION\n');
fprintf('============================================\n');

fprintf('Original FFP          : 1 x 1024  PASSED\n');
fprintf('TQWT subbands         : 30         PASSED\n');
fprintf('FFP per subband       : 1 x 1024  PASSED\n');

fprintf('\n');

fprintf('31 signal representations : %d\n', ...
    size(allFeatures,1));

fprintf('Features per representation : %d\n', ...
    size(allFeatures,2));

fprintf('Total feature values : %d\n', ...
    numel(allFeatures));

assert(numel(allFeatures) == 31 * 1024);

fprintf('31 x 1024 = 31,744 : PASSED\n');

fprintf('Finite-value check   : PASSED\n');

fprintf('\n');
fprintf('============================================\n');
fprintf('TQWT + FFP TEST COMPLETED\n');
fprintf('============================================\n');