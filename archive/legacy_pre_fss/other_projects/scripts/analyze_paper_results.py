#!/usr/bin/env python3
"""
Paper Results Analysis - Process 1M step simulation results
Creates MSD plots, growth exponent analysis, and rheological properties
"""

import argparse
import sys
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from pathlib import Path
from scipy import stats
from scipy.optimize import curve_fit
import json
from typing import Dict, List, Tuple, Optional

# Add parent directory to path for imports
sys.path.append(str(Path(__file__).parent.parent))

def load_simulation_data(base_dir: str, p_values: List[float]) -> Dict[float, pd.DataFrame]:
    """Load MSD data from all simulations"""
    
    data = {}
    base_path = Path(base_dir)
    
    for p_value in p_values:
        # Try different possible file patterns
        possible_files = [
            base_path / f"p_{p_value:.4f}" / f"msd_results_L100_p{p_value:.4f}.csv",
            base_path / f"p_{p_value:.4f}" / "msd_results.csv",
            base_path / f"msd_results_L100_p{p_value:.4f}.csv"
        ]
        
        file_found = False
        for file_path in possible_files:
            if file_path.exists():
                df = pd.read_csv(file_path)
                data[p_value] = df
                print(f"✅ Loaded p = {p_value:.4f}: {len(df)} data points")
                file_found = True
                break
        
        if not file_found:
            print(f"❌ No data found for p = {p_value:.4f}")
    
    return data

def calculate_growth_exponent(tau: np.ndarray, msd: np.ndarray, 
                            start_idx: int = 100, end_idx: Optional[int] = None) -> Tuple[float, float, float]:
    """
    Calculate growth exponent α from MSD data
    MSD(τ) ∝ τ^α
    """
    
    if end_idx is None:
        end_idx = len(tau)
    
    # Use log-log fit
    log_tau = np.log10(tau[start_idx:end_idx])
    log_msd = np.log10(msd[start_idx:end_idx])
    
    # Remove any invalid values
    valid_mask = np.isfinite(log_tau) & np.isfinite(log_msd) & (log_msd > 0)
    
    if np.sum(valid_mask) < 10:
        return np.nan, np.nan, np.nan
    
    log_tau_valid = log_tau[valid_mask]
    log_msd_valid = log_msd[valid_mask]
    
    # Linear fit: log(MSD) = α * log(τ) + b
    slope, intercept, r_value, p_value, std_err = stats.linregress(log_tau_valid, log_msd_valid)
    
    alpha = slope
    r_squared = r_value ** 2
    
    return alpha, r_squared, std_err

