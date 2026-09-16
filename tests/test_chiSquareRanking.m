function test_chiSquareRanking()

    fprintf('\n');
    fprintf('============================================\n');
    fprintf('CHI-SQUARE FEATURE RANKING TEST\n');
    fprintf('============================================\n');

    %% Load configuration

    config = getConfig();

    %% Load GAMEEMO

    fprintf('\nLoading GAMEEMO dataset...\n');

    dataset = loadGAMEEMO(config);

    %% Build AF3 dataset

    fprintf('\nBuilding AF3 dataset...\n');
    fprintf('This may take some time.\n\n');

    datasetTable = buildChannelDataset( ...
        dataset, config, 'AF3');

    %% Extract metadata

    labels = datasetTable.Label;

    %% Extract features

    featureStart = 5;

    X = table2array( ...
        datasetTable(:,featureStart:end));

    fprintf('============================================\n');
    fprintf('INPUT DATA\n');
    fprintf('============================================\n');

    fprintf('Instances : %d\n',size(X,1));
    fprintf('Features  : %d\n',size(X,2));

    %% Run Chi-square ranking

    fprintf('\nRunning Chi-square ranking...\n');

    tic;

    [rankedFeatures, chi2Scores] = ...
        chiSquareRanking(X,labels);

    elapsedTime = toc;

    %% Validation

    fprintf('\n============================================\n');
    fprintf('VALIDATION\n');
    fprintf('============================================\n');

    fprintf('Ranking length : %d\n', ...
        length(rankedFeatures));

    fprintf('Expected       : %d\n', ...
        size(X,2));

    if length(rankedFeatures) == size(X,2)
        fprintf('Ranking length : PASSED\n');
    else
        error('Incorrect ranking length.');
    end

    %% Check uniqueness

    if length(unique(rankedFeatures)) == size(X,2)
        fprintf('Unique indices : PASSED\n');
    else
        error('Feature indices are not unique.');
    end

    %% Check score values

    if all(isfinite(chi2Scores))
        fprintf('Finite scores  : PASSED\n');
    else
        error('Chi-square scores contain invalid values.');
    end

    %% Display top features

    fprintf('\n============================================\n');
    fprintf('TOP 20 FEATURES\n');
    fprintf('============================================\n');

    fprintf('\nRank    Feature       Chi2 Score\n');
    fprintf('--------------------------------------------\n');

    for i = 1:20

        featureIndex = rankedFeatures(i);

        fprintf('%4d    F%05d       %.6f\n', ...
            i, ...
            featureIndex, ...
            chi2Scores(featureIndex));

    end

    fprintf('\nProcessing time : %.2f seconds\n', ...
        elapsedTime);

    fprintf('\n============================================\n');
    fprintf('CHI-SQUARE TEST COMPLETED\n');
    fprintf('============================================\n');

end