function K = cubicKernel(X1, X2, sigma)
% cubicKernel
% Cubic polynomial kernel with optional scaling.
%
% K = (X1*X2' / sigma + 1)^3
%
% If sigma is omitted, sigma = 1.

    X1 = double(X1);
    X2 = double(X2);

    if nargin < 3 || isempty(sigma)
        sigma = 1;
    end

    if sigma <= 0 || ~isfinite(sigma)
        error('Kernel scale sigma must be positive and finite.');
    end

    K = (X1 * X2' / sigma + 1).^3;

end