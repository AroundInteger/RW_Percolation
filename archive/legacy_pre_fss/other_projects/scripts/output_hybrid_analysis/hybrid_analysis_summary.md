# Hybrid Alpha Analysis Summary Report

## Overview

This report summarizes the hybrid analysis approach combining:
- **Physics-based classification** for clear regimes
- **Transition detection** for critical regions
- **Sigmoid fitting** for continuous parameter evolution
- **Adaptive critical region** width determination

## Dataset Analysis Results

### Original Dataset (p_output_C1.csv)

- **Total p-values analyzed**: 34
- **Regime distribution**:
  - liquid: 22 p-values
  - critical: 11 p-values
  - solid: 1 p-values
- **Sigmoid fit parameters**:
  - p_c = 0.6837
  - Width = 0.0146
  - α_min = 0.0000
  - α_max = 0.9968
  - R² = 0.9957

### New Dataset (p_output_NEW34.csv)

- **Total p-values analyzed**: 34
- **Regime distribution**:
  - liquid: 20 p-values
  - critical: 8 p-values
  - solid: 6 p-values
- **Sigmoid fit parameters**:
  - p_c = 0.6836
  - Width = 0.0138
  - α_min = 0.0000
  - α_max = 0.9945
  - R² = 0.9969

## Key Insights

1. **Transition Detection**: The hybrid approach successfully identifies critical regions
2. **Continuous Parameters**: Sigmoid fitting enables calculation of G', G'', δ, and tan δ at any p-value
3. **Robust Classification**: Combines multiple methods for reliable regime determination
4. **Physics Preservation**: Maintains physical consistency while improving classification accuracy

## Output Files

- `*_hybrid_results.csv`: Detailed analysis results for each dataset
- `plots/`: Comprehensive visualization plots
- `dataset_comparison.png`: Direct comparison between datasets
- `hybrid_analysis_summary.md`: This summary report

