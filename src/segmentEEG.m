function blocks = segmentEEG(EEG, numBlocks)
% segmentEEG
%
% Divide an EEG recording into equal, non-overlapping blocks.
%
% Input:
%   EEG       : one-dimensional EEG signal
%   numBlocks : number of blocks
%
% Output:
%   blocks    : numBlocks x blockLength matrix
%
% Any samples that cannot be included in all equal blocks
% are ignored at the end of the recording.

    %% Validate input

    EEG = EEG(:);

    if nargin < 2
        numBlocks = 5;
    end

    if numBlocks < 1 || mod(numBlocks,1) ~= 0
        error('numBlocks must be a positive integer.');
    end

    %% Calculate block length

    N = length(EEG);

    blockLength = floor(N / numBlocks);

    if blockLength < 1
        error('EEG signal is too short for %d blocks.', numBlocks);
    end

    %% Allocate output

    blocks = zeros(numBlocks, blockLength);

    %% Extract blocks

    for b = 1:numBlocks

        startIndex = (b-1)*blockLength + 1;
        endIndex   = b*blockLength;

        blocks(b,:) = EEG(startIndex:endIndex);

    end

end