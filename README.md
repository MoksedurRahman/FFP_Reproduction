# Firat Fractal Pattern (FFP) EEG Reproduction

MATLAB implementation of the method described in:

**Tuncer, T., Doğan, S., & Subasi, A. (2021).**  
*A New Fractal Pattern Feature Generation Function based Emotion Recognition Method using EEG.*  
*Chaos, Solitons & Fractals*, 144, 110671.  
DOI: 10.1016/j.chaos.2021.110671

This repository follows the processing steps, parameters, feature construction and classifiers described in the paper. The sections below explain the paper's method and show how the MATLAB implementation represents each stage.

---

## 1. Method Overview

The paper presents an EEG emotion-recognition method based on the **Firat Fractal Pattern (FFP)** feature-generation function. FFP is combined with the **Tunable Q-factor Wavelet Transform (TQWT)** and **Iterative Chi-square (IChi2)** feature selection before classification.

The MATLAB implementation follows this sequence:

```text
GAMEEMO EEG
    ↓
Five non-overlapping segments
    ↓
FFP feature extraction
    ↓
TQWT decomposition
    ↓
FFP feature extraction from TQWT components
    ↓
31,744 features
    ↓
Min-max normalization
    ↓
Chi-square feature ranking
    ↓
IChi2 feature selection
    ↓
Cubic SVM / LDA / k-NN
    ↓
10-fold cross-validation
```

---

## 2. GAMEEMO Dataset

The paper uses the **GAMEEMO** EEG dataset for emotion recognition. The dataset contains EEG recordings from 28 subjects using 14 EEG channels.

| Item | Value |
|---|---|
| EEG channels | 14 |
| Sampling frequency | 2048 Hz |
| Subjects | 28 |
| Classes | 4 |
| Samples per recording | 38,252 |
| EEG device | Emotiv EPOC+ |

Channels:

```text
AF3, AF4, F3, F4, F7, F8, FC5, FC6,
O1, O2, P7, P8, T7, T8
```

Classes:

```text
G1 = Boring
G2 = Calm
G3 = Horror
G4 = Funny
```

### Code implementation

The dataset-loading code reads the GAMEEMO recordings and prepares individual EEG channels for feature extraction.

The implementation divides each 38,252-sample recording into **five non-overlapping segments** of 7,650 samples:

```text
38,252 samples
      ↓
5 × 7,650 samples
      ↓
2 samples remaining
```

Thus, for each channel:

```text
28 subjects × 4 classes × 5 segments
= 560 instances
```

Main code:

```text
src/loadGAMEEMO.m
src/segmentEEG.m
src/buildChannelDataset.m
```

---

## 3. Firat Fractal Pattern (FFP)

The main feature-generation method proposed in the paper is the **Firat Fractal Pattern (FFP)**. The method converts short EEG signal windows into 5 × 5 matrices and uses four graph patterns to generate binary maps.

### Parameters

| Parameter | Value |
|---|---:|
| Window length | 25 samples |
| Matrix | 5 × 5 |
| Graph patterns | 4 |
| Comparisons per graph | 8 |
| Map values | 0–255 |
| Histogram bins | 256 |
| FFP features | 1,024 |

### Code implementation

For every 25-sample EEG window, the code:

1. Converts the samples into a 5 × 5 matrix.
2. Applies the four graph patterns described in the paper.
3. Compares consecutive points along each graph.
4. Generates an 8-bit map value.
5. Builds a 256-bin histogram.
6. Concatenates the four histograms.

The resulting feature vector is:

```text
4 × 256 = 1,024 features
```

The binary comparison used in the implementation is equivalent to the paper's signum rule:

```matlab
bit = double(initialPoint >= endpoint);
```

The map value is generated using:

```matlab
mapValue = sum(bits .* 2.^(0:7));
```

Main code:

```text
src/FFP.m
```

For a signal containing 38,252 samples, the number of overlapping 25-sample windows is:

```text
38,252 − 25 + 1 = 38,228 windows
```

---

## 4. TQWT

The paper combines FFP with the **Tunable Q-factor Wavelet Transform (TQWT)**. TQWT decomposes the EEG signal into multiple components, and FFP is then applied to these components.

### Parameters

| Parameter | Value |
|---|---:|
| Q | 3.5 |
| r | 3 |
| J | 29 |
| Components | 30 |

### Code implementation

The code first calculates the FFP features of the original EEG signal and then applies FFP to each of the 30 TQWT components.

```text
Original EEG
    → 1 × 1,024 features

TQWT component 1
    → 1 × 1,024 features

...

TQWT component 30
    → 1 × 1,024 features
```

Therefore:

