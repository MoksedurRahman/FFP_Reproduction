# FFP Reproduction — Step-by-Step Execution Guide

This document describes the recommended order for creating, testing, and running the MATLAB implementation of the FFP-based GAMEEMO experiment.

The purpose of this guide is to make the repository easy to understand and reproducible: each stage should be verified before moving to the next stage.

---

## 1. Overall Pipeline

The complete workflow is:

```text
GAMEEMO
   ↓
Load EEG recordings
   ↓
Five non-overlapping segments
   ↓
FFP feature extraction
   ↓
TQWT decomposition
   ↓
FFP extraction from original EEG + TQWT components
   ↓
31,744 features per instance
   ↓
Min-max normalization
   ↓
Chi-square feature ranking
   ↓
IChi2 feature selection (100–1000)
   ↓
10-fold cross-validation
   ↓
Classifier
   ├── Cubic SVM
   ├── kNN
   └── LDA
   ↓
All 14 channels
   ↓
Final results and figures
```

---

# 2. Recommended Project Structure

The repository should follow this general structure:

```text
FFP_Reproduction/
│
├── data/
│   └── GAMEEMO/
│
├── src/
│   ├── FFP.m
│   ├── segmentEEG.m
│   ├── loadGAMEEMO.m
│   ├── extractTQWTFFP.m
│   ├── buildChannelDataset.m
│   ├── chiSquareRanking.m
│   ├── IChi2.m
│   ├── IChi2_LDA.m
│   ├── cubicKernel.m
│   ├── estimateKernelScale.m
│   ├── trainBinarySVM.m
│   ├── predictBinarySVM.m
│   ├── trainCubicSVM_OVA.m
│   └── predictCubicSVM_OVA.m
│
├── tests/
│   ├── FFP tests
│   ├── segmentation tests
│   ├── TQWT tests
│   ├── dataset tests
│   ├── feature-ranking tests
│   └── classifier tests
│
├── results/
│   └── IChi2/
│
├── getConfig.m
├── main.m
├── README.md
└── EXECUTION_GUIDE.md
```

The exact contents may change as the project develops, but the processing order should remain clear.

---

# 3. Step 1 — Create and Test `getConfig.m`

## Purpose

`getConfig.m` contains the main experimental parameters used throughout the project.

Important parameters:

```matlab
config.TQWT.Q = 3.5;
config.TQWT.r = 3;
config.TQWT.J = 29;

config.FFP.windowLength = 25;
config.FFP.matrixSize = [5 5];
config.FFP.histogramBins = 256;

config.IChi2.lowerBound = 100;
config.IChi2.upperBound = 1000;
config.IChi2.folds = 10;

config.validation.folds = 10;
```

## Test

Run:

```matlab
config = getConfig()
```

Verify that the parameters are displayed correctly.

Do not proceed until the configuration loads successfully.

---

# 4. Step 2 — Load GAMEEMO

## File

```text
src/loadGAMEEMO.m
```

## Purpose

Load and organise the GAMEEMO EEG recordings.

The dataset used in this implementation contains:

- 28 subjects
- 4 games/classes
- 14 EEG channels
- 38,252 samples per recording

The four classes are:

```text
Boring
Calm
Funny
Horror
```

## Test

Run:

```matlab
config = getConfig();
dataset = loadGAMEEMO(config);
```

Inspect:

```matlab
dataset
```

Confirm that the expected recordings and channels are available.

---

# 5. Step 3 — Segment the EEG

## File

```text
src/segmentEEG.m
```

## Purpose

Each EEG recording is divided into **five non-overlapping segments**.

For a 38,252-sample recording:

```text
floor(38252 / 5) = 7650
```

Therefore:

```text
5 × 7650 = 38250
```

Two samples are not included in the five segments.

Each segment contains:

```text
7,650 samples
```

## Test

Use one EEG recording:

```matlab
segments = segmentEEG(signal);
```

Verify that five segments are produced and that each contains 7,650 samples.

---

# 6. Step 4 — Test FFP

## File

```text
src/FFP.m
```

## Purpose

FFP converts a one-dimensional EEG segment into a **1 × 1024 feature vector**.

The implementation uses:

- 25-sample overlapping windows
- 5 × 5 matrix representation
- Four directed Hamiltonian graph patterns
- Eight binary comparisons per graph
- 256-bin histogram for each graph
- Four histograms concatenated

Therefore:

```text
4 × 256 = 1024 features
```

## Test

Run:

```matlab
featureVector = FFP(segment);
```

Verify:

```matlab
size(featureVector)
```

Expected:

```text
1     1024
```

For a 7,650-sample segment:

```text
7650 - 25 + 1 = 7626 windows
```

Four maps are generated per window:

```text
7626 × 4 = 30504
```

Therefore:

```matlab
sum(featureVector)
```

should be:

```text
30504
```

---

# 7. Step 5 — Verify FFP Map Values

Run:

```matlab
[features, mapValues] = FFP(segment);
```

Check:

```matlab
size(mapValues)
```

Expected:

```text
7626     4
```

Then:

```matlab
min(mapValues(:))
max(mapValues(:))
```

