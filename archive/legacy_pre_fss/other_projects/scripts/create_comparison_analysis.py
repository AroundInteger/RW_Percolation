#!/usr/bin/env python3
"""
Create comparison analysis between both datasets and save outputs to output_comparison/
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import os
from pathlib import Path

def create_comparison_analysis():
    """Create comparison analysis between both datasets"""
    print("=== CREATING COMPARISON ANALYSIS ===")
    
    # Create output directory
    output_dir = "output_comparison"
    os.makedirs(output_dir, exist_ok=True)
    
    # Change working directory to output folder
    original_cwd = os.getcwd()
    os.chdir(output_dir)
    
    try:
        # Load both datasets' results
        print("Loading analysis results from both datasets...")
        
        # Check if both analysis results exist
        original_results = "../output_original_dataset/corrected_alpha_analysis_results.csv"
        new_results = "../output_new_dataset/corrected_alpha_analysis_results.csv"
        
        if not os.path.exists(original_results):
            print(f"Error: {original_results} not found. Please run analyze_original_dataset.py first.")
            return
        if not os.path.exists(new_results):
            print(f"Error: {new_results} not found. Please run analyze_new_dataset.py first.")
            return
        
        # Load the results
        df_orig = pd.read_csv(original_results)
        df_new = pd.read_csv(new_results)
        
        print(f"Original dataset: {len(df_orig)} p-values")
        print(f"New dataset: {len(df_new)} p-values")
        
        # Create comprehensive comparison plots
        print("\nCreating comparison plots...")
        
        # 1. Alpha comparison plot
        create_alpha_comparison_plot(df_orig, df_new)
        
        # 2. Phase angle comparison plot
        create_phase_angle_comparison_plot(df_orig, df_new)
        
        # 3. Sigmoid fit comparison
        create_sigmoid_comparison_plot(df_orig, df_new)
        
        # 4. Statistical comparison table
        create_statistical_comparison(df_orig, df_new)
        
        print(f"\n=== COMPARISON ANALYSIS COMPLETE ===")
        print(f"All outputs saved to: {output_dir}/")
        
    except Exception as e:
        print(f"Error during comparison analysis: {e}")
        import traceback
        traceback.print_exc()
    
    finally:
        # Return to original directory
        os.chdir(original_cwd)

def create_alpha_comparison_plot(df_orig, df_new):
    """Create alpha comparison plot"""
    print("Creating alpha comparison plot...")
    
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(20, 8))
    
    # Plot 1: Original dataset
    for strategy in ['liquid', 'critical', 'solid']:
        mask = df_orig['strategy'] == strategy
        if mask.any():
            ax1.scatter(df_orig[mask]['p'], df_orig[mask]['alpha_opt'], 
                       s=100, alpha=0.7, label=f'{strategy.title()}')
    
    ax1.axhline(y=1.0, color='blue', linestyle='--', alpha=0.7, label='α = 1.0 (liquid)')
    ax1.axhline(y=0.5, color='orange', linestyle='--', alpha=0.7, label='α = 0.5 (critical)')
    ax1.axhline(y=0.0, color='red', linestyle='--', alpha=0.7, label='α = 0.0 (solid)')
    ax1.axvline(x=0.6884, color='black', linestyle=':', alpha=0.8, linewidth=2, label="p_c' = 0.6884")
    ax1.set_xlabel('Percolation Probability (p)', fontsize=12)
    ax1.set_ylabel('Growth Exponent (α)', fontsize=12)
    ax1.set_title('Original Dataset (p_output_C1.csv)', fontsize=14, fontweight='bold')
    ax1.legend(fontsize=10)
    ax1.grid(True, alpha=0.3)
    ax1.set_ylim(-0.1, 1.1)
    
    # Plot 2: New dataset
    for strategy in ['liquid', 'critical', 'solid']:
        mask = df_new['strategy'] == strategy
        if mask.any():
            ax2.scatter(df_new[mask]['p'], df_new[mask]['alpha_opt'], 
                       s=100, alpha=0.7, label=f'{strategy.title()}')
    
    ax2.axhline(y=1.0, color='blue', linestyle='--', alpha=0.7, label='α = 1.0 (liquid)')
    ax2.axhline(y=0.5, color='orange', linestyle='--', alpha=0.7, label='α = 0.5 (critical)')
    ax2.axhline(y=0.0, color='red', linestyle='--', alpha=0.7, label='α = 0.0 (solid)')
    ax2.axvline(x=0.6884, color='black', linestyle=':', alpha=0.8, linewidth=2, label="p_c' = 0.6884")
    ax2.set_xlabel('Percolation Probability (p)', fontsize=12)
    ax2.set_ylabel('Growth Exponent (α)', fontsize=12)
    ax2.set_title('New Dataset (p_output_NEW34.csv)', fontsize=14, fontweight='bold')
    ax2.legend(fontsize=10)
    ax2.grid(True, alpha=0.3)
    ax2.set_ylim(-0.1, 1.1)
    
    plt.tight_layout()
    plt.savefig('alpha_comparison.png', dpi=300, bbox_inches='tight')
    plt.close()
    print("Saved: alpha_comparison.png")

def create_phase_angle_comparison_plot(df_orig, df_new):
    """Create phase angle comparison plot"""
    print("Creating phase angle comparison plot...")
    
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(20, 8))
    
    # Calculate phase angles for both datasets
    def calculate_phase_angles(df):
        alpha_values = df['alpha_opt'].values
        tan_delta_values = []
        for alpha in alpha_values:
            if alpha <= 0:
                tan_delta = 0.0
            elif alpha >= 1:
                tan_delta = 100.0
            else:
                tan_delta = 1.0
            tan_delta_values.append(tan_delta)
        
        delta_values = np.arctan(tan_delta_values) * 180 / np.pi
        return delta_values
    
    delta_orig = calculate_phase_angles(df_orig)
    delta_new = calculate_phase_angles(df_new)
    
    # Plot 1: Original dataset
    for strategy in ['liquid', 'critical', 'solid']:
        mask = df_orig['strategy'] == strategy
        if mask.any():
            ax1.scatter(df_orig[mask]['p'], delta_orig[mask], 
                       s=100, alpha=0.7, label=f'{strategy.title()}')
    
    ax1.axhline(y=90.0, color='blue', linestyle='--', alpha=0.7, label='δ = 90° (liquid)')
    ax1.axhline(y=45.0, color='orange', linestyle='--', alpha=0.7, label='δ = 45° (critical)')
    ax1.axhline(y=0.0, color='red', linestyle='--', alpha=0.7, label='δ = 0° (solid)')
    ax1.axvline(x=0.6884, color='black', linestyle=':', alpha=0.8, linewidth=2, label="p_c' = 0.6884")
    ax1.set_xlabel('Percolation Probability (p)', fontsize=12)
    ax1.set_ylabel('Phase Angle δ (degrees)', fontsize=12)
    ax1.set_title('Original Dataset - Phase Angles', fontsize=14, fontweight='bold')
    ax1.legend(fontsize=10)
    ax1.grid(True, alpha=0.3)
    ax1.set_ylim(-5, 95)
    
    # Plot 2: New dataset
    for strategy in ['liquid', 'critical', 'solid']:
        mask = df_new['strategy'] == strategy
        if mask.any():
            ax2.scatter(df_new[mask]['p'], delta_new[mask], 
                       s=100, alpha=0.7, label=f'{strategy.title()}')
    
    ax2.axhline(y=90.0, color='blue', linestyle='--', alpha=0.7, label='δ = 90° (liquid)')
    ax2.axhline(y=45.0, color='orange', linestyle='--', alpha=0.7, label='δ = 45° (critical)')
    ax2.axhline(y=0.0, color='red', linestyle='--', alpha=0.7, label='δ = 0° (solid)')
    ax2.axvline(x=0.6884, color='black', linestyle=':', alpha=0.8, linewidth=2, label="p_c' = 0.6884")
    ax2.set_xlabel('Percolation Probability (p)', fontsize=12)
    ax2.set_ylabel('Phase Angle δ (degrees)', fontsize=12)
    ax2.set_title('New Dataset - Phase Angles', fontsize=14, fontweight='bold')
    ax2.legend(fontsize=10)
    ax2.grid(True, alpha=0.3)
    ax2.set_ylim(-5, 95)
    
    plt.tight_layout()
    plt.savefig('phase_angle_comparison.png', dpi=300, bbox_inches='tight')
    plt.close()
    print("Saved: phase_angle_comparison.png")

def create_sigmoid_comparison_plot(df_orig, df_new):
    """Create sigmoid fit comparison plot"""
    print("Creating sigmoid comparison plot...")
    
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(20, 8))
    
    # Fit sigmoid to both datasets
    from scipy.optimize import curve_fit
    
    def sigmoid_function(p, p_c, width, alpha_min, alpha_max):
        alpha_min = max(0.0, alpha_min)
        alpha_max = min(1.0, alpha_max)
        return alpha_min + (alpha_max - alpha_min) / (1 + np.exp((p - p_c) / width))
    
    # Original dataset fit
    try:
        popt_orig, pcov_orig = curve_fit(sigmoid_function, df_orig['p'].values, df_orig['alpha_opt'].values,
                                        p0=[0.6884, 0.05, 0.0, 1.0],
                                        bounds=([0.6, 0.01, 0.0, 0.8], [0.8, 0.2, 0.1, 1.0]))
        
        p_c_orig, width_orig, alpha_min_orig, alpha_max_orig = popt_orig
        p_fit_orig = np.linspace(min(df_orig['p']), max(df_orig['p']), 100)
        alpha_fit_orig = sigmoid_function(p_fit_orig, p_c_orig, width_orig, alpha_min_orig, alpha_max_orig)
        
        ax1.scatter(df_orig['p'], df_orig['alpha_opt'], s=100, alpha=0.7, color='blue', label='Data')
        ax1.plot(p_fit_orig, alpha_fit_orig, 'r-', linewidth=2, 
                label=f'Sigmoid fit\np_c={p_c_orig:.4f}\nwidth={width_orig:.4f}')
        ax1.axvline(x=0.6884, color='black', linestyle=':', alpha=0.8, linewidth=2, label="p_c' = 0.6884")
        ax1.set_xlabel('Percolation Probability (p)', fontsize=12)
        ax1.set_ylabel('Growth Exponent (α)', fontsize=12)
        ax1.set_title('Original Dataset - Sigmoid Fit', fontsize=14, fontweight='bold')
        ax1.legend(fontsize=10)
        ax1.grid(True, alpha=0.3)
        ax1.set_ylim(-0.1, 1.1)
        
    except Exception as e:
        print(f"Warning: Sigmoid fitting failed for original dataset: {e}")
        ax1.text(0.5, 0.5, 'Sigmoid fitting failed', ha='center', va='center', transform=ax1.transAxes)
    
    # New dataset fit
    try:
        popt_new, pcov_new = curve_fit(sigmoid_function, df_new['p'].values, df_new['alpha_opt'].values,
                                      p0=[0.6884, 0.05, 0.0, 1.0],
                                      bounds=([0.6, 0.01, 0.0, 0.8], [0.8, 0.2, 0.1, 1.0]))
        
        p_c_new, width_new, alpha_min_new, alpha_max_new = popt_new
        p_fit_new = np.linspace(min(df_new['p']), max(df_new['p']), 100)
        alpha_fit_new = sigmoid_function(p_fit_new, p_c_new, width_new, alpha_min_new, alpha_max_new)
        
        ax2.scatter(df_new['p'], df_new['alpha_opt'], s=100, alpha=0.7, color='blue', label='Data')
        ax2.plot(p_fit_new, alpha_fit_new, 'r-', linewidth=2, 
                label=f'Sigmoid fit\np_c={p_c_new:.4f}\nwidth={width_new:.4f}')
        ax2.axvline(x=0.6884, color='black', linestyle=':', alpha=0.8, linewidth=2, label="p_c' = 0.6884")
        ax2.set_xlabel('Percolation Probability (p)', fontsize=12)
        ax2.set_ylabel('Growth Exponent (α)', fontsize=12)
        ax2.set_title('New Dataset - Sigmoid Fit', fontsize=14, fontweight='bold')
        ax2.legend(fontsize=10)
        ax2.grid(True, alpha=0.3)
        ax2.set_ylim(-0.1, 1.1)
        
    except Exception as e:
        print(f"Warning: Sigmoid fitting failed for new dataset: {e}")
        ax2.text(0.5, 0.5, 'Sigmoid fitting failed', ha='center', va='center', transform=ax2.transAxes)
    
    plt.tight_layout()
    plt.savefig('sigmoid_comparison.png', dpi=300, bbox_inches='tight')
    plt.close()
    print("Saved: sigmoid_comparison.png")

def create_statistical_comparison(df_orig, df_new):
    """Create statistical comparison table"""
    print("Creating statistical comparison...")
    
    # Calculate statistics for both datasets
    stats_orig = {
        'Dataset': 'Original (p_output_C1)',
        'P-value range': f"{min(df_orig['p']):.4f} - {max(df_orig['p']):.4f}",
        'Critical region points': len(df_orig[df_orig['strategy'] == 'critical']),
        'Liquid region points': len(df_orig[df_orig['strategy'] == 'liquid']),
        'Solid region points': len(df_orig[df_orig['strategy'] == 'solid']),
        'Mean α (liquid)': df_orig[df_orig['strategy'] == 'liquid']['alpha_opt'].mean(),
        'Mean α (critical)': df_orig[df_orig['strategy'] == 'critical']['alpha_opt'].mean(),
        'Mean α (solid)': df_orig[df_orig['strategy'] == 'solid']['alpha_opt'].mean(),
        'Overall α std': df_orig['alpha_opt'].std(),
        'Mean R²': df_orig['r_squared'].mean()
    }
    
    stats_new = {
        'Dataset': 'New (p_output_NEW34)',
        'P-value range': f"{min(df_new['p']):.4f} - {max(df_new['p']):.4f}",
        'Critical region points': len(df_new[df_new['strategy'] == 'critical']),
        'Liquid region points': len(df_new[df_new['strategy'] == 'liquid']),
        'Solid region points': len(df_new[df_new['strategy'] == 'solid']),
        'Mean α (liquid)': df_new[df_new['strategy'] == 'liquid']['alpha_opt'].mean(),
        'Mean α (critical)': df_new[df_new['strategy'] == 'critical']['alpha_opt'].mean(),
        'Mean α (solid)': df_new[df_new['strategy'] == 'solid']['alpha_opt'].mean(),
        'Overall α std': df_new['alpha_opt'].std(),
        'Mean R²': df_new['r_squared'].mean()
    }
    
    # Create comparison DataFrame
    comparison_df = pd.DataFrame([stats_orig, stats_new])
    comparison_df.to_csv('statistical_comparison.csv', index=False)
    print("Saved: statistical_comparison.csv")
    
    # Print summary
    print("\n=== STATISTICAL COMPARISON SUMMARY ===")
    print(comparison_df.to_string(index=False))

if __name__ == "__main__":
    create_comparison_analysis()