```text
1,024 + (30 × 1,024)
= 31,744 features
```

Main code:

```text
src/extractTQWTFFP.m
```

The project contains the TQWT implementation under:

```text
external/TQWT/
```

---

## 5. Feature Vector Construction

The feature-generation process combines the FFP representation of the original EEG with the FFP representations obtained from the TQWT components.

The MATLAB code stores the resulting features sequentially:

```text
Features 1–1,024
    Original EEG FFP

Features 1,025–2,048
    TQWT component 1 FFP

Features 2,049–3,072
    TQWT component 2 FFP

...

Features 30,721–31,744
    TQWT component 30 FFP
```

Thus, every EEG segment produces:

```text
31,744 features
```

For the complete channel dataset:

```text
560 instances × 31,744 features
```

---

## 6. Chi-square Feature Ranking

The paper uses Chi-square feature ranking after min-max normalization.

The normalization used in the implementation is:

```matlab
xmin = min(X,[],1);
xmax = max(X,[],1);
featureRange = xmax - xmin;
featureRange(featureRange == 0) = 1;
XNorm = (X - xmin) ./ featureRange;
```

The current MATLAB implementation performs Chi-square feature ranking using the Statistics and Machine Learning Toolbox:

```matlab
[idx, scores] = fscchi2(XNorm, target);
```

Here:

- `idx` contains feature indices in ranked order.
- `scores` contains the corresponding Chi-square scores.

The ranking is then supplied to the IChi2 procedure.

Main code:

```text
src/chiSquareRanking.m
src/IChi2.m
```

---

## 7. IChi2 Feature Selection

The paper introduces an **Iterative Chi-square (IChi2)** feature-selection procedure. After Chi-square ranking, different numbers of the highest-ranked features are evaluated using the classifier and 10-fold cross-validation.

The implementation evaluates every integer feature count from 100 to 1,000:

```matlab
featureCounts = 100:1000;
```

Therefore:

```text
100, 101, 102, ..., 999, 1000
```

For each selected feature count:

```text
Ranked features
      ↓
Select first i features
      ↓
Classification
      ↓
10-fold cross-validation
      ↓
Accuracy
      ↓
Loss
```

The loss is calculated as:

```text
Loss = 1 − Accuracy
```

The feature count corresponding to the minimum loss is retained as the **optimal feature count**.

Main code:

```text
src/IChi2.m
src/IChi2_LDA.m
src/IChi2_kNN.m
```

---

## 8. Classification

The paper evaluates three classifiers after IChi2 feature selection:

```text
Cubic SVM
LDA
k-NN
```

Each classifier is evaluated using 10-fold cross-validation.

### 8.1 Cubic SVM

The paper specifies a cubic polynomial SVM with:

```text
Polynomial order = 3
Box constraint C = 1
Kernel scale = Auto
One-vs-all coding
10-fold cross-validation
```

The MATLAB implementation uses:

```matlab
templateSVM( ...
    'KernelFunction','polynomial', ...
    'PolynomialOrder',3, ...
    'BoxConstraint',1, ...
    'KernelScale','auto')
```

and:

```matlab
fitcecoc(..., 'Coding','onevsall')
```

Main code:

```text
src/IChi2.m
src/trainCubicSVM_OVA.m
src/predictCubicSVM_OVA.m
```

### 8.2 LDA

The paper specifies a linear discriminant with Gamma = 0.

The MATLAB implementation uses:

```matlab
fitcdiscr( ...
    XTrain, YTrain, ...
    'DiscrimType','linear', ...
    'Gamma',0)
```

Main code:

```text
src/IChi2_LDA.m
```

### 8.3 k-NN

The paper specifies:

```text
k = 1
Manhattan distance
Equal distance weighting
10-fold cross-validation
```

The MATLAB implementation uses MATLAB's `fitcknn` with the corresponding settings:

```matlab
fitcknn( ...
    XTrain, YTrain, ...
    'NumNeighbors',1, ...
    'Distance','cityblock', ...
    'DistanceWeight','equal')
```

Here, MATLAB's `cityblock` distance represents Manhattan distance.

Main code:

```text
src/IChi2_kNN.m
```

---

## 9. Published Results

The paper reports the following overall mean classification accuracies:

| Classifier | Mean accuracy |
|---|---:|
| k-NN | 98.31% |
| LDA | 86.84% |
| SVM | 98.88% |

The paper reports the following selected feature counts:

| Channel | Selected features |
|---|---:|
| AF3 | 396 |
| AF4 | 871 |
| F3 | 723 |
| F4 | 517 |
| F7 | 778 |
| F8 | 888 |
| FC5 | 731 |
| FC6 | 799 |
| O1 | 582 |
| O2 | 819 |
| P7 | 733 |
| P8 | 860 |
| T7 | 990 |
| T8 | 771 |

