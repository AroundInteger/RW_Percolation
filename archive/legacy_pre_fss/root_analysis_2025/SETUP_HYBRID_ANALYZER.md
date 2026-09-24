# Setup Guide for Hybrid Alpha Analyzer

## 🚀 **Quick Start**

This guide will help you set up and run the hybrid alpha analyzer in both Python and MATLAB environments.

## 📋 **Prerequisites**

### **Python Requirements**
- Python 3.8+ 
- Required packages: `pandas`, `numpy`, `matplotlib`, `scipy`, `seaborn`

### **MATLAB Requirements**
- MATLAB R2018b+ (for `lsqcurvefit` function)
- Optimization Toolbox (for sigmoid fitting)
- Statistics and Machine Learning Toolbox (recommended)

## 🐍 **Python Setup**

### **1. Install Required Packages**

```bash
# Using pip
pip install pandas numpy matplotlib scipy seaborn

# Using conda
conda install pandas numpy matplotlib scipy seaborn
```

### **2. Verify Installation**

```bash
python -c "import pandas, numpy, matplotlib, scipy, seaborn; print('All packages installed successfully!')"
```

### **3. Run the Analyzer**

```bash
# Navigate to scripts directory
cd scripts

# Run complete analysis pipeline
python hybrid_complete_analysis.py

# Or run individual analyzer
python hybrid_alpha_analyzer.py
```

### **4. Expected Output**

```
=== HYBRID ANALYSIS OF 34 P-VALUES ===
  Progress: 1/34 - p = 0.0000
  Progress: 2/34 - p = 0.0500
  ...
Fitting sigmoid function to α(p) data...
✓ Sigmoid fit successful!
  p_c = 0.6836 ± 0.0009
  width = 0.0138 ± 0.0008
  α_min = 0.0000 ± 0.0097
  α_max = 0.9945 ± 0.0062
  R² = 0.9969
```

## 🔢 **MATLAB Setup**

### **1. Verify Toolbox Availability**

```matlab
% Check if Optimization Toolbox is available
if license('test', 'Optimization_Toolbox')
    fprintf('✓ Optimization Toolbox available\n');
else
    fprintf('✗ Optimization Toolbox required for sigmoid fitting\n');
end

% Check if Statistics Toolbox is available
if license('test', 'Statistics_Toolbox')
    fprintf('✓ Statistics Toolbox available\n');
else
    fprintf('⚠ Statistics Toolbox recommended but not required\n');
end
```

### **2. Run the Analyzer**

```matlab
% Navigate to matlab directory
cd matlab

% Define p-values to analyze
p_vals = [0.0, 0.1, 0.2, 0.3, 0.3116, 0.4, 0.5, 0.6, 0.6884, 0.7, 0.8];

% Run hybrid analysis
[results, analyzer] = hybrid_alpha_analyzer('p_output_NEW34.csv', p_vals);

% Test specific p-value
test_p = 0.6384;
alpha_test = analyzer.alpha_sigmoid_function(test_p);
fprintf('α(%.4f) = %.4f\n', test_p, alpha_test);
```

### **3. Run Test Script**

```matlab
% Run comprehensive test
test_hybrid_analyzer;
```

## 📁 **File Structure Setup**

### **Required Directory Structure**

```
RW_Percolation/
├── scripts/
│   ├── hybrid_alpha_analyzer.py          # Python analyzer
│   ├── hybrid_complete_analysis.py       # Complete pipeline
│   └── __init__.py                       # Python package init
├── matlab/
│   ├── hybrid_alpha_analyzer.m           # MATLAB analyzer
│   ├── test_hybrid_analyzer.m            # MATLAB test script
│   ├── p_output_C1.csv                   # Original dataset
│   └── p_output_NEW34.csv                # New dataset
└── output_hybrid_analysis/               # Results directory (auto-created)
```

### **Data File Requirements**

- **CSV format** with columns: `MSD_0.0000`, `MSD_0.0500`, `MSD_0.1000`, etc.
- **MSD data** should be numeric and finite
- **Column names** must follow pattern: `MSD_{p_value}`

## 🔧 **Configuration Options**

### **Python Configuration**

```python
from hybrid_alpha_analyzer import HybridAlphaAnalyzer

# Customize analyzer parameters
analyzer = HybridAlphaAnalyzer(
    p_c_prime=0.6884,        # Critical threshold
    r2_threshold=0.8,        # R² threshold for physics-based classification
    confidence_threshold=0.7  # Confidence threshold
)

# Analyze with custom parameters
results = analyzer.analyze_dataset(df, p_values)
```

### **MATLAB Configuration**

```matlab
% Customize analyzer parameters
p_c_prime = 0.6884;          % Critical threshold
r2_threshold = 0.8;          % R² threshold
confidence_threshold = 0.7;   % Confidence threshold

% Run analysis
[results, analyzer] = hybrid_alpha_analyzer('data.csv', p_values, p_c_prime);
```

## 🧪 **Testing and Validation**

### **Python Testing**

```bash
# Run basic test
cd scripts
python -c "
from hybrid_alpha_analyzer import HybridAlphaAnalyzer
analyzer = HybridAlphaAnalyzer()
print('✓ Python analyzer imported successfully')
"

# Run complete analysis
python hybrid_complete_analysis.py
```

