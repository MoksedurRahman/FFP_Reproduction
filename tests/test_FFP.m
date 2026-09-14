%% Test FFP feature generator

clear;
clc;

% Create a simple test signal
EEG = 1:100;

% Run FFP
features = FFP(EEG);

% Display size
disp('Feature vector size:');
disp(size(features));

% Display first 20 features
disp('First 20 features:');
disp(features(1:20));