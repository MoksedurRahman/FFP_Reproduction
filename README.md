# FFP Methodology Reproduction

MATLAB implementation and experimental reproduction of the EEG feature-generation methodology based on the **Firat Fractal Pattern (FFP)** described in:

> Tuncer, T., Dogan, S., & Subasi, A. (2021). *A New Fractal Pattern Feature Generation Function based Emotion Recognition Method using EEG.* Chaos, Solitons & Fractals, 144, 110671. DOI: 10.1016/j.chaos.2021.110671

## Project Overview

This project implements and investigates the FFP-based EEG processing methodology described in the paper.

The current aims are to:

1. Understand the published methodology.
2. Implement the individual stages in MATLAB.
3. Validate each stage independently.
4. Reproduce the feature-generation pipeline.
5. Reproduce the reported classification workflow as closely as the available paper description permits.
6. Identify differences between the published results and the current implementation.
7. Record implementation choices and reproducibility limitations explicitly.

**Status:** Initial methodology reproduction and investigation. The project does not yet claim exact reproduction of all published results.

## Processing Pipeline

```text
GAMEEMO EEG recording
        |
        v
5 non-overlapping segments
        |
        v
TQWT
Q = 3.5, r = 3, J = 29
        |
        v
30 TQWT components
        |
        +----------------------+
        |                      |
        v                      v
     Raw EEG          30 TQWT components
        |                      |
        +----------+-----------+
                   |
                   v
                  FFP
                   |
                   v
          31 x 1,024 features
                   |
                   v
             31,744 features
                   |
                   v
        MATLAB fscchi2 ranking
                   |
                   v
                 IChi2
                   |
          +--------+--------+
          |        |        |
          v        v        v
       SVM       LDA       kNN
          |
          v
      10-fold CV
```

The current implementation evaluates the three classifier families described by the paper: cubic-kernel SVM, linear LDA, and k-NN. SVM and LDA experiments are currently in progress/completed at different stages; k-NN remains pending.

## Dataset

The current experiments use the **GAMEEMO EEG dataset**.

The dataset is **not included in this repository**.

Dataset information:

- 28 subjects
- 14 EEG channels
- 4 classes/games
- Sampling frequency: 2048 Hz
- 38,252 samples per recording

Channels:

```text
AF3, AF4, F3, F4, F7, F8, FC5,
FC6, O1, O2, P7, P8, T7, T8
```

Current class mapping used by the implementation:

```text
G1 -> Boring
G2 -> Calm
G3 -> Horror
G4 -> Funny
```

### Dataset organisation used for the current tests

For example, subject S01 contains preprocessed MATLAB files such as:

```text
S01G1AllChannels.mat
S01G2AllChannels.mat
S01G3AllChannels.mat
S01G4AllChannels.mat
```

The current reproduction initially uses the **preprocessed EEG** files. Raw and preprocessed data should not be mixed without explicitly documenting the experiment.

## EEG Segmentation

Each 38,252-sample recording is divided into **five non-overlapping segments** of 7,650 samples.

```text
38,252 samples
   |
   +-- Segment 1 -> 7,650
   +-- Segment 2 -> 7,650
   +-- Segment 3 -> 7,650
   +-- Segment 4 -> 7,650
   +-- Segment 5 -> 7,650
```

Thus:

```text
5 x 7,650 = 38,250 samples
```

Two samples remain unused.

The resulting experimental unit count is:

```text
28 subjects x 4 games x 5 segments = 560 instances
```

The paper contains wording referring to signals divided into frames as well as an explicit five-block construction. The current implementation follows the explicit five-segment construction because it produces the reported **560 instances**.

## TQWT

The TQWT stage uses the parameters reported in the paper:

```text
Q = 3.5
r = 3
J = 29
```

The implementation produces **30 TQWT components/subbands** for these settings.

The project uses an external MATLAB TQWT implementation because the required `tqwt` function was not initially available in the MATLAB installation. The exact TQWT implementation/version should therefore be recorded for reproducibility.

## Firat Fractal Pattern (FFP)

The FFP implementation follows the published procedure:

```text
EEG signal
    |
    v
25-sample overlapping window
    |
    v
5 x 5 matrix
    |
    v
Four directed Hamiltonian graph patterns
    |
    v
8 binary comparisons per graph
    |
    v
Map values 0-255
    |
    v
256-bin histogram per graph
    |
    v
4 x 256
    |
    v
1,024 FFP features
```

For a 38,252-sample recording:

