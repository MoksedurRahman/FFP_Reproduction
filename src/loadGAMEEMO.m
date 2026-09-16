function dataset = loadGAMEEMO(config)
% loadGAMEEMO
%
% Load GAMEEMO preprocessed MATLAB recordings.
%
% Expected structure:
%
% data/GAMEEMO/
%     (S01)/
%         Preprocessed EEG Data/
%             .mat format/
%                 S01G1AllChannels.mat
%                 S01G2AllChannels.mat
%                 S01G3AllChannels.mat
%                 S01G4AllChannels.mat
%
% Output:
%   dataset : structure containing subjects, recordings and channels

    %% Configuration

    dataRoot = config.dataRoot;

    channels = { ...
        'AF3', 'AF4', 'F3', 'F4', ...
        'F7', 'F8', 'FC5', 'FC6', ...
        'O1', 'O2', 'P7', 'P8', ...
        'T7', 'T8'};

    numSubjects = 28;
    numGames = 4;

    %% Allocate dataset structure

    dataset = struct();

    dataset.channels = channels;
    dataset.numSubjects = numSubjects;
    dataset.numGames = numGames;

    dataset.subjects = struct([]);

    %% ========================================================
    % Load every subject
    % =========================================================

    for s = 1:numSubjects

        subjectName = sprintf('(S%02d)', s);
        subjectID   = sprintf('S%02d', s);

        subjectFolder = fullfile( ...
            dataRoot, ...
            subjectName, ...
            'Preprocessed EEG Data', ...
            '.mat format');

        %% Check subject folder

        if ~isfolder(subjectFolder)

            error( ...
                'Subject folder not found:\n%s', ...
                subjectFolder);

        end

        %% Subject information

        dataset.subjects(s).id = subjectID;
        dataset.subjects(s).folder = subjectFolder;
        dataset.subjects(s).games = struct([]);

        %% Load four recordings

        for g = 1:numGames

            fileName = sprintf( ...
                '%sG%dAllChannels.mat', ...
                subjectID, g);

            filePath = fullfile( ...
                subjectFolder, ...
                fileName);

            %% Check file

            if ~isfile(filePath)

                error( ...
                    'MAT file not found:\n%s', ...
                    filePath);

            end

            %% Load MAT file

            data = load(filePath);

            %% Store recording information

            dataset.subjects(s).games(g).id = ...
                sprintf('G%d', g);

            dataset.subjects(s).games(g).file = ...
                filePath;

            %% Store channels

            for c = 1:length(channels)

                channelName = channels{c};

                if ~isfield(data, channelName)

                    error( ...
                        'Channel %s missing from %s.', ...
                        channelName, ...
                        fileName);

                end

                signal = data.(channelName);

                signal = signal(:);

                dataset.subjects(s).games(g). ...
                    channels.(channelName) = signal;

            end

        end

    end

end