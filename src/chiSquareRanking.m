function [rankedFeatures, chi2Scores] = chiSquareRanking(X, labels)
% chiSquareRanking
%
% Manual Chi-square feature ranking.
%
% INPUT
%   X      : N x D feature matrix
%   labels : N x 1 class labels
%
% OUTPUT
%   rankedFeatures : feature indices sorted by descending Chi-square score
%   chi2Scores     : D x 1 Chi-square scores
%
% Notes:
%   Features are first converted into binary variables using their
%   median value. This provides a toolbox-independent Chi-square
%   association test between each feature and the class labels.
%
%   This function is intended for reproduction work where
%   Statistics and Machine Learning Toolbox is unavailable.

    X = double(X);

    if isstring(labels)
        labels = cellstr(labels);
    end

    if iscell(labels)
        [~,~,labels] = unique(labels);
    elseif iscategorical(labels)
        labels = double(labels);
    else
        [~,~,labels] = unique(labels);
    end

    labels = labels(:);

    [N, D] = size(X);

    if length(labels) ~= N
        error('Number of labels must equal number of observations.');
    end

    chi2Scores = zeros(D,1);

    uniqueClasses = unique(labels);
    numClasses = length(uniqueClasses);

    for f = 1:D

        feature = X(:,f);

        % Handle NaN/Inf
        if ~all(isfinite(feature))
            feature(~isfinite(feature)) = median( ...
                feature(isfinite(feature)));
        end

        % Binary discretisation
        threshold = median(feature);

        binaryFeature = feature >= threshold;

        % Observed contingency table
        observed = zeros(2,numClasses);

        for c = 1:numClasses

            classMask = labels == uniqueClasses(c);

            observed(1,c) = sum(~binaryFeature & classMask);
            observed(2,c) = sum( binaryFeature & classMask);

        end

        % Expected frequencies
        rowTotals = sum(observed,2);
        colTotals = sum(observed,1);
        total = sum(observed(:));

        expected = zeros(size(observed));

        for r = 1:2
            for c = 1:numClasses
                expected(r,c) = ...
                    (rowTotals(r) * colTotals(c)) / total;
            end
        end

        % Chi-square statistic
        score = 0;

        for r = 1:2
            for c = 1:numClasses

                if expected(r,c) > 0
                    score = score + ...
                        ((observed(r,c) - expected(r,c))^2) ...
                        / expected(r,c);
                end

            end
        end

        chi2Scores(f) = score;

    end

    % Rank from highest to lowest
    [~, rankedFeatures] = sort(chi2Scores, 'descend');

end