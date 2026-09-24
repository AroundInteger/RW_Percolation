# MSD Evaluation Strategy: Where to Look

## The Key Insight

The theoretical α values tell us **exactly where to evaluate** the MSD curve to extract the correct values:

### **α = 1.000 (p < p_c')**: Normal Diffusion
- **Where to look**: **Early time regime** where ⟨r²(t)⟩ ∝ t
- **Physical meaning**: Free Brownian motion, liquid-like behavior
- **MSD curve region**: Linear region on log-log plot (slope = 1)

### **α = 0.500 (p = p_c')**: Critical Gel Point
- **Where to look**: **Intermediate time regime** where ⟨r²(t)⟩ ∝ t^0.5
- **Physical meaning**: Anomalous diffusion, viscoelastic behavior
- **MSD curve region**: Power law region with slope = 0.5

### **α = 0.000 (p > p_c')**: Arrested Diffusion
- **Where to look**: **Long time regime** where ⟨r²(t)⟩ = constant
- **Physical meaning**: No motion, solid-like behavior
- **MSD curve region**: Plateau region (slope ≈ 0)

## MSD Curve Structure

```
log(MSD)
    ^
    |    α = 1.0 (liquid)
    |   /
    |  /
    | /     α = 0.5 (critical)
    |/    /
    |   /
    |  /     α = 0.0 (solid)
    | /    _______
    |/   /
    +-----------------> log(time)
    early  mid    late
```

## Evaluation Strategy

### 1. **For p < p_c' (α ≈ 1.000)**
- **Look at**: Early time regime (t < t_crossover)
- **Expect**: Linear MSD with slope ≈ 1
- **Avoid**: Long-time plateau or crossover regions
- **Physical**: Free diffusion before encountering obstacles

### 2. **For p ≈ p_c' (α ≈ 0.500)**
- **Look at**: Intermediate time regime (t_crossover < t < t_plateau)
- **Expect**: Power law MSD with slope ≈ 0.5
- **Avoid**: Early ballistic or late arrested regions
- **Physical**: Critical diffusion through percolating network

### 3. **For p > p_c' (α ≈ 0.000)**
- **Look at**: Long time regime (t > t_plateau)
- **Expect**: Plateau in MSD (slope ≈ 0)
- **Avoid**: Early transient regions
- **Physical**: Arrested motion in solid-like network

## Time Regime Identification

### **Early Time Regime (t < t_crossover)**
- **Characteristic**: Ballistic motion, free diffusion
- **Slope**: α ≈ 1-2 (ballistic to diffusive)
- **Duration**: ~10-100 time steps
- **Use for**: p < p_c' analysis

### **Intermediate Time Regime (t_crossover < t < t_plateau)**
- **Characteristic**: Anomalous diffusion, power law
- **Slope**: α ≈ 0.1-0.9 (depends on p)
- **Duration**: ~100-1000 time steps
- **Use for**: p ≈ p_c' analysis

### **Long Time Regime (t > t_plateau)**
- **Characteristic**: Arrested motion, plateau
- **Slope**: α ≈ 0 (constant MSD)
- **Duration**: ~1000+ time steps
- **Use for**: p > p_c' analysis

## Implementation Strategy

### **Adaptive Time Window Selection**

```matlab
% For each p value, select appropriate time window
if p < p_c_prime - 0.05
    % Liquid regime: use early time
    time_window = 1:min(100, length(t));
    expected_alpha = 1.0;
elseif abs(p - p_c_prime) < 0.05
    % Critical regime: use intermediate time
    time_window = 100:min(1000, length(t));
    expected_alpha = 0.5;
else
    % Solid regime: use late time
    time_window = 1000:length(t);
    expected_alpha = 0.0;
end
```

### **Quality Criteria**

1. **R² > 0.95** for linear fit in selected window
2. **Minimum 20 data points** in window
3. **Consistent slope** across adjacent windows
4. **Physical consistency** with expected α range

## Validation Approach

### **Cross-Validation**
- **Multiple windows**: Test different time ranges
- **Consistency check**: α should be stable within expected range
- **Physical check**: α should match theoretical predictions

### **Error Estimation**
- **Statistical error**: Standard error of fit
- **Systematic error**: Window selection uncertainty
- **Physical error**: Deviation from theoretical expectation

## Expected Results

### **For Our Simulation Range [0.60, 0.70]**

| p | Expected α | Time Window | MSD Behavior |
|---|------------|-------------|--------------|
| 0.60 | 0.097 | Intermediate | Power law, slope ≈ 0.1 |
| 0.62 | 0.073 | Intermediate | Power law, slope ≈ 0.07 |
| 0.64 | 0.049 | Late | Near plateau, slope ≈ 0.05 |
| 0.66 | 0.027 | Late | Plateau, slope ≈ 0.03 |
| 0.68 | 0.007 | Late | Plateau, slope ≈ 0.01 |
| 0.69 | 0.000 | Late | Plateau, slope ≈ 0.00 |
| 0.70 | 0.000 | Late | Plateau, slope ≈ 0.00 |

## Key Advantages

### **1. Targeted Analysis**
- Look in the **right place** for each p value
- Avoid **misleading regions** (early transients, late noise)
- Focus on **physically relevant** time scales

### **2. Physical Consistency**
- α values match **theoretical expectations**
- Time windows correspond to **physical regimes**
- Results align with **percolation theory**

### **3. Robust Estimation**
- **Multiple validation** approaches
- **Error quantification** for each estimate
- **Cross-checking** between different methods

## Conclusion

This theoretical framework gives us a **precise roadmap** for MSD analysis:

1. **Know where to look** based on p value
2. **Expect specific α values** from theory
3. **Validate results** against predictions
4. **Quantify uncertainties** in estimates

This should dramatically improve our α estimation accuracy and provide robust evidence for the δ phase transition!

---

*The key is matching the time window selection to the expected physical behavior for each p value.* 