```text
38,252 - 25 + 1 = 38,228
```

overlapping FFP windows are produced.

The implementation has been tested using S01G1 and across all 14 EEG channels. A single FFP feature vector contains **1,024 features**.

### FFP graph patterns

The four directed graph patterns implemented in `FFP.m` are based on the 5 x 5 matrix and use the centre element as the starting/return point. The four graph paths are implemented explicitly so that the numerical behaviour can be tested independently.

For each graph, eight comparisons are encoded into an 8-bit map value. The four 256-bin histograms are concatenated to form the final 1,024-dimensional FFP representation.

## TQWT + FFP Features

FFP is applied to:

1. The original EEG segment.
2. Each of the 30 TQWT components.

Therefore:

```text
1 raw EEG + 30 TQWT components = 31 representations

31 x 1,024 = 31,744 features
```

Each EEG segment is represented by **31,744 features**.

## Dataset Assembly Validation

The complete dataset assembly has been tested using channel **F8**.

| Property | Value |
|---|---:|
| Channel | F8 |
| Subjects | 28 |
| Games/classes | 4 |
| Segments per recording | 5 |
| Total instances | 560 |
| Features per instance | 31,744 |

The assembled feature matrix therefore has the form:

```text
X : 560 x 31,744
Y : 560 x 1
```

The feature table also retains subject, game, segment and label metadata.

## IChi2 Feature Selection

The paper introduces an iterative chi-square feature-selection method called **IChi2**.

The reported procedure is approximately:

```text
Feature matrix
      |
      v
Min-max normalisation
      |
      v
Chi-square feature ranking
      |
      v
Select i features
      |
      v
Cubic SVM
      |
      v
10-fold cross-validation
      |
      v
Calculate loss
      |
      v
Repeat for i = 100,...,1000
      |
      v
Select minimum-loss feature count
```

The paper's Algorithm 2 evaluates every integer feature count from **100 through 1,000**.

### Current MATLAB implementation

The MATLAB Statistics and Machine Learning Toolbox is now installed and available. The primary current ranking implementation therefore uses:

```matlab
[idx, scores] = fscchi2(XNorm, Y);
```

This is MATLAB's built-in univariate chi-square feature ranking function. The paper itself refers to an abstract function:

```matlab
idx = chi2(XNorm,trgt)
```

but the internal implementation of the authors' `chi2()` function is not provided in the available article.

Therefore, **MATLAB `fscchi2` is the current documented reconstruction, not a claim that it is the authors' original `chi2()` implementation.**

The default MATLAB `fscchi2` configuration is currently used as the primary experiment because the paper does not explicitly specify an alternative number of bins for its chi-square calculation.

An additional `NumBins = 2` experiment was also investigated as a reconstruction candidate, but it is not treated as the definitive paper implementation.

## Cubic SVM

The paper reports:

- Cubic SVM (third-degree polynomial kernel)
- C = 1
- Kernel Scale = Auto
- One-vs-all coding
- 10-fold cross-validation

The project initially contained a custom cubic-kernel SVM/SMO implementation. After the MATLAB Statistics and Machine Learning Toolbox became available, the main SVM reproduction was moved to MATLAB's built-in implementation:

```matlab
fitcecoc(...)
```

with a polynomial SVM template using:

```matlab
'KernelFunction','polynomial'
'PolynomialOrder',3
'BoxConstraint',1
'KernelScale','auto'
```

This is now the **primary SVM implementation** for the reproduction experiments.

The older custom SVM files are retained for diagnostic/research comparison and should not be treated as the primary reproduction result.

## F8 IChi2 + SVM Results

F8 was used as the initial controlled channel for validating the complete feature-selection/classification workflow.

Using MATLAB `fscchi2` ranking and MATLAB cubic SVM, the ten-point feature-count diagnostic was:

| Selected features | Accuracy (%) |
|---:|---:|
| 100 | 82.32 |
| 200 | 87.86 |
| 300 | 88.93 |
| 400 | 93.75 |
| 500 | 92.68 |
| 600 | 96.07 |
| 700 | 96.43 |
| 800 | 97.32 |
| 900 | 97.32 |
| 1000 | 97.32 |

A full integer search from **100 to 1,000** was subsequently completed for F8 using the current IChi2 implementation.

| Measure | Result |
|---|---:|
| Channel | F8 |
| Instances | 560 |
| Original features | 31,744 |
| IChi2 search | 100:1000 |
| Optimal feature count | **980** |
| Minimum loss | **0.0250** |
| Optimal 10-fold CV accuracy | **97.50%** |

