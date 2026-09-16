function datasetTable = buildChannelDataset(dataset, config, channelName)
% buildChannelDataset
%
% Generate TQWT + FFP features for all GAMEEMO instances for one EEG
% channel.
%
% Output:
%   datasetTable : table containing
%       Subject
%       Game
%       Block
%       Label
%       F00001 ... F31744
%
% GAMEEMO:
%   28 subjects
%   4 games/classes
%   5 blocks per recording
%
% Therefore:
%   28 x 4 x 5 = 560 instances
%
% Each instance:
%   31,744 TQWT + FFP features
%
% Verified GAMEEMO mapping:
%   G1 = Boring
%   G2 = Calm
%   G3 = Horror
%   G4 = Funny

    %% Dataset parameters

    numSubjects = dataset.numSubjects;
    numGames = dataset.numGames;
    numBlocks = 5;
    numFeatures = 31744;

    numInstances = ...
        numSubjects * numGames * numBlocks;

    %% GAMEEMO class mapping

    gameToLabel = containers.Map( ...
        {'G1','G2','G3','G4'}, ...
        {'Boring','Calm','Horror','Funny'});

    %% Allocate feature matrix

    X = zeros(numInstances, numFeatures);

    %% Allocate metadata

    subjectIDs = strings(numInstances,1);
    gameIDs    = strings(numInstances,1);
    blockIDs   = zeros(numInstances,1);
    labels     = strings(numInstances,1);

    %% Build dataset

    row = 0;

    for s = 1:numSubjects

        subjectID = dataset.subjects(s).id;

        for g = 1:numGames

            gameID = dataset.subjects(s).games(g).id;

            %% Check game mapping

            if ~isKey(gameToLabel, char(gameID))
                error( ...
                    'Unknown GAMEEMO game ID: %s', ...
                    gameID);
            end

            classLabel = gameToLabel(char(gameID));

            %% Load channel

            signal = dataset.subjects(s) ...
                .games(g) ...
                .channels.(channelName);

            %% Segment recording

            blocks = segmentEEG(signal, numBlocks);

            for b = 1:numBlocks

                row = row + 1;

                %% Select block

                block = blocks(b,:);

                %% TQWT + FFP feature extraction

                featureVector = ...
                    extractTQWTFFP(block, config);

                %% Validate feature vector

                if length(featureVector) ~= numFeatures

                    error( ...
                        ['Unexpected feature length for ' ...
                         '%s %s block %d. Expected %d, got %d.'], ...
                        subjectID, ...
                        gameID, ...
                        b, ...
                        numFeatures, ...
                        length(featureVector));

                end

                %% Store features

                X(row,:) = featureVector;

                %% Store metadata

                subjectIDs(row) = subjectID;
                gameIDs(row)    = gameID;
                blockIDs(row)   = b;
                labels(row)     = classLabel;

            end
        end
    end

    %% Create metadata table

    datasetTable = table( ...
        subjectIDs, ...
        gameIDs, ...
        blockIDs, ...
        labels, ...
        'VariableNames', ...
        {'Subject','Game','Block','Label'});

    %% Create feature names

    featureNames = strings(1,numFeatures);

    for f = 1:numFeatures
        featureNames(f) = sprintf('F%05d', f);
    end

    %% Convert features to table

    featureTable = array2table( ...
        X, ...
        'VariableNames', ...
        cellstr(featureNames));

    %% Combine metadata and features

    datasetTable = [datasetTable featureTable];

end