# Paper Simulations: 1M Steps, 1000 Walkers

This document provides instructions for running the exact simulations needed for your paper with the parameters:
- **Lattice size:** 100³
- **Steps:** 1,000,000
- **Walkers:** 1,000
- **P-values:** [0.0, 0.3116, 0.6884, 0.75]

## Quick Start

### Python Version (Recommended)
```bash
# 1. Test the setup
python scripts/test_paper_setup.py

# 2. Run full simulations
python scripts/run_paper_simulations.py

# 3. Analyze results
python scripts/analyze_paper_results.py
```

### MATLAB Version (Alternative)
```bash
# 1. Navigate to MATLAB directory
cd matlab

# 2. Run all simulations
./run_paper_batch.sh

# 3. Results are automatically collected and plotted
```

## Detailed Workflow

### Phase 1: System Check
First, verify your system can handle the computational load:

```bash
# Check system resources
python scripts/run_paper_simulations.py --test
```

This runs a quick test with reduced parameters to ensure everything works.

### Phase 2: Full Simulations
Run the complete simulations with your paper parameters:

```bash
# Run all 4 p-values sequentially (recommended for stability)
python scripts/run_paper_simulations.py --parallel 1

# Or run with limited parallelism (if you have sufficient RAM)
python scripts/run_paper_simulations.py --parallel 2
```

**Expected runtime:** ~80 minutes total (20 minutes per simulation)

**Memory usage:** ~0.4 GB total (0.1 GB per simulation)

### Phase 3: Analysis
Process the results and generate plots:

```bash
python scripts/analyze_paper_results.py
```

## Output Structure

```
paper_simulations/
├── p_0.0000/
│   ├── msd_results_L100_p0.0000.csv
│   ├── simulation_summary_p_0.0000.json
│   └── checkpoints/
├── p_0.3116/
│   ├── msd_results_L100_p0.3116.csv
│   ├── simulation_summary_p_0.3116.json
│   └── checkpoints/
├── p_0.6884/
│   ├── msd_results_L100_p0.6884.csv
│   ├── simulation_summary_p_0.6884.json
│   └── checkpoints/
├── p_0.7500/
│   ├── msd_results_L100_p0.7500.csv
│   ├── simulation_summary_p_0.7500.json
│   └── checkpoints/
└── simulation_summary.md

paper_analysis/
├── msd_comparison_1M_steps.png
├── growth_exponent_analysis.png
├── final_msd_vs_p.png
├── analysis_report.md
└── analysis_results.json

matlab/matlab_output/  (if using MATLAB version)
├── msd_results_L100_p0.0000.csv
├── msd_results_L100_p0.0000.mat
├── msd_results_L100_p0.3116.csv
├── msd_results_L100_p0.3116.mat
├── msd_results_L100_p0.6884.csv
├── msd_results_L100_p0.6884.mat
├── msd_results_L100_p0.7500.csv
├── msd_results_L100_p0.7500.mat
├── paper_results_combined.mat
├── paper_results_combined.csv
├── paper_msd_comparison.png
└── paper_msd_comparison.fig
```

## Key Features

### Robust Resource Management
- **Memory monitoring:** Prevents system crashes
- **Checkpointing:** Resume interrupted simulations
- **Progress tracking:** Real-time status updates
- **Error handling:** Graceful failure recovery

### Optimized Performance
- **MSD sampling:** Every 1,000 steps (1,000 data points per simulation)
- **Checkpointing:** Every 50,000 steps
- **Memory efficiency:** ~0.1 GB per simulation
- **Parallel processing:** Configurable parallelism

### Comprehensive Analysis
- **Growth exponents:** Early, late, and full-range α values
- **Statistical analysis:** R² values and error estimates
- **Publication-ready plots:** High-resolution PNG files
- **Detailed reports:** Markdown and JSON outputs

## Simulation Parameters