The paper reports **888 selected features for F8**. The current implementation obtains **980**, so this difference remains a reproducibility issue and has not been artificially adjusted.

## IChi2 + SVM: All 14 Channels

A full 100:1000 IChi2 search using MATLAB `fscchi2` and MATLAB cubic SVM has been completed for all 14 channels. Results currently available are:

| Channel | Optimal features | Accuracy (%) | Loss |
|---|---:|---:|---:|
| AF3 | 934 | 97.50 | 0.025000 |
| AF4 | 998 | 98.571 | 0.014286 |
| F3 | 827 | 97.679 | 0.023214 |
| F4 | 984 | 98.571 | 0.014286 |
| F7 | 954 | 96.607 | 0.033929 |
| F8 | 980 | 97.500 | 0.025000 |
| FC5 | 835 | 98.929 | 0.010714 |
| FC6 | 628 | 96.607 | 0.033929 |
| O1 | 995 | 97.321 | 0.026786 |
| O2 | 951 | 97.857 | 0.021429 |
| P7 | 786 | 98.929 | 0.010714 |
| P8 | 805 | 98.036 | 0.019643 |
| T7 | 982 | 98.393 | 0.016071 |
| T8 | 807 | 97.321 | 0.026786 |

These values are **current reproduction results**, not claims of exact agreement with the paper.

The full-search script is resumable and saves each channel's result separately so that completed channels do not need to be recomputed after an interruption.

## LDA

The paper reports an LDA configuration described as:

- Linear discriminant
- Full covariance structure
- Gamma = 0
- 10-fold cross-validation

The current MATLAB implementation uses:

```matlab
fitcdiscr(...,
    'DiscrimType','linear', ...
    'Gamma',0)
```

The current LDA workflow uses the same MATLAB `fscchi2` feature ranking and evaluates feature counts from 100 to 1,000.

### F8 LDA diagnostic

A ten-point F8 experiment produced:

| Selected features | Accuracy (%) | Loss |
|---:|---:|---:|
| 100 | 65.18 | 0.3482 |
| 200 | 73.04 | 0.2696 |
| 300 | 72.50 | 0.2750 |
| 400 | 70.89 | 0.2911 |
| 500 | **27.68** | **0.7232** |
| 600 | 68.57 | 0.3143 |
| 700 | 78.57 | 0.2143 |
| 800 | 83.57 | 0.1643 |
| 900 | 87.32 | 0.1268 |
| 1000 | **90.36** | **0.0964** |

The current optimum in this ten-point diagnostic is therefore **1,000 features with 90.36% accuracy**.

### 500-feature LDA diagnostic

The unusual 500-feature result was investigated using the same fixed 10-fold partition. The result was confirmed across all folds:

| Measure | Result |
|---|---:|
| Mean accuracy | **27.68%** |
| Mean loss | **0.7232** |
| Minimum fold accuracy | 19.64% |
| Maximum fold accuracy | 35.71% |
| Standard deviation | 4.47 percentage points |

The overall predicted class distribution was:

| Class | True instances | Predicted instances |
|---|---:|---:|
| Boring | 140 | 90 |
| Calm | 140 | 164 |
| Funny | 140 | 149 |
| Horror | 140 | 157 |

This indicates that the 27.68% result is not caused by one failed fold or by predicting only a single class. It is retained as an observed result of the current implementation and is not manually removed.

A full all-channel IChi2 + LDA experiment is the next classification stage.

## Published Results Used for Comparison

The paper reports the following overall classifier accuracies for its experimental setup:

| Classifier | Published mean accuracy |
|---|---:|
| k-NN | 98.31% |
| LDA | 86.84% |
| Cubic SVM | 98.88% |

The paper also reports **99.82% accuracy for F8 using SVM**, with 888 selected features. The published F8 confusion matrix contains one misclassification out of 560 instances.

These published values are comparison targets only. Differences in implementation, chi-square ranking, segmentation interpretation, TQWT implementation and validation details must be considered before drawing conclusions from numerical differences.

## Current Progress