Expected range:

```text
0 to 255
```

This confirms that each graph produces an 8-bit map value.

---

# 8. Step 6 — Test TQWT

## Purpose

Apply the Tunable-Q Wavelet Transform using:

```text
Q = 3.5
r = 3
J = 29
```

The configured decomposition produces:

```text
30 components
```

Test TQWT independently before combining it with FFP.

Verify that all expected components are returned and that their values are finite.

The exact TQWT function syntax depends on the TQWT implementation installed in the MATLAB environment.

---

# 9. Step 7 — Test `extractTQWTFFP.m`

## File

```text
src/extractTQWTFFP.m
```

## Purpose

Generate FFP features from:

1. The original EEG segment
2. Each of the 30 TQWT components

Feature construction:

```text
Original EEG
    1 × 1024

TQWT component 1
    1 × 1024

...

TQWT component 30
    1 × 1024
```

Total:

```text
31 × 1024 = 31,744 features
```

## Test

Run:

```matlab
features = extractTQWTFFP(segment, config);
```

Verify:

```matlab
size(features)
```

Expected:

```text
1     31744
```

This is a major checkpoint before building the complete dataset.

---

# 10. Step 8 — Build a Channel Dataset

## File

```text
src/buildChannelDataset.m
```

Start with one channel, for example:

```matlab
config = getConfig();

dataset = loadGAMEEMO(config);

datasetTable = buildChannelDataset( ...
    dataset, ...
    config, ...
    'F8');
```

Check:

```matlab
size(datasetTable)
```

Expected:

```text
560     31748
```

The four additional columns are metadata:

```text
Subject
Game
Block/Segment identifier
Label
```

The feature columns contain:

```text
F00001 ... F31744
```

Therefore:

```text
560 instances × 31,744 features
```

Extract the feature matrix:

```matlab
X = table2array(datasetTable(:,5:end));
```

Verify:

```matlab
size(X)
```

Expected:

```text
560     31744
```

Extract labels:

```matlab
Y = datasetTable.Label;
```

The dataset contains four classes:

```text
Boring
Calm
Funny
Horror
```

The 560 instances arise from:

```text
28 subjects × 4 games × 5 segments
= 560 instances
```

---

# 11. Step 9 — Min-Max Normalization

Before chi-square feature ranking, normalize the feature matrix.

```matlab
X = double(X);

xmin = min(X,[],1);
xmax = max(X,[],1);

featureRange = xmax - xmin;
featureRange(featureRange == 0) = 1;

Xnorm = (X - xmin) ./ featureRange;
```

Verify:

```matlab
min(Xnorm(:))
max(Xnorm(:))
```

Expected:

```text
0
1
```

---

# 12. Step 10 — Chi-Square Feature Ranking

Use MATLAB's Statistics and Machine Learning Toolbox:

```matlab
[idx, scores] = fscchi2(Xnorm, Y);
```

Verify:

```matlab
length(idx)
```

Expected:

```text
31744
```

`idx` contains the feature indices in descending ranking order.

For example:

```matlab
idx(1:20)
```

shows the first 20 ranked features.

---

# 13. Step 11 — Run IChi2

## File

```text
src/IChi2.m
```

The feature-count search is:

```matlab
featureCounts = 100:1000;
```

This means the experiment evaluates:

```text
100, 101, 102, ..., 1000
```

selected features.

Run:

```matlab
results = IChi2( ...
    X, ...
    Y, ...
    featureCounts, ...
    1);
```

Important result fields include:

```matlab
results.optimalFeatureCount
results.optimalAccuracy
results.minimumLoss
results.rankedFeatures
results.chi2Scores
results.foldAccuracies
```

---

# 14. Step 12 — Test One Channel with SVM

Before running all channels, test one channel.

Example:

```matlab
config = getConfig();

dataset = loadGAMEEMO(config);

datasetTable = buildChannelDataset( ...
    dataset, config, 'F8');

X = table2array(datasetTable(:,5:end));
Y = datasetTable.Label;

results = IChi2(X, Y, 100:1000, 1);
```

The current F8 SVM result is:

```text
Optimal feature count: 980
Optimal accuracy:       97.500%
```

---

# 15. Step 13 — Run IChi2 + Cubic SVM for All Channels

Use:

```text
run_IChi2_AllChannels_SVM.m
```

Run:

```matlab
run_IChi2_AllChannels_SVM
```

The script processes:

```text
AF3
AF4
F3
F4
F7
F8
FC5
FC6
O1
O2
P7
P8
T7
T8
```

Current mean accuracy:

```text
97.844%
```

---

# 16. Step 14 — Run IChi2 + kNN

The same feature-generation and IChi2 framework is evaluated using kNN.

Current all-channel mean:

```text
95.702%
```

The complete results are stored under the IChi2 results directory.

---

# 17. Step 15 — Run IChi2 + LDA

The same feature-generation and IChi2 framework is evaluated using LDA.

Current all-channel mean:

```text
93.622%
```

---

# 18. Step 16 — Final Classifier Results

Current all-channel results:

