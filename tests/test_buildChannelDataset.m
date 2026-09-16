clc;
clear;
close all;

addpath(genpath('../src'));
addpath(genpath('../external/TQWT'));

fprintf('\n');
fprintf('============================================\n');
fprintf('CHANNEL DATASET ASSEMBLY TEST\n');
fprintf('============================================\n');

%% Configuration

config = getConfig();

%% Load GAMEEMO

fprintf('\nLoading GAMEEMO dataset...\n');

dataset = loadGAMEEMO(config);

%% Select channel

channelName = 'AF3';

fprintf('\nSelected channel : %s\n', channelName);

%% Build dataset

fprintf('\nBuilding dataset...\n');
fprintf('This may take some time.\n');

tic;

datasetTable = buildChannelDataset( ...
    dataset, ...
    config, ...
    channelName);

elapsedTime = toc;

%% Basic information

fprintf('\n');
fprintf('============================================\n');
fprintf('DATASET INFORMATION\n');
fprintf('============================================\n');

fprintf('Channel              : %s\n', channelName);
fprintf('Number of instances  : %d\n', height(datasetTable));
fprintf('Number of variables  : %d\n', width(datasetTable));
fprintf('Processing time      : %.2f seconds\n', elapsedTime);

%% Identify feature columns

featureColumns = startsWith( ...
    datasetTable.Properties.VariableNames, 'F');

numFeatureColumns = sum(featureColumns);

fprintf('Number of features   : %d\n', numFeatureColumns);

%% Validate dimensions

assert(height(datasetTable) == 560);
assert(numFeatureColumns == 31744);

fprintf('\n');
fprintf('============================================\n');
fprintf('DIMENSION VALIDATION\n');
fprintf('============================================\n');

fprintf('560 instances       : PASSED\n');
fprintf('31,744 features     : PASSED\n');

%% Validate metadata

assert(height(datasetTable) == 560);

uniqueSubjects = unique(datasetTable.Subject);
uniqueGames = unique(datasetTable.Game);

fprintf('\n');
fprintf('Metadata\n');
fprintf('--------------------------------------------\n');

fprintf('Unique subjects : %d\n', length(uniqueSubjects));
fprintf('Unique games    : %d\n', length(uniqueGames));

assert(length(uniqueSubjects) == 28);
assert(length(uniqueGames) == 4);

fprintf('28 subjects     : PASSED\n');
fprintf('4 games         : PASSED\n');

%% Check blocks

uniqueBlocks = unique(datasetTable.Block);

fprintf('Unique blocks   : %d\n', length(uniqueBlocks));

assert(length(uniqueBlocks) == 5);
assert(all(uniqueBlocks == (1:5)'));

fprintf('5 blocks        : PASSED\n');

%% Check instances per game

fprintf('\n');
fprintf('Instances per game\n');
fprintf('--------------------------------------------\n');

for g = 1:4

    gameName = sprintf('G%d',g);

    count = sum(datasetTable.Game == gameName);

    fprintf('%s : %d instances\n', ...
        gameName, count);

    assert(count == 140);

end

fprintf('\n140 instances per game : PASSED\n');

%% Check feature values

X = datasetTable{:,featureColumns};

assert(all(isfinite(X(:))));

fprintf('Finite feature values   : PASSED\n');

%% Display first rows of metadata

fprintf('\n');
fprintf('First 10 instances\n');
fprintf('--------------------------------------------\n');

disp(datasetTable(1:10, ...
    {'Subject','Game','Block','Label'}));

%% Final summary

fprintf('\n');
fprintf('============================================\n');
fprintf('FINAL VALIDATION\n');
fprintf('============================================\n');

fprintf('Channel                : %s\n', channelName);
fprintf('Instances              : 560\n');
fprintf('Features per instance  : 31,744\n');
fprintf('Expected feature matrix: 560 x 31,744\n');
fprintf('28 subjects            : PASSED\n');
fprintf('4 games                : PASSED\n');
fprintf('5 blocks               : PASSED\n');
fprintf('140 instances/game     : PASSED\n');
fprintf('Finite-value check     : PASSED\n');

fprintf('\n');
fprintf('============================================\n');
fprintf('CHANNEL DATASET TEST COMPLETED\n');
fprintf('============================================\n');