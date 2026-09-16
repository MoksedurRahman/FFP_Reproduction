function model = trainBinarySVM(X, y, C, sigma)
% trainBinarySVM
% Binary cubic-kernel SVM using a simplified SMO solver.
%
% Inputs:
%   X     : N x D training matrix
%   y     : N x 1 labels, must be -1 or +1
%   C     : SVM regularisation parameter
%   sigma : cubic-kernel scale
%
% Output:
%   model : trained binary SVM model

    X = double(X);
    y = double(y(:));

    if nargin < 3 || isempty(C)
        C = 1;
    end

    if nargin < 4 || isempty(sigma)
        sigma = estimateKernelScale(X);
    end

    if ~all(ismember(y,[-1 1]))
        error('Labels must be -1 or +1.');
    end

    N = size(X,1);

    if N < 2
        error('At least two samples are required.');
    end

    %% Calculate scaled cubic kernel

    K = cubicKernel(X,X,sigma);

    %% SMO parameters

    alpha = zeros(N,1);
    b = 0;

    tolerance = 1e-3;
    maxPasses = 10;
    passes = 0;

    %% SMO optimisation

    while passes < maxPasses

        numChanged = 0;

        for i = 1:N

            Ei = sum(alpha .* y .* K(:,i)) + b - y(i);

            condition1 = ...
                (y(i) * Ei < -tolerance) && (alpha(i) < C);

            condition2 = ...
                (y(i) * Ei > tolerance) && (alpha(i) > 0);

            if ~(condition1 || condition2)
                continue;
            end

            %% Randomly select second alpha

            j = randi(N-1);

            if j >= i
                j = j + 1;
            end

            Ej = sum(alpha .* y .* K(:,j)) + b - y(j);

            alphaIold = alpha(i);
            alphaJold = alpha(j);

            %% Calculate bounds

            if y(i) ~= y(j)

                L = max(0,alpha(j) - alpha(i));
                H = min(C,C + alpha(j) - alpha(i));

            else

                L = max(0,alpha(i) + alpha(j) - C);
                H = min(C,alpha(i) + alpha(j));

            end

            if L == H
                continue;
            end

            %% Calculate eta

            eta = 2*K(i,j) - K(i,i) - K(j,j);

            if eta >= 0
                continue;
            end

            %% Update alpha(j)

            alpha(j) = alpha(j) ...
                - y(j)*(Ei - Ej)/eta;

            %% Clip alpha(j)

            if alpha(j) > H

                alpha(j) = H;

            elseif alpha(j) < L

                alpha(j) = L;

            end

            %% Check whether update is meaningful

            if abs(alpha(j) - alphaJold) < 1e-5

                alpha(j) = alphaJold;

                continue;

            end

            %% Update alpha(i)

            alpha(i) = alpha(i) ...
                + y(i)*y(j)*(alphaJold - alpha(j));

            %% Calculate bias values

            b1 = b ...
                - Ei ...
                - y(i)*(alpha(i)-alphaIold)*K(i,i) ...
                - y(j)*(alpha(j)-alphaJold)*K(i,j);

            b2 = b ...
                - Ej ...
                - y(i)*(alpha(i)-alphaIold)*K(i,j) ...
                - y(j)*(alpha(j)-alphaJold)*K(j,j);

            %% Select bias

            if alpha(i) > 0 && alpha(i) < C

                b = b1;

            elseif alpha(j) > 0 && alpha(j) < C

                b = b2;

            else

                b = (b1 + b2)/2;

            end

            numChanged = numChanged + 1;

        end

        %% Check convergence

        if numChanged == 0

            passes = passes + 1;

        else

            passes = 0;

        end

    end

    %% Identify support vectors

    supportMask = alpha > 1e-6;

    %% Store trained model

    model.X = X(supportMask,:);
    model.y = y(supportMask);

    model.alpha = alpha(supportMask);

    model.b = b;

    model.C = C;

    model.sigma = sigma;

end