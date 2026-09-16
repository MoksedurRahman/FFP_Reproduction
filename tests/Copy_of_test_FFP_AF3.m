clc;
clear;
close all;

%% ============================================================
% FFP TEST - S01G1 AF3
% =============================================================

%% Add source code

addpath(genpath('../src'));

%% Load EEG recording

filePath = fullfile( ...
    'data', ...
    'GAMEEMO', ...
    '(S01)', ...
    'Preprocessed EEG Data', ...
    '.mat format', ...
    'S01G1AllChannels.mat');

data = load(filePath);

AF3 = data.AF3;

%% Display input information

fprintf('\n');
fprintf('============================================\n');
fprintf('FFP TEST - S01G1 AF3\n');
fprintf('============================================\n');

fprintf('Signal size       : %d x %d\n', ...
    size(AF3,1), size(AF3,2));

fprintf('Number of samples : %d\n', length(AF3));

%% ============================================================
% Apply FFP
% =============================================================

[features, mapValues] = FFP(AF3);

%% Display FFP information

fprintf('\n');
fprintf('FFP Results\n');
fprintf('--------------------------------------------\n');

fprintf('Number of windows : %d\n', size(mapValues,1));
fprintf('Number of graphs  : %d\n', size(mapValues,2));
fprintf('Feature length    : %d\n', length(features));

fprintf('============================================\n');

%% ============================================================
% Visualise the original EEG signal
% =============================================================

figure;

plot(AF3);

xlabel('Sample');
ylabel('Amplitude');

title('S01G1 - AF3 EEG Signal');

grid on;


%% ============================================================
% Visualise the four FFP histograms
% =============================================================

figure;

for k = 1:4

    subplot(4,1,k);

    histogram( ...
        mapValues(:,k), ...
        0:256);

    xlabel('FFP Map Value');
    ylabel('Frequency');

    title(['FFP Graph ', num2str(k)]);

    grid on;

end