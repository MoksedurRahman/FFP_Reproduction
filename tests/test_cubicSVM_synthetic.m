function test_cubicSVM_synthetic()

    fprintf('\n');
    fprintf('============================================\n');
    fprintf('CUBIC SVM SYNTHETIC VALIDATION\n');
    fprintf('============================================\n');

    %% Reproducibility

    rng(1,'twister');

    %% Create four clearly separated classes

    samplesPerClass = 50;

    X1 = randn(samplesPerClass,2) + [-5 -5];
    X2 = randn(samplesPerClass,2) + [-5  5];
    X3 = randn(samplesPerClass,2) + [ 5 -5];
    X4 = randn(samplesPerClass,2) + [ 5  5];

    X = [
        X1
        X2
        X3
        X4
    ];

    y = [
        ones(samplesPerClass,1)
        2*ones(samplesPerClass,1)
        3*ones(samplesPerClass,1)
        4*ones(samplesPerClass,1)
    ];

    %% Normalise

    xmin = min(X,[],1);
    xmax = max(X,[],1);

    X = (X-xmin)./(xmax-xmin);

    %% Train

    fprintf('\nTraining cubic one-vs-all SVM...\n');

    model = trainCubicSVM_OVA(X,y,1);

    %% Predict

    [prediction,~] = ...
        predictCubicSVM_OVA(model,X);

    %% Accuracy

    accuracy = mean(prediction == y)*100;

    fprintf('\n============================================\n');
    fprintf('RESULT\n');
    fprintf('============================================\n');

    fprintf('Samples        : %d\n',size(X,1));
    fprintf('Classes        : %d\n',length(unique(y)));
    fprintf('Training acc.  : %.2f %%\n',accuracy);

    %% Validation

    if accuracy >= 90

        fprintf('Synthetic SVM  : PASSED\n');

    else

        fprintf('Synthetic SVM  : FAILED\n');
        error('Cubic SVM failed the synthetic validation.');

    end

    fprintf('\n============================================\n');
    fprintf('SYNTHETIC SVM TEST COMPLETED\n');
    fprintf('============================================\n');

end