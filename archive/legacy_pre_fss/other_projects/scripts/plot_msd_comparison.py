#!/usr/bin/env python3
"""
Plot MSD comparison for different p-values
"""

import sys
import os
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from pathlib import Path

# Add parent directory to path for imports
sys.path.append(str(Path(__file__).parent.parent))

def plot_msd_comparison(output_dir='enhanced_output', save_plot=True):
    """
    Plot MSD comparison for different p-values
    """
    
    # Define p-values and their colors/labels
    p_values = [0.0000, 0.3116, 0.6884]
    colors = ['blue', 'orange', 'red']
    labels = ['p = 0.0000 (Free RW)', 'p = 0.3116 (Near Critical)', 'p = 0.6884 (High Occupation)']
    
    plt.figure(figsize=(12, 8))
    
    # Load and plot each MSD file
    for i, p_val in enumerate(p_values):
        filename = f"msd_results_L100_p{p_val:.4f}.csv"
        filepath = Path(output_dir) / filename
        
        if filepath.exists():
            df = pd.read_csv(filepath)
            
            # Plot MSD vs step
            plt.plot(df['step'], df['msd'], 
                    color=colors[i], 
                    label=labels[i], 
                    linewidth=2, 
                    marker='o', 
                    markersize=4,
                    alpha=0.8)
            
            print(f"✅ Loaded {filename}: {len(df)} data points, final MSD = {df['msd'].iloc[-1]:.1f}")
        else:
            print(f"❌ File not found: {filepath}")
    
    # Customize the plot
    plt.xlabel('Step', fontsize=12)
    plt.ylabel('Mean Squared Displacement (MSD)', fontsize=12)
    plt.title('MSD Comparison: Random Walk on Percolation Lattices\nL=100, 10 walkers, 10,000 steps', 
              fontsize=14, fontweight='bold')
    
    plt.legend(fontsize=11, loc='upper left')
    plt.grid(True, alpha=0.3)
    plt.xscale('log')
    plt.yscale('log')
    
    # Add theoretical reference line for free random walk (MSD ∝ t)
    if any(p == 0.0000 for p in p_values):
        # Get the first non-zero p=0.0000 data point for scaling
        free_file = Path(output_dir) / "msd_results_L100_p0.0000.csv"
        if free_file.exists():
            free_df = pd.read_csv(free_file)
            if len(free_df) > 0:
                # Theoretical line: MSD = 6Dt (3D diffusion)
                # Use the first data point to scale the theoretical line
                first_step = free_df['step'].iloc[0]
                first_msd = free_df['msd'].iloc[0]
                D = first_msd / (6 * first_step)  # Estimate diffusion coefficient
                
                steps_theory = np.logspace(2, 4, 100)
                msd_theory = 6 * D * steps_theory
                
                plt.plot(steps_theory, msd_theory, 'k--', 
                        label=f'Theoretical (D={D:.3f})', 
                        linewidth=1.5, alpha=0.7)
    
    plt.tight_layout()
    
    if save_plot:
        plot_filename = Path(output_dir) / "msd_comparison_plot.png"
        plt.savefig(plot_filename, dpi=300, bbox_inches='tight')
        print(f"📊 Plot saved: {plot_filename}")
    
    plt.show()
    
    return plt.gcf()

def plot_msd_growth_rate(output_dir='enhanced_output', save_plot=True):
    """
    Plot MSD growth rate analysis (log-log slope)
    """
    
    p_values = [0.0000, 0.3116, 0.6884]
    colors = ['blue', 'orange', 'red']
    labels = ['p = 0.0000', 'p = 0.3116', 'p = 0.6884']
    
    plt.figure(figsize=(10, 6))
    
    for i, p_val in enumerate(p_values):
        filename = f"msd_results_L100_p{p_val:.4f}.csv"
        filepath = Path(output_dir) / filename
        
        if filepath.exists():
            df = pd.read_csv(filepath)
            
            # Calculate growth rate (slope in log-log plot)
            log_steps = np.log10(df['step'].values)
            log_msd = np.log10(df['msd'].values)
            
            # Fit linear trend
            coeffs = np.polyfit(log_steps, log_msd, 1)
            slope = coeffs[0]
            
            # Plot log-log data
            plt.plot(log_steps, log_msd, 
                    color=colors[i], 
                    label=f'{labels[i]} (slope={slope:.2f})', 
                    linewidth=2, 
                    marker='o', 
                    markersize=4)
            
            print(f"📈 {labels[i]}: Growth exponent = {slope:.3f}")
    
    plt.xlabel('log₁₀(Step)', fontsize=12)
    plt.ylabel('log₁₀(MSD)', fontsize=12)
    plt.title('MSD Growth Rate Analysis\nSlope indicates diffusion exponent', 
              fontsize=14, fontweight='bold')
    
    plt.legend(fontsize=11)
    plt.grid(True, alpha=0.3)
    
    # Add reference lines
    plt.axhline(y=0, color='k', linestyle=':', alpha=0.5)
    plt.axvline(x=0, color='k', linestyle=':', alpha=0.5)
    
    plt.tight_layout()
    
    if save_plot:
        plot_filename = Path(output_dir) / "msd_growth_rate_plot.png"
        plt.savefig(plot_filename, dpi=300, bbox_inches='tight')
        print(f"📊 Growth rate plot saved: {plot_filename}")
    
    plt.show()
    
    return plt.gcf()

def main():
    """Main function to create comparison plots"""
    
    print("📊 Creating MSD comparison plots...")
    print("=" * 50)
    
    # Check if output directory exists
    output_dir = 'enhanced_output'
    if not Path(output_dir).exists():
        print(f"❌ Output directory not found: {output_dir}")
        print("Please run the simulations first.")
        return
    
    # Create comparison plot
    print("\n1. Creating MSD comparison plot...")
    fig1 = plot_msd_comparison(output_dir)
    
    # Create growth rate plot
    print("\n2. Creating growth rate analysis plot...")
    fig2 = plot_msd_growth_rate(output_dir)
    
    print("\n" + "=" * 50)
    print("✅ All plots created successfully!")
    print(f"📁 Check the '{output_dir}' directory for saved plots.")

if __name__ == "__main__":
    main() 