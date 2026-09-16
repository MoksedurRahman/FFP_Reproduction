function test_SVM_diagnostic()

clc;

fprintf('\n============================================\n');
fprintf('SVM KERNEL DIAGNOSTIC\n');
fprintf('============================================\n');

%% Load data

config = getConfig();

fprintf('\nLoading GAMEEMO...\n');
dataset = loadGAMEEMO(config);

fprintf('Building AF3 dataset...\n');
datasetTable = buildChannelDataset(dataset, config, 'AF3');

%% Features and labels

X = table2array(datasetTable(:,5:end));

labelText = string(datasetTable.Label);

classes = unique(labelText);

labels = zeros(length(labelText),1);

for i = 1:length(classes)
    labels(labelText == classes(i)) = i;
end

fprintf('\nSamples  = %d\n',size(X,1));
fprintf('Features = %d\n',size(X,2));
fprintf('Classes  = %d\n',length(classes));

%% Normalise

xmin = min(X,[],1);
xmax = max(X,[],1);

rangeX = xmax - xmin;
rangeX(rangeX == 0) = 1;

Xnorm = (X - xmin) ./ rangeX;

fprintf('\nNormalisation complete.\n');
fprintf('Minimum = %.6f\n',min(Xnorm(:)));
fprintf('Maximum = %.6f\n',max(Xnorm(:)));

%% Chi-square ranking

fprintf('\nCalculating Chi-square ranking...\n');

[rankedFeatures,chi2Scores] = chiSquareRanking(Xnorm,labels);

fprintf('Ranking complete.\n');

%% Test dimensions

featureCounts = [100 400 600 1000];

for q = 1:length(featureCounts)

    D = featureCounts(q);

    fprintf('\n--------------------------------------------\n');
    fprintf('TESTING %d FEATURES\n',D);
    fprintf('--------------------------------------------\n');

    selected = rankedFeatures(1:D);

    Xtest = Xnorm(:,selected);

    fprintf('Feature matrix: %d samples x %d features\n', ...
        size(Xtest,1),size(Xtest,2));

    %% Kernel

    fprintf('Calculating kernel...\n');

    K = cubicKernel(Xtest,Xtest);

    fprintf('Kernel calculated.\n');

    a = min(K(:));
    b = max(K(:));
    c = mean(K(:));
    d = std(K(:));

    fprintf('K minimum = %.6e\n',a);
    fprintf('K maximum = %.6e\n',b);
    fprintf('K mean    = %.6e\n',c);
    fprintf('K std     = %.6e\n',d);

    if all(isfinite(K(:)))
        fprintf('Finite values = PASSED\n');
    else
        fprintf('Finite values = FAILED\n');
    end

    %% Symmetry

    Ktranspose = K';

    difference = abs(K - Ktranspose);

    symmetryError = max(difference(:));

    fprintf('Symmetry error = %.6e\n',symmetryError);

    clear K Ktranspose difference

end

fprintf('\n============================================\n');
fprintf('KERNEL DIAGNOSTIC COMPLETED\n');
fprintf('============================================\n');

end