The paper reports an F8 SVM accuracy of:

```text
99.82%
```

---

## 10. Current Reproduction Results

The following results are from the current MATLAB implementation using the pipeline described in this README.

### 10.1 IChi2 + Cubic SVM

| Channel | Optimal features | Accuracy |
|---|---:|---:|
| AF3 | 934 | 97.500% |
| AF4 | 998 | 98.571% |
| F3 | 827 | 97.679% |
| F4 | 984 | 98.571% |
| F7 | 954 | 96.607% |
| F8 | 980 | 97.500% |
| FC5 | 835 | 98.929% |
| FC6 | 628 | 96.607% |
| O1 | 995 | 97.321% |
| O2 | 951 | 97.857% |
| P7 | 786 | 98.929% |
| P8 | 805 | 98.036% |
| T7 | 982 | 98.393% |
| T8 | 807 | 97.321% |
| **Mean** | — | **97.844%** |

### 10.2 IChi2 + k-NN

| Channel | Optimal features | Accuracy |
|---|---:|---:|
| AF3 | 961 | 95.714% |
| AF4 | 986 | 95.357% |
| F3 | 999 | 94.821% |
| F4 | 888 | 95.357% |
| F7 | 633 | 95.536% |
| F8 | 908 | 96.250% |
| FC5 | 632 | 96.429% |
| FC6 | 979 | 95.893% |
| O1 | 865 | 97.143% |
| O2 | 573 | 94.643% |
| P7 | 849 | 94.821% |
| P8 | 987 | 95.179% |
| T7 | 763 | 95.893% |
| T8 | 857 | 96.786% |
| **Mean** | — | **95.702%** |

### 10.3 IChi2 + LDA

| Channel | Optimal features | Accuracy |
|---|---:|---:|
| AF3 | 987 | 93.929% |
| AF4 | 972 | 95.000% |
| F3 | 904 | 94.643% |
| F4 | 991 | 95.357% |
| F7 | 965 | 87.143% |
| F8 | 1000 | 90.357% |
| FC5 | 996 | 95.000% |
| FC6 | 984 | 93.214% |
| O1 | 990 | 93.393% |
| O2 | 972 | 94.643% |
| P7 | 995 | 94.286% |
| P8 | 1000 | 96.250% |
| T7 | 978 | 93.929% |
| T8 | 926 | 93.571% |
| **Mean** | — | **93.622%** |

### 10.4 Classifier comparison

The mean accuracies from the current implementation are:

| Classifier | Published mean accuracy | Current reproduction mean accuracy |
|---|---:|---:|
| Cubic SVM | 98.88% | **97.844%** |
| k-NN | 98.31% | **95.702%** |
| LDA | 86.84% | **93.622%** |

The published values and the current reproduction values are shown separately so that the results from the paper are not confused with results produced by this implementation.

---

## 11. Current Reproduction Result Details

### Optimal feature counts

The current implementation evaluates every feature count from 100 to 1,000 and records the feature count giving the minimum cross-validation loss for each channel and classifier.

For the three classifiers, the optimal feature-count ranges are:

| Classifier | Minimum selected | Maximum selected |
|---|---:|---:|
| Cubic SVM | 628 | 998 |
| k-NN | 573 | 999 |
| LDA | 904 | 1000 |

The values are channel-specific and are retained in the saved result files.

### Result files

The all-channel experiments save individual result files and summary files under the `results` directory. The exact subdirectory can depend on the runner used.

Typical result files include:

```text
results/IChi2/SVM/
    AF3_IChi2_SVM_full_results.mat
    AF4_IChi2_SVM_full_results.mat
    ...
    T8_IChi2_SVM_full_results.mat
    IChi2_SVM_AllChannels_Summary.mat
```

and corresponding LDA and k-NN result directories.

Each result contains the IChi2 feature counts, accuracies/losses, selected feature ranking information and the optimal result recorded by the corresponding experiment.

---

## 12. Verification Tests

The project includes separate tests for the main stages.

### FFP

```text
test_FFP_singleWindow.m
test_FFP_AF3.m
test_FFP_allChannels.m
```

The FFP tests verify the 5 × 5 construction, graph maps and 1,024-feature output.

### Segmentation

```text
test_segmentation.m
test_5Blocks_TQWTFFP.m
```

These tests verify the five non-overlapping segment construction used for the GAMEEMO recordings.

### TQWT and TQWT + FFP