### P-values and Their Significance
- **p = 0.0000:** Free random walk (no obstacles)
- **p = 0.3116:** Near percolation threshold (true gel point)
- **p = 0.6884:** Apparent gel point (loss of sample-spanning void space)
- **p = 0.7500:** Confined regime (strong confinement effects)

### Technical Details
- **Lattice:** 3D cubic, 100×100×100 sites
- **Boundary conditions:** Periodic
- **Walker movement:** 6-directional (von Neumann neighborhood)
- **MSD calculation:** Unwrapped positions (corrected for PBCs)
- **Random seed:** 42 (reproducible results)

## Expected Results

### Growth Exponents (α)
Based on theoretical expectations:
- **p = 0.0000:** α ≈ 1.0 (normal diffusion)
- **p = 0.3116:** α < 1.0 (subdiffusive, near critical)
- **p = 0.6884:** α < 1.0 (subdiffusive, apparent gel point)
- **p = 0.7500:** α << 1.0 (strongly subdiffusive, confined)

### Final MSD Values
Expected trends:
- **p = 0.0000:** Highest MSD (unrestricted diffusion)
- **p = 0.3116:** Intermediate MSD (some obstruction)
- **p = 0.6884:** Lower MSD (significant confinement)
- **p = 0.7500:** Lowest MSD (strong confinement)

## Version Comparison

### Python vs MATLAB
Both versions produce identical results when using the same parameters:

| Feature | Python | MATLAB |
|---------|--------|--------|
| **Ease of use** | ✅ Excellent | ✅ Good |
| **Resource management** | ✅ Built-in | ⚠️ Manual |
| **Checkpointing** | ✅ Automatic | ❌ None |
| **Parallel processing** | ✅ Configurable | ✅ Built-in |
| **Output formats** | CSV, JSON | CSV, MAT |
| **Analysis tools** | ✅ Comprehensive | ⚠️ Basic |
| **Cluster support** | ✅ Excellent | ✅ Good |

**Recommendation:** Use Python version for production runs, MATLAB version as backup or for specific analysis needs.

## Troubleshooting

### Common Issues

**1. Memory Errors**
```bash
# Reduce parallelism
python scripts/run_paper_simulations.py --parallel 1
```

**2. Timeout Errors**
```bash
# Check system resources
python scripts/run_paper_simulations.py --test
```

**3. Missing Data**
```bash
# Check if simulations completed
ls paper_simulations/p_*/
```

### Recovery Options

**Resume Interrupted Simulations**
The system automatically creates checkpoints. Simply re-run the same command to resume.

**Partial Results**
If some simulations fail, you can still analyze the successful ones:
```bash
python scripts/analyze_paper_results.py --p-values 0.0 0.3116
```

## Performance Optimization

### For Faster Execution
- **Increase parallelism** (if sufficient RAM available)
- **Use SSD storage** for faster I/O
- **Close other applications** to free memory

### For Better Statistics
- **Increase number of walkers** (if memory allows)
- **Run multiple realizations** with different seeds
- **Extend simulation time** beyond 1M steps

## Integration with Paper

### Plot Generation
The analysis script creates publication-ready plots:
- `msd_comparison_1M_steps.png` - Main MSD comparison
- `growth_exponent_analysis.png` - Growth exponent analysis
- `final_msd_vs_p.png` - Final MSD vs occupation probability

### Data Export
Raw data is available in CSV format for further analysis:
- `msd_results_L100_p{p}.csv` - MSD vs time data
- `analysis_results.json` - Processed analysis results

### Citation Information
Include in your paper:
- **Simulation parameters:** L=100³, 1M steps, 1000 walkers
- **P-values:** [0.0, 0.3116, 0.6884, 0.75]
- **Analysis:** Growth exponents, final MSD values
- **Software:** Custom Python implementation with robust resource management

## Support

If you encounter issues:
1. Check the test output: `python scripts/test_paper_setup.py`
2. Review the simulation logs in each output directory
3. Verify system resources meet requirements
4. Check for any error messages in the console output

The system is designed to be robust and provide clear feedback about any issues encountered during execution. 