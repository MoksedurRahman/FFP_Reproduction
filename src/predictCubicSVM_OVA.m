function [predictedLabels, scores] = ...
    predictCubicSVM_OVA(model, X)

% predictCubicSVM_OVA
%
% One-vs-all prediction using cubic SVM models.

    X = double(X);

    numSamples = size(X,1);
    numClasses = length(model.classes);

    scores = zeros(numSamples,numClasses);

    for c = 1:numClasses

        [~,decisionValue] = ...
            predictBinarySVM( ...
                model.binaryModels{c},X);

        scores(:,c) = decisionValue;

    end

    [~,index] = max(scores,[],2);

    predictedLabels = model.classes(index);

end