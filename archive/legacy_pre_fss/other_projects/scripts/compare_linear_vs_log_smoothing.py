#!/usr/bin/env python3
"""
Compare Linear vs Log-Space Lag-Time Averaging

This script compares:
1. Linear space lag-time averaging
2. Log-space lag-time averaging
3. Simple analysis method (t > 1e4)
4. How they affect α calculations
"""

import numpy as np
import matplotlib.pyplot as plt
import pandas as pd
import os

def load_p_output_data():
    """Load the p_output.csv data with MSD_ prefix headers"""
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

def simple_analysis(t, msd_data, p_values):
    """Simple analysis method: t > 1e4 for all p-values"""
    print("=== SIMPLE ANALYSIS (t > 1e4) ===")
    
    # Define time region
    t_threshold = 1e4
    id_mask = t > t_threshold
    
    alpha_exponent = []
    
    for i, p in enumerate(p_values):
        msd_col = f'MSD_{p}'
        if msd_col in msd_data.columns:
            msd = msd_data[msd_col].values
            
            # Filter data for t > 1e4
            t_filtered = t[id_mask]
            msd_filtered = msd[id_mask]
            
            # Remove any NaN or infinite values
            valid_mask = np.isfinite(msd_filtered) & (msd_filtered > 0)
            t_valid = t_filtered[valid_mask]
            msd_valid = msd_filtered[valid_mask]
            
            if len(t_valid) >= 5:
                # Fit log(MSD) = α*log(t) + b
                log_t = np.log10(t_valid)
                log_msd = np.log10(msd_valid)
                
                coeffs = np.polyfit(log_t, log_msd, 1)
                alpha = coeffs[0]
                alpha_exponent.append(alpha)
                
                print(f"p = {p:.4f}: α = {alpha:.6f}")
            else:
                alpha_exponent.append(np.nan)
                print(f"p = {p:.4f}: Insufficient data")
    
    return alpha_exponent

def smooth_msd_linear(msd, window_size=10):
    """Smooth MSD using linear space lag-time averaging"""
    msd_smoothed = np.full_like(msd, np.nan)
    half_window = window_size // 2
    
    for i in range(len(msd)):
        start_idx = max(0, i - half_window)
        end_idx = min(len(msd), i + half_window + 1)
        window_data = msd[start_idx:end_idx]
        if len(window_data) > 0:
            msd_smoothed[i] = np.mean(window_data)
    
    return msd_smoothed

def smooth_msd_log(msd, window_size=10):
    """Smooth MSD using log-space lag-time averaging"""
    # Convert to log space first
    log_msd = np.log10(msd)
    
    # Average in log space
    log_msd_smoothed = np.full_like(log_msd, np.nan)
    half_window = window_size // 2
    
    for i in range(len(log_msd)):
        start_idx = max(0, i - half_window)
        end_idx = min(len(log_msd), i + half_window + 1)
        window_data = log_msd[start_idx:end_idx]
        if len(window_data) > 0:
            log_msd_smoothed[i] = np.mean(window_data)
    
    # Convert back to linear space
    return 10**log_msd_smoothed

def calculate_alpha_from_region(t, msd, region_start, region_end):
    """Calculate α from a specific region"""
    region_mask = (t >= region_start) & (t <= region_end)
    t_region = t[region_mask]
    msd_region = msd[region_mask]
    
    if len(t_region) < 5:
        return np.nan, np.nan, np.nan
    
    # Remove any NaN or infinite values
    valid_mask = np.isfinite(msd_region) & (msd_region > 0)
    t_valid = t_region[valid_mask]
    msd_valid = msd_region[valid_mask]
    
    if len(t_valid) < 5:
        return np.nan, np.nan, np.nan
    
    # Calculate in log space
    log_t_region = np.log10(t_valid)
    log_msd_region = np.log10(msd_valid)
    
    # Fit log(MSD) = α*log(t) + b
    coeffs = np.polyfit(log_t_region, log_msd_region, 1)
    alpha = coeffs[0]
    intercept = coeffs[1]
    
    # Calculate R²
    y_pred = alpha * log_t_region + intercept
    ss_res = np.sum((log_msd_region - y_pred) ** 2)
    ss_tot = np.sum((log_msd_region - np.mean(log_msd_region)) ** 2)
    r_squared = 1 - (ss_res / ss_tot)
    
    return alpha, r_squared, intercept

