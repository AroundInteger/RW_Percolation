#!/usr/bin/env python3
"""
Plot α vs p and δ vs p from p_output.csv

This script calculates and plots:
1. α vs p (anomalous diffusion exponent)
2. δ vs p (phase angle)
3. Theoretical predictions vs empirical values
"""

import numpy as np
import matplotlib.pyplot as plt
import pandas as pd
import os
from scipy.signal import savgol_filter
from scipy.optimize import curve_fit

def load_p_output_data():
    """Load the p_output.csv data"""
    filepath = "/Users/rowanbrown/Documents/GitHub/RW_Percolation/matlab/p_output.csv"
    
    if not os.path.exists(filepath):
        raise FileNotFoundError(f"Data file not found: {filepath}")
    
    # Load data
    data = pd.read_csv(filepath)
    
    # Extract p-values from headers (remove 'MSD_' prefix)
    p_values = []
    for col in data.columns:
        if col.startswith('MSD_'):
            p_str = col[4:]  # Remove 'MSD_' prefix
            try:
                p_values.append(float(p_str))
            except ValueError:
                print(f"Warning: Could not parse p-value from column {col}")
    
    # Create time array (steps)
    t = np.arange(len(data))
    
    return data, p_values, t

def calculate_alpha_for_p(t, msd, p, p_c_prime=0.6884):
    """Calculate α for a given p-value using optimal region identification"""
    
    # Calculate local α
    log_t = np.log10(t[1:])  # Skip t=0
    log_msd = np.log10(msd[1:])  # Skip MSD=0
    
    alpha_local = np.full_like(t, np.nan)
    window_size = min(15, len(log_t) // 4)
    if window_size < 5:
        window_size = 5
    
    for i in range(window_size, len(log_t) - window_size):
        window_start = i - window_size // 2
        window_end = i + window_size // 2
        t_window = log_t[window_start:window_end]
        msd_window = log_msd[window_start:window_end]
        coeffs = np.polyfit(t_window, msd_window, 1)
        alpha_local[i+1] = coeffs[0]
    
    valid_mask = np.isfinite(alpha_local)
    if not np.any(valid_mask):
        return np.nan, np.nan, np.nan
    
    alpha_valid = alpha_local[valid_mask]
    t_valid = t[valid_mask]
    
    # Determine regime and optimal α calculation strategy
    if p < p_c_prime - 0.05:  # Liquid regime
        # Look for stable α ≈ 1.0 in later time regions
        stable_mask = (np.abs(alpha_valid - 1.0) < 0.2) & (t_valid > t_valid[len(t_valid)//3])
        if np.any(stable_mask):
            stable_indices = np.where(stable_mask)[0]
            if len(stable_indices) >= 10:
                start_idx = stable_indices[len(stable_indices)//2]
                end_idx = min(start_idx + 20, len(alpha_valid))
                alpha_region = alpha_valid[start_idx:end_idx]
                alpha_mean = np.mean(alpha_region)
                alpha_std = np.std(alpha_region)
                return alpha_mean, alpha_std, t_valid[start_idx]
    
    elif abs(p - p_c_prime) < 0.05:  # Critical regime
        # Look for stable α ≈ 0.5 in middle time regions
        stable_mask = (np.abs(alpha_valid - 0.5) < 0.3) & (t_valid > t_valid[len(t_valid)//4]) & (t_valid < t_valid[3*len(t_valid)//4])
        if np.any(stable_mask):
            stable_indices = np.where(stable_mask)[0]
            if len(stable_indices) >= 10:
                start_idx = stable_indices[len(stable_indices)//2]
                end_idx = min(start_idx + 20, len(alpha_valid))
                alpha_region = alpha_valid[start_idx:end_idx]
                alpha_mean = np.mean(alpha_region)
                alpha_std = np.std(alpha_region)
                return alpha_mean, alpha_std, t_valid[start_idx]
    
    else:  # Solid regime
        # Look for stable α ≈ 0.0 in early time regions
        stable_mask = (np.abs(alpha_valid - 0.0) < 0.3) & (t_valid < t_valid[len(t_valid)//3])
        if np.any(stable_mask):
            stable_indices = np.where(stable_mask)[0]
            if len(stable_indices) >= 10:
                start_idx = stable_indices[len(stable_indices)//2]
                end_idx = min(start_idx + 20, len(alpha_valid))
                alpha_region = alpha_valid[start_idx:end_idx]
                alpha_mean = np.mean(alpha_region)
                alpha_std = np.std(alpha_region)
                return alpha_mean, alpha_std, t_valid[start_idx]
    
    # Fallback: use overall mean in valid region
    alpha_mean = np.mean(alpha_valid)
    alpha_std = np.std(alpha_valid)
    return alpha_mean, alpha_std, t_valid[len(t_valid)//2]

def calculate_delta_from_alpha(alpha):
    """Calculate δ from α using the relationship δ = πα/2"""
    return np.pi * alpha / 2

def theoretical_alpha(p, p_c_prime=0.6884):
    """Theoretical α values based on regime"""
    if p < p_c_prime - 0.05:
        return 1.0  # Liquid
    elif abs(p - p_c_prime) < 0.05:
        return 0.53  # Critical
    else:
        return 0.0  # Solid

def theoretical_delta(p, p_c_prime=0.6884):
    """Theoretical δ values based on regime"""
    alpha_theory = theoretical_alpha(p, p_c_prime)
    return calculate_delta_from_alpha(alpha_theory)

def analyze_all_p_values():
    """Analyze all p-values to get α and δ"""
    
    print("=== α vs p and δ vs p ANALYSIS ===")
    print("Calculating α and δ for all p-values")
    print("=" * 60)
    
    # Load data
    data, p_values, t = load_p_output_data()
    
    print(f"Loaded data with {len(p_values)} p-values")
    print(f"Time range: {t[0]} to {t[-1]} steps")
    print()
    
    results = []
    
    # Analyze each p-value
    for i, p in enumerate(p_values):
        try:
            print(f"Analyzing p = {p:.4f} ({i+1}/{len(p_values)})")
            
            # Extract MSD data for this p-value
            msd_col = f'MSD_{p}'
            if msd_col in data.columns:
                msd = data[msd_col].values
                
                # Calculate α
                alpha_mean, alpha_std, tau_region = calculate_alpha_for_p(t, msd, p)
                
                # Calculate δ
                delta_mean = calculate_delta_from_alpha(alpha_mean)
                delta_std = np.pi * alpha_std / 2
                
                # Theoretical values
                alpha_theory = theoretical_alpha(p)
                delta_theory = theoretical_delta(p)
                
                # Determine regime
                p_c_prime = 0.6884
                if p < p_c_prime - 0.05:
                    regime = "LIQUID"
                elif abs(p - p_c_prime) < 0.05:
                    regime = "CRITICAL"
                else:
                    regime = "SOLID"
                
                # Store results
                result = {
                    'p': p,
                    'regime': regime,
                    'alpha_empirical': alpha_mean,
                    'alpha_std': alpha_std,
                    'alpha_theory': alpha_theory,
                    'delta_empirical': delta_mean,
                    'delta_std': delta_std,
                    'delta_theory': delta_theory,
                    'tau_region': tau_region,
                    'alpha_error': abs(alpha_mean - alpha_theory),
                    'delta_error': abs(delta_mean - delta_theory)
                }
                results.append(result)
                
                print(f"  Regime: {regime}, α = {alpha_mean:.3f} ± {alpha_std:.3f}, δ = {delta_mean:.3f} ± {delta_std:.3f}")
                
            else:
                print(f"  Warning: Column {msd_col} not found")
                
        except Exception as e:
            print(f"  Error analyzing p = {p:.4f}: {e}")
            continue
    
    return pd.DataFrame(results)

def plot_alpha_delta_vs_p(df):
    """Plot α vs p and δ vs p"""
    
    fig, axes = plt.subplots(2, 2, figsize=(16, 12))
    fig.suptitle('α vs p and δ vs p Analysis', fontsize=16)
    
    # Determine regime colors
    p_c_prime = 0.6884
    colors = []
    for p in df['p']:
        if p < p_c_prime - 0.05:
            colors.append('blue')  # Liquid
        elif abs(p - p_c_prime) < 0.05:
            colors.append('orange')  # Critical
        else:
            colors.append('red')  # Solid
    
    # Plot 1: α vs p
    ax1 = axes[0, 0]
    
    # Empirical values with error bars
    ax1.errorbar(df['p'], df['alpha_empirical'], yerr=df['alpha_std'], 
                fmt='o', capsize=5, capthick=2, markersize=6, 
                color='black', alpha=0.7, label='Empirical α')
    
    # Theoretical values
    p_theory = np.linspace(0, 1, 100)
    alpha_theory = [theoretical_alpha(p) for p in p_theory]
    ax1.plot(p_theory, alpha_theory, 'r--', linewidth=2, label='Theoretical α')
    
    # Regime boundaries
    ax1.axvline(x=p_c_prime - 0.05, color='gray', linestyle=':', alpha=0.7, label='Liquid-Critical boundary')
    ax1.axvline(x=p_c_prime + 0.05, color='gray', linestyle=':', alpha=0.7, label='Critical-Solid boundary')
    
    ax1.set_xlabel('p')
    ax1.set_ylabel('α')
    ax1.set_title('α vs p')
    ax1.legend()
    ax1.grid(True, alpha=0.3)
    
    # Plot 2: δ vs p
    ax2 = axes[0, 1]
    
    # Empirical values with error bars
    ax2.errorbar(df['p'], df['delta_empirical'], yerr=df['delta_std'], 
                fmt='s', capsize=5, capthick=2, markersize=6, 
                color='black', alpha=0.7, label='Empirical δ')
    
    # Theoretical values
    delta_theory = [theoretical_delta(p) for p in p_theory]
    ax2.plot(p_theory, delta_theory, 'r--', linewidth=2, label='Theoretical δ')
    
    # Regime boundaries
    ax2.axvline(x=p_c_prime - 0.05, color='gray', linestyle=':', alpha=0.7, label='Liquid-Critical boundary')
    ax2.axvline(x=p_c_prime + 0.05, color='gray', linestyle=':', alpha=0.7, label='Critical-Solid boundary')
    
    ax2.set_xlabel('p')
    ax2.set_ylabel('δ')
    ax2.set_title('δ vs p')
    ax2.legend()
    ax2.grid(True, alpha=0.3)
    
    # Plot 3: α error vs p
    ax3 = axes[1, 0]
    
    # Color by regime
    for regime, color in [('LIQUID', 'blue'), ('CRITICAL', 'orange'), ('SOLID', 'red')]:
        regime_data = df[df['regime'] == regime]
        if len(regime_data) > 0:
            ax3.scatter(regime_data['p'], regime_data['alpha_error'], 
                       color=color, s=50, alpha=0.7, label=f'{regime} regime')
    
    ax3.set_xlabel('p')
    ax3.set_ylabel('|α_empirical - α_theory|')
    ax3.set_title('α Error vs p')
    ax3.legend()
    ax3.grid(True, alpha=0.3)
    
    # Plot 4: δ error vs p
    ax4 = axes[1, 1]
    
    # Color by regime
    for regime, color in [('LIQUID', 'blue'), ('CRITICAL', 'orange'), ('SOLID', 'red')]:
        regime_data = df[df['regime'] == regime]
        if len(regime_data) > 0:
            ax4.scatter(regime_data['p'], regime_data['delta_error'], 
                       color=color, s=50, alpha=0.7, label=f'{regime} regime')
    
    ax4.set_xlabel('p')
    ax4.set_ylabel('|δ_empirical - δ_theory|')
    ax4.set_title('δ Error vs p')
    ax4.legend()
    ax4.grid(True, alpha=0.3)
    
    plt.tight_layout()
    
    # Save plot
    output_dir = "../paper_figures"
    os.makedirs(output_dir, exist_ok=True)
    plt.savefig(f"{output_dir}/alpha_delta_vs_p.png", 
                dpi=300, bbox_inches='tight')
    
    return fig

def plot_regime_comparison(df):
    """Plot detailed comparison by regime"""
    
    fig, axes = plt.subplots(2, 2, figsize=(16, 12))
    fig.suptitle('Regime Comparison: α and δ Analysis', fontsize=16)
    
    regimes = ['LIQUID', 'CRITICAL', 'SOLID']
    colors = ['blue', 'orange', 'red']
    
    # Plot 1: α by regime
    ax1 = axes[0, 0]
    for i, regime in enumerate(regimes):
        regime_data = df[df['regime'] == regime]
        if len(regime_data) > 0:
            ax1.errorbar(regime_data['p'], regime_data['alpha_empirical'], 
                        yerr=regime_data['alpha_std'], fmt='o', 
                        color=colors[i], label=regime, capsize=5)
    
    # Add theoretical lines
    p_ranges = [(0, 0.6384), (0.6384, 0.7384), (0.7384, 1.0)]
    for i, (p_min, p_max) in enumerate(p_ranges):
        p_vals = np.linspace(p_min, p_max, 10)
        alpha_vals = [theoretical_alpha(p) for p in p_vals]
        ax1.plot(p_vals, alpha_vals, '--', color=colors[i], linewidth=2)
    
    ax1.set_xlabel('p')
    ax1.set_ylabel('α')
    ax1.set_title('α by Regime')
    ax1.legend()
    ax1.grid(True, alpha=0.3)
    
    # Plot 2: δ by regime
    ax2 = axes[0, 1]
    for i, regime in enumerate(regimes):
        regime_data = df[df['regime'] == regime]
        if len(regime_data) > 0:
            ax2.errorbar(regime_data['p'], regime_data['delta_empirical'], 
                        yerr=regime_data['delta_std'], fmt='s', 
                        color=colors[i], label=regime, capsize=5)
    
    # Add theoretical lines
    for i, (p_min, p_max) in enumerate(p_ranges):
        p_vals = np.linspace(p_min, p_max, 10)
        delta_vals = [theoretical_delta(p) for p in p_vals]
        ax2.plot(p_vals, delta_vals, '--', color=colors[i], linewidth=2)
    
    ax2.set_xlabel('p')
    ax2.set_ylabel('δ')
    ax2.set_title('δ by Regime')
    ax2.legend()
    ax2.grid(True, alpha=0.3)
    
    # Plot 3: α error by regime
    ax3 = axes[1, 0]
    for i, regime in enumerate(regimes):
        regime_data = df[df['regime'] == regime]
        if len(regime_data) > 0:
            ax3.scatter(regime_data['p'], regime_data['alpha_error'], 
                       color=colors[i], s=50, alpha=0.7, label=regime)
    
    ax3.set_xlabel('p')
    ax3.set_ylabel('|α_empirical - α_theory|')
    ax3.set_title('α Error by Regime')
    ax3.legend()
    ax3.grid(True, alpha=0.3)
    
    # Plot 4: δ error by regime
    ax4 = axes[1, 1]
    for i, regime in enumerate(regimes):
        regime_data = df[df['regime'] == regime]
        if len(regime_data) > 0:
            ax4.scatter(regime_data['p'], regime_data['delta_error'], 
                       color=colors[i], s=50, alpha=0.7, label=regime)
    
    ax4.set_xlabel('p')
    ax4.set_ylabel('|δ_empirical - δ_theory|')
    ax4.set_title('δ Error by Regime')
    ax4.legend()
    ax4.grid(True, alpha=0.3)
    
    plt.tight_layout()
    
    # Save plot
    output_dir = "../paper_figures"
    os.makedirs(output_dir, exist_ok=True)
    plt.savefig(f"{output_dir}/regime_comparison_alpha_delta.png", 
                dpi=300, bbox_inches='tight')
    
    return fig

def main():
    """Main analysis function"""
    print("=== α vs p and δ vs p ANALYSIS ===")
    print("Calculating and plotting α and δ across the percolation transition")
    print("=" * 60)
    
    try:
        # Analyze all p-values
        df = analyze_all_p_values()
        
        # Save results
        output_file = "../paper_figures/alpha_delta_results.csv"
        df.to_csv(output_file, index=False)
        print(f"\nResults saved to: {output_file}")
        
        # Create plots
        print("\nCreating plots...")
        fig1 = plot_alpha_delta_vs_p(df)
        plt.close(fig1)
        
        fig2 = plot_regime_comparison(df)
        plt.close(fig2)
        
        # Print summary statistics
        print(f"\n{'='*60}")
        print("SUMMARY STATISTICS")
        print(f"{'='*60}")
        
        for regime in ['LIQUID', 'CRITICAL', 'SOLID']:
            regime_data = df[df['regime'] == regime]
            if len(regime_data) > 0:
                print(f"\n{regime} regime ({len(regime_data)} p-values):")
                print(f"  Mean α error: {regime_data['alpha_error'].mean():.3f} ± {regime_data['alpha_error'].std():.3f}")
                print(f"  Mean δ error: {regime_data['delta_error'].mean():.3f} ± {regime_data['delta_error'].std():.3f}")
                print(f"  Mean α empirical: {regime_data['alpha_empirical'].mean():.3f} ± {regime_data['alpha_empirical'].std():.3f}")
                print(f"  Mean δ empirical: {regime_data['delta_empirical'].mean():.3f} ± {regime_data['delta_empirical'].std():.3f}")
        
        print(f"\nOverall statistics ({len(df)} p-values):")
        print(f"  Mean α error: {df['alpha_error'].mean():.3f} ± {df['alpha_error'].std():.3f}")
        print(f"  Mean δ error: {df['delta_error'].mean():.3f} ± {df['delta_error'].std():.3f}")
        
        print("\nAnalysis complete!")
        print("Check ../paper_figures/ for plots and results")
        
    except Exception as e:
        print(f"Error in analysis: {e}")

if __name__ == "__main__":
    main() 