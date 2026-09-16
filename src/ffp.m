function [featureVector, mapValues] = FFP(EEG)
% FFP - Firat Fractal Pattern feature extraction
%
% Input:
%   EEG : one-dimensional EEG signal
%
% Outputs:
%   featureVector : 1 x 1024 FFP feature vector
%   mapValues     : Nwindows x 4 map values
%
% The FFP method uses:
%   - 25-sample overlapping windows
%   - 5 x 5 matrix representation
%   - 4 directed Hamiltonian graphs
%   - 8 binary comparisons per graph
%   - 256-bin histogram per graph
%   - 4 x 256 = 1024 features

    %% Validate input

    EEG = EEG(:);

    if numel(EEG) < 25
        error('EEG signal must contain at least 25 samples.');
    end

    %% Number of overlapping windows

    N = length(EEG);
    numWindows = N - 25 + 1;

    %% Store map values

    mapValues = zeros(numWindows, 4);

    %% Process every 25-sample window

    for i = 1:numWindows

        % Extract 25 consecutive samples
        window = EEG(i:i+24);

        % Convert to 5 x 5 matrix
        M = reshape(window, 5, 5)';

        %% Hamiltonian graph 1

        G1 = [ ...
            M(3,3), ...
            M(2,3), ...
            M(2,2), ...
            M(3,2), ...
            M(3,3), ...
            M(4,3), ...
            M(4,4), ...
            M(3,4), ...
            M(3,3)];

        %% Hamiltonian graph 2

        G2 = [ ...
            M(3,3), ...
            M(2,3), ...
            M(2,4), ...
            M(3,4), ...
            M(3,3), ...
            M(4,3), ...
            M(4,2), ...
            M(3,2), ...
            M(3,3)];

        %% Hamiltonian graph 3

        G3 = [ ...
            M(3,3), ...
            M(1,3), ...
            M(1,1), ...
            M(3,1), ...
            M(3,3), ...
            M(5,3), ...
            M(5,5), ...
            M(3,5), ...
            M(3,3)];

        %% Hamiltonian graph 4

        G4 = [ ...
            M(3,3), ...
            M(1,3), ...
            M(1,5), ...
            M(3,5), ...
            M(3,3), ...
            M(5,3), ...
            M(5,1), ...
            M(3,1), ...
            M(3,3)];

        %% Generate four map values

        mapValues(i,1) = generateMap(G1);
        mapValues(i,2) = generateMap(G2);
        mapValues(i,3) = generateMap(G3);
        mapValues(i,4) = generateMap(G4);

    end

    %% Generate 256-bin histogram for each graph

    featureVector = zeros(1, 1024);

    for k = 1:4

        histogram = histcounts( ...
            mapValues(:,k), ...
            0:256);

        startIndex = (k-1)*256 + 1;
        endIndex   = k*256;

        featureVector(startIndex:endIndex) = histogram;

    end

end


%% ============================================================
% Generate 8-bit FFP map
% =============================================================

function mapValue = generateMap(graph)

    bits = zeros(1,8);

    for p = 1:8

        ip = graph(p);
        ep = graph(p+1);

        % Paper's signum definition:
        % 0 if ip - ep < 0
        % 1 if ip - ep >= 0

        if ip - ep >= 0
            bits(p) = 1;
        else
            bits(p) = 0;
        end

    end

    %% Convert 8-bit pattern to decimal map value

    mapValue = sum( ...
        bits .* 2.^(0:7));

end