```text
test_TQWT.m
test_TQWT_FFP.m
test_extractTQWTFFP.m
```

### Dataset construction

```text
test_buildChannelDataset.m
```

The dataset construction test verifies the expected 560 instances and 31,744 features per channel.

### Feature ranking and classification

```text
test_chiSquareRanking.m
test_IChi2.m
test_cubicSVM.m
test_cubicSVM_synthetic.m
test_SVM_diagnostic.m
test_SVM_600.m
test_kernel_scale.m
test_LDA_500.m
```

All-channel experiment runners:

```text
run_IChi2_AllChannels_Full.m
run_IChi2_LDA_AllChannels.m
run_IChi2_kNN_AllChannels.m
run_IChi2_AllChannels_SVM.m
```

---

## 13. MATLAB Environment

```text
MATLAB R2024b Update 8
Windows 11
```

Installed toolboxes used by the project include:

```text
Deep Learning Toolbox
Image Processing Toolbox
Parallel Computing Toolbox
Signal Processing Toolbox
Statistics and Machine Learning Toolbox
Wavelet Toolbox
```

The project also uses a MATLAB implementation of TQWT in:

```text
external/TQWT/
```

---

## 14. Configuration

The main parameters are maintained in `getConfig.m`.

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

Keeping the main parameters in one configuration file makes it straightforward to use the same settings throughout the reproduction code.

---

## 15. Project Structure

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
│   ├── create10Folds.m
│   ├── cubicKernel.m
│   ├── estimateKernelScale.m
│   ├── trainBinarySVM.m
│   ├── predictBinarySVM.m
│   ├── trainCubicSVM_OVA.m
│   ├── predictCubicSVM_OVA.m
│   ├── IChi2.m
│   ├── IChi2_LDA.m
│   └── IChi2_kNN.m
│
├── external/
│   └── TQWT/
│
├── tests/
│   ├── test_FFP_AF3.m
│   ├── test_FFP_singleWindow.m
│   ├── test_FFP_allChannels.m
│   ├── test_segmentation.m
│   ├── test_loadGAMEEMO.m
│   ├── test_TQWT.m
│   ├── test_TQWT_FFP.m
│   ├── test_extractTQWTFFP.m
│   ├── test_5Blocks_TQWTFFP.m
│   ├── test_buildChannelDataset.m
│   ├── test_chiSquareRanking.m
│   ├── test_create10Folds.m
│   ├── test_cubicSVM.m
│   ├── test_cubicSVM_synthetic.m
│   ├── test_IChi2.m
│   ├── test_SVM_diagnostic.m
│   ├── test_SVM_600.m
│   ├── test_kernel_scale.m
│   ├── test_LDA_500.m
│   ├── run_IChi2_AllChannels_Full.m
│   ├── run_IChi2_LDA_AllChannels.m
│   ├── run_IChi2_kNN_AllChannels.m
│   └── run_IChi2_AllChannels_SVM.m
│
├── results/
│   └── IChi2/
│       ├── SVM/
│       └── ...
│
├── getConfig.m
├── main.m
├── README.md
└── .gitignore
```

---

## 16. Running the Project

### Load GAMEEMO

```matlab
config = getConfig();
dataset = loadGAMEEMO(config);
```

### Build a channel dataset

```matlab
datasetTable = buildChannelDataset(dataset, config, 'F8');
```

### Run IChi2 + Cubic SVM

```matlab
run_IChi2_AllChannels_SVM
```

### Run IChi2 + LDA

```matlab
run_IChi2_LDA_AllChannels
```

### Run IChi2 + k-NN

```matlab
run_IChi2_kNN_AllChannels
```

The all-channel runners save each completed channel result before continuing to the next channel. This allows a later run to continue using existing result files.

---

## 17. Reproduction Sequence

The complete implementation can be followed in this order:

```text
1. Load GAMEEMO
2. Segment EEG recordings into five non-overlapping segments
3. Extract FFP features from the original EEG
4. Apply TQWT
5. Extract FFP from the TQWT components
6. Construct 31,744-feature vectors
7. Perform min-max normalization
8. Rank features using Chi-square
9. Run IChi2 from 100 to 1,000 features
10. Evaluate cubic SVM
11. Evaluate LDA
12. Evaluate k-NN
13. Record the optimal feature count and classification accuracy
14. Save channel-level and all-channel results
```

---

## Reference

Tuncer, T., Doğan, S., & Subasi, A. (2021).

**A New Fractal Pattern Feature Generation Function based Emotion Recognition Method using EEG.**

*Chaos, Solitons & Fractals*, 144, 110671.

DOI: 10.1016/j.chaos.2021.110671
