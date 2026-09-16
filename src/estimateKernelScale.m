function sigma = estimateKernelScale(X)
% estimateKernelScale
% Estimate kernel scale using median pairwise Euclidean distance.

    X = double(X);

    G = sum(X.^2,2);

    distanceSquared = bsxfun(@plus,G,G') ...
                    - 2*(X*X');

    distanceSquared(distanceSquared < 0) = 0;

    distances = sqrt(distanceSquared(:));

    sigma = median(distances);

    if sigma <= 0 || ~isfinite(sigma)
        error('Unable to calculate a valid kernel scale.');
    end

end