def compare_smoothing_methods():
    """Compare linear vs log-space smoothing"""
    
    print("=== LINEAR vs LOG-SPACE SMOOTHING COMPARISON ===")
    print("Comparing lag-time averaging methods")
    print("=" * 60)
    
    # Load data
    data, p_values, t = load_p_output_data()
    
    # Select key p-values for comparison
    key_p_values = [0.0, 0.3116, 0.6884, 0.7484]  # Representative from each regime
    
    results = []
    
    for p in key_p_values:
        msd_col = f'MSD_{p}'
        if msd_col not in data.columns:
            continue
            
        msd = data[msd_col].values
        
        # Determine regime
        p_c_prime = 0.6884
        if p < p_c_prime - 0.05:
            regime = "LIQUID"
            region_start, region_end = 1e5, 1e6  # Later time region
        elif abs(p - p_c_prime) < 0.05:
            regime = "CRITICAL"
            region_start, region_end = 1e4, 1e5  # Middle time region
        else:
            regime = "SOLID"
            region_start, region_end = 1e4, 1e6  # Plateau region
        
        print(f"\nAnalyzing p = {p:.4f} ({regime} regime)")
        print(f"  Region: t = {region_start:.0e} to {region_end:.0e}")
        
        # Apply both smoothing methods
        msd_linear = smooth_msd_linear(msd, window_size=15)
        msd_log = smooth_msd_log(msd, window_size=15)
        
        # Calculate α for each method
        alpha_raw, r2_raw, intercept_raw = calculate_alpha_from_region(t, msd, region_start, region_end)
        alpha_linear, r2_linear, intercept_linear = calculate_alpha_from_region(t, msd_linear, region_start, region_end)
        alpha_log, r2_log, intercept_log = calculate_alpha_from_region(t, msd_log, region_start, region_end)
        
        # Theoretical α
        if regime == "LIQUID":
            alpha_theory = 1.0
        elif regime == "CRITICAL":
            alpha_theory = 0.53
        else:
            alpha_theory = 0.0
        
        # Store results
        result = {
            'p': p,
            'regime': regime,
            'alpha_raw': alpha_raw,
            'alpha_linear': alpha_linear,
            'alpha_log': alpha_log,
            'alpha_theory': alpha_theory,
            'r2_raw': r2_raw,
            'r2_linear': r2_linear,
            'r2_log': r2_log,
            'error_raw': abs(alpha_raw - alpha_theory),
            'error_linear': abs(alpha_linear - alpha_theory),
            'error_log': abs(alpha_log - alpha_theory)
        }
        results.append(result)
        
        print(f"  Raw:      α = {alpha_raw:.6f}, R² = {r2_raw:.6f}, Error = {abs(alpha_raw - alpha_theory):.6f}")
        print(f"  Linear:   α = {alpha_linear:.6f}, R² = {r2_linear:.6f}, Error = {abs(alpha_linear - alpha_theory):.6f}")
        print(f"  Log:      α = {alpha_log:.6f}, R² = {r2_log:.6f}, Error = {abs(alpha_log - alpha_theory):.6f}")
        print(f"  Theory:   α = {alpha_theory}")
    
    return pd.DataFrame(results)

