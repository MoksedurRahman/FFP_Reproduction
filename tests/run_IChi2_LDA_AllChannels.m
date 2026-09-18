%% ============================================================
% run_IChi2_LDA_AllChannels.m
%
% IChi2 + LDA experiment for all 14 GAMEEMO channels.
%
% Feature selection:
%   MATLAB fscchi2
%
% Classifier:
%   Linear LDA
%   DiscrimType = linear
%   Gamma = 0
%
% Validation:
%   10-fold cross-validation
%
% Feature counts:
%   100:1000
%
% ============================================================

clear;
clc;

fprintf('\n============================================\n');
fprintf('IChi2 + LDA - ALL 14 CHANNELS\n');
fprintf('============================================\n');


%% ============================================================
% 1. CONFIGURATION
% ============================================================

config = getConfig();

dataset = loadGAMEEMO(config);

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

resultsDir = fullfile( ...
    'results', ...
    'LDA');

if ~exist(resultsDir, 'dir')
    mkdir(resultsDir);
end


%% ============================================================
% 2. SUMMARY TABLE
% ============================================================

summaryFile = fullfile( ...
    resultsDir, ...
    'IChi2_LDA_AllChannels_Summary.mat');

summaryCSV = fullfile( ...
    resultsDir, ...
    'IChi2_LDA_AllChannels_Summary.csv');


% Preallocate summary

summary = table( ...
    string(channels(:)), ...
    NaN(numel(channels),1), ...
    NaN(numel(channels),1), ...
    false(numel(channels),1), ...
    'VariableNames', { ...
        'Channel', ...
        'OptimalFeatureCount', ...
        'OptimalAccuracy', ...
        'Completed'});


%% ============================================================
% 3. LOAD EXISTING RESULTS
% ============================================================

for c = 1:numel(channels)

    channel = channels{c};

    resultFile = fullfile( ...
        resultsDir, ...
        sprintf('%s_IChi2_LDA_full_results.mat', ...
        channel));

    if exist(resultFile, 'file')

        fprintf('\nExisting result found: %s\n', ...
            channel);

        loaded = load(resultFile);

        if isfield(loaded, 'results')

            oldResults = loaded.results;

            if isfield(oldResults, ...
                    'optimalFeatureCount')

                summary.OptimalFeatureCount(c) = ...
                    oldResults.optimalFeatureCount;

            end

            if isfield(oldResults, ...
                    'optimalAccuracy')

                summary.OptimalAccuracy(c) = ...
                    oldResults.optimalAccuracy;

            end

            summary.Completed(c) = true;

        end

    end

end


%% ============================================================
% 4. PROCESS EACH CHANNEL
% ============================================================

for c = 1:numel(channels)

    channel = channels{c};

    resultFile = fullfile( ...
        resultsDir, ...
        sprintf('%s_IChi2_LDA_full_results.mat', ...
        channel));


    %% --------------------------------------------------------
    % Skip completed channel
    % ---------------------------------------------------------

    if summary.Completed(c)

        fprintf('\n--------------------------------------------\n');
        fprintf('%s already completed - skipping.\n', ...
            channel);
        fprintf('--------------------------------------------\n');

        continue;

    end


    %% --------------------------------------------------------
    % Channel header
    % ---------------------------------------------------------

    fprintf('\n\n============================================\n');
    fprintf('CHANNEL %d / %d : %s\n', ...
        c, numel(channels), channel);
    fprintf('============================================\n');


    %% --------------------------------------------------------
    % Build dataset
    % ---------------------------------------------------------

    fprintf('\nBuilding dataset for %s...\n', ...
        channel);

    datasetTable = buildChannelDataset( ...
        dataset, ...
        config, ...
        channel);

    X = table2array( ...
        datasetTable(:,5:end));

    Y = datasetTable.Label;

    X = double(X);

    fprintf('Instances : %d\n', size(X,1));
    fprintf('Features  : %d\n', size(X,2));


    %% --------------------------------------------------------
    % Min-max normalization
    % ---------------------------------------------------------

    fprintf('\nNormalizing features...\n');

    xmin = min(X, [], 1);
    xmax = max(X, [], 1);

    featureRange = xmax - xmin;

    featureRange(featureRange == 0) = 1;

    Xnorm = (X - xmin) ./ featureRange;


    %% --------------------------------------------------------
    % Chi-square ranking
    % ---------------------------------------------------------

    fprintf('\nRunning MATLAB fscchi2...\n');

    [rankedFeatures, chi2Scores] = ...
        fscchi2(Xnorm, Y);

    fprintf('Chi-square ranking completed.\n');


    %% --------------------------------------------------------
    % Fixed 10-fold partition
    % ---------------------------------------------------------

    rng(seed);

    cvp = cvpartition( ...
        Y, ...
        'KFold', ...
        10);

    fprintf('\n10-fold cross-validation created.\n');


    %% --------------------------------------------------------
    % Run IChi2 + LDA
    % ---------------------------------------------------------

    fprintf('\nRunning IChi2 + LDA...\n');

    results = IChi2_LDA( ...
        X, ...
        Y, ...
        rankedFeatures, ...
        featureCounts, ...
        cvp);


    %% --------------------------------------------------------
    % Add metadata
    % ---------------------------------------------------------

    results.channel = channel;

    results.dataset = 'GAMEEMO';

    results.originalFeatureCount = size(X,2);

    results.instanceCount = size(X,1);

    results.seed = seed;

    results.featureSelectionMethod = ...
        'MATLAB fscchi2';

    results.classifier = ...
        'Linear LDA';

    results.discrimType = ...
        'linear';

    results.gamma = 0;

    results.crossValidation = ...
        '10-fold';


    %% --------------------------------------------------------
    % Save immediately
    % ---------------------------------------------------------

    save( ...
        resultFile, ...
        'results', ...
        '-v7.3');


    %% --------------------------------------------------------
    % Update summary
    % ---------------------------------------------------------

    summary.OptimalFeatureCount(c) = ...
        results.optimalFeatureCount;

    summary.OptimalAccuracy(c) = ...
        results.optimalAccuracy;

    summary.Completed(c) = true;


    save( ...
        summaryFile, ...
        'summary');


    writetable( ...
        summary, ...
        summaryCSV);


    %% --------------------------------------------------------
    % Display result
    % ---------------------------------------------------------

    fprintf('\n============================================\n');
    fprintf('%s RESULT\n', channel);
    fprintf('============================================\n');

    fprintf('Optimal feature count : %d\n', ...
        results.optimalFeatureCount);

    fprintf('Minimum loss         : %.4f\n', ...
        results.minimumLoss);

    fprintf('Optimal accuracy     : %.2f %%\n', ...
        results.optimalAccuracy);

    fprintf('============================================\n');

end


%% ============================================================
% 5. FINAL SUMMARY
% ============================================================

fprintf('\n\n============================================\n');
fprintf('IChi2 + LDA - ALL CHANNELS SUMMARY\n');
fprintf('============================================\n');

disp(summary);


%% ============================================================
% 6. SAVE FINAL SUMMARY
% ============================================================

save( ...
    summaryFile, ...
    'summary');

writetable( ...
    summary, ...
    summaryCSV);


fprintf('\nSummary saved to:\n');
fprintf('%s\n', summaryFile);

fprintf('\nCSV saved to:\n');
fprintf('%s\n', summaryCSV);

fprintf('\n============================================\n');
fprintf('ALL CHANNEL PROCESSING FINISHED\n');
fprintf('============================================\n');