### **MATLAB Testing**

```matlab
% Basic functionality test
try
    [results, analyzer] = hybrid_alpha_analyzer('p_output_NEW34.csv', [0.0, 0.1, 0.2]);
    fprintf('✓ MATLAB analyzer working correctly\n');
catch ME
    fprintf('✗ MATLAB analyzer error: %s\n', ME.message);
end

% Run comprehensive test
test_hybrid_analyzer;
```

## 📊 **Expected Results**

### **Classification Distribution**

| Regime | Expected Count | Description |
|--------|----------------|-------------|
| Liquid | ~20-22 p-values | α > 0.8, clear liquid behavior |
| Critical | ~8-11 p-values | 0.3 < α < 0.7, transition region |
| Solid | ~1-6 p-values | α < 0.2, arrested diffusion |

### **Sigmoid Fit Quality**

- **R² > 0.99** for both datasets
- **p_c within 0.005** of theoretical value (0.6884)
- **Sharp transitions** (width < 0.02)
- **Perfect bounds** (α_min ≈ 0, α_max ≈ 1)

### **Critical Case Resolution**

**p = 0.6384** should be correctly classified as:
- **Strategy**: `liquid`
- **Method**: `physics_based`
- **α**: ~0.96
- **δ**: ~86°

## 🚨 **Troubleshooting**

### **Common Python Issues**

#### **Import Errors**
```bash
# Solution: Install missing packages
pip install pandas numpy matplotlib scipy seaborn

# Or create virtual environment
python -m venv hybrid_env
source hybrid_env/bin/activate  # On Windows: hybrid_env\Scripts\activate
pip install -r requirements.txt
```

#### **File Not Found Errors**
```bash
# Check current directory
pwd
ls -la

# Navigate to correct directory
cd /path/to/RW_Percolation/scripts
```

#### **Memory Issues**
```python
# For large datasets, reduce fine grid resolution
analyzer.calculate_continuous_parameters(results_df, grid_points=500)  # Default: 1000
```

### **Common MATLAB Issues**

#### **Toolbox Not Available**
```matlab
% Check available toolboxes
ver

% Alternative: Use basic optimization (may be slower)
% Modify hybrid_alpha_analyzer.m to use fmincon instead of lsqcurvefit
```

#### **File Path Issues**
```matlab
% Check current directory
pwd
dir

% Navigate to correct directory
cd('path/to/RW_Percolation/matlab')
```

#### **Data Format Issues**
```matlab
% Check CSV file structure
opts = detectImportOptions('p_output_NEW34.csv');
opts.VariableNames

% Ensure column names follow pattern: MSD_0.0000, MSD_0.0500, etc.
```

## 📈 **Performance Optimization**

### **Python Optimization**

```python
# For large datasets, use parallel processing
from multiprocessing import Pool

def analyze_p_value_parallel(args):
    p_value, df = args
    return analyzer.analyze_single_p_value(df, p_value)

# Parallel analysis
with Pool() as pool:
    results = pool.map(analyze_p_value_parallel, 
                      [(p, df) for p in p_values])
```

### **MATLAB Optimization**

```matlab
% Enable parallel processing
if license('test', 'Distrib_Computing_Toolbox')
    parpool('local');
end

% Vectorized operations where possible
alpha_values = [window_results.alpha];
r_squared_values = [window_results.r_squared];
```

## 🔍 **Validation Checklist**

### **Before Running Analysis**

- [ ] Required packages installed (Python) or toolboxes available (MATLAB)
- [ ] Data files in correct location and format
- [ ] Directory structure matches expected layout
- [ ] Sufficient memory for dataset size

### **After Running Analysis**

- [ ] Sigmoid fit R² > 0.99
- [ ] p_c within 0.01 of theoretical value (0.6884)
- [ ] p = 0.6384 classified as liquid
- [ ] All three regimes (liquid, critical, solid) detected
- [ ] Output files generated in expected locations

### **Quality Checks**

- [ ] α values bounded in [0, 1]
- [ ] Phase angle δ bounded in [0°, 90°]
- [ ] Loss tangent tan δ reasonable values
- [ ] Classification confidence > 0.5 for most p-values

## 📚 **Additional Resources**

### **Documentation**
- **README_HYBRID_ANALYSIS.md**: Comprehensive project documentation
- **Code comments**: Detailed inline documentation
- **Example scripts**: Working examples for both languages

### **Support**
- **GitHub Issues**: Report bugs and request features
- **Code comments**: Implementation details and algorithms
- **Test scripts**: Validation and debugging tools

### **Extensions**
- **Custom datasets**: Modify column naming conventions
- **Additional parameters**: Extend viscoelastic calculations
- **Visualization**: Customize plotting functions

## 🎯 **Next Steps**

1. **Run basic analysis** to verify setup
2. **Explore results** in generated output directory
3. **Customize parameters** for your specific needs
4. **Extend functionality** for additional analysis types
5. **Contribute improvements** to the project

---

**Need Help?** Check the troubleshooting section above or create a GitHub issue with detailed error information.
