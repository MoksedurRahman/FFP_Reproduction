function test_SVM_600()

clc;

fprintf('\n============================================\n');
fprintf('CUBIC SVM 600-FEATURE TEST\n');
fprintf('============================================\n');

%% Load configuration

config = getConfig();

%% Load dataset

fprintf('\nLoading GAMEEMO...\n');

dataset = loadGAMEEMO(config);

fprintf('Building AF3 dataset...\n');

datasetTable = buildChannelDataset(dataset,config,'AF3');

%% Extract X

X = table2array(datasetTable(:,5:end));

%% Labels

labelText = string(datasetTable.Label);

classes = unique(labelText);

labels = zeros(length(labelText),1);

for i = 1:length(classes)
    labels(labelText == classes(i)) = i;
end

fprintf('\nSamples  = %d\n',size(X,1));
fprintf('Features = %d\n',size(X,2));

%% Normalise

xmin = min(X,[],1);
xmax = max(X,[],1);

rangeX = xmax - xmin;
rangeX(rangeX == 0) = 1;

Xnorm = (X - xmin) ./ rangeX;

%% Chi-square ranking

fprintf('\nCalculating Chi-square ranking...\n');

[rankedFeatures,~] = chiSquareRanking(Xnorm,labels);

%% Select 600

D = 600;

selected = rankedFeatures(1:D);

Xselected = Xnorm(:,selected);

fprintf('\nUsing top %d features.\n',D);

%% Create folds

foldID = create10Folds(size(X,1),1);

%% Fold 1

trainMask = foldID ~= 1;
testMask = foldID == 1;

XTrain = Xselected(trainMask,:);
yTrain = labels(trainMask);

XTest = Xselected(testMask,:);
yTest = labels(testMask);

fprintf('\nTraining SVM...\n');

tic;

model = trainCubicSVM_OVA(XTrain,yTrain,1);

trainingTime = toc;

fprintf('Training time = %.3f seconds\n',trainingTime);

%% Support vectors

fprintf('\nSupport vectors:\n');

for i = 1:length(model.classes)

    binaryModel = model.binaryModels{i};

    fprintf('Class %d: %d support vectors\n', ...
        model.classes(i),length(binaryModel.alpha));

end

%% Prediction

fprintf('\nPredicting...\n');

[predictedLabels,scores] = ...
    predictCubicSVM_OVA(model,XTest);

%% Accuracy

accuracy = mean(predictedLabels == yTest) * 100;

fprintf('\nAccuracy = %.2f %%\n',accuracy);

%% True class distribution

fprintf('\nTRUE CLASS DISTRIBUTION\n');

for i = 1:length(model.classes)

    currentClass = model.classes(i);

    count = sum(yTest == currentClass);

    fprintf('Class %d = %d\n',currentClass,count);

end

%% Predicted distribution

fprintf('\nPREDICTED CLASS DISTRIBUTION\n');

for i = 1:length(model.classes)

    currentClass = model.classes(i);

    count = sum(predictedLabels == currentClass);

    fprintf('Class %d = %d\n',currentClass,count);

end

%% Decision scores

fprintf('\nDECISION SCORES\n');

for i = 1:size(scores,2)

    fprintf('\nClass %d\n',model.classes(i));

    fprintf('Minimum = %.6e\n',min(scores(:,i)));
    fprintf('Maximum = %.6e\n',max(scores(:,i)));
    fprintf('Mean    = %.6e\n',mean(scores(:,i)));
    fprintf('Std     = %.6e\n',std(scores(:,i)));

end

fprintf('\n============================================\n');
fprintf('600-FEATURE TEST COMPLETED\n');
fprintf('============================================\n');

end