| Component | Status |
|---|---|
| GAMEEMO data loading | Completed |
| EEG segmentation | Completed and validated |
| FFP implementation | Completed and validated |
| FFP testing on all 14 channels | Completed |
| TQWT implementation | Completed and validated |
| TQWT + FFP | Completed and validated |
| 31,744-feature generation | Completed and validated |
| Dataset assembly | Completed and validated |
| MATLAB Statistics and Machine Learning Toolbox | Available |
| MATLAB `fscchi2` ranking | Completed and used as primary ranking |
| IChi2 + MATLAB cubic SVM | Completed for all 14 channels |
| F8 full IChi2 + SVM search | Completed |
| LDA implementation | Completed |
| F8 LDA ten-point diagnostic | Completed |
| F8 500-feature LDA diagnostic | Completed |
| All-channel IChi2 + LDA | **Next stage** |
| k-NN | Pending |
| Confusion matrices for final classifier results | Pending |
| Additional performance metrics | Pending |
| Exact reproduction of paper | Under investigation |
| Subject-wise/nested validation | Future methodological stage |

## Important Reproducibility Limitations

### 1. Original `chi2()` implementation

The paper uses `chi2(XNorm,trgt)`, but the internal implementation is not provided in the available manuscript. MATLAB `fscchi2` is therefore used as the current documented reconstruction.

### 2. Number of chi-square bins

MATLAB `fscchi2` supports configurable binning. The paper does not explicitly specify the bin count in the available description. The current primary experiment uses MATLAB's default configuration rather than selecting a setting solely to match a target result. A two-bin reconstruction was investigated separately.

### 3. TQWT implementation

The paper specifies Q, r and J but does not provide enough MATLAB-specific implementation information to guarantee identical numerical coefficients. The external TQWT implementation and MATLAB release should therefore be recorded.

### 4. Cross-validation placement

The current reproduction ranks features after global min-max normalization and then evaluates candidate feature counts using 10-fold instance-level cross-validation. This follows the described reproduction workflow but is **not a strict leakage-safe subject-wise nested validation design**.

For the later PhD methodology, feature selection and normalization should be incorporated within the appropriate training folds, with subjects kept separated between training and testing.

### 5. Segmentation wording in the paper

The paper contains wording referring to four frames while the explicit data-construction description and the reported 560 instances are consistent with five segments per recording. The current implementation follows the five-segment construction and records this decision explicitly.

### 6. Published feature counts versus current feature counts

The paper reports channel-specific selected feature counts, including:

```text
AF3 396    AF4 871    F3 723    F4 517
F7 778     F8 888     FC5 731    FC6 799
O1 582     O2 819     P7 733     P8 860
T7 990     T8 771
```

The current implementation produces different counts. This is treated as a reproducibility finding, not as a value to be forced to match.

## Project Structure

```text
FFP_Reproduction/
|
+-- data/
|   +-- GAMEEMO/
|       +-- .gitkeep
|
+-- src/
|   +-- FFP.m
|   +-- segmentEEG.m
|   +-- loadGAMEEMO.m
|   +-- extractTQWTFFP.m
|   +-- buildChannelDataset.m
|   +-- chiSquareRanking.m
|   +-- create10Folds.m
|   +-- cubicKernel.m
|   +-- estimateKernelScale.m
|   +-- trainBinarySVM.m
|   +-- predictBinarySVM.m
|   +-- trainCubicSVM_OVA.m
|   +-- predictCubicSVM_OVA.m
|   +-- IChi2.m
|   +-- IChi2_LDA.m
|
+-- external/
|   +-- TQWT/
|
+-- tests/
|   +-- test_FFP_AF3.m
|   +-- test_FFP_singleWindow.m
|   +-- test_FFP_allChannels.m
|   +-- test_segmentation.m
|   +-- test_loadGAMEEMO.m
|   +-- test_TQWT.m
|   +-- test_TQWT_FFP.m
|   +-- test_extractTQWTFFP.m
|   +-- test_5Blocks_TQWTFFP.m
|   +-- test_buildChannelDataset.m
|   +-- test_chiSquareRanking.m
|   +-- test_create10Folds.m
|   +-- test_cubicSVM.m
|   +-- test_cubicSVM_synthetic.m
|   +-- test_IChi2.m
|   +-- test_SVM_diagnostic.m
|   +-- test_SVM_600.m
|   +-- test_kernel_scale.m
|   +-- test_LDA_500.m
|   +-- run_IChi2_AllChannels_Full.m
|   +-- run_IChi2_LDA_AllChannels.m
|
+-- results/
|   +-- IChi2/
|   +-- LDA/
|
+-- getConfig.m
+-- main.m
+-- README.md
+-- .gitignore
```

## MATLAB Environment

Current development environment:

```text
MATLAB R2024b Update 8
Windows 11
```

