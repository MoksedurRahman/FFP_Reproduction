%% test_IChi2_AllChannels
% Run MATLAB fscchi2 + cubic SVM IChi2 analysis
% for all 14 GAMEEMO EEG channels.

clear;
clc;

%% ============================================================
% Configuration
% =============================================================

config = getConfig();

channels = { ...
    'AF3','AF4','F3','F4', ...
    'F7','F8','FC5','FC6', ...
    'O1','O2','P7','P8','T7','T8'};

% Diagnostic feature counts
featureCounts = [100 200 300 400 500 ...
                 600 700 800 900 1000];

% Reproducible CV seed
seed = 1;

%% ============================================================
% Load GAMEEMO
% =============================================================

fprintf('\n');
fprintf('============================================\n');
fprintf('GAMEEMO DATASET LOADING\n');
fprintf('============================================\n');

dataset = loadGAMEEMO(config);

fprintf('\nGAMEEMO loaded successfully.\n');

%% ============================================================
% Prepare results table
% =============================================================

numChannels = length(channels);

summary = table( ...
    strings(numChannels,1), ...
    zeros(numChannels,1), ...
    zeros(numChannels,1), ...
    zeros(numChannels,1), ...
    'VariableNames', { ...
        'Channel', ...
        'OptimalFeatureCount', ...
        'OptimalAccuracy', ...
        'MinimumLoss'});

%% ============================================================
% Create results directory
% =============================================================

resultsDir = fullfile('results','IChi2');

if ~exist(resultsDir,'dir')
    mkdir(resultsDir);
end

%% ============================================================
% Process each channel
% =============================================================

for c = 1:numChannels

    channelName = channels{c};

    fprintf('\n\n');
    fprintf('############################################\n');
    fprintf('# CHANNEL %d/%d: %s\n', ...
        c,numChannels,channelName);
    fprintf('############################################\n');

    %% --------------------------------------------------------
    % Build channel dataset
    % ---------------------------------------------------------

    fprintf('\nBuilding dataset for %s...\n',channelName);

    datasetTable = buildChannelDataset( ...
        dataset, ...
        config, ...
        channelName);

    fprintf('Dataset size: %d samples x %d variables\n', ...
        height(datasetTable), ...
        width(datasetTable));

    %% --------------------------------------------------------
    % Extract X and Y
    % ---------------------------------------------------------

    X = table2array(datasetTable(:,5:end));

    Y = datasetTable.Label;

    fprintf('Feature matrix: %d x %d\n', ...
        size(X,1), ...
        size(X,2));

    %% --------------------------------------------------------
    % Run IChi2
    % ---------------------------------------------------------

    tic;

    results = IChi2( ...
        X, ...
        Y, ...
        featureCounts, ...
        seed);

    elapsedTime = toc;

    %% --------------------------------------------------------
    % Store summary
    % ---------------------------------------------------------

    summary.Channel(c) = string(channelName);

    summary.OptimalFeatureCount(c) = ...
        results.optimalFeatureCount;

    summary.OptimalAccuracy(c) = ...
        results.optimalAccuracy;

    summary.MinimumLoss(c) = ...
        results.minimumLoss;

    %% --------------------------------------------------------
    % Add metadata
    % ---------------------------------------------------------

    results.channel = channelName;

    results.numInstances = size(X,1);

    results.numOriginalFeatures = size(X,2);

    results.processingTimeSeconds = elapsedTime;

    %% --------------------------------------------------------
    % Save channel result
    % ---------------------------------------------------------

    resultFile = fullfile( ...
        resultsDir, ...
        sprintf('%s_IChi2_results.mat',channelName));

    save(resultFile,'results');

    fprintf('\n%s completed.\n',channelName);

    fprintf('Optimal features : %d\n', ...
        results.optimalFeatureCount);

    fprintf('Accuracy         : %.2f %%\n', ...
        results.optimalAccuracy);

    fprintf('Loss             : %.4f\n', ...
        results.minimumLoss);

    fprintf('Processing time  : %.2f seconds\n', ...
        elapsedTime);

end

%% ============================================================
% Display final summary
% =============================================================

fprintf('\n\n');
fprintf('============================================\n');
fprintf('ALL CHANNELS — IChi2 SUMMARY\n');
fprintf('============================================\n');

disp(summary);

%% ============================================================
% Save summary
% =============================================================

summaryFile = fullfile( ...
    resultsDir, ...
    'AllChannels_IChi2_summary.mat');

save(summaryFile,'summary');

writetable( ...
    summary, ...
    fullfile(resultsDir,'AllChannels_IChi2_summary.csv'));

fprintf('\nSummary saved to:\n%s\n',resultsDir);

fprintf('\n');
fprintf('ALL CHANNEL PROCESSING COMPLETED.\n');
fprintf('============================================\n');