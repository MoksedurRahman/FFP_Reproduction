# FFP Methodology Reproduction

MATLAB implementation and initial experimental reproduction of the EEG feature-generation methodology based on the **Firat Fractal Pattern (FFP)** described in:

> Tuncer, T., Dogan, S., & Subasi, A. (2021). *A New Fractal Pattern Feature Generation Function based Emotion Recognition Method using EEG.* Chaos, Solitons & Fractals, 144, 110671. DOI: 10.1016/j.chaos.2021.110671

## Project Overview

This project implements and investigates the FFP-based EEG processing methodology described in the paper.

The current aims are to:

1. Understand the published methodology.
2. Implement the individual stages in MATLAB.
3. Validate each stage independently.
4. Reproduce the feature-generation pipeline.
5. Perform initial reproduction experiments using GAMEEMO EEG data.
6. Identify differences between the published results and the current implementation.

**Status:** Initial methodology reproduction and investigation. The project does not yet claim exact reproduction of all published results.

## Processing Pipeline

```text
GAMEEMO EEG
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
     +------------------+
     |                  |
     v                  v
  Raw EEG         TQWT components
     |                  |
     +--------+---------+
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
       Chi-square ranking
              |
              v
             IChi2
              |
              v
        Cubic SVM
              |
              v
         10-fold CV
```

## Dataset

The current experiments use the **GAMEEMO EEG dataset**.

The dataset is **not included in this repository**.

