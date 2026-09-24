#!/usr/bin/env python3
"""
Plot MSD comparison for fine resolution data (every 100 steps)
Shows early-time behavior and detailed growth patterns
"""

import sys
import os
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from pathlib import Path

# Add parent directory to path for imports
sys.path.append(str(Path(__file__).parent.parent))

def plot_fine_resolution_msd(output_dir='enhanced_output_fine', save_plot=True):
    """
    Plot fine resolution MSD comparison showing early-time behavior
    """
    
    # Define p-values and their colors/labels
    p_values = [0.0000, 0.3116, 0.6884]
    colors = ['blue', 'orange', 'red']
    labels = ['p = 0.0000 (Free RW)', 'p = 0.3116 (Near Critical)', 'p = 0.6884 (High Occupation)']
    
    # Create figure with subplots
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(16, 6))
    
    # Load and plot each MSD file
    for i, p_val in enumerate(p_values):
        filename = f"msd_results_L100_p{p_val:.4f}.csv"
        filepath = Path(output_dir) / filename
        
        if not filepath.exists():
            print(f"Warning: {filename} not found")
            continue
        
        df = pd.read_csv(filepath)
        
        # Plot 1: Full range (log-log scale)
        ax1.loglog(df['step'], df['msd'], 
                  color=colors[i], label=labels[i], 
                  linewidth=2, alpha=0.8)
        
        # Plot 2: Early time behavior (first 1000 steps)
        early_data = df[df['step'] <= 1000]
        if len(early_data) > 0:
            ax2.loglog(early_data['step'], early_data['msd'], 
                      color=colors[i], label=labels[i], 
                      linewidth=2, alpha=0.8, marker='o', markersize=3)
    
    # Customize Plot 1: Full range
    ax1.set_xlabel('Time Step (τ)', fontsize=12)
    ax1.set_ylabel('Mean Squared Displacement (MSD)', fontsize=12)
    ax1.set_title('MSD vs Time - Full Range (Fine Resolution)', fontsize=14, fontweight='bold')
    ax1.grid(True, alpha=0.3)
    ax1.legend(fontsize=10)
    ax1.set_xlim(100, 100000)
    
    # Customize Plot 2: Early time
    ax2.set_xlabel('Time Step (τ)', fontsize=12)
    ax2.set_ylabel('Mean Squared Displacement (MSD)', fontsize=12)
    ax2.set_title('Early-Time Behavior (First 1000 Steps)', fontsize=14, fontweight='bold')
    ax2.grid(True, alpha=0.3)
    ax2.legend(fontsize=10)
    ax2.set_xlim(100, 1000)
    
    plt.tight_layout()
    
    if save_plot:
        plot_file = Path(output_dir) / "msd_fine_resolution_comparison.png"
        plt.savefig(plot_file, dpi=300, bbox_inches='tight')
        print(f"Fine resolution plot saved: {plot_file}")
    
    plt.show()
    
    return fig

def analyze_early_time_behavior(output_dir='enhanced_output_fine'):
    """
    Analyze early-time behavior and growth exponents
    """
    
    print("=== Early-Time Behavior Analysis ===")
    print()
    
    p_values = [0.0000, 0.3116, 0.6884]
    
    for p_val in p_values:
        filename = f"msd_results_L100_p{p_val:.4f}.csv"
        filepath = Path(output_dir) / filename
        
        if not filepath.exists():
            continue
        
        df = pd.read_csv(filepath)
        
        # Early time analysis (first 1000 steps)
        early_data = df[df['step'] <= 1000]
        
        if len(early_data) >= 5:
            # Calculate growth exponent for early time
            tau_early = early_data['step'].values
            msd_early = early_data['msd'].values
            
            # Fit power law: MSD ~ τ^α
            log_tau = np.log10(tau_early)
            log_msd = np.log10(msd_early)
            
            coeffs = np.polyfit(log_tau, log_msd, 1)
            growth_exponent_early = coeffs[0]
            
            # Late time analysis (last 1000 steps)
            late_data = df[df['step'] >= 90000]
            
            if len(late_data) >= 5:
                tau_late = late_data['step'].values
                msd_late = late_data['msd'].values
                
                log_tau_late = np.log10(tau_late)
                log_msd_late = np.log10(msd_late)
                
                coeffs_late = np.polyfit(log_tau_late, log_msd_late, 1)
                growth_exponent_late = coeffs_late[0]
            else:
                growth_exponent_late = None
            
            print(f"p = {p_val:.4f}:")
            print(f"  Early time (steps 100-1000):")
            print(f"    First MSD: {msd_early[0]:.1f} at step {tau_early[0]}")
            print(f"    Last MSD: {msd_early[-1]:.1f} at step {tau_early[-1]}")
            print(f"    Growth exponent: {growth_exponent_early:.3f}")
            
            if growth_exponent_late is not None:
                print(f"  Late time (steps 90k-100k):")
                print(f"    Growth exponent: {growth_exponent_late:.3f}")
                print(f"    Exponent change: {growth_exponent_late - growth_exponent_early:.3f}")
            
            print()

def create_summary_table(output_dir='enhanced_output_fine'):
    """
    Create a summary table of the fine resolution results
    """
    
    print("=== Fine Resolution Results Summary ===")
    print()
    
    results = []
    p_values = [0.0000, 0.3116, 0.6884]
    
    for p_val in p_values:
        filename = f"msd_results_L100_p{p_val:.4f}.csv"
        filepath = Path(output_dir) / filename
        
        if not filepath.exists():
            continue
        
        df = pd.read_csv(filepath)
        
        # Calculate statistics
        first_msd = df['msd'].iloc[0]
        last_msd = df['msd'].iloc[-1]
        total_data_points = len(df)
        
        # Calculate overall growth exponent
        tau_all = df['step'].values
        msd_all = df['msd'].values
        
        log_tau = np.log10(tau_all)
        log_msd = np.log10(msd_all)
        
        coeffs = np.polyfit(log_tau, log_msd, 1)
        growth_exponent = coeffs[0]
        
        results.append({
            'p_value': p_val,
            'first_msd': first_msd,
            'last_msd': last_msd,
            'data_points': total_data_points,
            'growth_exponent': growth_exponent,
            'msd_ratio': last_msd / first_msd if first_msd > 0 else 0
        })
    
    # Create summary table
    print(f"{'p-value':<10} {'First MSD':<12} {'Last MSD':<12} {'Data Points':<12} {'Growth Exp':<12} {'MSD Ratio':<12}")
    print("-" * 80)
    
    for result in results:
        print(f"{result['p_value']:<10.4f} {result['first_msd']:<12.1f} {result['last_msd']:<12.1f} "
              f"{result['data_points']:<12} {result['growth_exponent']:<12.3f} {result['msd_ratio']:<12.1f}")
    
    print()

if __name__ == "__main__":
    # Create plots
    plot_fine_resolution_msd()
    
    # Analyze behavior
    analyze_early_time_behavior()
    
    # Create summary
    create_summary_table() 