# Viscoelastic Lattice Analysis: G', G'', tan(δ), τ_l, τ_cr Research System

## 🎯 **Research Context**

This system is specifically designed for **universality class discovery** through microrheological random walk analysis on percolation lattices. The key research goals are:

1. **Calculate G'(ω), G''(ω), tan(δ)** as functions of percolation probability p
2. **Analyze τ_l (local time scale)** and **τ_cr (cross-over time)** behavior
3. **Verify critical gel-point** at p_c_prime = 0.6884
4. **Discover new universality classes** through variant comparison

## 🔬 **Critical Regions & Physical Significance**

### **Standard Percolation Threshold: p_c = 0.3116**
- **Behavior**: Critical percolation (anomalous diffusion)
- **Expected α**: α ≈ 0.5 (viscoelastic)
- **Focus**: τ_l analysis and anomalous diffusion region
- **Physical meaning**: Transition from liquid-like to viscoelastic behavior

### **Critical Gel-Point: p_c_prime = 0.6884**
- **Behavior**: Critical gel-point (viscoelastic transition)
- **Expected α**: α ≈ 0.0 (arrested diffusion)
- **Focus**: τ_cr analysis and viscoelastic transition
- **Physical meaning**: Transition from viscoelastic to solid-like behavior

### **Fine Resolution Regions**
- **Gel-point region**: [0.61, 0.69] with high resolution (Δp ≈ 0.01)
- **Critical region**: [0.25, 0.40] around p_c
- **Purpose**: Capture phase transitions and universality class changes

## 🏗️ **Lattice Variants for Universality Class Research**

### **1. 6N Templated Growth**
- **Connectivity**: 6-neighbor (most connected)
- **Purpose**: Baseline for templated growth universality class
- **Expected behavior**: Smoother transitions, more connected clusters

### **2. 26N Templated Growth**
- **Connectivity**: 26-neighbor (more fragmented)
- **Purpose**: Test connectivity effects on universality class
- **Expected behavior**: More fragmented clusters, different scaling

### **3. Density Increment Growth**
- **Method**: Random addition without adjacency constraints
- **Purpose**: Test growth mechanism effects on universality class
- **Expected behavior**: Intermediate between templated and random

### **4. Random Percolation**
- **Method**: Independent Bernoulli percolation
- **Purpose**: Baseline for comparison (standard universality class)
- **Expected behavior**: Well-established percolation theory predictions

## 📊 **Analysis Outputs**

### **Individual Lattice Files**
Each lattice is saved with enhanced metadata:
```
Lattice_6N_Templated_p0.3116_L500.mat
├── lattice: 3D logical array (occupied/unoccupied sites)
├── p_value: Occupation probability
├── variant: Lattice type
├── L: Lattice size
├── generation_time: Timestamp
├── cluster_stats: [num_clusters, largest_cluster, avg_cluster_size, density]
├── is_critical_region: Boolean flag for p_c region
├── is_gel_point_region: Boolean flag for p_c_prime region
├── expected_behavior: Physical behavior prediction
└── analysis_notes: Specific analysis guidance
```

### **Specialized Analysis Plots**
1. **Viscoelastic Analysis**: 6-panel comprehensive view
2. **Critical Region Analysis**: Focus on p_c and p_c_prime regions
3. **Gel-Point Transition**: Fine resolution around p_c_prime
4. **Universality Class Indicators**: Connectivity and phase transition metrics

### **Numerical Results**
- **Cluster statistics**: Number, size, distribution analysis
- **Percolation ratios**: Largest cluster / total occupied sites
- **Phase transition indicators**: Rate of change in cluster properties
- **Connectivity indicators**: Universality class signatures

## 🚀 **Workflow for Universality Class Research**

### **Step 1: Generate Lattices**
```matlab
% Run specialized viscoelastic analysis
run_viscoelastic_analysis
```

