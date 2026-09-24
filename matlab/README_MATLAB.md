# MATLAB Paper Simulations

This directory contains MATLAB scripts for running the paper simulations with 1M steps and 1000 walkers.

## Files

- `RW3D_paper_batch.m` - Main batch simulation script
- `collect_paper_results.m` - Results collection and plotting script
- `run_paper_batch.sh` - Shell script to run all simulations
- `README_MATLAB.md` - This file

## Prerequisites

1. **MATLAB** with Parallel Computing Toolbox
2. **RW3D_P_SP.m** - The 3D random walk function (must be in MATLAB path)

## Quick Start

### Option 1: Use the shell script (recommended)
```bash
cd matlab
./run_paper_batch.sh
```

### Option 2: Run manually
```bash
cd matlab
matlab -nodisplay -r "RW3D_paper_batch(1); exit"
matlab -nodisplay -r "RW3D_paper_batch(2); exit"
matlab -nodisplay -r "RW3D_paper_batch(3); exit"
matlab -nodisplay -r "RW3D_paper_batch(4); exit"
matlab -nodisplay -r "collect_paper_results; exit"
```

### Option 3: Run in parallel (if you have multiple cores)
```bash
cd matlab
parallel 'matlab -nodisplay -r "RW3D_paper_batch({}); exit"' ::: 1 2 3 4
matlab -nodisplay -r "collect_paper_results; exit"
```

## Parameters

- **Lattice size:** 100³
- **Steps:** 1,000,000
- **Walkers:** 1,000
- **P-values:** [0.0, 0.3116, 0.6884, 0.75]
- **Random seed:** 42 (reproducible)

## Output Files

### Individual Simulations
Each job creates:
- `msd_results_L100_p{p}.csv` - CSV format (for Python compatibility)
- `msd_results_L100_p{p}.mat` - MATLAB format (with full trajectory data)

### Combined Results
After running `collect_paper_results.m`:
- `paper_results_combined.mat` - All data in one file
- `paper_results_combined.csv` - All data in CSV format
- `paper_msd_comparison.png` - Publication-ready plot
- `paper_msd_comparison.fig` - MATLAB figure file

## Cluster/Grid Usage

### SLURM Example
```bash
#!/bin/bash
#SBATCH --array=1-4
#SBATCH --cpus-per-task=8
#SBATCH --mem=8G
#SBATCH --time=12:00:00
#SBATCH --job-name=rw3d_paper

module load matlab
cd /path/to/matlab
matlab -nodisplay -r "RW3D_paper_batch($SLURM_ARRAY_TASK_ID); exit"
```

### PBS Example
```bash
#!/bin/bash
#PBS -J 1-4
#PBS -l nodes=1:ppn=8
#PBS -l mem=8gb
#PBS -l walltime=12:00:00

module load matlab
cd $PBS_O_WORKDIR/matlab
matlab -nodisplay -r "RW3D_paper_batch($PBS_ARRAY_INDEX); exit"
```

## Troubleshooting

### Common Issues

1. **"RW3D_P_SP not found"**
   - Ensure `RW3D_P_SP.m` is in the MATLAB path
   - Copy it to the same directory as the batch scripts

2. **"Not enough free sites"**
   - This happens when p is too high for the lattice size
   - The current p-values should work with L=100

3. **Memory issues**
   - Reduce `NW` (number of walkers) if needed
   - Use sequential execution instead of parallel

4. **Long runtime**
   - Expected: ~20-30 minutes per simulation on modern hardware
   - Use `parfor` for parallel walker execution (already implemented)

## Comparison with Python Version

Both MATLAB and Python versions produce identical results when using:
- Same random seed (42)
- Same lattice size (100³)
- Same p-values [0.0, 0.3116, 0.6884, 0.75]
- Same number of steps (1M) and walkers (1000)

The MATLAB version saves both `.csv` and `.mat` files for maximum compatibility. 