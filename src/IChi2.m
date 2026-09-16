function results = IChi2(X, labels, featureCounts, seed)
% IChi2
%
% Toolbox-independent implementation of the iterative Chi-square
% feature-selection procedure described in the FFP paper.
%
% INPUT
%   X             : N x D feature matrix
%   labels        : N x 1 numeric class labels
%   featureCounts : candidate feature counts
%   seed          : random seed for 10-fold partition
%
% OUTPUT
%   results       : structure containing
%                   .featureCounts
%                   .accuracy
%                   .loss
%                   .optimalFeatureCount
%                   .minimumLoss
%                   .rankedFeatures
%
% Procedure:
%
%   1. Min-max normalisation
%   2. Chi-square feature ranking
%   3. Select first i ranked features
%   4. Cubic SVM
%   5. 10-fold cross-validation
%   6. Calculate loss = 1 - accuracy
%   7. Select minimum-loss feature count
%
% NOTE:
%   Algorithm 2 in the paper explicitly evaluates every integer
%   feature count from 100 to 1000:
%
%       i ∈ {100, 101, ..., 999, 1000}
%
%   Therefore, the default candidate range is:
%
%       featureCounts = 100:1000;

    if nargin < 3 || isempty(featureCounts)
        featureCounts = 100:1000;
    end

    if nargin < 4
        seed = 1;
    end

    X = double(X);
    labels = double(labels(:));

    [N,D] = size(X);

    if length(labels) ~= N
        error('Number of labels must match number of samples.');
    end

    if any(featureCounts > D)
        error('A requested feature count exceeds available features.');
    end

    %% ============================================================
    %  STEP 1: MIN-MAX NORMALISATION
    %  ============================================================

    fprintf('\nNormalising features...\n');

    xmin = min(X,[],1);
    xmax = max(X,[],1);

    featureRange = xmax-xmin;

    % Avoid division by zero
    featureRange(featureRange == 0) = 1;

    Xnorm = (X-xmin)./featureRange;

    %% ============================================================
    %  STEP 2: CHI-SQUARE RANKING
    %  ============================================================

    fprintf('Calculating Chi-square ranking...\n');

    [rankedFeatures,chi2Scores] = ...
        chiSquareRanking(Xnorm,labels);

    %% ============================================================
    %  STEP 3: 10-FOLD PARTITION
    %  ============================================================

    foldID = create10Folds(N,seed);

    numIterations = length(featureCounts);

    accuracies = zeros(numIterations,1);
    losses = zeros(numIterations,1);

    %% ============================================================
    %  STEP 4: ITERATIVE FEATURE SELECTION
    %  ============================================================

    fprintf('\n');
    fprintf('============================================\n');
    fprintf('ICH12 ITERATIVE FEATURE SELECTION\n');
    fprintf('============================================\n');

    fprintf('\n');
    fprintf('%10s %15s %15s\n', ...
        'Features','Accuracy (%)','Loss');

    fprintf('--------------------------------------------\n');

    for iteration = 1:numIterations

        numSelected = featureCounts(iteration);

        fprintf('\nEvaluating %d features...\n', ...
            numSelected);

        %% Select ranked features

        selectedFeatures = ...
            rankedFeatures(1:numSelected);

        Xselected = Xnorm(:,selectedFeatures);

        %% 10-fold CV

        foldAccuracy = zeros(10,1);

        for fold = 1:10

            trainMask = foldID ~= fold;
            testMask  = foldID == fold;

            XTrain = Xselected(trainMask,:);
            yTrain = labels(trainMask);

            XTest = Xselected(testMask,:);
            yTest = labels(testMask);

            %% Train cubic one-vs-all SVM

            model = trainCubicSVM_OVA( ...
                XTrain,yTrain,1);

            %% Predict

            prediction = predictCubicSVM_OVA( ...
                model,XTest);

            %% Accuracy

            foldAccuracy(fold) = ...
                mean(prediction == yTest)*100;

        end

        %% Mean accuracy

        accuracies(iteration) = ...
            mean(foldAccuracy);

        %% Loss

        losses(iteration) = ...
            1 - accuracies(iteration)/100;

        fprintf('%10d %15.2f %15.4f\n', ...
            numSelected, ...
            accuracies(iteration), ...
            losses(iteration));

    end

    %% ============================================================
    %  STEP 5: FIND MINIMUM LOSS
    %  ============================================================

    [minimumLoss,bestIndex] = min(losses);

    optimalFeatureCount = ...
        featureCounts(bestIndex);

    %% ============================================================
    %  OUTPUT
    %  ============================================================

    results.featureCounts = featureCounts(:);

    results.accuracy = accuracies;

    results.loss = losses;

    results.optimalFeatureCount = ...
        optimalFeatureCount;

    results.minimumLoss = ...
        minimumLoss;

    results.optimalAccuracy = ...
        accuracies(bestIndex);

    results.rankedFeatures = ...
        rankedFeatures;

    results.chi2Scores = ...
        chi2Scores;

    results.foldID = ...
        foldID;

    %% ============================================================
    %  FINAL REPORT
    %  ============================================================

    fprintf('\n');
    fprintf('============================================\n');
    fprintf('ICH12 RESULT\n');
    fprintf('============================================\n');

    fprintf('Optimal feature count : %d\n', ...
        optimalFeatureCount);

    fprintf('Minimum loss         : %.4f\n', ...
        minimumLoss);

    fprintf('Optimal accuracy     : %.2f %%\n', ...
        accuracies(bestIndex));

end