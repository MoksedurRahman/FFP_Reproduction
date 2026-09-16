function featureVector = FFP(EEG)
% FFP - Firat Fractal Pattern feature extraction
%
% Input:
%   EEG : one-dimensional EEG signal
%
% Output:
%   featureVector : 1 x 1024 FFP feature vector
%
% Based on:
% Tuncer, T., Dogan, S., Subasi, A. (2021)
% "A New Fractal Pattern Feature Generation Function
%  based Emotion Recognition Method using EEG"

    EEG = EEG(:)';   % force row vector

    N = length(EEG);

    if N < 25
        error('EEG signal must contain at least 25 samples.');
    end

    % Number of overlapping windows
    numWindows = N - 24;

    % Store four map values for every window
    mapValues = zeros(numWindows, 4);

    % ---------------------------------------------------------
    % Process every overlapping 25-sample window
    % ---------------------------------------------------------

    for i = 1:numWindows

        % 25-sample overlapping window
        w = EEG(i:i+24);

        % -----------------------------------------------------
        % Vector -> 5 x 5 matrix
        %
        % The paper displays the matrix in row-wise order.
        % MATLAB reshape is column-wise, hence transpose.
        % -----------------------------------------------------

        M = reshape(w, 5, 5)';

        % -----------------------------------------------------
        % Four Firat fractal graphs
        % -----------------------------------------------------

        % Graph 1
        g1 = [ ...
            M(3,3), M(2,3), M(2,2), M(3,2), ...
            M(3,3), M(4,3), M(4,4), M(3,4), M(3,3)];

        % Graph 2
        g2 = [ ...
            M(3,3), M(2,3), M(2,4), M(3,4), ...
            M(3,3), M(4,3), M(4,2), M(3,2), M(3,3)];

        % Graph 3
        g3 = [ ...
            M(3,3), M(1,3), M(1,1), M(3,1), ...
            M(3,3), M(5,3), M(5,5), M(3,5), M(3,3)];

        % Graph 4
        g4 = [ ...
            M(3,3), M(1,3), M(1,5), M(3,5), ...
            M(3,3), M(5,3), M(5,1), M(3,1), M(3,3)];

        % -----------------------------------------------------
        % Generate four 8-bit map values
        % -----------------------------------------------------

        mapValues(i,1) = generateMapValue(g1);
        mapValues(i,2) = generateMapValue(g2);
        mapValues(i,3) = generateMapValue(g3);
        mapValues(i,4) = generateMapValue(g4);

    end

    % ---------------------------------------------------------
    % Generate 256-bin histogram for each map
    % ---------------------------------------------------------

    featureVector = [];

    for k = 1:4

        histogram256 = histcounts( ...
            mapValues(:,k), ...
            0:256);

        featureVector = [featureVector histogram256];

    end

    % Ensure row vector
    featureVector = double(featureVector);

end


% =============================================================
% Helper function
% =============================================================

function mapValue = generateMapValue(graph)

    bits = zeros(1,8);

    % Eight directed comparisons
    for p = 1:8

        initialPoint = graph(p);
        endPoint     = graph(p+1);

        % Paper's signum function:
        % 0 if ip - ep < 0
        % 1 if ip - ep >= 0

        bits(p) = double(initialPoint >= endPoint);

    end

    % Convert 8 binary bits into decimal map value
    mapValue = sum(bits .* 2.^(0:7));

end