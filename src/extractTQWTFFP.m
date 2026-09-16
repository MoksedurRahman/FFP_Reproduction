function featureVector = extractTQWTFFP(EEG, config)
% extractTQWTFFP
%
% Generate the combined TQWT + FFP feature vector described in the
% GAMEEMO emotion-recognition methodology.
%
% Input:
%   EEG    : one-dimensional EEG signal/block
%   config : project configuration structure
%
% Output:
%   featureVector : 1 x 31744 feature vector
%
% Feature generation:
%   1. FFP on original EEG              -> 1024 features
%   2. TQWT                            -> 30 components
%   3. FFP on each TQWT component      -> 30 x 1024 features
%   4. Concatenate                     -> 31744 features
%
% TQWT parameters:
%   Q = 3.5
%   r = 3
%   J = 29

    %% Validate input

    EEG = EEG(:);

    if isempty(EEG)
        error('EEG input cannot be empty.');
    end

    if ~isfield(config, 'TQWT')
        error('Configuration does not contain TQWT parameters.');
    end

    %% TQWT parameters

    Q = config.TQWT.Q;
    r = config.TQWT.r;
    J = config.TQWT.J;

    %% FFP on original EEG

    originalFeatures = FFP(EEG);

    if length(originalFeatures) ~= 1024
        error( ...
            'Unexpected FFP feature length for original EEG: %d.', ...
            length(originalFeatures));
    end

    %% TQWT decomposition

    tqwtComponents = tqwt(EEG, Q, r, J);

    numComponents = length(tqwtComponents);

    if numComponents ~= J + 1
        error( ...
            'Expected %d TQWT components, obtained %d.', ...
            J + 1, numComponents);
    end

    %% FFP on TQWT components

    tqwtFeatures = zeros(numComponents, 1024);

    for j = 1:numComponents

        component = tqwtComponents{j};

        if length(component) < 25
            error( ...
                ['TQWT component %d contains only %d samples. ' ...
                 'FFP requires at least 25 samples.'], ...
                j, length(component));
        end

        componentFeatures = FFP(component);

        if length(componentFeatures) ~= 1024
            error( ...
                'Unexpected FFP feature length for TQWT component %d.', ...
                j);
        end

        tqwtFeatures(j,:) = componentFeatures;

    end

    %% Combine all features

    featureVector = [ ...
        originalFeatures, ...
        tqwtFeatures(:)' ...
    ];

    %% Final validation

    expectedLength = (J + 2) * 1024;

    % For J = 29:
    % (29 + 2) * 1024 = 31 * 1024 = 31744

    if length(featureVector) ~= expectedLength
        error( ...
            'Unexpected combined feature length: %d. Expected %d.', ...
            length(featureVector), expectedLength);
    end

    if ~all(isfinite(featureVector))
        error('Combined feature vector contains NaN or Inf.');
    end

end