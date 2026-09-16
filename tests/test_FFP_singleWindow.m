clc;
clear;
close all;

%% Add source code

addpath(genpath('../src'));

%% Load EEG

filePath = fullfile( ...
    'data', ...
    'GAMEEMO', ...
    '(S01)', ...
    'Preprocessed EEG Data', ...
    '.mat format', ...
    'S01G1AllChannels.mat');

data = load(filePath);

AF3 = data.AF3;

%% Take first 25 samples

window = AF3(1:25);

%% Convert to 5 x 5 matrix

M = reshape(window,5,5)';

%% Display

fprintf('\n============================================\n');
fprintf('FFP SINGLE WINDOW TEST\n');
fprintf('============================================\n');

fprintf('\n25-sample window:\n');
disp(window);

fprintf('\n5 x 5 matrix:\n');
disp(M);

%% ============================================================
% G1
% =============================================================

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

fprintf('\nG1 values:\n');
disp(G1);

%% ============================================================
% Calculate G1 bits
% =============================================================

bits = zeros(1,8);

for p = 1:8

    ip = G1(p);
    ep = G1(p+1);

    if ip - ep >= 0
        bits(p) = 1;
    else
        bits(p) = 0;
    end

end

fprintf('\nG1 bits:\n');
disp(bits);

%% ============================================================
% Calculate decimal map
% =============================================================

mapValue = sum(bits .* 2.^(0:7));

fprintf('\nG1 decimal map value: %d\n', mapValue);

fprintf('\n============================================\n');

%% ============================================================
% G2
% =============================================================

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

bits2 = zeros(1,8);

for p = 1:8

    if G2(p) - G2(p+1) >= 0
        bits2(p) = 1;
    end

end

map2 = sum(bits2 .* 2.^(0:7));


%% ============================================================
% G3
% =============================================================

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

bits3 = zeros(1,8);

for p = 1:8

    if G3(p) - G3(p+1) >= 0
        bits3(p) = 1;
    end

end

map3 = sum(bits3 .* 2.^(0:7));


%% ============================================================
% G4
% =============================================================

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

bits4 = zeros(1,8);

for p = 1:8

    if G4(p) - G4(p+1) >= 0
        bits4(p) = 1;
    end

end

map4 = sum(bits4 .* 2.^(0:7));


%% ============================================================
% Display all graphs
% =============================================================

fprintf('\n============================================\n');
fprintf('ALL FOUR FFP GRAPHS - FIRST WINDOW\n');
fprintf('============================================\n');

fprintf('\nGraph 1:\n');
fprintf('Bits: ');
fprintf('%d ', bits);
fprintf('\nMap : %d\n', mapValue);

fprintf('\nGraph 2:\n');
fprintf('Bits: ');
fprintf('%d ', bits2);
fprintf('\nMap : %d\n', map2);

fprintf('\nGraph 3:\n');
fprintf('Bits: ');
fprintf('%d ', bits3);
fprintf('\nMap : %d\n', map3);

fprintf('\nGraph 4:\n');
fprintf('Bits: ');
fprintf('%d ', bits4);
fprintf('\nMap : %d\n', map4);

fprintf('\n============================================\n');