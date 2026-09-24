#!/usr/bin/env python3
"""
Plot α vs p and δ vs p from p_output.csv with MSD smoothing

This script calculates and plots:
1. α vs p (anomalous diffusion exponent) with lag-time averaged MSD
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

def smooth_msd_lag_time_averaging(msd, window_size=10):
    """
    Smooth MSD using lag-time averaging
    
    Parameters:
    - msd: raw MSD data
    - window_size: number of points to average over
    
    Returns:
    - msd_smoothed: smoothed MSD data
    """
    msd_smoothed = np.full_like(msd, np.nan)
    
    # Handle edge cases
    half_window = window_size // 2
    
    for i in range(len(msd)):
        start_idx = max(0, i - half_window)
        end_idx = min(len(msd), i + half_window + 1)
        
        # Average over the window
        window_data = msd[start_idx:end_idx]
        if len(window_data) > 0:
            msd_smoothed[i] = np.mean(window_data)
    
    return msd_smoothed

def calculate_alpha_for_p_smoothed(t, msd, p, p_c_prime=0.6884, smoothing_window=15):
    """Calculate α for a given p-value using smoothed MSD data"""
    
    # First, smooth the MSD data using lag-time averaging
    msd_smoothed = smooth_msd_lag_time_averaging(msd, window_size=smoothing_window)
    
    # Calculate local α from smoothed data
    log_t = np.log10(t[1:])  # Skip t=0
    log_msd = np.log10(msd_smoothed[1:])  # Skip MSD=0
    
    alpha_local = np.full_like(t, np.nan)
    window_size = min(15, len(log_t) // 4)
    if window_size < 5:
        window_size = 5
    
    for i in range(window_size, len(log_t) - window_size):
        window_start = i - window_size // 2
        window_end = i + window_size // 2
        t_window = log_t[window_start:window_end]
        msd_window = log_msd[window_start:window_end]
        
        # Check for valid data
        if np.all(np.isfinite(msd_window)) and np.all(np.isfinite(t_window)):
            coeffs = np.polyfit(t_window, msd_window, 1)
            alpha_local[i+1] = coeffs[0]
    
    valid_mask = np.isfinite(alpha_local)
    if not np.any(valid_mask):
        return np.nan, np.nan, np.nan, msd_smoothed
    
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
                return alpha_mean, alpha_std, t_valid[start_idx], msd_smoothed
    
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
                return alpha_mean, alpha_std, t_valid[start_idx], msd_smoothed
    
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
                return alpha_mean, alpha_std, t_valid[start_idx], msd_smoothed
    
    # Fallback: use overall mean in valid region
    alpha_mean = np.mean(alpha_valid)
    alpha_std = np.std(alpha_valid)
    return alpha_mean, alpha_std, t_valid[len(t_valid)//2], msd_smoothed

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

def analyze_all_p_values_smoothed():
    """Analyze all p-values to get α and δ with smoothed MSD"""
    
    print("=== α vs p and δ vs p ANALYSIS (with MSD smoothing) ===")
    print("Calculating α and δ for all p-values using lag-time averaged MSD")
    print("=" * 70)
    
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
                
                # Calculate α with smoothed MSD
                alpha_mean, alpha_std, tau_region, msd_smoothed = calculate_alpha_for_p_smoothed(t, msd, p)
                
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

def plot_smoothed_vs_raw_comparison(data, p_values, t):
    """Plot comparison of raw vs smoothed MSD for selected p-values"""
    
    selected_p = [0.0, 0.3116, 0.6884, 0.7484]
    
    fig, axes = plt.subplots(2, 2, figsize=(16, 12))
    fig.suptitle('Raw vs Smoothed MSD Comparison', fontsize=16)
    
    for i, p in enumerate(selected_p):
        ax = axes[i//2, i%2]
        
        msd_col = f'MSD_{p}'
        if msd_col in data.columns:
            msd = data[msd_col].values
            msd_smoothed = smooth_msd_lag_time_averaging(msd, window_size=15)
            
            # Determine regime
            p_c_prime = 0.6884
            if p < p_c_prime - 0.05:
                regime = "LIQUID"
            elif abs(p - p_c_prime) < 0.05:
                regime = "CRITICAL"
            else:
                regime = "SOLID"
            
            # Plot raw and smoothed
            ax.loglog(t, msd, 'b-', alpha=0.5, linewidth=1, label='Raw MSD')
            ax.loglog(t, msd_smoothed, 'r-', linewidth=2, label='Smoothed MSD')
            
            ax.set_xlabel('Time τ')
            ax.set_ylabel('MSD')
            ax.set_title(f'p = {p:.4f} ({regime})')
            ax.legend()
            ax.grid(True, alpha=0.3)
    
    plt.tight_layout()
    
    # Save plot
    output_dir = "../paper_figures"
    os.makedirs(output_dir, exist_ok=True)
    plt.savefig(f"{output_dir}/msd_smoothing_comparison.png", 
                dpi=300, bbox_inches='tight')
    
    return fig

def plot_alpha_delta_vs_p_smoothed(df):
    """Plot α vs p and δ vs p with smoothed data"""
    
    fig, axes = plt.subplots(2, 2, figsize=(16, 12))
    fig.suptitle('α vs p and δ vs p Analysis (with MSD Smoothing)', fontsize=16)
    
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
                color='black', alpha=0.7, label='Empirical α (smoothed)')
    
    # Theoretical values
    p_theory = np.linspace(0, 1, 100)
    alpha_theory = [theoretical_alpha(p) for p in p_theory]
    ax1.plot(p_theory, alpha_theory, 'r--', linewidth=2, label='Theoretical α')
    
    # Regime boundaries
    ax1.axvline(x=p_c_prime - 0.05, color='gray', linestyle=':', alpha=0.7, label='Liquid-Critical boundary')
    ax1.axvline(x=p_c_prime + 0.05, color='gray', linestyle=':', alpha=0.7, label='Critical-Solid boundary')
    
    ax1.set_xlabel('p')
    ax1.set_ylabel('α')
    ax1.set_title('α vs p (with MSD smoothing)')
    ax1.legend()
    ax1.grid(True, alpha=0.3)
    
    # Plot 2: δ vs p
    ax2 = axes[0, 1]
    
    # Empirical values with error bars
    ax2.errorbar(df['p'], df['delta_empirical'], yerr=df['delta_std'], 
                fmt='s', capsize=5, capthick=2, markersize=6, 
                color='black', alpha=0.7, label='Empirical δ (smoothed)')
    
    # Theoretical values
    delta_theory = [theoretical_delta(p) for p in p_theory]
    ax2.plot(p_theory, delta_theory, 'r--', linewidth=2, label='Theoretical δ')
    
    # Regime boundaries
    ax2.axvline(x=p_c_prime - 0.05, color='gray', linestyle=':', alpha=0.7, label='Liquid-Critical boundary')
    ax2.axvline(x=p_c_prime + 0.05, color='gray', linestyle=':', alpha=0.7, label='Critical-Solid boundary')
    
    ax2.set_xlabel('p')
    ax2.set_ylabel('δ')
    ax2.set_title('δ vs p (with MSD smoothing)')
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
    ax3.set_title('α Error vs p (with MSD smoothing)')
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
    ax4.set_title('δ Error vs p (with MSD smoothing)')
    ax4.legend()
    ax4.grid(True, alpha=0.3)
    
    plt.tight_layout()
    
    # Save plot
    output_dir = "../paper_figures"
    os.makedirs(output_dir, exist_ok=True)
    plt.savefig(f"{output_dir}/alpha_delta_vs_p_smoothed.png", 
                dpi=300, bbox_inches='tight')
    
    return fig

def main():
    """Main analysis function"""
    print("=== α vs p and δ vs p ANALYSIS (with MSD smoothing) ===")
    print("Calculating and plotting α and δ across the percolation transition")
    print("Using lag-time averaging for MSD smoothing")
    print("=" * 70)
    
    try:
        # Load data
        data, p_values, t = load_p_output_data()
        
        # Create smoothing comparison plot
        print("Creating MSD smoothing comparison plot...")
        fig0 = plot_smoothed_vs_raw_comparison(data, p_values, t)
        plt.close(fig0)
        
        # Analyze all p-values with smoothing
        df = analyze_all_p_values_smoothed()
        
        # Save results
        output_file = "../paper_figures/alpha_delta_results_smoothed.csv"
        df.to_csv(output_file, index=False)
        print(f"\nResults saved to: {output_file}")
        
        # Create plots
        print("\nCreating plots...")
        fig1 = plot_alpha_delta_vs_p_smoothed(df)
        plt.close(fig1)
        
        # Print summary statistics
        print(f"\n{'='*70}")
        print("SUMMARY STATISTICS (with MSD smoothing)")
        print(f"{'='*70}")
        
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