function plot_IChi2_results()

clc;
close all;

fprintf('\n============================================\n');
fprintf('IChi2 RESULT PLOT\n');
fprintf('============================================\n');

%% Load results

if ~isfile('AF3_IChi2_results.mat')
    error('AF3_IChi2_results.mat was not found.');
end

load('AF3_IChi2_results.mat','results');

%% Display optimum

fprintf('\nChannel: AF3\n');
fprintf('Optimal feature count: %d\n', ...
    results.optimalFeatureCount);

fprintf('Optimal accuracy: %.2f %%\n', ...
    results.optimalAccuracy);

fprintf('Minimum loss: %.4f\n', ...
    results.minimumLoss);

%% Accuracy plot

figure;

plot(results.featureCounts, ...
     results.accuracy, ...
     '-o');

xlabel('Number of Selected Features');

ylabel('10-Fold CV Accuracy (%)');

title('AF3 - IChi2 Feature Selection');

grid on;

%% Loss plot

figure;

plot(results.featureCounts, ...
     results.loss, ...
     '-o');

xlabel('Number of Selected Features');

ylabel('Loss');

title('AF3 - IChi2 Loss');

grid on;

fprintf('\nPlots generated successfully.\n');

end