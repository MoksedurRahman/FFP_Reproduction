function results = IChi2_LDA(X, labels, rankedFeatures, ...
                              featureCounts, cvp)
% IChi2_LDA
%
% Evaluate LDA classification using the feature ranking generated
% by MATLAB fscchi2.
%
% INPUT
%   X              : N x D feature matrix
%   labels         : N x 1 class labels
%   rankedFeatures : Feature ranking from fscchi2
%   featureCounts  : Candidate feature counts
%   cvp            : MATLAB cvpartition object
%
% OUTPUT
%   results.featureCounts
%   results.accuracy
%   results.loss
%   results.optimalFeatureCount
%   results.optimalAccuracy
%   results.minimumLoss
%   results.foldAccuracies

    %% Input checking

    X = double(X);
    labels = labels(:);

    [N,D] = size(X);

    if length(labels) ~= N
        error('Number of labels must match number of samples.');
    end

    if any(featureCounts > D)
        error('Requested feature count exceeds available features.');
    end

    %% Min-max normalisation

    xmin = min(X,[],1);
    xmax = max(X,[],1);

    featureRange = xmax - xmin;
    featureRange(featureRange == 0) = 1;

    Xnorm = (X - xmin) ./ featureRange;

    %% Results

    numIterations = length(featureCounts);

    accuracies = zeros(numIterations,1);
    losses = zeros(numIterations,1);

    foldAccuracies = zeros(numIterations,cvp.NumTestSets);

    %% Iterative feature evaluation

    fprintf('\n');
    fprintf('============================================\n');
    fprintf('IChi2 + LDA\n');
    fprintf('============================================\n');

    fprintf('\n');
    fprintf('%10s %15s %15s\n', ...
        'Features','Accuracy (%)','Loss');

    fprintf('--------------------------------------------\n');

    for iteration = 1:numIterations

        numSelected = featureCounts(iteration);

        %% Select ranked features

        selectedFeatures = ...
            rankedFeatures(1:numSelected);

        Xselected = Xnorm(:,selectedFeatures);

        %% 10-fold CV

        foldAccuracy = zeros(cvp.NumTestSets,1);

        for fold = 1:cvp.NumTestSets

            trainMask = training(cvp,fold);
            testMask  = test(cvp,fold);

            XTrain = Xselected(trainMask,:);
            yTrain = labels(trainMask);

            XTest = Xselected(testMask,:);
            yTest = labels(testMask);

            %% MATLAB LDA
            %
            % Full covariance, corresponding to Gamma = 0.
            %

            Mdl = fitcdiscr( ...
                XTrain, ...
                yTrain, ...
                'DiscrimType','linear', ...
                'Gamma',0);

            %% Prediction

            prediction = predict(Mdl,XTest);

            %% Accuracy

            foldAccuracy(fold) = ...
                mean(prediction == yTest) * 100;

        end

        %% Mean accuracy

        accuracies(iteration) = ...
            mean(foldAccuracy);

        %% Loss

        losses(iteration) = ...
            1 - accuracies(iteration)/100;

        foldAccuracies(iteration,:) = ...
            foldAccuracy(:)';

        fprintf('%10d %15.2f %15.4f\n', ...
            numSelected, ...
            accuracies(iteration), ...
            losses(iteration));

    end

    %% Find minimum loss

    [minimumLoss,bestIndex] = min(losses);

    optimalFeatureCount = ...
        featureCounts(bestIndex);

    optimalAccuracy = ...
        accuracies(bestIndex);

    %% Output

    results.featureCounts = featureCounts(:);

    results.accuracy = accuracies;

    results.loss = losses;

    results.optimalFeatureCount = ...
        optimalFeatureCount;

    results.optimalAccuracy = ...
        optimalAccuracy;

    results.minimumLoss = ...
        minimumLoss;

    results.foldAccuracies = ...
        foldAccuracies;

    %% Final report

    fprintf('\n');
    fprintf('============================================\n');
    fprintf('IChi2 + LDA RESULT\n');
    fprintf('============================================\n');

    fprintf('Optimal feature count : %d\n', ...
        optimalFeatureCount);

    fprintf('Minimum loss         : %.4f\n', ...
        minimumLoss);

    fprintf('Optimal accuracy     : %.2f %%\n', ...
        optimalAccuracy);

    fprintf('============================================\n');

end