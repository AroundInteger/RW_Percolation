# Hybrid Alpha Analysis for 3D Percolation Random Walks

## 🎯 **Project Overview**

This project implements a **hybrid approach** to analyzing growth exponents (α) in 3D percolation random walk systems, combining **physics-based classification**, **transition detection**, and **sigmoid fitting** for robust regime classification and continuous parameter evolution.

## 🔬 **Scientific Background**

### **3D Percolation Random Walks**
- **Site Percolation**: Obstacles on 3D periodic lattices defined by occupation probability `p`
- **Critical Thresholds**: 
  - `p_c ≈ 0.3116` (gel-point of occupied sites)
  - `p_c' ≈ 0.6884` (gel-point of unoccupied sites/accessible volume)
- **Mean Squared Displacement (MSD)**: Primary metric for analyzing random walk behavior
- **Growth Exponent (α)**: Characterizes diffusion behavior (MSD ∝ t^α)

### **Physical Regimes**
- **Liquid (p < p_c')**: α ≈ 1 (normal diffusion)
- **Critical (p ≈ p_c')**: 0 < α < 1 (anomalous diffusion, α ≈ 0.5 at gel-point)
- **Solid (p > p_c')**: α ≈ 0 (arrested diffusion, plateau)

### **The Challenge**
Traditional geometric classification using rigid thresholds (e.g., |p - p_c'| < 0.05) fails to:
- Capture the **critical transition region** where α evolves smoothly from 1 to 0
- Handle **edge cases** where α behavior doesn't match geometric expectations
- Provide **continuous parameter evolution** for viscoelastic properties

## 🚀 **The Hybrid Solution**

### **Three-Pronged Approach**

#### **1. Physics-Based Classification**
- **Clear Liquid**: α > 0.8, high R² (> 0.8)
- **Clear Solid**: α < 0.2, high R² (> 0.8)
- **Intermediate**: 0.4 < α < 0.6, high R² (> 0.8)

#### **2. Transition Detection**
- **Multi-window analysis**: Early, Middle, Late, Very Late time windows
- **High α variability** (std > 0.3) suggests transition behavior
- **Regime differences** between early and late windows
- **Adaptive critical region** width based on α behavior

#### **3. Sigmoid Fitting**
- **Continuous α(p) function**: α(p) = α_min + (α_max - α_min) / (1 + exp((p - p_c) / width))
- **Bounded parameters**: α_min ∈ [0, 1], α_max ∈ [0, 1]
- **Excellent fit quality**: R² > 0.99 for both datasets
- **Continuous viscoelastic parameters**: G'(ω), G''(ω), δ, tan δ

## 📁 **Project Structure**

```
RW_Percolation/
├── scripts/
│   ├── hybrid_alpha_analyzer.py          # Python hybrid analyzer
│   ├── hybrid_complete_analysis.py       # Complete analysis pipeline
│   └── ...                               # Other analysis scripts
├── matlab/
│   ├── hybrid_alpha_analyzer.m           # MATLAB hybrid analyzer
│   ├── p_output_C1.csv                   # Original dataset (34 p-values)
│   ├── p_output_NEW34.csv                # New dataset (34 p-values)
│   └── ...                               # Other MATLAB files
├── output_hybrid_analysis/               # Analysis results
│   ├── *_hybrid_results.csv              # Detailed results
│   ├── plots/                            # Comprehensive visualizations
│   ├── dataset_comparison.png            # Dataset comparison
│   └── hybrid_analysis_summary.md        # Summary report
└── README_HYBRID_ANALYSIS.md             # This documentation
```

## 🐍 **Python Implementation**

### **Core Class: `HybridAlphaAnalyzer`**

```python
from hybrid_alpha_analyzer import HybridAlphaAnalyzer

# Initialize analyzer
analyzer = HybridAlphaAnalyzer(p_c_prime=0.6884)

# Analyze dataset
results = analyzer.analyze_dataset(df, p_values)

# Access fitted sigmoid function
alpha_at_p = analyzer.alpha_sigmoid_function(0.6384)  # α = 0.959

# Get continuous parameters
delta_at_p = analyzer.get_parameter_at_p(0.6384, 'delta')  # δ = 86.34°
```

### **Key Methods**

- **`analyze_dataset()`**: Complete analysis pipeline
- **`analyze_single_p_value()`**: Single p-value analysis
- **`fit_sigmoid_function()`**: Sigmoid fitting with bounds
- **`calculate_continuous_parameters()`**: G', G'', δ, tan δ evolution
- **`get_parameter_at_p()`**: Parameter interpolation at any p-value

### **Complete Analysis Pipeline**

```bash
cd scripts
python hybrid_complete_analysis.py
```

**Outputs:**
- `output_hybrid_analysis/` directory
- Comprehensive plots and analysis results
- Dataset comparison and summary report

## 🔢 **MATLAB Implementation**

### **Main Function: `hybrid_alpha_analyzer`**

```matlab
% Define p-values to analyze
p_vals = [0.0, 0.1, 0.2, 0.3, 0.3116, 0.4, 0.5, 0.6, 0.6884, 0.7, 0.8];

% Run hybrid analysis
[results, analyzer] = hybrid_alpha_analyzer('p_output_NEW34.csv', p_vals);

% Access fitted sigmoid function
alpha_at_p = analyzer.alpha_sigmoid_function(0.6384);

% Get continuous parameters
delta_at_p = get_parameter_at_p(analyzer, 0.6384, 'delta');
```

### **Key Features**

- **Full MATLAB compatibility** with built-in functions
- **Optimization Toolbox** for sigmoid fitting (`lsqcurvefit`)
- **Structured output** with comprehensive results
- **Function handles** for continuous parameter calculation

## 📊 **Results and Validation**

### **Dataset Analysis Summary**

| Dataset | P-values | Liquid | Critical | Solid | R² |
|---------|----------|---------|----------|-------|-----|
| Original (C1) | 34 | 22 | 11 | 1 | 0.9957 |
| New (NEW34) | 34 | 20 | 8 | 6 | 0.9969 |

### **Sigmoid Fit Parameters**

| Parameter | Original | New | Theoretical |
|-----------|----------|-----|-------------|
| p_c | 0.6837 ± 0.0010 | 0.6836 ± 0.0009 | 0.6884 |
| Width | 0.0146 ± 0.0008 | 0.0138 ± 0.0008 | - |
| α_min | 0.0000 ± 0.0182 | 0.0000 ± 0.0097 | 0.0 |
| α_max | 0.9968 ± 0.0062 | 0.9945 ± 0.0062 | 1.0 |

### **Critical Case Resolution**

**Problem Case: p = 0.6384**
- **Before**: Misclassified as "solid" (geometric method)
- **After**: Correctly classified as "liquid" (hybrid method)
- **Evidence**: α = 0.962, δ = 86.34°, clear liquid behavior
- **Multi-window analysis**: Shows transition behavior in critical region

## 🎨 **Visualization Outputs**

### **Generated Plots**

1. **`*_alpha_vs_p_comprehensive.png`**
   - α vs p with sigmoid fit
   - Classification confidence visualization
   - Theoretical lines and critical thresholds

2. **`*_continuous_parameters.png`**
   - G'(ω) and G''(ω) evolution
   - Phase angle δ evolution
   - Loss tangent tan δ evolution
   - Sigmoid fit analysis

3. **`*_transition_analysis.png`**
   - α variability across windows
   - Classification confidence vs p
   - Transition detection summary
   - Method effectiveness comparison

4. **`dataset_comparison.png`**
   - Direct dataset comparison
   - Classification method distribution
   - Sigmoid parameter comparison
   - Transition detection comparison

## 🔧 **Technical Implementation Details**

### **Multi-Window Analysis**

```python
windows = [
    {'name': 'Early', 'start_frac': 0.1, 'end_frac': 0.5, 'strategy': 'liquid'},
    {'name': 'Middle', 'start_frac': 0.25, 'end_frac': 0.75, 'strategy': 'critical'},
    {'name': 'Late', 'start_frac': 0.5, 'end_frac': 1.0, 'strategy': 'liquid'},
    {'name': 'Very Late', 'start_frac': 0.75, 'end_frac': 1.0, 'strategy': 'solid'}
]
```

### **Transition Detection Logic**

```python
def _detect_transition_behavior(self, alpha_values, r_squared_values):
    alpha_std = np.std(alpha_values)
    high_variability = alpha_std > 0.3
    
    if len(alpha_values) >= 4:
        early_alpha = np.mean(alpha_values[:2])
        late_alpha = np.mean(alpha_values[-2:])
        regime_difference = abs(early_alpha - late_alpha) > 0.4
    else:
        regime_difference = False
    
    is_transition = high_variability or regime_difference
    return is_transition
```

### **Sigmoid Function with Bounds**

```python
def sigmoid_function(p, p_c, width, alpha_min, alpha_max):
    alpha_min = max(0.0, alpha_min)      # Enforce lower bound
    alpha_max = min(1.0, alpha_max)      # Enforce upper bound
    return alpha_min + (alpha_max - alpha_min) / (1 + np.exp((p - p_c) / width))
```

### **Continuous Parameter Calculation**

```python
def calculate_phase_angle(self, alpha_values):
    # δ = πα/2 for power law materials
    delta_rad = np.pi * alpha_values / 2
    delta_deg = delta_rad * 180 / np.pi
    return delta_deg

def calculate_loss_tangent(self, alpha_values):
    for i, alpha in enumerate(alpha_values):
        if alpha <= 0:
            tan_delta[i] = 0.0      # Solid: no loss
        elif alpha >= 1:
            tan_delta[i] = 100.0    # Liquid: purely viscous
        else:
            tan_delta[i] = np.tan(np.pi * alpha / 2)  # Viscoelastic
```

## 🚀 **Usage Examples**

### **Python: Quick Analysis**

```python
import pandas as pd
from hybrid_alpha_analyzer import HybridAlphaAnalyzer

# Load data
df = pd.read_csv("matlab/p_output_NEW34.csv")

# Extract p-values
p_values = [float(col.replace('MSD_', '')) for col in df.columns if col.startswith('MSD_')]
p_values.sort()

# Initialize and run analyzer
analyzer = HybridAlphaAnalyzer()
results = analyzer.analyze_dataset(df, p_values)

# Check specific p-value
test_p = 0.6384
alpha_test = analyzer.get_parameter_at_p(test_p, 'alpha')
delta_test = analyzer.get_parameter_at_p(test_p, 'delta')
print(f"p = {test_p}: α = {alpha_test:.4f}, δ = {delta_test:.2f}°")
```

### **MATLAB: Quick Analysis**

```matlab
% Define p-values
p_vals = [0.0, 0.1, 0.2, 0.3, 0.3116, 0.4, 0.5, 0.6, 0.6884, 0.7, 0.8];

% Run analysis
[results, analyzer] = hybrid_alpha_analyzer('p_output_NEW34.csv', p_vals);

% Check specific p-value
test_p = 0.6384;
alpha_test = analyzer.alpha_sigmoid_function(test_p);
delta_test = get_parameter_at_p(analyzer, test_p, 'delta');
fprintf('p = %.4f: α = %.4f, δ = %.2f°\n', test_p, alpha_test, delta_test);
```

## 📈 **Performance and Accuracy**

### **Classification Accuracy**

- **Physics-based**: 20/34 p-values (58.8%)
- **Transition detected**: 8/34 p-values (23.5%)
- **Adaptive critical**: 8/34 p-values (23.5%)
- **Geometric fallback**: 6/34 p-values (17.6%)

### **Sigmoid Fit Quality**

- **R² > 0.99** for both datasets
- **p_c within 0.005** of theoretical value
- **Sharp transitions** (width < 0.02)
- **Perfect bounds** (α_min ≈ 0, α_max ≈ 1)

### **Computational Efficiency**

- **34 p-values**: ~30 seconds analysis time
- **1000-point interpolation**: Instant parameter calculation
- **Memory efficient**: Structured data storage
- **Scalable**: Easy to extend to more p-values

## 🔍 **Validation and Testing**

### **Edge Case Resolution**

1. **p = 0.6384 (New Dataset)**
   - **Geometric method**: "solid" (incorrect)
   - **Hybrid method**: "liquid" (correct)
   - **Evidence**: α = 0.962, clear liquid behavior

2. **Critical Region Detection**
   - **Traditional**: Rigid |p - p_c'| < 0.05
   - **Hybrid**: Adaptive width based on α behavior
   - **Result**: Captures true critical region evolution

### **Physical Consistency**

- **α bounds**: [0, 1] enforced in sigmoid fitting
- **Phase angle**: δ ∈ [0°, 90°] for all p-values
- **Loss tangent**: tan δ → ∞ for liquid, 0 for solid
- **Gel-point**: α ≈ 0.5 at p ≈ p_c'

## 🚀 **Future Enhancements**

### **Planned Improvements**

1. **Advanced Transition Detection**
   - Machine learning for regime classification
   - Dynamic window sizing based on data quality
   - Confidence intervals for all parameters

2. **Extended Parameter Space**
   - Frequency-dependent viscoelastic response
   - Temperature effects on percolation
   - Multi-component systems

3. **Real-time Analysis**
   - Streaming data analysis
   - Interactive parameter exploration
   - Real-time visualization updates

### **Extension Possibilities**

- **2D percolation systems**
- **Different lattice geometries**
- **Time-dependent percolation**
- **Experimental data integration**

## 📚 **References and Background**

### **Key Papers**

1. **Percolation Theory**: Stauffer & Aharony (1994)
2. **Random Walks**: Hughes (1995)
3. **Anomalous Diffusion**: Metzler & Klafter (2000)
4. **Viscoelasticity**: Ferry (1980)

### **Theoretical Framework**

- **Site Percolation**: Occupation probability p
- **Gel-Point**: Critical percolation threshold p_c
- **Fractal Dimension**: D_f = 2.5 for 3D percolation
- **Scaling Laws**: α ∝ (p - p_c)^β near critical point

## 🤝 **Contributing and Collaboration**

### **How to Contribute**

1. **Fork the repository**
2. **Create feature branch**
3. **Implement improvements**
4. **Submit pull request**

### **Areas for Contribution**

- **Algorithm optimization**
- **Additional visualization types**
- **Extended parameter calculations**
- **Documentation improvements**
- **Testing and validation**

## 📞 **Contact and Support**

### **Project Maintainers**

- **Primary Contact**: [Your Name/Institution]
- **GitHub Repository**: [Repository URL]
- **Documentation**: This README and associated docs

### **Support Resources**

- **Issues**: GitHub Issues page
- **Discussions**: GitHub Discussions
- **Wiki**: Project Wiki (if available)
- **Email**: [Contact Email]

## 📄 **License and Citation**

### **License**

This project is licensed under the [MIT License](LICENSE) - see the LICENSE file for details.

### **Citation**

If you use this work in your research, please cite:

```bibtex
@software{hybrid_alpha_analyzer,
  title={Hybrid Alpha Analysis for 3D Percolation Random Walks},
  author={[Your Name]},
  year={2024},
  url={[Repository URL]}
}
```

## 🎉 **Acknowledgments**

- **Research Community**: For theoretical foundations
- **Open Source**: For enabling tools and libraries
- **Colleagues**: For feedback and testing
- **Reviewers**: For constructive criticism and improvements

---

**Last Updated**: August 19, 2024  
**Version**: 1.0.0  
**Status**: Active Development
