function results = IChi2(X, labels, featureCounts, seed)
% IChi2
%
% Iterative Chi-square feature-selection procedure using MATLAB's
% Statistics and Machine Learning Toolbox.
%
% INPUT
%   X             : N x D feature matrix
%   labels        : N x 1 class labels
%   featureCounts : candidate feature counts
%   seed          : random seed for reproducible 10-fold partition
%
% OUTPUT
%   results       : structure containing
%                   .featureCounts
%                   .accuracy
%                   .loss
%                   .optimalFeatureCount
%                   .minimumLoss
%                   .optimalAccuracy
%                   .rankedFeatures
%                   .chi2Scores
%                   .foldID
%
% PROCEDURE
%
%   1. Min-max normalisation
%   2. MATLAB fscchi2 feature ranking
%   3. Select first i ranked features
%   4. MATLAB cubic polynomial SVM
%   5. One-vs-all multiclass coding
%   6. 10-fold cross-validation
%   7. Calculate loss = 1 - accuracy
%   8. Select minimum-loss feature count
%
% NOTE
%   The paper's Algorithm 2 evaluates:
%
%       i = 100, 101, ..., 999, 1000
%
%   Therefore the default candidate range is:
%
%       featureCounts = 100:1000
%
% IMPORTANT
%   MATLAB's fscchi2 is used for feature ranking.
%   The custom chiSquareRanking.m is NOT used here.
%
%   MATLAB's fitcecoc + templateSVM is used for the cubic SVM.
%   The custom trainCubicSVM_OVA.m is NOT used here.

    %% ============================================================
    %  INPUT CHECKING
    %  ============================================================

    if nargin < 3 || isempty(featureCounts)
        featureCounts = 100:1000;
    end

    if nargin < 4 || isempty(seed)
        seed = 1;
    end

    X = double(X);
    labels = labels(:);

    [N,D] = size(X);

    if length(labels) ~= N
        error('Number of labels must match number of samples.');
    end

    featureCounts = featureCounts(:)';

    if any(featureCounts < 1)
        error('Feature counts must be positive integers.');
    end

    if any(mod(featureCounts,1) ~= 0)
        error('Feature counts must contain integers.');
    end

    if any(featureCounts > D)
        error('A requested feature count exceeds available features.');
    end

    if numel(unique(labels)) < 2
        error('At least two classes are required.');
    end

    %% ============================================================
    %  STEP 1: MIN-MAX NORMALISATION
    %  ============================================================

    fprintf('\n');
    fprintf('Step 1: Min-max normalisation...\n');

    xmin = min(X,[],1);
    xmax = max(X,[],1);

    featureRange = xmax - xmin;

    % Avoid division by zero for constant features
    featureRange(featureRange == 0) = 1;

    Xnorm = (X - xmin) ./ featureRange;

    fprintf('Samples  : %d\n',N);
    fprintf('Features : %d\n',D);

    %% ============================================================
    %  STEP 2: MATLAB CHI-SQUARE FEATURE RANKING
    %  ============================================================

    fprintf('\n');
    fprintf('Step 2: MATLAB fscchi2 feature ranking...\n');

    % MATLAB Statistics and Machine Learning Toolbox
    [rankedFeatures, chi2Scores] = ...
        fscchi2(Xnorm, labels);

    fprintf('Feature ranking completed.\n');

    %% ============================================================
    %  DISPLAY TOP FEATURES
    %  ============================================================

    numTopToDisplay = min(20,D);

    fprintf('\nTop %d ranked features:\n',numTopToDisplay);
    fprintf('%10s %15s\n','Rank','Feature');
    fprintf('----------------------------\n');

    for k = 1:numTopToDisplay
        fprintf('%10d %15d\n', ...
            k, ...
            rankedFeatures(k));
    end

    %% ============================================================
    %  STEP 3: CREATE REPRODUCIBLE 10-FOLD PARTITION
    %  ============================================================

    fprintf('\n');
    fprintf('Step 3: Creating 10-fold partition...\n');

    rng(seed);

    cvp = cvpartition(labels,'KFold',10);

    fprintf('10-fold partition created.\n');
    fprintf('Random seed : %d\n',seed);

    %% ============================================================
    %  STEP 4: ITERATIVE FEATURE SELECTION
    %  ============================================================

    numIterations = length(featureCounts);

    accuracies = zeros(numIterations,1);
    losses = zeros(numIterations,1);

    foldAccuracies = zeros(numIterations,10);

    fprintf('\n');
    fprintf('============================================\n');
    fprintf('IChi2 ITERATIVE FEATURE SELECTION\n');
    fprintf('============================================\n');

    fprintf('\n');
    fprintf('%10s %15s %15s\n', ...
        'Features','Accuracy (%)','Loss');

    fprintf('--------------------------------------------\n');

    for iteration = 1:numIterations

        numSelected = featureCounts(iteration);

        %% --------------------------------------------------------
        % Select the first i ranked features
        % ---------------------------------------------------------

        selectedFeatures = ...
            rankedFeatures(1:numSelected);

        Xselected = Xnorm(:,selectedFeatures);

        %% --------------------------------------------------------
        % MATLAB cubic SVM template
        % ---------------------------------------------------------

        svmTemplate = templateSVM( ...
            'KernelFunction','polynomial', ...
            'PolynomialOrder',3, ...
            'BoxConstraint',1, ...
            'KernelScale','auto');

        %% --------------------------------------------------------
        % 10-fold cross-validation
        % ---------------------------------------------------------

        foldAccuracy = zeros(10,1);

        for fold = 1:10

            trainMask = training(cvp,fold);
            testMask  = test(cvp,fold);

            XTrain = Xselected(trainMask,:);
            yTrain = labels(trainMask);

            XTest = Xselected(testMask,:);
            yTest = labels(testMask);

            %% ----------------------------------------------------
            % MATLAB multiclass cubic SVM
            % One-vs-all coding
            % -----------------------------------------------------

            Mdl = fitcecoc( ...
                XTrain, ...
                yTrain, ...
                'Learners',svmTemplate, ...
                'Coding','onevsall');

            %% ----------------------------------------------------
            % Prediction
            % -----------------------------------------------------

            prediction = predict(Mdl,XTest);

            %% ----------------------------------------------------
            % Fold accuracy
            % -----------------------------------------------------

            foldAccuracy(fold) = ...
                mean(prediction == yTest) * 100;

        end

        %% --------------------------------------------------------
        % Mean accuracy
        % ---------------------------------------------------------

        accuracies(iteration) = ...
            mean(foldAccuracy);

        %% --------------------------------------------------------
        % Loss
        % ---------------------------------------------------------

        losses(iteration) = ...
            1 - accuracies(iteration)/100;

        %% --------------------------------------------------------
        % Store fold-level results
        % ---------------------------------------------------------

        foldAccuracies(iteration,:) = ...
            foldAccuracy(:)';

        %% --------------------------------------------------------
        % Display result
        % ---------------------------------------------------------

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

    optimalAccuracy = ...
        accuracies(bestIndex);

    %% ============================================================
    %  OUTPUT
    %  ============================================================

    results.featureCounts = ...
        featureCounts(:);

    results.accuracy = ...
        accuracies;

    results.loss = ...
        losses;

    results.optimalFeatureCount = ...
        optimalFeatureCount;

    results.minimumLoss = ...
        minimumLoss;

    results.optimalAccuracy = ...
        optimalAccuracy;

    results.rankedFeatures = ...
        rankedFeatures;

    results.chi2Scores = ...
        chi2Scores;

    results.foldAccuracies = ...
        foldAccuracies;

    results.seed = ...
        seed;

    %% ============================================================
    %  FINAL REPORT
    %  ============================================================

    fprintf('\n');
    fprintf('============================================\n');
    fprintf('IChi2 RESULT\n');
    fprintf('============================================\n');

    fprintf('Total original features : %d\n',D);

    fprintf('Optimal feature count   : %d\n', ...
        optimalFeatureCount);

    fprintf('Minimum loss            : %.4f\n', ...
        minimumLoss);

    fprintf('Optimal accuracy        : %.2f %%\n', ...
        optimalAccuracy);

    fprintf('============================================\n');

end