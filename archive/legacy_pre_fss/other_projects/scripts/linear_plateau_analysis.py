#!/usr/bin/env python3
"""
LINEAR PLATEAU ANALYSIS
Analyze plateau behavior using linear time plotting for p > p_c'
"""

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from pathlib import Path
import sys

def load_ensemble_data(p: float, seed: int):
    """Load ensemble simulation data"""
    data_path = Path(f"../ensemble_simulations/seed_{seed:02d}/p_{p:.4f}/msd_results_L500_p{p:.4f}.csv")
    data = pd.read_csv(data_path)
    
    if 'tau' in data.columns:
        t = data['tau'].values
    else:
        t = data.iloc[:, 0].values
    
    if 'msd' in data.columns:
        msd = data['msd'].values
    else:
        msd = data.iloc[:, 1].values
    
    t = np.maximum(t, 1e-3)
    msd = np.maximum(msd, 1e-6)
    
    return t, msd

def analyze_linear_plateau(t, msd, p, seed):
    """Analyze plateau behavior using linear time plotting"""
    
    print(f"=== LINEAR PLATEAU ANALYSIS FOR p = {p:.4f}, seed = {seed:02d} ===")
    
    # Calculate local slopes using linear time (not log-log)
    # For plateau detection, we want d(MSD)/dt ≈ 0
    dt = np.diff(t)
    dmsd = np.diff(msd)
    
    # Local slope (dMSD/dt)
    local_slope = dmsd / dt
    
    # Normalize by MSD to get relative change
    relative_slope = local_slope / msd[:-1]
    
    # Find plateau regions where relative slope is small
    plateau_threshold = 1e-4  # Very small relative change
    plateau_mask = np.abs(relative_slope) < plateau_threshold
    
    # Find consecutive plateau regions
    plateau_regions = []
    start_idx = None
    
    for i in range(len(plateau_mask)):
        if plateau_mask[i] and start_idx is None:
            start_idx = i
        elif not plateau_mask[i] and start_idx is not None:
            if i - start_idx >= 10:  # Minimum 10 consecutive points
                plateau_regions.append((start_idx, i-1))
            start_idx = None
    
    # Handle case where plateau extends to end
    if start_idx is not None and len(plateau_mask) - start_idx >= 10:
        plateau_regions.append((start_idx, len(plateau_mask)-1))
    
    print(f"Plateau threshold: |dMSD/dt|/MSD < {plateau_threshold}")
    print(f"Total plateau points: {np.sum(plateau_mask)} ({100*np.sum(plateau_mask)/len(plateau_mask):.1f}%)")
    print(f"Number of plateau regions (≥10 points): {len(plateau_regions)}")
    
    # Analyze plateau regions
    plateau_analysis = []
    for i, (start, end) in enumerate(plateau_regions):
        region_length = end - start + 1
        time_range = (t[start], t[end])
        msd_range = (msd[start], msd[end])
        slope_mean = np.mean(relative_slope[start:end+1])
        slope_std = np.std(relative_slope[start:end+1])
        
        print(f"\nPlateau Region {i+1}:")
        print(f"  Length: {region_length} points")
        print(f"  Time: {time_range[0]:.2e} to {time_range[1]:.2e}")
        print(f"  MSD: {msd_range[0]:.2e} to {msd_range[1]:.2e}")
        print(f"  Relative slope: {slope_mean:.2e} ± {slope_std:.2e}")
        
        plateau_analysis.append({
            'region': i+1,
            'start_idx': start,
            'end_idx': end,
            'length': region_length,
            'time_start': time_range[0],
            'time_end': time_range[1],
            'msd_start': msd_range[0],
            'msd_end': msd_range[1],
            'slope_mean': slope_mean,
            'slope_std': slope_std
        })
    
    return relative_slope, plateau_regions, plateau_analysis

