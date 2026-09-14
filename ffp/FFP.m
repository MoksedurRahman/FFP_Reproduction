function featureVector = FFP(EEG)
% FFP
% Firat Fractal Pattern feature generator
%
% Input:
%   EEG - one-dimensional EEG signal
%
% Output:
%   featureVector - 1 x 1024 FFP feature vector

    % Make sure EEG is a row vector
    EEG = EEG(:)';

    % Signal length
    N = length(EEG);

    % Minimum signal length
    if N < 25
        error('EEG signal must contain at least 25 samples.');
    end

    % Number of overlapping windows
    numWindows = N - 24;

    % Four map signals
    mapValues = zeros(numWindows, 4);

    % ---------------------------------------------------------
    % Process every 25-sample overlapping window
    % ---------------------------------------------------------
    for i = 1:numWindows

        % Extract 25 samples
        w = EEG(i:i+24);

        % Convert 25 samples into a 5 x 5 matrix
        M = reshape(w, 5, 5)';

        % -----------------------------------------------------
        % Graph 1
        % -----------------------------------------------------
        g1 = [ ...
            M(3,3), ...
            M(2,3), ...
            M(2,2), ...
            M(3,2), ...
            M(3,3), ...
            M(4,3), ...
            M(4,4), ...
            M(3,4), ...
            M(3,3)];

        % -----------------------------------------------------
        % Graph 2
        % -----------------------------------------------------
        g2 = [ ...
            M(3,3), ...
            M(2,3), ...
            M(2,4), ...
            M(3,4), ...
            M(3,3), ...
            M(4,3), ...
            M(4,2), ...
            M(3,2), ...
            M(3,3)];

        % -----------------------------------------------------
        % Graph 3
        % -----------------------------------------------------
        g3 = [ ...
            M(3,3), ...
            M(1,3), ...
            M(1,1), ...
            M(3,1), ...
            M(3,3), ...
            M(5,3), ...
            M(5,5), ...
            M(3,5), ...
            M(3,3)];

        % -----------------------------------------------------
        % Graph 4
        % -----------------------------------------------------
        g4 = [ ...
            M(3,3), ...
            M(1,3), ...
            M(1,5), ...
            M(3,5), ...
            M(3,3), ...
            M(5,3), ...
            M(5,1), ...
            M(3,1), ...
            M(3,3)];

        % Generate one map value from each graph
        mapValues(i,1) = generateMap(g1);
        mapValues(i,2) = generateMap(g2);
        mapValues(i,3) = generateMap(g3);
        mapValues(i,4) = generateMap(g4);

    end

    % ---------------------------------------------------------
    % Generate four 256-bin histograms
    % ---------------------------------------------------------

    featureVector = [];

    for k = 1:4

        % Map values are integers from 0 to 255.
        % Bin edges are therefore 0,1,...,256.
        h = histcounts(mapValues(:,k), 0:256);

        % Append histogram
        featureVector = [featureVector, h];

    end

end


% =============================================================
% Helper function
% =============================================================
function mapValue = generateMap(graph)

    % Eight binary comparisons
    bits = zeros(1,8);

    for p = 1:8

        % Initial point
        ip = graph(p);

        % Endpoint
        ep = graph(p+1);

        % Signum comparison
        %
        % 0 if ip - ep < 0
        % 1 if ip - ep >= 0

        bits(p) = double(ip >= ep);

    end

    % Convert eight bits into an 8-bit decimal value
    mapValue = sum(bits .* 2.^(0:7));

end