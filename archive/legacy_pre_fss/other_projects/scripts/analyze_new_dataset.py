#!/usr/bin/env python3
"""
Analyze the new MSD dataset (p_output_NEW34.csv) and save outputs to output_new_dataset/
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import os
from pathlib import Path

# Import our analysis functions
from corrected_alpha_analysis import CorrectedAlphaAnalyzer

def analyze_new_dataset():
    """Analyze the new dataset and save to output_new_dataset/"""
    print("=== ANALYZING NEW DATASET (p_output_NEW34.csv) ===")
    
    # Create output directory
    output_dir = "output_new_dataset"
    os.makedirs(output_dir, exist_ok=True)
    
    # Change working directory to output folder
    original_cwd = os.getcwd()
    os.chdir(output_dir)
    
    try:
        # Load the new dataset
        print("Loading new dataset...")
        df = pd.read_csv("../matlab/p_output_NEW34.csv")
        print(f"Loaded dataset with {len(df)} rows and {len(df.columns)} columns")
        
        # Extract p-values and MSD data
        p_values = []
        msd_data = {}
        
        for col in df.columns:
            if col.startswith('MSD_'):
                try:
                    p_val = float(col.replace('MSD_', ''))
                    p_values.append(p_val)
                    msd_data[p_val] = df[col].values
                except ValueError:
                    print(f"Warning: Could not parse p-value from column {col}")
        
        p_values.sort()
        print(f"Found {len(p_values)} p-values: {[f'{p:.4f}' for p in p_values]}")
        
        # Create time array (assuming 1M steps)
        time_steps = np.arange(1, len(df) + 1)
        
        # Run corrected alpha analysis
        print("\nRunning corrected alpha analysis...")
        analyzer = CorrectedAlphaAnalyzer()
        
        results = []
        for p in p_values:
            print(f"  Analyzing p = {p:.4f}...")
            result = analyzer.analyze_single_p_value(df, p, plot=False)
            if result:
                results.append({
                    'p': p,
                    'alpha_opt': result['alpha_opt'],
                    'tau_cr': result['tau_cr'],
                    'strategy': result['strategy'],
                    'r_squared': result['r_squared']
                })
            else:
                print(f"    Warning: Analysis failed for p = {p:.4f}")
        
        # Create results DataFrame
        results_df = pd.DataFrame(results)
        results_df.to_csv('corrected_alpha_analysis_results.csv', index=False)
        print(f"Saved alpha analysis results to: corrected_alpha_analysis_results.csv")
        
        # Create alpha vs p plot
        print("\nCreating alpha vs p plot...")
        fig, ax = plt.subplots(figsize=(12, 8))
        
        for strategy in ['liquid', 'critical', 'solid']:
            mask = results_df['strategy'] == strategy
            if mask.any():
                ax.scatter(results_df[mask]['p'], results_df[mask]['alpha_opt'], 
                          s=100, alpha=0.7, label=f'{strategy.title()}')
        
        ax.axvline(x=0.6884, color='black', linestyle=':', alpha=0.8, linewidth=2, label="p_c' = 0.6884")
        ax.set_xlabel('Percolation Probability (p)', fontsize=14)
        ax.set_ylabel('Growth Exponent (α)', fontsize=14)
        ax.set_title('Growth Exponent vs Percolation Probability\n(New Dataset)', fontsize=16, fontweight='bold')
        ax.legend(fontsize=12)
        ax.grid(True, alpha=0.3)
        ax.set_ylim(-0.1, 1.1)
        
        plt.tight_layout()
        plt.savefig('alpha_vs_p_new.png', dpi=300, bbox_inches='tight')
        plt.close()
        print("Saved: alpha_vs_p_new.png")
        
        # Create viscoelastic analysis plots
        print("\nCreating viscoelastic analysis plots...")
        create_viscoelastic_plots(results_df, output_prefix='new_')
        
        print(f"\n=== ANALYSIS COMPLETE ===")
        print(f"All outputs saved to: {output_dir}/")
        
    except Exception as e:
        print(f"Error during analysis: {e}")
        import traceback
        traceback.print_exc()
    
    finally:
        # Return to original directory
        os.chdir(original_cwd)

def create_viscoelastic_plots(df, output_prefix=''):
    """Create viscoelastic analysis plots with custom prefix"""
    print("Creating viscoelastic plots...")
    
    # Create alpha and delta vs p plot
    fig, axes = plt.subplots(2, 2, figsize=(16, 12))
    
    p_values = df['p'].values
    alpha_values = df['alpha_opt'].values
    
    # Plot 1: Alpha vs p
    ax1 = axes[0, 0]
    for strategy in ['liquid', 'critical', 'solid']:
        mask = df['strategy'] == strategy
        if mask.any():
            ax1.scatter(df[mask]['p'], df[mask]['alpha_opt'], s=100, alpha=0.7, 
                       label=f'{strategy.title()}')
    
    ax1.axhline(y=1.0, color='blue', linestyle='--', alpha=0.7, label='α = 1.0 (liquid)')
    ax1.axhline(y=0.5, color='orange', linestyle='--', alpha=0.7, label='α = 0.5 (critical)')
    ax1.axhline(y=0.0, color='red', linestyle='--', alpha=0.7, label='α = 0.0 (solid)')
    ax1.axvline(x=0.6884, color='black', linestyle=':', alpha=0.8, linewidth=2, label="p_c' = 0.6884")
    ax1.set_xlabel('Percolation Probability (p)', fontsize=12)
    ax1.set_ylabel('Growth Exponent (α)', fontsize=12)
    ax1.set_title('Growth Exponent vs Percolation Probability', fontsize=14, fontweight='bold')
    ax1.legend(fontsize=10)
    ax1.grid(True, alpha=0.3)
    ax1.set_ylim(-0.1, 1.1)
    
    # Plot 2: Loss tangent vs p
    ax2 = axes[0, 1]
    tan_delta_values = []
    for alpha in alpha_values:
        if alpha <= 0:
            tan_delta = 0.0
        elif alpha >= 1:
            tan_delta = 100.0
        else:
            tan_delta = 1.0
        tan_delta_values.append(tan_delta)
    
    ax2.scatter(p_values, tan_delta_values, s=100, alpha=0.7, color='green')
    ax2.axhline(y=100.0, color='blue', linestyle='--', alpha=0.7, label='tan δ = ∞ (liquid, δ = 90°)')
    ax2.axhline(y=1.0, color='orange', linestyle='--', alpha=0.7, label='tan δ = 1 (critical, δ = 45°)')
    ax2.axhline(y=0.0, color='red', linestyle='--', alpha=0.7, label='tan δ = 0 (solid, δ = 0°)')
    ax2.axvline(x=0.6884, color='black', linestyle=':', alpha=0.8, linewidth=2, label="p_c' = 0.6884")
    ax2.set_xlabel('Percolation Probability (p)', fontsize=12)
    ax2.set_ylabel('Loss Tangent (tan δ)', fontsize=12)
    ax2.set_title('Loss Tangent vs Percolation Probability', fontsize=14, fontweight='bold')
    ax2.legend(fontsize=10)
    ax2.grid(True, alpha=0.3)
    ax2.set_ylim(-5, 110)
    
    # Plot 3: Phase angle δ vs p
    ax3 = axes[1, 0]
    delta_values = np.arctan(tan_delta_values) * 180 / np.pi
    
    for strategy in ['liquid', 'critical', 'solid']:
        mask = df['strategy'] == strategy
        if mask.any():
            ax3.scatter(df[mask]['p'], delta_values[mask], s=100, alpha=0.7, 
                       label=f'{strategy.title()}')
    
    ax3.axhline(y=90.0, color='blue', linestyle='--', alpha=0.7, label='δ = 90° (liquid)')
    ax3.axhline(y=45.0, color='orange', linestyle='--', alpha=0.7, label='δ = 45° (critical)')
    ax3.axhline(y=0.0, color='red', linestyle='--', alpha=0.7, label='δ = 0° (solid)')
    ax3.axvline(x=0.6884, color='black', linestyle=':', alpha=0.8, linewidth=2, label="p_c' = 0.6884")
    ax3.set_xlabel('Percolation Probability (p)', fontsize=12)
    ax3.set_ylabel('Phase Angle δ (degrees)', fontsize=12)
    ax3.set_title('Phase Angle vs Percolation Probability', fontsize=14, fontweight='bold')
    ax3.legend(fontsize=10)
    ax3.grid(True, alpha=0.3)
    ax3.set_ylim(-5, 95)
    
    # Plot 4: Sigmoid fit
    ax4 = axes[1, 1]
    from scipy.optimize import curve_fit
    
    def sigmoid_function(p, p_c, width, alpha_min, alpha_max):
        alpha_min = max(0.0, alpha_min)
        alpha_max = min(1.0, alpha_max)
        return alpha_min + (alpha_max - alpha_min) / (1 + np.exp((p - p_c) / width))
    
    try:
        popt, pcov = curve_fit(sigmoid_function, p_values, alpha_values,
                              p0=[0.6884, 0.05, 0.0, 1.0],
                              bounds=([0.6, 0.01, 0.0, 0.8], [0.8, 0.2, 0.1, 1.0]))
        
        p_c, width, alpha_min, alpha_max = popt
        p_fit = np.linspace(min(p_values), max(p_values), 100)
        alpha_fit = sigmoid_function(p_fit, p_c, width, alpha_min, alpha_max)
        
        ax4.scatter(p_values, alpha_values, s=100, alpha=0.7, color='blue', label='Data')
        ax4.plot(p_fit, alpha_fit, 'r-', linewidth=2, label=f'Sigmoid fit\np_c={p_c:.4f}\nwidth={width:.4f}')
        ax4.axvline(x=0.6884, color='black', linestyle=':', alpha=0.8, linewidth=2, label="p_c' = 0.6884")
        ax4.set_xlabel('Percolation Probability (p)', fontsize=12)
        ax4.set_ylabel('Growth Exponent (α)', fontsize=12)
        ax4.set_title('Sigmoid Fit to α vs p', fontsize=14, fontweight='bold')
        ax4.legend(fontsize=10)
        ax4.grid(True, alpha=0.3)
        ax4.set_ylim(-0.1, 1.1)
        
    except Exception as e:
        print(f"Warning: Sigmoid fitting failed: {e}")
        ax4.text(0.5, 0.5, 'Sigmoid fitting failed', ha='center', va='center', transform=ax4.transAxes)
    
    plt.tight_layout()
    plt.savefig(f'{output_prefix}viscoelastic_analysis.png', dpi=300, bbox_inches='tight')
    plt.close()
    print(f"Saved: {output_prefix}viscoelastic_analysis.png")

if __name__ == "__main__":
    analyze_new_dataset()
