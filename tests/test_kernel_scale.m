function test_kernel_scale()

clc;

fprintf('\n============================================\n');
fprintf('KERNEL SCALE TEST\n');
fprintf('============================================\n');

%% Load dataset

config = getConfig();

fprintf('\nLoading GAMEEMO...\n');

dataset = loadGAMEEMO(config);

fprintf('Building AF3 dataset...\n');

datasetTable = buildChannelDataset(dataset,config,'AF3');

%% Features

X = table2array(datasetTable(:,5:end));

%% Labels

labelText = string(datasetTable.Label);

classes = unique(labelText);

labels = zeros(length(labelText),1);

for i = 1:length(classes)
    labels(labelText == classes(i)) = i;
end

%% Normalisation

xmin = min(X,[],1);
xmax = max(X,[],1);

rangeX = xmax - xmin;
rangeX(rangeX == 0) = 1;

Xnorm = (X - xmin) ./ rangeX;

%% Chi-square ranking

fprintf('\nCalculating Chi-square ranking...\n');

[rankedFeatures,~] = chiSquareRanking(Xnorm,labels);

%% Use 600 features

D = 600;

selected = rankedFeatures(1:D);

Xselected = Xnorm(:,selected);

fprintf('\nUsing %d features.\n',D);

%% Calculate pairwise squared distances

fprintf('\nCalculating pairwise distances...\n');

G = sum(Xselected.^2,2);

distanceSquared = bsxfun(@plus,G,G') ...
                - 2*(Xselected*Xselected');

distanceSquared(distanceSquared < 0) = 0;

fprintf('Minimum squared distance = %.6e\n', ...
    min(distanceSquared(:)));

fprintf('Maximum squared distance = %.6e\n', ...
    max(distanceSquared(:)));

fprintf('Mean squared distance = %.6e\n', ...
    mean(distanceSquared(:)));

%% Automatic scale estimate

sigma = median(sqrt(distanceSquared(:)));

if sigma <= 0
    error('Invalid kernel scale.');
end

fprintf('\nEstimated kernel scale:\n');
fprintf('Sigma = %.6e\n',sigma);

%% Scaled polynomial kernel

fprintf('\nCalculating scaled cubic kernel...\n');

Kscaled = (Xselected*Xselected' / sigma + 1).^3;

fprintf('Scaled kernel statistics:\n');

fprintf('Minimum = %.6e\n',min(Kscaled(:)));
fprintf('Maximum = %.6e\n',max(Kscaled(:)));
fprintf('Mean    = %.6e\n',mean(Kscaled(:)));
fprintf('Std     = %.6e\n',std(Kscaled(:)));

if all(isfinite(Kscaled(:)))
    fprintf('Finite values = PASSED\n');
else
    fprintf('Finite values = FAILED\n');
end

%% Compare with current kernel

fprintf('\nCurrent kernel statistics:\n');

Kcurrent = cubicKernel(Xselected,Xselected);

fprintf('Minimum = %.6e\n',min(Kcurrent(:)));
fprintf('Maximum = %.6e\n',max(Kcurrent(:)));
fprintf('Mean    = %.6e\n',mean(Kcurrent(:)));
fprintf('Std     = %.6e\n',std(Kcurrent(:)));

%% Finish

fprintf('\n============================================\n');
fprintf('KERNEL SCALE TEST COMPLETED\n');
fprintf('============================================\n');

end