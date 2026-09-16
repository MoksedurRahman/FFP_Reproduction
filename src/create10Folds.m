function foldID = create10Folds(numSamples, seed)
% create10Folds
%
% Create a reproducible random 10-fold partition without
% Statistics and Machine Learning Toolbox.
%
% INPUT
%   numSamples : number of observations
%   seed       : random seed
%
% OUTPUT
%   foldID     : numSamples x 1 vector
%                containing fold numbers 1...10

    if nargin < 2
        seed = 1;
    end

    if numSamples < 10
        error('At least 10 samples are required.');
    end

    % Save current RNG state
    oldState = rng;

    % Set reproducible seed
    rng(seed,'twister');

    % Random permutation
    permutation = randperm(numSamples);

    foldID = zeros(numSamples,1);

    % Balanced fold sizes
    baseSize = floor(numSamples / 10);
    remainder = mod(numSamples,10);

    startIndex = 1;

    for fold = 1:10

        if fold <= remainder
            foldSize = baseSize + 1;
        else
            foldSize = baseSize;
        end

        indices = permutation( ...
            startIndex:startIndex+foldSize-1);

        foldID(indices) = fold;

        startIndex = startIndex + foldSize;

    end

    % Restore previous RNG state
    rng(oldState);

end