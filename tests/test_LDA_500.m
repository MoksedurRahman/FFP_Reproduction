%% ============================================================
% test_LDA_500.m
%
% Purpose:
%   Diagnose the unusual 500-feature result from
%   IChi2 + LDA on the F8 channel.
%
% Method:
%   1. Load GAMEEMO F8 dataset
%   2. Min-max normalisation
%   3. MATLAB fscchi2 feature ranking
%   4. Select top 500 features
%   5. 10-fold cross-validation
%   6. Linear LDA
%   7. Gamma = 0
%   8. Examine fold accuracy and predicted class distribution
%
% ============================================================

clear;
clc;

fprintf('\n============================================\n');
fprintf('500-FEATURE LDA DIAGNOSTIC\n');
fprintf('============================================\n');


%% ============================================================
% 1. LOAD F8 DATASET
% ============================================================

config = getConfig();

dataset = loadGAMEEMO(config);

datasetTable = buildChannelDataset( ...
    dataset, ...
    config, ...
    'F8');

X = table2array(datasetTable(:,5:end));
Y = datasetTable.Label;

X = double(X);

fprintf('\nDataset information:\n');
fprintf('Instances : %d\n', size(X,1));
fprintf('Features  : %d\n', size(X,2));
fprintf('Channel   : F8\n');


%% ============================================================
% 2. MIN-MAX NORMALISATION
% ============================================================

xmin = min(X, [], 1);
xmax = max(X, [], 1);

featureRange = xmax - xmin;

% Avoid division by zero for constant features
featureRange(featureRange == 0) = 1;

Xnorm = (X - xmin) ./ featureRange;

fprintf('\nNormalization completed.\n');


%% ============================================================
% 3. CHI-SQUARE FEATURE RANKING
% ============================================================

fprintf('\nCalculating chi-square ranking...\n');

[idx, scores] = fscchi2(Xnorm, Y);

fprintf('Chi-square ranking completed.\n');

fprintf('Highest chi-square score: %.4f\n', ...
    max(scores));


%% ============================================================
% 4. CREATE FIXED 10-FOLD CROSS-VALIDATION PARTITION
% ============================================================

rng(1);

cvp = cvpartition(Y, 'KFold', 10);

fprintf('\n10-fold cross-validation created.\n');


%% ============================================================
% 5. SELECT TOP 500 FEATURES
% ============================================================

numSelected = 500;

selectedFeatures = idx(1:numSelected);

X500 = Xnorm(:, selectedFeatures);

fprintf('\nSelected features: %d\n', ...
    numSelected);


%% ============================================================
% 6. LDA CROSS-VALIDATION
% ============================================================

foldAccuracy = NaN(cvp.NumTestSets, 1);

% Store predictions for additional diagnostic analysis
allPredictions = strings(size(Y));

% Store true labels as strings
allTrueLabels = string(Y);

for fold = 1:cvp.NumTestSets

    fprintf('\n--------------------------------------------\n');
    fprintf('Fold %d / %d\n', ...
        fold, cvp.NumTestSets);
    fprintf('--------------------------------------------\n');


    %% --------------------------------------------------------
    % Training/testing split
    % ---------------------------------------------------------

    trainMask = training(cvp, fold);
    testMask  = test(cvp, fold);

    XTrain = X500(trainMask, :);
    YTrain = Y(trainMask);

    XTest = X500(testMask, :);
    YTest = Y(testMask);

    fprintf('Training samples: %d\n', ...
        size(XTrain,1));

    fprintf('Testing samples : %d\n', ...
        size(XTest,1));


    %% --------------------------------------------------------
    % Train LDA
    % ---------------------------------------------------------

    try

        Mdl = fitcdiscr( ...
            XTrain, ...
            YTrain, ...
            'DiscrimType', 'linear', ...
            'Gamma', 0);


        %% ----------------------------------------------------
        % Prediction
        % -----------------------------------------------------

        prediction = predict(Mdl, XTest);


        %% ----------------------------------------------------
        % Accuracy
        % -----------------------------------------------------

        foldAccuracy(fold) = ...
            mean(prediction == YTest) * 100;

        fprintf('\nAccuracy: %.2f %%\n', ...
            foldAccuracy(fold));


        %% ----------------------------------------------------
        % Save predictions
        % -----------------------------------------------------

        allPredictions(testMask) = string(prediction);


    catch ME

        fprintf('\nLDA ERROR in fold %d:\n', ...
            fold);

        fprintf('%s\n', ...
            ME.message);

        continue;

    end


    %% ========================================================
    % 7. PREDICTED CLASS DISTRIBUTION
    % ========================================================

    % This section is deliberately outside the try/catch so that
    % a display problem cannot overwrite a valid LDA accuracy.

    fprintf('\nPredicted class distribution:\n');

    classes = unique(allTrueLabels);

    for c = 1:numel(classes)

        count = sum( ...
            string(prediction) == classes(c));

        fprintf('  %-10s : %d\n', ...
            classes(c), ...
            count);

    end


    %% --------------------------------------------------------
    % True class distribution
    % ---------------------------------------------------------

    fprintf('True class distribution:\n');

    for c = 1:numel(classes)

        count = sum( ...
            string(YTest) == classes(c));

        fprintf('  %-10s : %d\n', ...
            classes(c), ...
            count);

    end

