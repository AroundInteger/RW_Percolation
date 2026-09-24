# Step 1: MSD Data Import and Transformation

## Overview
This step imports the MSD data from `p_output_NEW34.csv` and transforms it to logspace with linear interpolation for consistent analysis. This prepares the data for the local α(ω) analysis in the next steps.

## Files Created

### Main Script
- **`step1_import_and_transform_msd.m`**: Main transformation script that:
  - Imports the 1,000,000 × 34 MSD dataset
  - Transforms to logspace (1000 points)
  - Interpolates to linear spacing (2000 points)
  - Creates quality checks and visualizations
  - Saves processed data in both `.mat` and `.csv` formats

### Test Script
- **`test_step1_data_loading.m`**: Test script to verify:
  - Data file existence and size
  - Data structure validation
  - Transformation process
  - Output file creation
  - Data quality checks

### Output Files
- **`msd_processed_data.mat`**: MATLAB format with all variables
- **`msd_processed_data.csv`**: CSV format for compatibility

## Data Structure

### Input Data
- **Source**: `p_output.csv`
- **Size**: 1,000,001 rows × 34 columns
- **Content**: MSD values for 34 p-values (0.0000 to 0.9500)
- **Time range**: 0 to 999,999 simulation steps

### Processed Data
- **Log-spaced**: 1000 time points (logarithmically distributed)
- **Linear interpolation**: 2000 time points (evenly spaced)
- **Time range**: 1 to 999,999 steps (avoiding t=0)
- **Frequency range**: ω ≈ [0.000001, 0.001] (1/time)

## Key Transformations

### 1. Logspace Transformation
- **Purpose**: Focus on meaningful time scales, avoid very early times
- **Method**: `logspace(log10(1), log10(999999), 1000)`
- **Benefits**: Better resolution at longer time scales

### 2. Linear Interpolation
- **Purpose**: Create consistent, evenly-spaced time points
- **Method**: `interp1()` with 'pchip' interpolation
- **Benefits**: Smooth curves, consistent analysis windows

### 3. Quality Assurance
- **NaN/Inf detection**: Ensures no interpolation artifacts
- **Data validation**: Confirms p-value extraction and time mapping
- **Visualization**: 4-panel plot showing transformation quality

## Critical Parameters

### Percolation Values
- **Total**: 34 p-values
- **Range**: 0.0000 to 0.9500
- **Critical thresholds**: 
  - p_c ≈ 0.3116 (occupied sites)
  - p_c' ≈ 0.6884 (accessible volume)

### Time Windows
- **Original**: 1,000,000 steps
- **Log-spaced**: 1000 points
- **Linear**: 2000 points
- **Resolution**: ~500 steps between points

## Next Steps: Local α(ω) Analysis

### Phase 2: Frequency Window Definition
1. **Define frequency grid**: ω = [0.001, 0.002, 0.004, 0.008, 0.014, 0.027, 0.0518, 0.01]
2. **Map ω → t**: Convert each frequency to corresponding time windows
3. **Window sizing**: Determine optimal window size for each frequency

### Phase 3: Local α Extraction
1. **Time window analysis**: Extract MSD data within each frequency window
2. **Local fitting**: Fit α locally within each window using log(MSD) vs log(t)
3. **Quality assessment**: R² values and confidence metrics for each fit

### Phase 4: Viscoelastic Calculation
1. **G'(ω, p)**: Storage modulus using local α(ω, p)
2. **G''(ω, p)**: Loss modulus using local α(ω, p)
3. **Loss tangent**: tan δ(ω, p) = G''/G'

### Phase 5: Validation
1. **Gel point consistency**: All α(ω, p_c') should be equal
2. **Regime behavior**: α(ω, p < p_c') → 1, α(ω, p > p_c') → 0
3. **Transition width**: Should increase with decreasing frequency

## Running the Scripts

### Prerequisites
- MATLAB with Statistics and Machine Learning Toolbox
- `p_output_NEW34.csv` in the same directory

### Execution
```matlab
% Test the setup first
test_step1_data_loading

% Or run the main script directly
step1_import_and_transform_msd
```

### Expected Output
- Console output showing progress and data statistics
- 4-panel visualization figure
- Processed data files saved
- Summary of key parameters

## Technical Notes

### Interpolation Method
- **'pchip'**: Piecewise Cubic Hermite Interpolating Polynomial
- **Advantages**: Preserves monotonicity, smooth derivatives
- **Alternative**: 'spline' for smoother curves (may overshoot)

### Memory Considerations
- **Original data**: ~272 MB (1M × 34 × 8 bytes)
- **Processed data**: ~544 KB (2000 × 34 × 8 bytes)
- **Compression**: ~500x reduction in memory usage

### Performance
- **Loading**: ~10-30 seconds (depends on system)
- **Transformation**: ~5-10 seconds
- **Interpolation**: ~2-5 seconds
- **Total**: ~20-45 seconds for complete transformation

## Troubleshooting

### Common Issues
1. **File not found**: Ensure `p_output_NEW34.csv` is in the working directory
2. **Memory errors**: Close other MATLAB windows, clear workspace
3. **Interpolation artifacts**: Check for NaN/Inf in original data
4. **Plot errors**: Ensure figure window is not minimized

### Data Quality Issues
- **NaN values**: May indicate missing data or simulation issues
- **Inf values**: May indicate numerical overflow in simulation
- **Zero MSD**: Expected for t=0, but check for other time points

## Validation Checklist

- [ ] Data file loads without errors
- [ ] 34 p-values extracted correctly
- [ ] Time transformation produces expected ranges
- [ ] No NaN/Inf values in processed data
- [ ] Visualization shows expected behavior
- [ ] Output files created successfully
- [ ] Data size matches expectations
- [ ] Ready for Phase 2 (frequency window definition)
