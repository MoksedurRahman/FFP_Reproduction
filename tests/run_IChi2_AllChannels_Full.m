%% run_IChi2_AllChannels_Full
%
% Full paper-style IChi2 search for all GAMEEMO EEG channels.
%
% Feature counts:
%       100:1000
%
% MATLAB:
%       fscchi2
%       fitcecoc + cubic polynomial SVM
%
% Results are saved after each channel so the experiment can
% be stopped and resumed safely.

clear;
clc;

%% ============================================================
% Configuration
% ============================================================

config = getConfig();

channels = { ...
    'AF3','AF4','F3','F4', ...
    'F7','F8','FC5','FC6', ...
    'O1','O2','P7','P8','T7','T8'};

featureCounts = 100:1000;

seed = 1;

resultsDir = fullfile('results','IChi2');

if ~exist(resultsDir,'dir')
    mkdir(resultsDir);
end

%% ============================================================
% Load GAMEEMO once
% ============================================================

fprintf('\n');
fprintf('============================================\n');
fprintf('LOADING GAMEEMO DATASET\n');
fprintf('============================================\n');

dataset = loadGAMEEMO(config);

fprintf('GAMEEMO loaded successfully.\n');

%% ============================================================
% Summary file
% ============================================================

summaryFile = fullfile( ...
    resultsDir, ...
    'AllChannels_IChi2_full_summary.mat');

%% ============================================================
% Initialise / load summary
% ============================================================

if isfile(summaryFile)

    fprintf('\nExisting summary found.\n');
    fprintf('Loading previous results...\n');

    S = load(summaryFile);

    summary = S.summary;

else

    summary = table( ...
        strings(length(channels),1), ...
        NaN(length(channels),1), ...
        NaN(length(channels),1), ...
        NaN(length(channels),1), ...
        false(length(channels),1), ...
        'VariableNames',{ ...
            'Channel', ...
            'OptimalFeatureCount', ...
            'OptimalAccuracy', ...
            'MinimumLoss', ...
            'Completed'});

    summary.Channel = string(channels(:));

end

%% ============================================================
% Process channels
% ============================================================

for c = 1:length(channels)

    channelName = channels{c};

    fprintf('\n\n');
    fprintf('############################################\n');
    fprintf('# CHANNEL %d / %d : %s\n', ...
        c,length(channels),channelName);
    fprintf('############################################\n');

    %% --------------------------------------------------------
    % Skip completed channel
    % ---------------------------------------------------------

    resultFile = fullfile( ...
        resultsDir, ...
        sprintf('%s_IChi2_full_results.mat',channelName));

    if isfile(resultFile)

        fprintf('\nExisting result found for %s.\n', ...
            channelName);

        fprintf('Skipping channel.\n');

        summary.Completed(c) = true;

        continue;

    end

    %% --------------------------------------------------------
    % Build dataset
    % ---------------------------------------------------------

    fprintf('\nBuilding %s dataset...\n',channelName);

    tic;

    datasetTable = buildChannelDataset( ...
        dataset, ...
        config, ...
        channelName);

    datasetBuildTime = toc;

    %% --------------------------------------------------------
    % Extract X and Y
    % ---------------------------------------------------------

    X = table2array(datasetTable(:,5:end));

    Y = datasetTable.Label;

    fprintf('Instances          : %d\n',size(X,1));
    fprintf('Original features  : %d\n',size(X,2));

    %% --------------------------------------------------------
    % Run full IChi2
    % ---------------------------------------------------------

    fprintf('\n');
    fprintf('Starting full IChi2 search:\n');
    fprintf('Feature counts = 100:1000\n');
    fprintf('This may take a considerable amount of time.\n');

    tic;

    results = IChi2( ...
        X, ...
        Y, ...
        featureCounts, ...
        seed);

    IChi2Time = toc;

    %% --------------------------------------------------------
    % Add metadata
    % ---------------------------------------------------------

    results.channel = channelName;

    results.numInstances = size(X,1);

    results.numOriginalFeatures = size(X,2);

    results.datasetBuildTimeSeconds = ...
        datasetBuildTime;

    results.IChi2TimeSeconds = ...
        IChi2Time;

    %% --------------------------------------------------------
    % Save immediately
    % ---------------------------------------------------------

    save( ...
        resultFile, ...
        'results', ...
        '-v7.3');

    fprintf('\n');
    fprintf('RESULT SAVED:\n%s\n',resultFile);

    %% --------------------------------------------------------
    % Update summary
    % ---------------------------------------------------------

    summary.OptimalFeatureCount(c) = ...
        results.optimalFeatureCount;

    summary.OptimalAccuracy(c) = ...
        results.optimalAccuracy;

    summary.MinimumLoss(c) = ...
        results.minimumLoss;

    summary.Completed(c) = true;

    %% --------------------------------------------------------
    % Save summary immediately
    % ---------------------------------------------------------

    save( ...
        summaryFile, ...
        'summary');

    writetable( ...
        summary, ...
        fullfile( ...
            resultsDir, ...
            'AllChannels_IChi2_full_summary.csv'));

    %% --------------------------------------------------------
    % Display channel result
    % ---------------------------------------------------------

    fprintf('\n');
    fprintf('============================================\n');
    fprintf('%s COMPLETED\n',channelName);
    fprintf('============================================\n');

    fprintf('Optimal features : %d\n', ...
        results.optimalFeatureCount);

    fprintf('Accuracy         : %.2f %%\n', ...
        results.optimalAccuracy);

    fprintf('Minimum loss     : %.4f\n', ...
        results.minimumLoss);

    fprintf('IChi2 time       : %.2f minutes\n', ...
        IChi2Time/60);

end

%% ============================================================
% Final summary
% ============================================================

fprintf('\n\n');
fprintf('============================================\n');
fprintf('FULL IChi2 — ALL CHANNELS SUMMARY\n');
fprintf('============================================\n');

disp(summary);

%% ============================================================
% Save final summary
% ============================================================

save( ...
    summaryFile, ...
    'summary');

writetable( ...
    summary, ...
    fullfile( ...
        resultsDir, ...
        'AllChannels_IChi2_full_summary.csv'));

fprintf('\n');
fprintf('Summary saved to:\n');
fprintf('%s\n',resultsDir);

fprintf('\n');
fprintf('============================================\n');
fprintf('FULL ANALYSIS COMPLETED\n');
fprintf('============================================\n');