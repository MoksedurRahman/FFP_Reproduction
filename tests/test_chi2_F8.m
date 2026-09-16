function test_chi2_F8()

    fprintf('\n');
    fprintf('============================================\n');
    fprintf('F8 CHI-SQUARE RANKING DIAGNOSTIC\n');
    fprintf('============================================\n');

    %% Configuration

    config = getConfig();

    %% Load dataset

    fprintf('\nLoading GAMEEMO...\n');

    dataset = loadGAMEEMO(config);

    %% Build F8 dataset

    fprintf('\nBuilding F8 dataset...\n');

    tic;

    datasetTable = buildChannelDataset( ...
        dataset, config, 'F8');

    assemblyTime = toc;

    %% Extract X

    X = table2array( ...
        datasetTable(:,5:end));

    %% Labels

    labelStrings = string(datasetTable.Label);

    labels = zeros(length(labelStrings),1);

    labels(labelStrings == "Boring") = 1;
    labels(labelStrings == "Calm")   = 2;
    labels(labelStrings == "Horror") = 3;
    labels(labelStrings == "Funny")  = 4;

    %% Min-max normalisation

    xmin = min(X,[],1);
    xmax = max(X,[],1);

    featureRange = xmax - xmin;

    featureRange(featureRange == 0) = 1;

    Xnorm = (X - xmin) ./ featureRange;

    %% Chi-square ranking

    fprintf('\nCalculating Chi-square ranking...\n');

    tic;

    [rankedFeatures, chi2Scores] = ...
        chiSquareRanking(Xnorm, labels);

    chiTime = toc;

    %% Display top features

    fprintf('\n');
    fprintf('Top 20 ranked features:\n');
    fprintf('--------------------------------------------\n');

    fprintf('%10s %20s\n', ...
        'Rank', 'Feature Index');

    fprintf('--------------------------------------------\n');

    for i = 1:20

        fprintf('%10d %20d\n', ...
            i, rankedFeatures(i));

    end

    %% Score information

    fprintf('\n');
    fprintf('Chi-square score statistics:\n');

    fprintf('Minimum : %.6f\n', ...
        min(chi2Scores));

    fprintf('Maximum : %.6f\n', ...
        max(chi2Scores));

    fprintf('Mean    : %.6f\n', ...
        mean(chi2Scores));

    fprintf('Median  : %.6f\n', ...
        median(chi2Scores));

    %% Check selected counts

    fprintf('\n');
    fprintf('Feature-selection checkpoints:\n');

    checkpoints = [100 500 888 900 1000];

    for k = 1:length(checkpoints)

        n = checkpoints(k);

        selected = rankedFeatures(1:n);

        fprintf('%4d features: feature range [%d, %d]\n', ...
            n, ...
            min(selected), ...
            max(selected));

    end

    %% Final

    fprintf('\n');
    fprintf('Dataset assembly time : %.2f s\n', ...
        assemblyTime);

    fprintf('Chi-square time       : %.2f s\n', ...
        chiTime);

    fprintf('\n');
    fprintf('============================================\n');
    fprintf('CHI-SQUARE DIAGNOSTIC COMPLETED\n');
    fprintf('============================================\n');

end