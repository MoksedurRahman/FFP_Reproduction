clc;
clear;
close all;

%% Add source code

addpath(genpath('../src'));

%% Configuration

config = getConfig();

%% Load dataset

fprintf('\n');
fprintf('============================================\n');
fprintf('GAMEEMO DATASET LOADER TEST\n');
fprintf('============================================\n');

dataset = loadGAMEEMO(config);

%% Basic information

fprintf('\nSubjects loaded : %d\n', ...
    dataset.numSubjects);

fprintf('Games per subject : %d\n', ...
    dataset.numGames);

fprintf('Channels : %d\n', ...
    length(dataset.channels));

%% Check S01

fprintf('\n');
fprintf('S01 validation\n');
fprintf('--------------------------------------------\n');

for g = 1:4

    fprintf('\nG%d\n', g);

    for c = 1:length(dataset.channels)

        channelName = dataset.channels{c};

        signal = dataset.subjects(1).games(g). ...
            channels.(channelName);

        fprintf('%-4s : %d samples\n', ...
            channelName, ...
            length(signal));

    end

end

%% ============================================================
% Validation
% =============================================================

assert(dataset.numSubjects == 28);

assert(dataset.numGames == 4);

assert(length(dataset.channels) == 14);

fprintf('\n');
fprintf('============================================\n');
fprintf('LOADER VALIDATION\n');
fprintf('============================================\n');

fprintf('28 subjects check : PASSED\n');
fprintf('4 games check     : PASSED\n');
fprintf('14 channels check : PASSED\n');

%% Check S01G1

for g = 1:4

    for c = 1:length(dataset.channels)

        channelName = dataset.channels{c};

        signal = dataset.subjects(1).games(g). ...
            channels.(channelName);

        assert(length(signal) == 38252);

    end

end

fprintf('S01 signal length check : PASSED\n');

fprintf('\n============================================\n');
fprintf('GAMEEMO LOADER TEST COMPLETED\n');
fprintf('============================================\n');