%% run_IChi2_AllChannels_SVM
% IChi2 + cubic SVM on all 14 GAMEEMO EEG channels.
%
% Pipeline:
% GAMEEMO -> 5 non-overlapping segments -> FFP + TQWT
% -> 31,744 features -> min-max normalization/ranking inside IChi2
% -> chi-square ranking -> 100:1000 selected features
% -> cubic SVM (one-vs-all) -> 10-fold cross-validation
%
% The IChi2 function used here is the current MATLAB implementation based
% on fscchi2 + fitcecoc/templateSVM.

clear;
clc;

%% Paths and configuration
config = getConfig();

resultDir = fullfile('results', 'IChi2', 'SVM');

if ~exist(resultDir, 'dir')
    mkdir(resultDir);
end

channels = { ...
    'AF3','AF4','F3','F4','F7','F8','FC5','FC6', ...
    'O1','O2','P7','P8','T7','T8'};

featureCounts = 100:1000;
seed = 1;

%% Load GAMEEMO
fprintf('\n============================================\n');
fprintf('IChi2 + CUBIC SVM - ALL CHANNELS\n');
fprintf('============================================\n');

dataset = loadGAMEEMO(config);

summaryFile = fullfile( ...
    resultDir, ...
    'IChi2_SVM_AllChannels_Summary.mat');

%% Preallocate summary table
summary = table( ...
    string(channels(:)), ...
    nan(numel(channels),1), ...
    nan(numel(channels),1), ...
    false(numel(channels),1), ...
    'VariableNames', { ...
        'Channel', ...
        'OptimalFeatureCount', ...
        'OptimalAccuracy', ...
        'Completed'});

%% Process each channel
for c = 1:numel(channels)

    channelName = channels{c};

    resultFile = fullfile( ...
        resultDir, ...
        sprintf('%s_IChi2_SVM_full_results.mat', ...
        channelName));

    fprintf('\n--------------------------------------------\n');
    fprintf('Channel %s (%d/%d)\n', ...
        channelName, c, numel(channels));
    fprintf('--------------------------------------------\n');

    %% Resume if result already exists
    if exist(resultFile, 'file')

        fprintf('Existing result found. Loading:\n');
        fprintf('%s\n', resultFile);

        S = load(resultFile);

        if isfield(S, 'results')
            results = S.results;
        else
            error( ...
                'Result file does not contain variable "results": %s', ...
                resultFile);
        end

    else

        %% Build channel dataset
        fprintf('Building dataset for %s...\n', ...
            channelName);

        datasetTable = buildChannelDataset( ...
            dataset, ...
            config, ...
            channelName);

        %% Separate features and labels
        X = table2array(datasetTable(:,5:end));
        Y = datasetTable.Label;

        X = double(X);
        Y = categorical(Y);

        fprintf( ...
            'Dataset size: %d instances x %d features\n', ...
            size(X,1), ...
            size(X,2));

        %% Run IChi2 + cubic SVM
        fprintf('\n');
        fprintf('Running IChi2 + cubic SVM...\n');
        fprintf( ...
            'Feature counts: %d:%d\n', ...
            featureCounts(1), ...
            featureCounts(end));

        results = IChi2( ...
            X, ...
            Y, ...
            featureCounts, ...
            seed);

        %% Save individual channel result
        save( ...
            resultFile, ...
            'results', ...
            '-v7.3');

        fprintf('Saved:\n%s\n', ...
            resultFile);
    end

    %% Extract optimal result
    if isfield(results, 'optimalFeatureCount')

        optimalFeatureCount = ...
            results.optimalFeatureCount;

    else

        error( ...
            'Missing results.optimalFeatureCount for %s.', ...
            channelName);

    end

    if isfield(results, 'optimalAccuracy')

        optimalAccuracy = ...
            results.optimalAccuracy;

    else

        error( ...
            'Missing results.optimalAccuracy for %s.', ...
            channelName);

    end

    %% Update summary
    summary.OptimalFeatureCount(c) = ...
        optimalFeatureCount;

    summary.OptimalAccuracy(c) = ...
        optimalAccuracy;

    summary.Completed(c) = true;

    %% Save summary after every channel
    save( ...
        summaryFile, ...
        'summary', ...
        '-v7.3');

    %% Display channel result
    fprintf('\n');
    fprintf( ...
        'Optimal features : %d\n', ...
        optimalFeatureCount);

    fprintf( ...
        'Optimal accuracy : %.3f %%\n', ...
        optimalAccuracy);

end

%% Final summary
fprintf('\n============================================\n');
fprintf('IChi2 + CUBIC SVM - ALL CHANNELS SUMMARY\n');
fprintf('============================================\n');

disp(summary);

%% Calculate overall statistics
completedMask = ...
    summary.Completed & ...
    ~isnan(summary.OptimalAccuracy);

if any(completedMask)

    meanAccuracy = ...
        mean(summary.OptimalAccuracy(completedMask));

    minAccuracy = ...
        min(summary.OptimalAccuracy(completedMask));

    maxAccuracy = ...
        max(summary.OptimalAccuracy(completedMask));

    fprintf('\n');
    fprintf( ...
        'Mean accuracy across completed channels: %.3f %%\n', ...
        meanAccuracy);

    fprintf( ...
        'Minimum channel accuracy: %.3f %%\n', ...
        minAccuracy);

    fprintf( ...
        'Maximum channel accuracy: %.3f %%\n', ...
        maxAccuracy);

else

    fprintf('\n');
    fprintf('No completed channel results found.\n');

end

%% Final save
save( ...
    summaryFile, ...
    'summary', ...
    '-v7.3');

fprintf('\n');
fprintf('Summary saved to:\n');
fprintf('%s\n', summaryFile);