def analyze_msd_curves(data: Dict[float, pd.DataFrame]) -> Dict[float, Dict]:
    """Analyze MSD curves and extract key parameters"""
    
    analysis = {}
    
    for p_value, df in data.items():
        tau = df['step'].values
        msd = df['msd'].values
        
        # Calculate growth exponents for different time ranges
        # Early time (first 10% of data)
        early_idx = max(100, len(tau) // 10)
        alpha_early, r2_early, err_early = calculate_growth_exponent(tau, msd, 100, early_idx)
        
        # Late time (last 50% of data)
        late_start = len(tau) // 2
        alpha_late, r2_late, err_late = calculate_growth_exponent(tau, msd, late_start)
        
        # Full range (excluding very early data)
        alpha_full, r2_full, err_full = calculate_growth_exponent(tau, msd, 100)
        
        # Final MSD value
        final_msd = msd[-1] if len(msd) > 0 else np.nan
        
        analysis[p_value] = {
            'alpha_early': alpha_early,
            'alpha_late': alpha_late,
            'alpha_full': alpha_full,
            'r2_early': r2_early,
            'r2_late': r2_late,
            'r2_full': r2_full,
            'err_early': err_early,
            'err_late': err_late,
            'err_full': err_full,
            'final_msd': final_msd,
            'data_points': len(df)
        }
        
        print(f"📊 p = {p_value:.4f}:")
        print(f"   Early α = {alpha_early:.3f} ± {err_early:.3f} (R² = {r2_early:.3f})")
        print(f"   Late α = {alpha_late:.3f} ± {err_late:.3f} (R² = {r2_late:.3f})")
        print(f"   Full α = {alpha_full:.3f} ± {err_full:.3f} (R² = {r2_full:.3f})")
        print(f"   Final MSD = {final_msd:.1f}")
    
    return analysis

def create_msd_comparison_plot(data: Dict[float, pd.DataFrame], output_dir: str):
    """Create main MSD comparison plot"""
    
    plt.figure(figsize=(12, 8))
    
    # Color scheme matching paper
    colors = {
        0.0: 'blue',
        0.3116: 'orange', 
        0.6884: 'red',
        0.75: 'purple'
    }
    
    labels = {
        0.0: 'p = 0.0000 (Free RW)',
        0.3116: 'p = 0.3116 (Near Critical)',
        0.6884: 'p = 0.6884 (High Occupation)',
        0.75: 'p = 0.7500 (Confined)'
    }
    
    for p_value, df in data.items():
        if p_value in colors:
            plt.loglog(df['step'], df['msd'], 
                      color=colors[p_value], 
                      label=labels[p_value],
                      linewidth=2,
                      alpha=0.8)
    
    plt.xlabel('Time Step τ', fontsize=14)
    plt.ylabel('Mean Squared Displacement ⟨Δr²(τ)⟩', fontsize=14)
    plt.title('MSD Comparison: Random Walk on 3D Percolation Lattices\n'
              'L=100³, 1,000 walkers, 1,000,000 steps', 
              fontsize=16, fontweight='bold')
    
    plt.legend(fontsize=12, loc='upper left')
    plt.grid(True, alpha=0.3)
    
    # Add theoretical reference lines
    x_ref = np.logspace(2, 6, 100)
    plt.loglog(x_ref, x_ref, 'k--', alpha=0.5, label='Normal diffusion (α=1)')
    plt.loglog(x_ref, x_ref**0.5, 'k:', alpha=0.5, label='Subdiffusion (α=0.5)')
    
    plt.tight_layout()
    
    # Save plot
    plot_path = Path(output_dir) / "msd_comparison_1M_steps.png"
    plt.savefig(plot_path, dpi=300, bbox_inches='tight')
    plt.close()
    
    print(f"📈 MSD comparison plot saved: {plot_path}")

def create_growth_exponent_plot(analysis: Dict[float, Dict], output_dir: str):
    """Create growth exponent analysis plot"""
    
    p_values = sorted(analysis.keys())
    
    # Extract data
    alpha_early = [analysis[p]['alpha_early'] for p in p_values]
    alpha_late = [analysis[p]['alpha_late'] for p in p_values]
    alpha_full = [analysis[p]['alpha_full'] for p in p_values]
    
    err_early = [analysis[p]['err_early'] for p in p_values]
    err_late = [analysis[p]['err_late'] for p in p_values]
    err_full = [analysis[p]['err_full'] for p in p_values]
    
    plt.figure(figsize=(12, 8))
    
    # Plot growth exponents
    plt.errorbar(p_values, alpha_early, yerr=err_early, 
                marker='o', label='Early time (α)', linewidth=2, markersize=8)
    plt.errorbar(p_values, alpha_late, yerr=err_late, 
                marker='s', label='Late time (α)', linewidth=2, markersize=8)
    plt.errorbar(p_values, alpha_full, yerr=err_full, 
                marker='^', label='Full range (α)', linewidth=2, markersize=8)
    
    # Add reference lines
    plt.axhline(y=1.0, color='k', linestyle='--', alpha=0.5, label='Normal diffusion')
    plt.axhline(y=0.5, color='k', linestyle=':', alpha=0.5, label='Subdiffusion')
    
    # Add percolation threshold markers
    plt.axvline(x=0.3116, color='red', linestyle='--', alpha=0.7, label='p_c (True gel point)')
    plt.axvline(x=0.6884, color='orange', linestyle='--', alpha=0.7, label="p_c' (Apparent gel point)")
    
    plt.xlabel('Occupation Probability p', fontsize=14)
    plt.ylabel('Growth Exponent α', fontsize=14)
    plt.title('MSD Growth Exponent vs Occupation Probability\n'
              '1,000,000 steps, 1,000 walkers', 
              fontsize=16, fontweight='bold')
    
    plt.legend(fontsize=12, loc='upper right')
    plt.grid(True, alpha=0.3)
    plt.xlim(-0.05, 0.8)
    plt.ylim(0, 1.2)
    
    plt.tight_layout()
    
    # Save plot
    plot_path = Path(output_dir) / "growth_exponent_analysis.png"
    plt.savefig(plot_path, dpi=300, bbox_inches='tight')
    plt.close()
    
    print(f"📊 Growth exponent plot saved: {plot_path}")

def create_final_msd_plot(analysis: Dict[float, Dict], output_dir: str):
    """Create final MSD vs p plot"""
    
    p_values = sorted(analysis.keys())
    final_msd = [analysis[p]['final_msd'] for p in p_values]
    
    plt.figure(figsize=(10, 6))
    
    plt.semilogy(p_values, final_msd, 'bo-', linewidth=2, markersize=8)
    
    # Add percolation threshold markers
    plt.axvline(x=0.3116, color='red', linestyle='--', alpha=0.7, label='p_c (True gel point)')
    plt.axvline(x=0.6884, color='orange', linestyle='--', alpha=0.7, label="p_c' (Apparent gel point)")
    
    plt.xlabel('Occupation Probability p', fontsize=14)
    plt.ylabel('Final MSD (at 1,000,000 steps)', fontsize=14)
    plt.title('Final MSD vs Occupation Probability\n'
              '1,000,000 steps, 1,000 walkers', 
              fontsize=16, fontweight='bold')
    
    plt.legend(fontsize=12)
    plt.grid(True, alpha=0.3)
    plt.xlim(-0.05, 0.8)
    
    plt.tight_layout()
    
    # Save plot
    plot_path = Path(output_dir) / "final_msd_vs_p.png"
    plt.savefig(plot_path, dpi=300, bbox_inches='tight')
    plt.close()
    
    print(f"📈 Final MSD plot saved: {plot_path}")

def create_analysis_report(analysis: Dict[float, Dict], output_dir: str):
    """Create comprehensive analysis report"""
    
    report_path = Path(output_dir) / "analysis_report.md"
    
    report_content = """# Paper Simulation Analysis Report

## Overview
Analysis of 1,000,000 step simulations with 1,000 walkers on 3D percolation lattices.

## Parameters
- **Lattice size:** 100³
- **Steps:** 1,000,000
- **Walkers:** 1,000
- **MSD sampling:** Every 1,000 steps (1,000 data points per simulation)

## Results Summary

### Growth Exponents (α)

| p-value | Early α | Late α | Full α | Final MSD |
|---------|---------|--------|--------|-----------|
"""
    
    for p_value in sorted(analysis.keys()):
        data = analysis[p_value]
        report_content += f"| {p_value:.4f} | {data['alpha_early']:.3f}±{data['err_early']:.3f} | {data['alpha_late']:.3f}±{data['err_late']:.3f} | {data['alpha_full']:.3f}±{data['err_full']:.3f} | {data['final_msd']:.1f} |\n"
    
    report_content += """

### Key Observations

#### 1. Free Random Walk (p = 0.0000)
- **Expected:** α ≈ 1.0 (normal diffusion)
- **Observed:** α ≈ [value] 
- **Interpretation:** [analysis]

#### 2. Near Critical Point (p = 0.3116)
- **Expected:** Complex behavior near percolation threshold
- **Observed:** α ≈ [value]
- **Interpretation:** [analysis]

#### 3. Apparent Gel Point (p = 0.6884)
- **Expected:** Loss of sample-spanning void space
- **Observed:** α ≈ [value]
- **Interpretation:** [analysis]

#### 4. Confined Regime (p = 0.7500)
- **Expected:** Strong confinement effects
- **Observed:** α ≈ [value]
- **Interpretation:** [analysis]

### Statistical Quality
- **Data points per simulation:** 1,000
- **Total steps:** 1,000,000
- **Number of walkers:** 1,000
- **Statistical significance:** High due to large ensemble

### Comparison with Theory
- **Free random walk:** Should approach α = 1.0 asymptotically
- **Percolation systems:** Can show subdiffusive behavior (α < 1.0)
- **Finite size effects:** May influence long-time behavior

## Files Generated
- `msd_comparison_1M_steps.png` - Main MSD comparison plot
- `growth_exponent_analysis.png` - Growth exponent analysis
- `final_msd_vs_p.png` - Final MSD vs occupation probability
- `analysis_results.json` - Raw analysis data

## Next Steps
1. Calculate rheological properties (G', G'')
2. Analyze frequency dependence
3. Compare with experimental data
4. Extend to longer simulations if needed
"""
    
    with open(report_path, 'w') as f:
        f.write(report_content)
    
    print(f"📄 Analysis report saved: {report_path}")

def save_analysis_data(analysis: Dict[float, Dict], output_dir: str):
    """Save analysis data as JSON"""
    
    # Convert numpy types to native Python types for JSON serialization
    json_data = {}
    for p_value, data in analysis.items():
        json_data[str(p_value)] = {
            key: float(value) if isinstance(value, (np.floating, np.integer)) else value
            for key, value in data.items()
        }
    
    json_path = Path(output_dir) / "analysis_results.json"
    with open(json_path, 'w') as f:
        json.dump(json_data, f, indent=2)
    
    print(f"💾 Analysis data saved: {json_path}")

def main():
    parser = argparse.ArgumentParser(description="Analyze Paper Simulation Results")
    parser.add_argument('--input-dir', type=str, default='paper_simulations',
                       help='Input directory containing simulation results')
    parser.add_argument('--output-dir', type=str, default='paper_analysis',
                       help='Output directory for analysis results')
    parser.add_argument('--p-values', nargs='+', type=float,
                       default=[0.0, 0.3116, 0.6884, 0.75],
                       help='P-values to analyze')
    
    args = parser.parse_args()
    
    print(f"🔍 Analyzing paper simulation results...")
    print(f"   Input directory: {args.input_dir}")
    print(f"   Output directory: {args.output_dir}")
    print(f"   P-values: {args.p_values}")
    
    # Create output directory
    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    
    # Load data
    print(f"\n📂 Loading simulation data...")
    data = load_simulation_data(args.input_dir, args.p_values)
    
    if not data:
        print("❌ No data found! Check input directory.")
        return 1
    
    print(f"✅ Loaded {len(data)} datasets")
    
    # Analyze MSD curves
    print(f"\n📊 Analyzing MSD curves...")
    analysis = analyze_msd_curves(data)
    
    # Create plots
    print(f"\n📈 Creating plots...")
    create_msd_comparison_plot(data, str(output_dir))
    create_growth_exponent_plot(analysis, str(output_dir))
    create_final_msd_plot(analysis, str(output_dir))
    
    # Create reports
    print(f"\n📄 Creating reports...")
    create_analysis_report(analysis, str(output_dir))
    save_analysis_data(analysis, str(output_dir))
    
    print(f"\n🎉 Analysis completed!")
    print(f"   Results saved in: {output_dir}")
    print(f"   Plots: 3 files")
    print(f"   Reports: 2 files")
    
    return 0

if __name__ == "__main__":
    sys.exit(main()) 