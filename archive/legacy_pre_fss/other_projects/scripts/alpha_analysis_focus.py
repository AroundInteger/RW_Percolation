#!/usr/bin/env python3
"""
Focused Alpha Analysis
Examine α values across the percolation spectrum to understand the physical behavior
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from scipy import stats

def load_and_analyze_alpha():
    """Load the robust analysis results and examine α values"""
    
    # Load the results
    df = pd.read_csv('robust_comprehensive_analysis_results.csv')
    
    print("=== ALPHA ANALYSIS ACROSS PERCOLATION SPECTRUM ===")
    print(f"Total p-values: {len(df)}")
    print()
    
    # Extract key data
    p_values = df['p'].values
    alpha_values = df['alpha_opt'].values
    alpha_errors = df['alpha_error'].values
    tau_cr_values = df['tau_cr'].values
    regimes = df['regime'].values
    
    # Critical points
    p_c = 0.3116
    p_c_prime = 0.6884
    
    print("CRITICAL POINTS:")
    print(f"  p_c (gel-point of occupied sites): {p_c}")
    print(f"  p_c' (gel-point of unoccupied sites): {p_c_prime}")
    print()
    
    # Analyze α values by regime
    print("=== ALPHA VALUES BY REGIME ===")
    
    for regime in ['LIQUID', 'CRITICAL', 'SOLID']:
        mask = regimes == regime
        if np.any(mask):
            p_regime = p_values[mask]
            alpha_regime = alpha_values[mask]
            error_regime = alpha_errors[mask]
            
            print(f"\n{regime} REGIME ({np.sum(mask)} p-values):")
            print(f"  Expected α: {get_expected_alpha(regime)}")
            print(f"  Actual α range: {alpha_regime.min():.3f} to {alpha_regime.max():.3f}")
            print(f"  Mean α: {np.mean(alpha_regime):.3f} ± {np.std(alpha_regime):.3f}")
            print(f"  Mean error: {np.mean(error_regime):.3f}")
            
            # Show individual values
            for i, (p, alpha, error) in enumerate(zip(p_regime, alpha_regime, error_regime)):
                print(f"    p = {p:.4f}: α = {alpha:.3f} (error = {error:.3f})")
    
    # Identify problematic values
    print("\n=== PROBLEMATIC ALPHA VALUES ===")
    problematic_mask = (alpha_values < -10) | (alpha_values > 10)
    if np.any(problematic_mask):
        print(f"Found {np.sum(problematic_mask)} problematic α values:")
        for i in np.where(problematic_mask)[0]:
            p = p_values[i]
            alpha = alpha_values[i]
            error = alpha_errors[i]
            regime = regimes[i]
            tau_cr = tau_cr_values[i]
            print(f"  p = {p:.4f} ({regime}): α = {alpha:.3f}, τ_cr = {tau_cr:.2e}, error = {error:.3f}")
    else:
        print("No problematic α values found (all between -10 and 10)")
    
    # Check for expected behavior
    print("\n=== EXPECTED vs ACTUAL BEHAVIOR ===")
    
    # Liquid regime (p < p_c' - 0.05)
    liquid_mask = p_values < (p_c_prime - 0.05)
    if np.any(liquid_mask):
        liquid_alphas = alpha_values[liquid_mask]
        print(f"LIQUID regime (p < {p_c_prime - 0.05:.3f}):")
        print(f"  Expected: α ≈ 1.0")
        print(f"  Actual: α = {np.mean(liquid_alphas):.3f} ± {np.std(liquid_alphas):.3f}")
        print(f"  Range: {liquid_alphas.min():.3f} to {liquid_alphas.max():.3f}")
    
    # Critical regime (|p - p_c'| < 0.05)
    critical_mask = np.abs(p_values - p_c_prime) < 0.05
    if np.any(critical_mask):
        critical_alphas = alpha_values[critical_mask]
        print(f"\nCRITICAL regime (|p - {p_c_prime}| < 0.05):")
        print(f"  Expected: α transitions from 1 to 0")
        print(f"  Actual: α = {np.mean(critical_alphas):.3f} ± {np.std(critical_alphas):.3f}")
        print(f"  Range: {critical_alphas.min():.3f} to {critical_alphas.max():.3f}")
    
    # Solid regime (p > p_c' + 0.05)
    solid_mask = p_values > (p_c_prime + 0.05)
    if np.any(solid_mask):
        solid_alphas = alpha_values[solid_mask]
        print(f"\nSOLID regime (p > {p_c_prime + 0.05:.3f}):")
        print(f"  Expected: α ≈ 0.0")
        print(f"  Actual: α = {np.mean(solid_alphas):.3f} ± {np.std(solid_alphas):.3f}")
        print(f"  Range: {solid_alphas.min():.3f} to {solid_alphas.max():.3f}")
    
    return df

def get_expected_alpha(regime):
    """Get expected α value for a regime"""
    if regime == 'LIQUID':
        return "≈ 1.0 (normal diffusion)"
    elif regime == 'CRITICAL':
        return "0.5 (anomalous diffusion)"
    elif regime == 'SOLID':
        return "≈ 0.0 (no diffusion)"
    else:
        return "unknown"

def create_alpha_vs_p_plot(df):
    """Create a detailed plot of α vs p"""
    
    p_values = df['p'].values
    alpha_values = df['alpha_opt'].values
    alpha_errors = df['alpha_error'].values
    regimes = df['regime'].values
    tau_cr_values = df['tau_cr'].values
    
    p_c = 0.3116
    p_c_prime = 0.6884
    
    # Create figure
    fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(12, 10))
    
    # Plot 1: α vs p with error bars
    regime_colors = {'LIQUID': 'blue', 'CRITICAL': 'orange', 'SOLID': 'red'}
    
    for regime in set(regimes):
        mask = regimes == regime
        if np.any(mask):
            ax1.errorbar(p_values[mask], alpha_values[mask], yerr=alpha_errors[mask], 
                        fmt='o', label=regime, color=regime_colors[regime], 
                        capsize=5, markersize=6, alpha=0.7)
    
    # Add expected behavior lines
    ax1.axhline(1.0, color='k', linestyle='--', alpha=0.5, label='Expected α = 1.0')
    ax1.axhline(0.0, color='k', linestyle='--', alpha=0.5, label='Expected α = 0.0')
    ax1.axvline(p_c, color='r', linestyle=':', alpha=0.7, label=f'p_c = {p_c}')
    ax1.axvline(p_c_prime, color='g', linestyle=':', alpha=0.7, label=f"p_c' = {p_c_prime}")
    
    ax1.set_xlabel('Percolation Probability p')
    ax1.set_ylabel('Growth Exponent α')
    ax1.set_title('α vs p Across Percolation Spectrum')
    ax1.legend()
    ax1.grid(True, alpha=0.3)
    
    # Set reasonable y limits
    reasonable_mask = (alpha_values >= -5) & (alpha_values <= 5)
    if np.any(reasonable_mask):
        y_min = alpha_values[reasonable_mask].min() - 0.5
        y_max = alpha_values[reasonable_mask].max() + 0.5
        ax1.set_ylim(y_min, y_max)
    
    # Plot 2: τ_cr vs p
    ax2.semilogy(p_values, tau_cr_values, 'ko-', markersize=6, alpha=0.7)
    ax2.axvline(p_c, color='r', linestyle=':', alpha=0.7, label=f'p_c = {p_c}')
    ax2.axvline(p_c_prime, color='g', linestyle=':', alpha=0.7, label=f"p_c' = {p_c_prime}")
    
    ax2.set_xlabel('Percolation Probability p')
    ax2.set_ylabel('Critical Time τ_cr')
    ax2.set_title('τ_cr vs p')
    ax2.legend()
    ax2.grid(True, alpha=0.3)
    
    plt.tight_layout()
    plt.savefig('alpha_analysis_focus.png', dpi=300, bbox_inches='tight')
    plt.show()
    
    print("Plot saved to: alpha_analysis_focus.png")

def identify_analysis_issues(df):
    """Identify potential issues with the analysis"""
    
    print("\n=== POTENTIAL ANALYSIS ISSUES ===")
    
    p_values = df['p'].values
    alpha_values = df['alpha_opt'].values
    alpha_errors = df['alpha_error'].values
    tau_cr_values = df['tau_cr'].values
    
    # Issue 1: Very large α values
    large_alpha_mask = np.abs(alpha_values) > 10
    if np.any(large_alpha_mask):
        print(f"Issue 1: {np.sum(large_alpha_mask)} very large α values (|α| > 10)")
        for i in np.where(large_alpha_mask)[0]:
            p = p_values[i]
            alpha = alpha_values[i]
            tau_cr = tau_cr_values[i]
            print(f"  p = {p:.4f}: α = {alpha:.3f}, τ_cr = {tau_cr:.2e}")
    
    # Issue 2: Very late τ_cr values
    late_tau_mask = tau_cr_values > 1e6
    if np.any(late_tau_mask):
        print(f"\nIssue 2: {np.sum(late_tau_mask)} very late τ_cr values (> 1e6)")
        for i in np.where(late_tau_mask)[0]:
            p = p_values[i]
            alpha = alpha_values[i]
            tau_cr = tau_cr_values[i]
            print(f"  p = {p:.4f}: τ_cr = {tau_cr:.2e}, α = {alpha:.3f}")
    
    # Issue 3: Poor fit quality
    poor_fit_mask = alpha_errors > 0.1
    if np.any(poor_fit_mask):
        print(f"\nIssue 3: {np.sum(poor_fit_mask)} poor fit quality (error > 0.1)")
        for i in np.where(poor_fit_mask)[0]:
            p = p_values[i]
            alpha = alpha_values[i]
            error = alpha_errors[i]
            print(f"  p = {p:.4f}: α = {alpha:.3f}, error = {error:.3f}")
    
    # Issue 4: Unexpected α values in liquid regime
    liquid_mask = p_values < 0.6384  # p_c' - 0.05
    if np.any(liquid_mask):
        liquid_alphas = alpha_values[liquid_mask]
        unexpected_liquid = (liquid_alphas < 0.5) | (liquid_alphas > 1.5)
        if np.any(unexpected_liquid):
            print(f"\nIssue 4: {np.sum(unexpected_liquid)} unexpected α values in liquid regime")
            for i in np.where(liquid_mask & unexpected_liquid)[0]:
                p = p_values[i]
                alpha = alpha_values[i]
                print(f"  p = {p:.4f}: α = {alpha:.3f} (expected ≈ 1.0)")

def main():
    """Main analysis function"""
    print("=== FOCUSED ALPHA ANALYSIS ===")
    print("Examining α values across the percolation spectrum")
    print()
    
    # Load and analyze results
    df = load_and_analyze_alpha()
    
    # Create visualization
    create_alpha_vs_p_plot(df)
    
    # Identify issues
    identify_analysis_issues(df)
    
    print("\n=== ANALYSIS COMPLETE ===")
    print("Check alpha_analysis_focus.png for visualization")

if __name__ == "__main__":
    main()