| Channel | SVM (%) | kNN (%) | LDA (%) |
|---|---:|---:|---:|
| AF3 | 97.500 | 95.714 | 93.929 |
| AF4 | 98.571 | 95.357 | 95.000 |
| F3 | 97.679 | 94.821 | 94.643 |
| F4 | 98.571 | 95.357 | 95.357 |
| F7 | 96.607 | 95.536 | 87.143 |
| F8 | 97.500 | 96.250 | 90.357 |
| FC5 | 98.929 | 96.429 | 95.000 |
| FC6 | 96.607 | 95.893 | 93.214 |
| O1 | 97.321 | 97.143 | 93.393 |
| O2 | 97.857 | 94.643 | 94.643 |
| P7 | 98.929 | 94.821 | 94.286 |
| P8 | 98.036 | 95.179 | 96.250 |
| T7 | 98.393 | 95.893 | 93.929 |
| T8 | 97.321 | 96.786 | 93.571 |
| **Mean** | **97.844** | **95.702** | **93.622** |

---

# 19. Step 17 — Final Result Files

The results should be organised so that individual channel experiments can be recovered without rerunning the entire pipeline.

Example:

```text
results/
└── IChi2/
    ├── SVM/
    │   ├── AF3_IChi2_SVM_full_results.mat
    │   ├── AF4_IChi2_SVM_full_results.mat
    │   ├── ...
    │   ├── T8_IChi2_SVM_full_results.mat
    │   └── IChi2_SVM_AllChannels_Summary.mat
    │
    ├── kNN/
    │   └── ...
    │
    └── LDA/
        └── ...
```

---

# 20. Step 18 — Create Final Tables and Figures

After all classifier experiments have completed, create scripts for:

```text
tests/create_final_results_table.m
tests/plot_classifier_accuracy.m
tests/plot_optimal_features.m
```

Recommended figures:

### Figure 1 — Accuracy by Channel

Compare:

```text
SVM
kNN
LDA
```

across all 14 channels.

### Figure 2 — Optimal Feature Count

Show the number of selected features for each channel.

### Figure 3 — Mean Classifier Accuracy

Show the mean accuracy of:

```text
SVM
kNN
LDA
```

---

# 21. Step 19 — Final Clean-Run Verification

After development is complete, perform a clean verification.

Check:

- Configuration loads.
- Dataset loads.
- Segmentation produces five non-overlapping segments.
- FFP produces 1,024 features.
- TQWT produces 30 components.
- TQWT + FFP produces 31,744 features.
- One channel produces 560 instances.
- Chi-square ranking returns 31,744 ranked features.
- IChi2 searches 100–1000 features.
- SVM, kNN and LDA complete successfully.
- All 14 channels have completed results.
- Result files are saved correctly.
- Summary tables contain no missing channel results.

---

# 22. Important Execution Principle

Always work from **smallest unit to largest experiment**.

The recommended order is:

```text
Configuration
     ↓
One EEG recording
     ↓
One segment
     ↓
FFP
     ↓
TQWT
     ↓
TQWT + FFP
     ↓
One channel
     ↓
Feature ranking
     ↓
IChi2
     ↓
One classifier
     ↓
All 14 channels
     ↓
All three classifiers
     ↓
Final tables
     ↓
Final figures
```

Do not start with the complete all-channel experiment when debugging a new component.

If a lower-level test fails, fix that stage first.

---

# 23. Final Reproduction Pipeline

The complete implementation can be summarised as:

```text
GAMEEMO
  │
  ├── 28 subjects
  ├── 4 games/classes
  └── 14 EEG channels
          │
          ▼
  Five non-overlapping segments
          │
          ▼
       FFP
          │
          └── 1,024 features
          │
          ▼
       TQWT
          │
          └── 30 components
                  │
                  ▼
             FFP on each
                  │
                  ▼
       31 × 1,024 = 31,744
             features
                  │
                  ▼
       Min-max normalization
                  │
                  ▼
        Chi-square ranking
                  │
                  ▼
       IChi2: 100–1000
          selected features
                  │
                  ▼
       10-fold cross-validation
                  │
        ┌─────────┼─────────┐
        ▼         ▼         ▼
       SVM       kNN       LDA
        │         │         │
        ▼         ▼         ▼
      Results   Results   Results
        └─────────┼─────────┘
                  ▼
          Final comparison
```

---

## 24. Completion Checklist

Use this checklist when working through the repository:

```text
[ ] getConfig.m
[ ] loadGAMEEMO.m
[ ] segmentEEG.m
[ ] FFP.m
[ ] FFP verification
[ ] TQWT verification
[ ] extractTQWTFFP.m
[ ] buildChannelDataset.m
[ ] Min-max normalization
[ ] fscchi2 ranking
[ ] IChi2.m
[ ] One-channel SVM test
[ ] All-channel SVM
[ ] All-channel kNN
[ ] All-channel LDA
[ ] Final master results table
[ ] Accuracy figure
[ ] Optimal feature-count figure
[ ] Clean-run verification
[ ] Final README review
```

The first fourteen items are already implemented/tested in the current project state. The remaining items are the final results, visualisation, verification, and documentation stages.
