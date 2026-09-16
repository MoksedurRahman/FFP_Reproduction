function test_create10Folds()

    fprintf('\n');
    fprintf('============================================\n');
    fprintf('10-FOLD CROSS-VALIDATION PARTITION TEST\n');
    fprintf('============================================\n');

    %% Dataset size

    numSamples = 560;

    %% Create folds

    foldID = create10Folds(numSamples,1);

    %% Basic validation

    fprintf('\n============================================\n');
    fprintf('FOLD INFORMATION\n');
    fprintf('============================================\n');

    fprintf('Number of samples : %d\n',numSamples);
    fprintf('Number of folds   : %d\n',length(unique(foldID)));

    %% Check number of folds

    if length(unique(foldID)) == 10
        fprintf('10 folds          : PASSED\n');
    else
        error('Incorrect number of folds.');
    end

    %% Count samples per fold

    fprintf('\nSamples per fold\n');
    fprintf('--------------------------------------------\n');

    foldCounts = zeros(10,1);

    for k = 1:10

        foldCounts(k) = sum(foldID == k);

        fprintf('Fold %2d : %d samples\n', ...
            k,foldCounts(k));

    end

    %% Balanced-fold validation

    if all(foldCounts == 56)
        fprintf('\nBalanced folds    : PASSED\n');
    else
        error('Fold sizes are not balanced.');
    end

    %% Check all samples assigned

    if all(foldID >= 1 & foldID <= 10)
        fprintf('All samples assigned : PASSED\n');
    else
        error('Invalid fold assignments.');
    end

    %% Reproducibility test

    foldID2 = create10Folds(numSamples,1);

    if isequal(foldID,foldID2)
        fprintf('Reproducibility   : PASSED\n');
    else
        error('Fold generation is not reproducible.');
    end

    %% Final

    fprintf('\n============================================\n');
    fprintf('10-FOLD TEST COMPLETED\n');
    fprintf('============================================\n');

end