function results = IChi2_kNN(X, labels, rankedFeatures, featureCounts, cvp)
% IChi2_kNN
%
% IChi2-ranked feature selection followed by 1-NN classification.
%
% kNN configuration based on the Tuncer et al. (2021) paper:
%   - Number of neighbors: 1
%   - Distance: Manhattan
%   - Distance weighting: Equal
%   - 10-fold cross-validation
%
% Inputs:
%   X              : N x D feature matrix
%   labels         : N x 1 class labels
%   rankedFeatures : feature indices ranked by IChi2
%   featureCounts  : feature counts to evaluate, e.g. 100:1000
%   cvp            : cvpartition object containing 10 folds
%
% Output:
%   results.featureCounts
%   results.accuracy
%   results.loss
%   results.optimalFeatureCount
%   results.optimalAccuracy
%   results.minimumLoss
%   results.foldAccuracies
%   results.rankedFeatures
%   results.cvPartition

    %% Input validation

    if nargin < 5
        error('IChi2_kNN requires X, labels, rankedFeatures, featureCounts and cvp.');
    end

    X = double(X);
    labels = labels(:);
    rankedFeatures = rankedFeatures(:)';
    featureCounts = featureCounts(:);

    [N, D] = size(X);

    if length(labels) ~= N
        error('Number of labels must match number of observations.');
    end

    if any(featureCounts < 1) || any(featureCounts > D)
        error('Feature counts must be between 1 and the number of available features.');
    end

    if any(featureCounts > numel(rankedFeatures))
        error('Feature count exceeds number of ranked features.');
    end

    %% Min-max normalization
    %
    % Keep this consistent with the current IChi2/SVM/LDA implementation.

    xmin = min(X, [], 1);
    xmax = max(X, [], 1);

    featureRange = xmax - xmin;
    featureRange(featureRange == 0) = 1;

    Xnorm = (X - xmin) ./ featureRange;

    %% Preallocate

    nCounts = numel(featureCounts);
    nFolds = cvp.NumTestSets;

    accuracies = zeros(nCounts, 1);
    losses = zeros(nCounts, 1);

    foldAccuracies = zeros(nCounts, nFolds);

    %% Main feature-count loop

    for i = 1:nCounts

        numSelected = featureCounts(i);

        fprintf('    kNN: %d selected features (%d/%d)\n', ...
            numSelected, i, nCounts);

        selectedFeatures = rankedFeatures(1:numSelected);

        Xselected = Xnorm(:, selectedFeatures);

        %% Cross-validation

        for fold = 1:nFolds

            trainMask = training(cvp, fold);
            testMask  = test(cvp, fold);

            XTrain = Xselected(trainMask, :);
            YTrain = labels(trainMask);

            XTest = Xselected(testMask, :);
            YTest = labels(testMask);

            %% 1-NN
            %
            % MATLAB's 'cityblock' distance is Manhattan distance.
            %
            % Equal distance weighting means every neighbour contributes
            % equally. With k = 1, this is simply the nearest neighbour.

            Mdl = fitcknn( ...
                XTrain, ...
                YTrain, ...
                'NumNeighbors', 1, ...
                'Distance', 'cityblock', ...
                'DistanceWeight', 'equal');

            YPred = predict(Mdl, XTest);

            foldAccuracy = mean(YPred == YTest) * 100;

            foldAccuracies(i, fold) = foldAccuracy;

        end

        %% Mean CV accuracy

        accuracies(i) = mean(foldAccuracies(i, :));

        losses(i) = 1 - accuracies(i) / 100;

    end

    %% Find optimal feature count

    [minimumLoss, bestIndex] = min(losses);

    optimalFeatureCount = featureCounts(bestIndex);
    optimalAccuracy = accuracies(bestIndex);

    %% Store results

    results.featureCounts = featureCounts;
    results.accuracy = accuracies;
    results.loss = losses;

    results.optimalFeatureCount = optimalFeatureCount;
    results.optimalAccuracy = optimalAccuracy;
    results.minimumLoss = minimumLoss;

    results.foldAccuracies = foldAccuracies;

    results.rankedFeatures = rankedFeatures;

    results.cvPartition = cvp;

    results.normalization = 'Min-max normalization';

    results.classifier = '1-NN';

    results.numNeighbors = 1;
    results.distance = 'cityblock (Manhattan)';
    results.distanceWeight = 'equal';

    fprintf('\n');
    fprintf('    Optimal feature count : %d\n', optimalFeatureCount);
    fprintf('    Optimal accuracy      : %.3f%%\n', optimalAccuracy);
    fprintf('    Minimum loss          : %.6f\n', minimumLoss);

end