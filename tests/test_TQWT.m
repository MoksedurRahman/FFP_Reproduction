clc;
clear;
close all;

addpath(genpath('../src'));

fprintf('\n');
fprintf('============================================\n');
fprintf('TQWT VALIDATION TEST\n');
fprintf('============================================\n');

%% Check that TQWT is available

fprintf('\nChecking MATLAB TQWT availability...\n');

assert(exist('tqwt', 'file') == 2, ...
    ['MATLAB function "tqwt" was not found. ' ...
     'Check that the required toolbox/function is installed.']);

fprintf('TQWT function : FOUND\n');

%% Load configuration

config = getConfig();

%% Load GAMEEMO dataset

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

fprintf('\nSelected EEG block\n');
fprintf('--------------------------------------------\n');
fprintf('Block number : 1\n');
fprintf('Samples      : %d\n', length(block));

%% TQWT parameters from the paper

Q = config.TQWT.Q;
r = config.TQWT.r;
J = config.TQWT.J;

fprintf('\nTQWT parameters\n');
fprintf('--------------------------------------------\n');
fprintf('Q : %.1f\n', Q);
fprintf('r : %.1f\n', r);
fprintf('J : %d\n', J);

%% Perform TQWT

fprintf('\nRunning TQWT...\n');

w = tqwt(block, Q, r, J);

%% Inspect output

fprintf('\nTQWT output\n');
fprintf('--------------------------------------------\n');

fprintf('Number of returned components : %d\n', length(w));

for j = 1:length(w)

    fprintf('Component %2d : %d samples\n', ...
        j, length(w{j}));

end

%% Basic validation

assert(~isempty(w), ...
    'TQWT returned an empty result.');

assert(length(w) == J + 1, ...
    ['Unexpected number of TQWT components. ' ...
     'Expected %d, obtained %d.'], ...
     J + 1, length(w));

fprintf('\n');
fprintf('============================================\n');
fprintf('TQWT VALIDATION\n');
fprintf('============================================\n');

fprintf('TQWT function available : PASSED\n');
fprintf('Q = %.1f                  : PASSED\n', Q);
fprintf('r = %.1f                  : PASSED\n', r);
fprintf('J = %d                    : PASSED\n', J);
fprintf('Components = J + 1       : PASSED\n');

%% Check numerical validity

allFinite = true;

for j = 1:length(w)

    if ~all(isfinite(w{j}))
        allFinite = false;
        break;
    end

end

assert(allFinite, ...
    'At least one TQWT component contains NaN or Inf.');

fprintf('Finite-value check        : PASSED\n');

%% Display energy of each component

fprintf('\nTQWT component energies\n');
fprintf('--------------------------------------------\n');

for j = 1:length(w)

    energy = sum(w{j}.^2);

    fprintf('Component %2d : %.6e\n', j, energy);

end

fprintf('\n');
fprintf('============================================\n');
fprintf('TQWT TEST COMPLETED\n');
fprintf('============================================\n');