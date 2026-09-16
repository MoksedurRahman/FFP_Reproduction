function config = getConfig()
% getConfig
% Configuration for FFP paper reproduction

    %% Dataset

    config.dataRoot = fullfile( ...
        'data', ...
        'GAMEEMO');

    %% TQWT

    config.TQWT.Q = 3.5;
    config.TQWT.r = 3;
    config.TQWT.J = 29;

    %% FFP

    config.FFP.windowLength = 25;
    config.FFP.matrixSize = [5 5];
    config.FFP.histogramBins = 256;

    %% IChi2

    config.IChi2.lowerBound = 100;
    config.IChi2.upperBound = 1000;
    config.IChi2.folds = 10;

    %% Classification

    config.validation.folds = 10;

end