end


%% ============================================================
% 8. DISPLAY FOLD-BY-FOLD RESULTS
% ============================================================

fprintf('\n============================================\n');
fprintf('FOLD-BY-FOLD RESULTS\n');
fprintf('============================================\n');

for fold = 1:length(foldAccuracy)

    if isnan(foldAccuracy(fold))

        fprintf('Fold %2d : ERROR\n', ...
            fold);

    else

        fprintf('Fold %2d : %7.2f %%\n', ...
            fold, ...
            foldAccuracy(fold));

    end

end


%% ============================================================
% 9. OVERALL STATISTICS
% ============================================================

meanAccuracy = mean( ...
    foldAccuracy, ...
    'omitnan');

minimumAccuracy = min( ...
    foldAccuracy, ...
    [], ...
    'omitnan');

maximumAccuracy = max( ...
    foldAccuracy, ...
    [], ...
    'omitnan');

standardDeviation = std( ...
    foldAccuracy, ...
    'omitnan');

meanLoss = 1 - meanAccuracy / 100;


%% ============================================================
% 10. OVERALL RESULT
% ============================================================

fprintf('\n============================================\n');
fprintf('500-FEATURE LDA DIAGNOSTIC RESULT\n');
fprintf('============================================\n');

fprintf('Mean accuracy : %.2f %%\n', ...
    meanAccuracy);

fprintf('Mean loss     : %.4f\n', ...
    meanLoss);

fprintf('Minimum fold  : %.2f %%\n', ...
    minimumAccuracy);

fprintf('Maximum fold  : %.2f %%\n', ...
    maximumAccuracy);

fprintf('Std. deviation: %.2f %%\n', ...
    standardDeviation);

fprintf('============================================\n');


%% ============================================================
% 11. OVERALL PREDICTED CLASS DISTRIBUTION
% ============================================================

fprintf('\n============================================\n');
fprintf('OVERALL PREDICTED CLASS DISTRIBUTION\n');
fprintf('============================================\n');

classes = unique(allTrueLabels);

for c = 1:numel(classes)

    count = sum( ...
        allPredictions == classes(c));

    fprintf('  %-10s : %d\n', ...
        classes(c), ...
        count);

end


%% ============================================================
% 12. OVERALL TRUE CLASS DISTRIBUTION
% ============================================================

fprintf('\n============================================\n');
fprintf('OVERALL TRUE CLASS DISTRIBUTION\n');
fprintf('============================================\n');

for c = 1:numel(classes)

    count = sum( ...
        allTrueLabels == classes(c));

    fprintf('  %-10s : %d\n', ...
        classes(c), ...
        count);

end


%% ============================================================
% 13. SAVE DIAGNOSTIC RESULT
% ============================================================

if ~exist('results', 'dir')
    mkdir('results');
end

if ~exist(fullfile('results','LDA'), 'dir')
    mkdir(fullfile('results','LDA'));
end


diagnostic.featureCount = numSelected;

diagnostic.foldAccuracy = foldAccuracy;

diagnostic.meanAccuracy = meanAccuracy;

diagnostic.meanLoss = meanLoss;

diagnostic.minimumAccuracy = minimumAccuracy;

diagnostic.maximumAccuracy = maximumAccuracy;

diagnostic.standardDeviation = standardDeviation;

diagnostic.rankedFeatures = idx;

diagnostic.chi2Scores = scores;

diagnostic.predictions = allPredictions;

diagnostic.trueLabels = allTrueLabels;

diagnostic.seed = 1;


save( ...
    fullfile( ...
        'results', ...
        'LDA', ...
        'F8_LDA_500_diagnostic.mat'), ...
    'diagnostic');


%% ============================================================
% 13. CONFUSION MATRIX
% ============================================================

fprintf('\n============================================\n');
fprintf('OVERALL CONFUSION MATRIX\n');
fprintf('============================================\n');

trueLabelsCat = categorical(allTrueLabels);
predLabelsCat = categorical(allPredictions);

figure;

confusionchart( ...
    trueLabelsCat, ...
    predLabelsCat);

title('F8 - LDA with 500 Selected Features');



%% ============================================================
% 14. FINISHED
% ============================================================

fprintf('\nDiagnostic result saved.\n');

fprintf('File:\n');

fprintf( ...
    'results/LDA/F8_LDA_500_diagnostic.mat\n');

fprintf('\n============================================\n');
fprintf('DIAGNOSTIC COMPLETE\n');
fprintf('============================================\n');