function test_IChi2_F8()

    fprintf('\n');
    fprintf('============================================\n');
    fprintf('ICH12 F8 TEST\n');
    fprintf('============================================\n');

    %% Configuration

    config = getConfig();

    %% Load GAMEEMO

    fprintf('\nLoading GAMEEMO dataset...\n');

    dataset = loadGAMEEMO(config);

    %% Build F8 dataset

    fprintf('\nBuilding F8 dataset...\n');
    fprintf('This may take some time.\n');

    tic;

    datasetTable = buildChannelDataset( ...
        dataset,config,'F8');

    assemblyTime = toc;

    %% Extract features

    X = table2array( ...
        datasetTable(:,5:end));

    %% Labels

    labelStrings = string(datasetTable.Label);

    labels = zeros(length(labelStrings),1);

    labels(labelStrings == "Boring") = 1;
    labels(labelStrings == "Calm")   = 2;
    labels(labelStrings == "Horror") = 3;
    labels(labelStrings == "Funny")  = 4;

    %% Candidate feature counts

    featureCounts = 100:100:1000;
    %%featureCounts = sort(unique([100:100:1000, 888]));

    %% Run IChi2

    fprintf('\n');
    fprintf('Starting IChi2...\n');

    tic;

    results = IChi2( ...
        X, ...
        labels, ...
        featureCounts, ...
        1);

    %% Save IChi2 results
    
    save('F8_IChi2_results.mat','results');
    
    fprintf('\nResults saved to:\n');
    fprintf('F8_IChi2_results.mat\n');

    ichi2Time = toc;

    %% Final report

    fprintf('\n');
    fprintf('============================================\n');
    fprintf('FINAL ICHI2 VALIDATION\n');
    fprintf('============================================\n');

    fprintf('Channel               : F8\n');
    fprintf('Instances             : %d\n',size(X,1));
    fprintf('Original features     : %d\n',size(X,2));

    fprintf('\n');

    fprintf('Optimal feature count : %d\n', ...
        results.optimalFeatureCount);

    fprintf('Optimal accuracy      : %.2f %%\n', ...
        results.optimalAccuracy);

    fprintf('Minimum loss          : %.4f\n', ...
        results.minimumLoss);

    fprintf('\n');

    fprintf('Dataset assembly time : %.2f s\n', ...
        assemblyTime);

    fprintf('IChi2 processing time : %.2f s\n', ...
        ichi2Time);

    %% Validate result

    if results.optimalFeatureCount >= 100 && ...
       results.optimalFeatureCount <= 1000

        fprintf('\nOptimal count range   : PASSED\n');

    else

        error('Optimal feature count is outside the expected range.');

    end

    if isfinite(results.minimumLoss)

        fprintf('Finite minimum loss   : PASSED\n');

    else

        error('Minimum loss is invalid.');

    end

    fprintf('\n');
    fprintf('============================================\n');
    fprintf('IChi2 TEST COMPLETED\n');
    fprintf('============================================\n');

end