### **Step 2: Load Lattices for Analysis**
```matlab
% Load specific variants for comparison
[lat_6n, meta_6n] = load_lattice_for_microrheology('6N_Templated', 0.3116, 500);
[lat_26n, meta_26n] = load_lattice_for_microrheology('26N_Templated', 0.3116, 500);
[lat_rand, meta_rand] = load_lattice_for_microrheology('Random_Percolation', 0.6884, 500);

% Prepare unoccupied sites for random walk analysis
rw_sites_6n = ~lat_6n;    % 6N templated unoccupied sites
rw_sites_26n = ~lat_26n;  % 26N templated unoccupied sites
rw_sites_rand = ~lat_rand; % Random percolation unoccupied sites
```

### **Step 3: Run Microrheological Simulations**
```matlab
% Run random walks on unoccupied sites
% Calculate MSD and extract α exponents
% Analyze τ_l and τ_cr time scales
% Compare across variants for universality class differences
```

### **Step 4: Calculate Viscoelastic Properties**
```matlab
% For each variant and p-value:
% 1. Extract α exponents from MSD analysis
% 2. Calculate G'(ω) and G''(ω) using GSER
% 3. Determine phase angle δ and tan(δ)
% 4. Identify τ_l and τ_cr time scales
% 5. Compare universality classes across variants
```

## 🔍 **Universality Class Discovery Strategy**

### **Critical Region Analysis**
- **p_c region**: Focus on τ_l behavior and anomalous diffusion
- **p_c_prime region**: Focus on τ_cr and viscoelastic transition
- **Fine resolution**: Capture subtle phase transition effects

### **Variant Comparison**
- **Templated vs Random**: Test growth mechanism effects
- **6N vs 26N**: Test connectivity effects
- **Density Increment**: Test intermediate behavior

### **Scaling Analysis**
- **α exponents**: Compare with theoretical predictions
- **τ_l scaling**: Local time scale universality
- **τ_cr scaling**: Cross-over time universality
- **Phase transitions**: Universality class boundaries

## 📈 **Expected Research Outcomes**

### **1. New Universality Classes**
- **Templated growth**: Different from standard percolation
- **Connectivity effects**: 6N vs 26N universality differences
- **Growth mechanism**: Density increment universality class

### **2. Enhanced Understanding**
- **τ_l behavior**: Local time scale universality
- **τ_cr behavior**: Cross-over time universality
- **Phase transitions**: Critical region universality

### **3. Physical Insights**
- **Gel-point dynamics**: Viscoelastic transition mechanisms
- **Connectivity effects**: How neighbor constraints affect universality
- **Growth history**: How templating affects material properties

## 🛠️ **Technical Features**

### **Memory Optimization**
- **Individual file output**: Each lattice saved separately
- **Peak memory**: Only 4 lattices in memory at once (~3.8 GB)
- **Total storage**: ~175 GB for all 184 lattices

### **Analysis Tools**
- **Specialized plotting**: Viscoelastic-focused visualizations
- **Critical region focus**: High resolution around key transitions
- **Universality indicators**: Quantitative measures for class differences

### **Data Management**
- **Clear naming convention**: Easy identification of variant relationships
- **Enhanced metadata**: Physical behavior predictions and analysis notes
- **Multiple formats**: .mat files for MATLAB, .csv for external analysis

## 🎯 **Next Steps for Research**

1. **Run viscoelastic analysis**: Generate all lattices with `run_viscoelastic_analysis`
2. **Load for microrheology**: Use `load_lattice_for_microrheology` for specific variants
3. **Run random walks**: Analyze MSD behavior on unoccupied sites
4. **Extract exponents**: Calculate α, τ_l, τ_cr for each variant
5. **Compare universality classes**: Identify new scaling behaviors
6. **Publish discoveries**: Document new universality classes in the literature

This system provides the foundation for groundbreaking research in percolation universality classes through microrheological analysis! 🚀✨
