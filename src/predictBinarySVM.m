function [predictedLabel, decisionValue] = predictBinarySVM(model, X)

    X=double(X);

    K=cubicKernel(X,model.X,model.sigma);

    decisionValue=K*(model.alpha.*model.y)+model.b;

    predictedLabel=ones(size(decisionValue));

    predictedLabel(decisionValue<0)=-1;

end