Currently installed and available:

- Deep Learning Toolbox
- Image Processing Toolbox
- Parallel Computing Toolbox
- Signal Processing Toolbox
- Statistics and Machine Learning Toolbox
- Wavelet Toolbox

The Statistics and Machine Learning Toolbox licence has been verified and functions including `fscchi2`, `fitcecoc`, `fitcdiscr` and related classification functions are available.

### Additional dependency

The project also uses an external MATLAB implementation of **TQWT**. The TQWT source is not assumed to be part of the MATLAB base installation and should be documented separately for reproducibility.

## Configuration

The main configuration is maintained in `getConfig.m`.

Current parameters include:

```matlab
config.dataRoot = fullfile('data','GAMEEMO');

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

## How to Run

### 1. Obtain the dataset

Download GAMEEMO separately. The dataset is not included in this repository.

### 2. Place the dataset

Place the dataset under:

```text
data/GAMEEMO/
```

### 3. Add the project to MATLAB

From the project root:

```matlab
addpath(genpath(pwd));
```

### 4. Run component tests

Examples:

```matlab
test_FFP_AF3
```

```matlab
test_TQWT
```

```matlab
test_5Blocks_TQWTFFP
```

### 5. Build a channel dataset

For example, F8:

```matlab
config = getConfig();
dataset = loadGAMEEMO(config);
datasetTable = buildChannelDataset(dataset, config, 'F8');

X = table2array(datasetTable(:,5:end));
Y = datasetTable.Label;
```

### 6. Run F8 IChi2 + SVM

The full F8 result is stored under:

```text
results/IChi2/F8_IChi2_full_results.mat
```

### 7. Run the 500-feature LDA diagnostic

```matlab
test_LDA_500
```

The diagnostic is saved under:

```text
results/LDA/F8_LDA_500_diagnostic.mat
```

### 8. Run all-channel IChi2 + SVM

```matlab
run_IChi2_AllChannels_Full
```

The script saves each channel independently and maintains a summary CSV.

### 9. Run all-channel IChi2 + LDA

```matlab
run_IChi2_LDA_AllChannels
```

This is the current next classification experiment.

## Reproducibility Workflow

The project is being developed and validated in stages:

```text
Test individual component
        |
        v
Validate numerical/output dimensions
        |
        v
Combine components
        |
        v
Validate complete stage
        |
        v
Run controlled F8 experiment
        |
        v
Extend to all 14 channels
        |
        v
Compare with published results
        |
        v
Develop stricter subject-wise validation
```

The project deliberately records discrepancies rather than changing parameters solely to reproduce a particular published number.

## Future Work

1. Complete all-channel IChi2 + LDA.
2. Implement and validate k-NN using the reported Manhattan distance, k = 1 and equal weighting.
3. Generate final confusion matrices.
4. Calculate accuracy, balanced accuracy, precision, recall, F1-score and geometric mean where appropriate.
5. Compare all classifier results systematically with the paper.
6. Investigate the remaining difference between the published and current IChi2 feature counts.
7. Investigate the original `chi2()` implementation if source code becomes available.
8. Investigate any remaining implementation differences in TQWT and classifier configuration.
9. Develop subject-wise/nested validation for the later PhD experiments.
10. After the reproduction stage, use the lessons learned to inform the planned explainable EEG methodology for Parkinson's disease research.

## Research Context

This reproduction work forms part of a broader PhD research project on:

> **Development of an explainable computational framework for early detection of neurological conditions.**

The current reproduction focuses on understanding EEG feature extraction, signal decomposition, feature selection and classification before developing and evaluating the proposed methodology for the PhD research.

## Citation

If you use or refer to the published methodology, please cite:

```text
Tuncer, T., Dogan, S., & Subasi, A. (2021).
A New Fractal Pattern Feature Generation Function based Emotion Recognition Method using EEG.
Chaos, Solitons & Fractals, 144, 110671.
https://doi.org/10.1016/j.chaos.2021.110671
```

## Project Status

**Current stage: Initial methodology reproduction and validation**

The FFP and TQWT feature-generation stages have been implemented and tested. MATLAB-based chi-square ranking and cubic SVM experiments have been completed for all 14 channels. LDA has been implemented and the F8 diagnostic has been completed; the full all-channel LDA experiment is the current next stage. k-NN and final comparative evaluation remain pending.

**The numerical results in this README are preliminary reproduction results. They should not be presented as exact replication of the published paper until the remaining implementation and validation differences have been resolved.**
