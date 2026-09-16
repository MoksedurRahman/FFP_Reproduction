function [predictedLabel, decisionValue] = ...
    predictBinarySVM(model, X)

% predictBinarySVM
%
% Predict using a trained cubic-kernel binary SVM.

    X = double(X);

    K = cubicKernel(X,model.X);

    decisionValue = ...
        K * (model.alpha .* model.y) + model.b;

    predictedLabel = ones(size(decisionValue));

    predictedLabel(decisionValue < 0) = -1;

end