Dataset source:
[GAMEEMO EEG Dataset on Kaggle](https://www.kaggle.com/datasets/sigfest/database-for-emotion-recognition-system-gameemo)

Please download the dataset separately and place it under:

data/GAMEEMO/


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

Current class mapping:

```text
G1 -> Boring
G2 -> Calm
G3 -> Horror
G4 -> Funny
```

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

The current implementation therefore produces:

```text
28 subjects x 4 classes x 5 segments = 560 EEG instances
```

## TQWT

The TQWT stage uses the parameters reported in the paper:

```text
Q = 3.5
r = 3
J = 29
```

The implementation produces **30 TQWT components/subbands**.

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
Four Hamiltonian graph patterns
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

overlapping windows are produced.

The FFP implementation has been tested on S01G1 and across all 14 EEG channels.

## TQWT + FFP Features

FFP is applied to:

1. The raw EEG signal.
2. All 30 TQWT components.

Therefore:

```text
1 raw EEG + 30 TQWT components = 31 representations

31 x 1,024 = 31,744 features
```

Each EEG segment is therefore represented by **31,744 features**.

## Dataset Assembly

The complete dataset assembly has been tested using channel **F8**.

| Property | Value |
|---|---:|
| Channel | F8 |
| Subjects | 28 |
| Classes | 4 |
| Segments per recording | 5 |
| Total instances | 560 |
| Features per instance | 31,744 |

## IChi2 Feature Selection

The paper introduces an iterative chi-square feature-selection method called **IChi2**.

The current implementation follows the reported overall procedure:

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
Repeat for different i
      |
      v
Select minimum-loss feature count
```

The paper's Algorithm 2 evaluates every integer feature count from **100 to 1,000**.

## Chi-square Ranking

The paper uses:

```matlab
idx = chi2(XNorm,trgt)
```

The internal implementation of the paper's `chi2()` function is not provided in the available article.

The current project therefore uses a **toolbox-independent reconstruction** of the chi-square ranking procedure.

This is not yet confirmed to be identical to the authors' original implementation.

## Cubic SVM

The paper reports:

- Cubic SVM
- C = 1
- Kernel Scale = Auto
- One-vs-all classification
- 10-fold cross-validation

The current project uses a custom cubic-kernel SVM implementation based on an SMO optimisation procedure.

The current SVM should therefore be considered a **reconstruction**, rather than a confirmed reproduction of MATLAB's original SVM implementation.

## Initial F8 Reproduction Result

F8 is currently being used as the controlled test case.

Latest result:

| Measure | Result |
|---|---:|
| Channel | F8 |
| Instances | 560 |
| Original features | 31,744 |
| IChi2 search range | 100-1,000 |
| Selected features | **1,000** |
| 10-fold CV accuracy | **94.82%** |
| Minimum loss | **0.0518** |
| Dataset assembly time | 56.24 s |
| IChi2 processing time | 45.35 s |

The published paper reports **888 selected features for F8**.

The current implementation selects **1,000 features**. This difference has not been artificially adjusted and is currently being investigated.

## Current Progress

| Component | Status |
|---|---|
| GAMEEMO data loading | Completed |
| EEG segmentation | Completed |
| FFP implementation | Completed and tested |
| FFP testing on 14 channels | Completed |
| TQWT implementation | Completed and tested |
| TQWT + FFP | Completed and tested |
| 31,744-feature generation | Completed and tested |
| Dataset assembly | Completed and tested |
| Chi-square ranking | Working reconstruction |
| IChi2 | Working reconstruction |
| Cubic SVM | Working custom implementation |
| F8 experiment | Completed |
| All 14-channel experiments | Pending |
| LDA | Pending |
| kNN | Pending |
| Confusion matrix | Pending |
| Exact reproduction of paper | Under investigation |
| Subject-wise validation | Future stage |

## Important Limitations

### 1. Original `chi2()` implementation

The paper uses `chi2(XNorm,trgt)`, but the internal implementation is not provided. The current project therefore uses a toolbox-independent reconstruction.

### 2. SVM implementation

The current cubic SVM is a custom implementation. The exact behaviour of the original MATLAB SVM configuration, particularly `KernelScale = Auto`, has not yet been confirmed.

### 3. Difference in F8 feature selection

Published paper:

```text
F8 -> 888 features
```

Current implementation:

```text
F8 -> 1,000 features
```

This difference requires further investigation.

### 4. Validation methodology

The current reproduction performs feature ranking before 10-fold cross-validation. For later PhD experiments, a stricter **subject-wise/nested validation strategy** will be considered to reduce the possibility of information leakage.

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
|   +-- IChi2.m
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
|   +-- ...
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

Currently installed:

- Deep Learning Toolbox
- Image Processing Toolbox
- Signal Processing Toolbox

The Statistics and Machine Learning Toolbox licence is available, but functions such as `fitcsvm` are currently not available in the installation.

## How to Run

### 1. Obtain the dataset

Download GAMEEMO from the dataset source listed above.

The dataset is not included in this repository.

### 2. Place the dataset

Place it under:

```text
data/GAMEEMO/
```

### 3. Add the project to MATLAB

From the project root:

```matlab
addpath(genpath(pwd));
```

### 4. Run tests

For example:

```matlab
test_FFP_AF3
```

```matlab
test_TQWT
```

For the F8 IChi2 experiment:

```matlab
clear
clc
test_IChi2_F8
```

## Reproducibility

The project is being developed and validated in stages:

```text
Test individual component
        |
        v
Validate output
        |
        v
Combine components
        |
        v
Validate complete stage
        |
        v
Proceed to next stage
```

## Future Work

1. Investigate the original `chi2()` implementation used by the authors.
2. Investigate MATLAB's cubic SVM implementation and `KernelScale = Auto`.
3. Understand the difference between the published F8 result and the current F8 result.
4. Complete the remaining classifier implementations.
5. Extend the experiment from F8 to all 14 EEG channels.
6. Generate confusion matrices and additional performance measures.
7. Compare the reproduced results with the published results.
8. Develop subject-wise/nested validation for the later PhD experiments.
9. After the reproduction stage, investigate possible extensions to the methodology.

## Research Context

This reproduction work forms part of a broader PhD research project on:

> **Development of an explainable computational framework for early detection of neurological conditions.**

The current work is being used to understand EEG feature extraction, signal decomposition, feature selection and classification before developing and evaluating the proposed methodology for the PhD research.

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

The FFP and TQWT feature-generation stages are working and have been tested. The IChi2 and cubic-SVM stages are operational but are still being investigated for closer equivalence with the published implementation.

**The results in this repository should therefore be considered preliminary reproduction results, not final experimental results.**
