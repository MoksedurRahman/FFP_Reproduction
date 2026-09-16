function model = trainCubicSVM_OVA(X, labels, C,sigma)
% trainCubicSVM_OVA
%
% One-vs-all multiclass cubic SVM.
%
% INPUT
%   X      : N x D feature matrix
%   labels : N x 1 numeric class labels
%   C      : SVM box constraint
%
% OUTPUT
%   model  : multiclass SVM model
%
% Classes are encoded as:
%   1 = Boring
%   2 = Calm
%   3 = Horror
%   4 = Funny

    X = double(X);
    labels = double(labels(:));

    if nargin<3
        C=1;
    end
    
    if nargin<4
        sigma=[];
    end

    classes = unique(labels);
    numClasses = length(classes);

    model.classes = classes;
    model.binaryModels = cell(numClasses,1);

    for c = 1:numClasses

        fprintf('Training class %d vs all...\n',classes(c));

        yBinary = -ones(size(labels));

        yBinary(labels == classes(c)) = 1;

        model.binaryModels{c} = ...
            trainBinarySVM(X,yBinary,C,sigma);

    end

end