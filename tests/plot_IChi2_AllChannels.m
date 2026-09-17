%% plot_IChi2_AllChannels
% Plot IChi2 accuracy curves for all 14 GAMEEMO channels.

clear;
clc;
close all;

%% ============================================================
% Configuration
% ============================================================

resultsDir = fullfile('results','IChi2');

channels = { ...
    'AF3','AF4','F3','F4', ...
    'F7','F8','FC5','FC6', ...
    'O1','O2','P7','P8','T7','T8'};

%% ============================================================
% Load results
% ============================================================

allResults = cell(length(channels),1);

for c = 1:length(channels)

    fileName = fullfile( ...
        resultsDir, ...
        sprintf('%s_IChi2_results.mat',channels{c}));

    if ~isfile(fileName)
        error('Result file not found: %s',fileName);
    end

    S = load(fileName);

    allResults{c} = S.results;

end

%% ============================================================
% Plot each channel
% ============================================================

for c = 1:length(channels)

    results = allResults{c};

    figure;

    plot( ...
        results.featureCounts, ...
        results.accuracy, ...
        '-o', ...
        'LineWidth',1.5, ...
        'MarkerSize',5);

    grid on;

    xlabel('Number of selected features');

    ylabel('10-fold CV accuracy (%)');

    title(sprintf( ...
        '%s — IChi2 Feature Selection', ...
        channels{c}));

    xlim([100 1000]);

end

%% ============================================================
% Combined plot
% ============================================================

figure;
hold on;

for c = 1:length(channels)

    results = allResults{c};

    plot( ...
        results.featureCounts, ...
        results.accuracy, ...
        '-o', ...
        'LineWidth',1.2, ...
        'MarkerSize',4);

end

grid on;

xlabel('Number of selected features');

ylabel('10-fold CV accuracy (%)');

title('IChi2 Accuracy Across GAMEEMO EEG Channels');

legend( ...
    channels, ...
    'Location','eastoutside');

xlim([100 1000]);

hold off;

%% ============================================================
% Report best tested result for each channel
% ============================================================

fprintf('\n');
fprintf('============================================\n');
fprintf('BEST TESTED RESULT PER CHANNEL\n');
fprintf('============================================\n');

fprintf('%6s %15s %15s\n', ...
    'Channel','Features','Accuracy (%)');

fprintf('--------------------------------------------\n');

for c = 1:length(channels)

    results = allResults{c};

    [bestAccuracy,bestIndex] = ...
        max(results.accuracy);

    bestFeatures = ...
        results.featureCounts(bestIndex);

    fprintf('%6s %15d %15.2f\n', ...
        channels{c}, ...
        bestFeatures, ...
        bestAccuracy);

end

fprintf('============================================\n');