def plot_linear_analysis(t, msd, results, p, seed):
    """Plot MSD vs linear time to show plateau regions"""
    
    fig, ((ax1, ax2), (ax3, ax4)) = plt.subplots(2, 2, figsize=(15, 10))
    
    relative_slope = results['relative_slope']
    plateau_regions = results['plateau_regions']
    
    # Plot 1: MSD vs linear time
    ax1.plot(t, msd, 'b-', linewidth=1, label='MSD', alpha=0.7)
    
    # Highlight plateau regions
    for start, end in plateau_regions:
        ax1.plot(t[start:end+1], msd[start:end+1], 'r-', linewidth=3, alpha=0.8)
    
    # Highlight longest plateau if available
    if results['plateau_analysis']:
        longest_plateau = max(results['plateau_analysis'], key=lambda x: x['length'])
        start_long = longest_plateau['start_idx']
        end_long = longest_plateau['end_idx']
        ax1.plot(t[start_long:end_long+1], msd[start_long:end_long+1], 'orange', linewidth=4, label=f'Longest plateau ({longest_plateau["length"]} points)')
    
    ax1.set_xlabel('Time (τ)')
    ax1.set_ylabel('MSD')
    ax1.set_title(f'MSD vs Linear Time (p = {p:.4f}, seed = {seed:02d})')
    ax1.legend()
    ax1.grid(True, alpha=0.3)
    
    # Plot 2: Relative slope vs time
    ax2.semilogx(t[:-1], relative_slope, 'b-', linewidth=1, label='dMSD/dt / MSD', alpha=0.7)
    ax2.axhline(0, color='black', linestyle='-', alpha=0.5)
    ax2.axhline(1e-4, color='orange', linestyle='--', label='Plateau threshold')
    ax2.axhline(-1e-4, color='orange', linestyle='--')
    
    # Highlight plateau regions
    for start, end in plateau_regions:
        ax2.semilogx(t[start:end+1], relative_slope[start:end+1], 'r-', linewidth=3, alpha=0.8)
    
    ax2.set_xlabel('Time (τ)')
    ax2.set_ylabel('Relative Slope (dMSD/dt / MSD)')
    ax2.set_title('Relative Slope vs Time')
    ax2.legend()
    ax2.grid(True, alpha=0.3)
    
    # Plot 3: Log-log MSD for comparison
    ax3.loglog(t, msd, 'b-', linewidth=1, label='MSD', alpha=0.7)
    
    # Highlight plateau regions
    for start, end in plateau_regions:
        ax3.loglog(t[start:end+1], msd[start:end+1], 'r-', linewidth=3, alpha=0.8)
    
    ax3.set_xlabel('Time (τ)')
    ax3.set_ylabel('MSD')
    ax3.set_title('MSD vs Log Time (for comparison)')
    ax3.legend()
    ax3.grid(True, alpha=0.3)
    
    # Plot 4: Plateau region zoom
    if results['plateau_analysis']:
        longest_plateau = max(results['plateau_analysis'], key=lambda x: x['length'])
        start_long = longest_plateau['start_idx']
        end_long = longest_plateau['end_idx']
        
        t_plateau = t[start_long:end_long+1]
        msd_plateau = msd[start_long:end_long+1]
        
        ax4.plot(t_plateau, msd_plateau, 'orange', linewidth=2, label='Plateau MSD')
        ax4.set_xlabel('Time (τ)')
        ax4.set_ylabel('MSD')
        ax4.set_title(f'Longest Plateau Region ({longest_plateau["length"]} points)')
        ax4.legend()
        ax4.grid(True, alpha=0.3)
    else:
        ax4.text(0.5, 0.5, 'No significant plateau regions', ha='center', va='center', transform=ax4.transAxes)
        ax4.set_title('Plateau Region')
    
    plt.tight_layout()
    plt.savefig(f'linear_plateau_analysis_p{p:.4f}_seed{seed:02d}.png', dpi=300, bbox_inches='tight')
    plt.show()

def main():
    """Main analysis function"""
    
    # Test cases: focus on p > p_c' (solid regime)
    test_cases = [
        (0.7500, 1, "SOLID"),
        (0.7500, 2, "SOLID"),
    ]
    
    print("=== LINEAR PLATEAU ANALYSIS ===")
    print("Examining plateau behavior using linear time plotting")
    print("=" * 60)
    
    for p, seed, regime in test_cases:
        print(f"\n{'='*60}")
        print(f"ANALYZING: p = {p:.4f}, seed = {seed:02d}, regime = {regime}")
        print(f"{'='*60}")
        
        try:
            # Load data
            t, msd = load_ensemble_data(p, seed)
            
            # Analyze plateau behavior
            relative_slope, plateau_regions, plateau_analysis = analyze_linear_plateau(t, msd, p, seed)
            
            results = {
                'relative_slope': relative_slope,
                'plateau_regions': plateau_regions,
                'plateau_analysis': plateau_analysis
            }
            
            # Plot analysis
            plot_linear_analysis(t, msd, results, p, seed)
            
        except Exception as e:
            print(f"Error analyzing p = {p:.4f}, seed = {seed:02d}: {e}")
        
        print(f"\n{'-'*60}")

if __name__ == "__main__":
    main() 