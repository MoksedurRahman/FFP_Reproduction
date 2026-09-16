function test_cubicSVM()

    fprintf('\n');
    fprintf('============================================\n');
    fprintf('CUBIC SVM TEST\n');
    fprintf('============================================\n');

    %% Load dataset

    fprintf('\nLoading GAMEEMO dataset...\n');

    config = getConfig();

    dataset = loadGAMEEMO(config);

    %% Build AF3 dataset

    fprintf('\nBuilding AF3 dataset...\n');

    datasetTable = buildChannelDataset( ...
        dataset,config,'AF3');

    %% Feature matrix

    X = table2array( ...
        datasetTable(:,5:end));

    %% Convert labels

    labelStrings = string(datasetTable.Label);

    labels = zeros(length(labelStrings),1);

    labels(labelStrings == "Boring") = 1;
    labels(labelStrings == "Calm")   = 2;
    labels(labelStrings == "Horror") = 3;
    labels(labelStrings == "Funny")  = 4;

    %% Chi-square ranking

    fprintf('\nCalculating Chi-square ranking...\n');

    [rankedFeatures,~] = ...
        chiSquareRanking(X,labelStrings);

    %% Select top 100

    numSelected = 100;

    selected = rankedFeatures(1:numSelected);

    X = X(:,selected);

    fprintf('\n============================================\n');
    fprintf('SVM INPUT\n');
    fprintf('============================================\n');

    fprintf('Instances         : %d\n',size(X,1));
    fprintf('Selected features : %d\n',size(X,2));

    %% Normalize

    minimum = min(X,[],1);
    maximum = max(X,[],1);

    rangeValue = maximum-minimum;

    rangeValue(rangeValue == 0) = 1;

    X = (X-minimum)./rangeValue;

    fprintf('Normalization     : Min-max\n');

    %% Create 10 folds

    foldID = create10Folds(size(X,1),1);

    %% Cross-validation

    accuracy = zeros(10,1);

    fprintf('\n============================================\n');
    fprintf('10-FOLD CROSS-VALIDATION\n');
    fprintf('============================================\n');

    for fold = 1:10

        fprintf('\nFold %d / 10\n',fold);

        trainMask = foldID ~= fold;
        testMask  = foldID == fold;

        XTrain = X(trainMask,:);
        yTrain = labels(trainMask);

        XTest = X(testMask,:);
        yTest = labels(testMask);

        %% Train

        tic;

        model = trainCubicSVM_OVA( ...
            XTrain,yTrain,1);

        trainingTime = toc;

        %% Predict

        [prediction,~] = ...
            predictCubicSVM_OVA(model,XTest);

        %% Accuracy

        accuracy(fold) = ...
            mean(prediction == yTest)*100;

        fprintf('Accuracy      : %.2f %%\n', ...
            accuracy(fold));

        fprintf('Training time : %.2f s\n', ...
            trainingTime);

    end

    %% Final result

    meanAccuracy = mean(accuracy);

    fprintf('\n============================================\n');
    fprintf('FINAL SVM RESULT\n');
    fprintf('============================================\n');

    fprintf('Mean accuracy : %.2f %%\n',meanAccuracy);
    fprintf('Std accuracy  : %.2f %%\n',std(accuracy));

    fprintf('\n============================================\n');
    fprintf('CUBIC SVM TEST COMPLETED\n');
    fprintf('============================================\n');

end