def plot_smoothing_comparison(data, p_values, t):
    """Plot comparison of smoothing methods"""
    
    # Select key p-values
    key_p_values = [0.0, 0.3116, 0.6884, 0.7484]
    
    fig, axes = plt.subplots(2, 2, figsize=(16, 12))
    fig.suptitle('Linear vs Log-Space Smoothing Comparison', fontsize=16)
    
    for i, p in enumerate(key_p_values):
        ax = axes[i//2, i%2]
        
        msd_col = f'MSD_{p}'
        if msd_col not in data.columns:
            continue
            
        msd = data[msd_col].values
        
        # Apply both smoothing methods
        msd_linear = smooth_msd_linear(msd, window_size=15)
        msd_log = smooth_msd_log(msd, window_size=15)
        
        # Determine regime
        p_c_prime = 0.6884
        if p < p_c_prime - 0.05:
            regime = "LIQUID"
        elif abs(p - p_c_prime) < 0.05:
            regime = "CRITICAL"
        else:
            regime = "SOLID"
        
        # Plot all three curves
        ax.loglog(t, msd, 'b-', alpha=0.5, linewidth=1, label='Raw MSD')
        ax.loglog(t, msd_linear, 'g-', linewidth=2, label='Linear smoothing')
        ax.loglog(t, msd_log, 'r-', linewidth=2, label='Log smoothing')
        
        ax.set_xlabel('Time τ')
        ax.set_ylabel('MSD')
        ax.set_title(f'p = {p:.4f} ({regime})')
        ax.legend()
        ax.grid(True, alpha=0.3)
    
    plt.tight_layout()
    
    # Save plot
    output_dir = "../paper_figures"
    os.makedirs(output_dir, exist_ok=True)
    plt.savefig(f"{output_dir}/smoothing_comparison.png", 
                dpi=300, bbox_inches='tight')
    
    return fig

def plot_phase_transition(data, p_values, t):
    """Plot the phase transition using simple analysis"""
    
    print("\n=== PHASE TRANSITION ANALYSIS ===")
    
    # Simple analysis for all p-values
    alpha_exponent = simple_analysis(t, data, p_values)
    
    # Create the phase transition plot
    fig, ax = plt.subplots(figsize=(12, 8))
    
    # Filter out NaN values
    valid_indices = [i for i, alpha in enumerate(alpha_exponent) if not np.isnan(alpha)]
    valid_p = [p_values[i] for i in valid_indices]
    valid_alpha = [alpha_exponent[i] for i in valid_indices]
    
    # Plot α vs p
    ax.plot(valid_p, valid_alpha, 'o-', linewidth=2, markersize=6, label='Empirical α')
    
    # Add theoretical predictions
    p_c_prime = 0.6884
    p_theory = np.array([0, p_c_prime - 0.1, p_c_prime, p_c_prime + 0.1, 1.0])
    alpha_theory = np.array([1.0, 1.0, 0.53, 0.0, 0.0])  # Liquid, Critical, Solid
    
    ax.plot(p_theory, alpha_theory, 'r--', linewidth=2, label='Theoretical α')
    
    # Add vertical line at critical point
    ax.axvline(x=p_c_prime, color='k', linestyle=':', alpha=0.7, label=f'p_c\' = {p_c_prime}')
    
    # Add region labels
    ax.text(0.2, 0.9, 'LIQUID\nα ≈ 1', ha='center', va='center', 
            bbox=dict(boxstyle="round,pad=0.3", facecolor="lightblue", alpha=0.7))
    ax.text(p_c_prime, 0.3, 'CRITICAL\nα ≈ 0.53', ha='center', va='center',
            bbox=dict(boxstyle="round,pad=0.3", facecolor="lightyellow", alpha=0.7))
    ax.text(0.8, 0.1, 'SOLID\nα ≈ 0', ha='center', va='center',
            bbox=dict(boxstyle="round,pad=0.3", facecolor="lightcoral", alpha=0.7))
    
    ax.set_xlabel('p (occupation probability)')
    ax.set_ylabel('α (anomalous diffusion exponent)')
    ax.set_title('Phase Transition: α vs p (Simple Analysis: t > 10⁴)')
    ax.legend()
    ax.grid(True, alpha=0.3)
    
    # Save plot
    output_dir = "../paper_figures"
    os.makedirs(output_dir, exist_ok=True)
    plt.savefig(f"{output_dir}/phase_transition_simple.png", 
                dpi=300, bbox_inches='tight')
    
    print(f"Phase transition plot saved to: {output_dir}/phase_transition_simple.png")
    
    return fig, valid_p, valid_alpha

def plot_alpha_comparison(df):
    """Plot α comparison between methods"""
    
    fig, axes = plt.subplots(2, 2, figsize=(16, 12))
    fig.suptitle('α Comparison: Raw vs Linear vs Log Smoothing', fontsize=16)
    
    # Plot 1: α values comparison
    ax1 = axes[0, 0]
    x_pos = np.arange(len(df))
    width = 0.25
    
    ax1.bar(x_pos - width, df['alpha_raw'], width, label='Raw', alpha=0.7)
    ax1.bar(x_pos, df['alpha_linear'], width, label='Linear smoothing', alpha=0.7)
    ax1.bar(x_pos + width, df['alpha_log'], width, label='Log smoothing', alpha=0.7)
    
    # Add theoretical values
    ax1.plot(x_pos, df['alpha_theory'], 'ro', markersize=8, label='Theoretical')
    
    ax1.set_xlabel('p-value')
    ax1.set_ylabel('α')
    ax1.set_title('α Values Comparison')
    ax1.set_xticks(x_pos)
    ax1.set_xticklabels([f'{p:.4f}' for p in df['p']])
    ax1.legend()
    ax1.grid(True, alpha=0.3)
    
    # Plot 2: Error comparison
    ax2 = axes[0, 1]
    ax2.bar(x_pos - width, df['error_raw'], width, label='Raw', alpha=0.7)
    ax2.bar(x_pos, df['error_linear'], width, label='Linear smoothing', alpha=0.7)
    ax2.bar(x_pos + width, df['error_log'], width, label='Log smoothing', alpha=0.7)
    
    ax2.set_xlabel('p-value')
    ax2.set_ylabel('|α - α_theory|')
    ax2.set_title('Error Comparison')
    ax2.set_xticks(x_pos)
    ax2.set_xticklabels([f'{p:.4f}' for p in df['p']])
    ax2.legend()
    ax2.grid(True, alpha=0.3)
    
    # Plot 3: R² comparison
    ax3 = axes[1, 0]
    ax3.bar(x_pos - width, df['r2_raw'], width, label='Raw', alpha=0.7)
    ax3.bar(x_pos, df['r2_linear'], width, label='Linear smoothing', alpha=0.7)
    ax3.bar(x_pos + width, df['r2_log'], width, label='Log smoothing', alpha=0.7)
    
    ax3.set_xlabel('p-value')
    ax3.set_ylabel('R²')
    ax3.set_title('R² Comparison')
    ax3.set_xticks(x_pos)
    ax3.set_xticklabels([f'{p:.4f}' for p in df['p']])
    ax3.legend()
    ax3.grid(True, alpha=0.3)
    
    # Plot 4: Summary table
    ax4 = axes[1, 1]
    ax4.axis('off')
    
    # Create summary table
    summary_data = []
    for _, row in df.iterrows():
        summary_data.append([
            f"{row['p']:.4f}",
            row['regime'],
            f"{row['alpha_raw']:.3f}",
            f"{row['alpha_linear']:.3f}",
            f"{row['alpha_log']:.3f}",
            f"{row['alpha_theory']:.3f}",
            f"{row['error_log']:.3f}"
        ])
    
    table = ax4.table(cellText=summary_data,
                     colLabels=['p', 'Regime', 'Raw α', 'Linear α', 'Log α', 'Theory α', 'Log Error'],
                     cellLoc='center',
                     loc='center')
    table.auto_set_font_size(False)
    table.set_fontsize(10)
    table.scale(1, 2)
    
    ax4.set_title('Summary Table')
    
    plt.tight_layout()
    
    # Save plot
    output_dir = "../paper_figures"
    os.makedirs(output_dir, exist_ok=True)
    plt.savefig(f"{output_dir}/alpha_comparison.png", 
                dpi=300, bbox_inches='tight')
    
    return fig

def main():
    """Main analysis function"""
    print("=== LINEAR vs LOG-SPACE SMOOTHING COMPARISON ===")
    print("Comparing lag-time averaging methods and their effect on α")
    print("=" * 60)
    
    try:
        # Load data
        data, p_values, t = load_p_output_data()
        
        print(f"Loaded data with {len(p_values)} p-values: {p_values[:5]}...{p_values[-5:]}")
        
        # Create phase transition plot (simple analysis)
        print("\nCreating phase transition plot...")
        fig1, valid_p, valid_alpha = plot_phase_transition(data, p_values, t)
        plt.close(fig1)
        
        # Create smoothing comparison plot
        print("Creating smoothing comparison plot...")
        fig2 = plot_smoothing_comparison(data, p_values, t)
        plt.close(fig2)
        
        # Compare methods
        df = compare_smoothing_methods()
        
        # Save results
        output_file = "../paper_figures/smoothing_comparison_results.csv"
        df.to_csv(output_file, index=False)
        print(f"\nResults saved to: {output_file}")
        
        # Create α comparison plot
        print("\nCreating α comparison plot...")
        fig3 = plot_alpha_comparison(df)
        plt.close(fig3)
        
        # Print summary statistics
        print(f"\n{'='*60}")
        print("SUMMARY STATISTICS")
        print(f"{'='*60}")
        
        print(f"\nMean errors:")
        print(f"  Raw:      {df['error_raw'].mean():.6f} ± {df['error_raw'].std():.6f}")
        print(f"  Linear:   {df['error_linear'].mean():.6f} ± {df['error_linear'].std():.6f}")
        print(f"  Log:      {df['error_log'].mean():.6f} ± {df['error_log'].std():.6f}")
        
        print(f"\nMean R²:")
        print(f"  Raw:      {df['r2_raw'].mean():.6f} ± {df['r2_raw'].std():.6f}")
        print(f"  Linear:   {df['r2_linear'].mean():.6f} ± {df['r2_linear'].std():.6f}")
        print(f"  Log:      {df['r2_log'].mean():.6f} ± {df['r2_log'].std():.6f}")
        
        # Determine best method
        best_method = 'Log' if df['error_log'].mean() < df['error_linear'].mean() else 'Linear'
        print(f"\nBest method: {best_method} smoothing")
        
        print("\nAnalysis complete!")
        print("Check ../paper_figures/ for plots and results")
        
    except Exception as e:
        print(f"Error in analysis: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    main() 