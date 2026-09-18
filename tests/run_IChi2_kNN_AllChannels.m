%% run_IChi2_kNN_AllChannels
%
% IChi2 + 1-NN kNN classification for all 14 GAMEEMO channels.
%
% kNN configuration:
%   k = 1
%   Distance = Manhattan (cityblock)
%   Distance weighting = Equal
%   10-fold cross-validation
%
% Feature counts:
%   100:1000
%
% Results are saved separately for each channel so that the experiment
% can be resumed if MATLAB is interrupted.

clear;
clc;

fprintf('\n');
fprintf('============================================\n');
fprintf('IChi2 + kNN - ALL CHANNELS\n');
fprintf('============================================\n');

%% Configuration

config = getConfig();

channels = { ...
    'AF3', ...
    'AF4', ...
    'F3', ...
    'F4', ...
    'F7', ...
    'F8', ...
    'FC5', ...
    'FC6', ...
    'O1', ...
    'O2', ...
    'P7', ...
    'P8', ...
    'T7', ...
    'T8'};

featureCounts = 100:1000;

seed = 1;

%% Load GAMEEMO

fprintf('\nLoading GAMEEMO dataset...\n');

dataset = loadGAMEEMO(config);

fprintf('Dataset loaded.\n');

%% Create results directory

resultsDir = fullfile('results', 'IChi2_kNN');

if ~exist(resultsDir, 'dir')
    mkdir(resultsDir);
end

%% Summary table

nChannels = numel(channels);

summary = table( ...
    strings(nChannels,1), ...
    zeros(nChannels,1), ...
    zeros(nChannels,1), ...
    false(nChannels,1), ...
    'VariableNames', { ...
        'Channel', ...
        'OptimalFeatureCount', ...
        'OptimalAccuracy', ...
        'Completed'});

%% Process channels

for c = 1:nChannels

    channelName = channels{c};

    fprintf('\n');
    fprintf('--------------------------------------------\n');
    fprintf('Channel %d/%d: %s\n', c, nChannels, channelName);
    fprintf('--------------------------------------------\n');

    resultFile = fullfile( ...
        resultsDir, ...
        sprintf('%s_IChi2_kNN_results.mat', channelName));

    %% Check whether this channel is already completed

    if exist(resultFile, 'file')

        fprintf('Existing result found.\n');
        fprintf('Skipping %s.\n', channelName);

        loaded = load(resultFile, 'results');

        if isfield(loaded, 'results')

            results = loaded.results;

            summary.Channel(c) = string(channelName);
            summary.OptimalFeatureCount(c) = ...
                results.optimalFeatureCount;

            summary.OptimalAccuracy(c) = ...
                results.optimalAccuracy;

            summary.Completed(c) = true;

        end

        continue;

    end

    %% Build channel dataset

    fprintf('\nBuilding dataset for %s...\n', channelName);

    datasetTable = buildChannelDataset( ...
        dataset, ...
        config, ...
        channelName);

    %% Extract X and Y

    X = table2array(datasetTable(:,5:end));
    Y = datasetTable.Label;

    X = double(X);

    fprintf('Dataset size: %d observations x %d features\n', ...
        size(X,1), size(X,2));

    %% IChi2 ranking

    fprintf('\nRunning MATLAB fscchi2 ranking...\n');

    % Initial normalization for chi-square ranking.
    %
    % This follows the same implementation currently used in the
    % SVM and LDA reproduction experiments.

    xmin = min(X, [], 1);
    xmax = max(X, [], 1);

    featureRange = xmax - xmin;
    featureRange(featureRange == 0) = 1;

    Xnorm = (X - xmin) ./ featureRange;

    [rankedFeatures, chi2Scores] = fscchi2(Xnorm, Y);

    fprintf('Chi-square ranking completed.\n');

    fprintf('Top 10 ranked features:\n');
    disp(rankedFeatures(1:10));

    %% Create reproducible 10-fold partition

    rng(seed);

    cvp = cvpartition(Y, 'KFold', 10);

    fprintf('\n10-fold cross-validation partition created.\n');

    %% Run IChi2 + kNN

    fprintf('\n');
    fprintf('Running IChi2 + 1-NN...\n');
    fprintf('Feature range: %d:%d\n', ...
        featureCounts(1), featureCounts(end));

    tic;

    results = IChi2_kNN( ...
        X, ...
        Y, ...
        rankedFeatures, ...
        featureCounts, ...
        cvp);

    elapsedTime = toc;

    %% Add metadata

    results.channel = channelName;
    results.chi2Scores = chi2Scores;
    results.numObservations = size(X,1);
    results.numOriginalFeatures = size(X,2);
    results.elapsedTimeSeconds = elapsedTime;
    results.seed = seed;

    %% Save result

    save(resultFile, 'results', '-v7.3');

    fprintf('\nResult saved:\n');
    fprintf('%s\n', resultFile);

    %% Update summary

    summary.Channel(c) = string(channelName);

    summary.OptimalFeatureCount(c) = ...
        results.optimalFeatureCount;

    summary.OptimalAccuracy(c) = ...
        results.optimalAccuracy;

    summary.Completed(c) = true;

    fprintf('\nChannel %s completed.\n', channelName);
    fprintf('Optimal features : %d\n', ...
        results.optimalFeatureCount);
    fprintf('Accuracy         : %.3f%%\n', ...
        results.optimalAccuracy);
    fprintf('Processing time  : %.2f seconds\n', ...
        elapsedTime);

    %% Save intermediate summary

    summaryFile = fullfile( ...
        resultsDir, ...
        'IChi2_kNN_AllChannels_Summary.mat');

    save(summaryFile, 'summary');

end

%% Display final summary

fprintf('\n');
fprintf('============================================\n');
fprintf('IChi2 + kNN - ALL CHANNELS SUMMARY\n');
fprintf('============================================\n');

disp(summary);

%% Save final summary

summaryFile = fullfile( ...
    resultsDir, ...
    'IChi2_kNN_AllChannels_Summary.mat');

save(summaryFile, 'summary');

fprintf('\nSummary saved to:\n');
fprintf('%s\n', summaryFile);

fprintf('\nExperiment completed.\n');