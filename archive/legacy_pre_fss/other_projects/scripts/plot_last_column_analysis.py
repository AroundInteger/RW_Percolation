#!/usr/bin/env python3
"""
Plot Last Column Analysis from p_output.csv

This script takes the last column (highest p-value) and plots the MSD curve
with the current α estimation range marked.
"""

import numpy as np
import matplotlib.pyplot as plt
import pandas as pd
import os
from scipy.signal import savgol_filter

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
    """Smooth MSD using lag-time averaging"""
    msd_smoothed = np.full_like(msd, np.nan)
    half_window = window_size // 2
    
    for i in range(len(msd)):
        start_idx = max(0, i - half_window)
        end_idx = min(len(msd), i + half_window + 1)
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
        return np.nan, np.nan, np.nan, msd_smoothed, alpha_local
    
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
                return alpha_mean, alpha_std, t_valid[start_idx], msd_smoothed, alpha_local
    
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
                return alpha_mean, alpha_std, t_valid[start_idx], msd_smoothed, alpha_local
    
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
                return alpha_mean, alpha_std, t_valid[start_idx], msd_smoothed, alpha_local
    
    # Fallback: use overall mean in valid region
    alpha_mean = np.mean(alpha_valid)
    alpha_std = np.std(alpha_valid)
    return alpha_mean, alpha_std, t_valid[len(t_valid)//2], msd_smoothed, alpha_local

def plot_last_column_analysis():
    """Plot analysis of the last column (highest p-value)"""
    
    print("=== LAST COLUMN ANALYSIS ===")
    print("Analyzing the highest p-value from p_output.csv")
    print("=" * 50)
    
    # Load data
    data, p_values, t = load_p_output_data()
    
    # Get the last column (highest p-value)
    last_p = p_values[-1]
    last_col = f'MSD_{last_p}'
    
    print(f"Last p-value: {last_p:.4f}")
    print(f"Column name: {last_col}")
    
    if last_col not in data.columns:
        print(f"Error: Column {last_col} not found!")
        return
    
    # Extract MSD data
    msd = data[last_col].values
    
    # Determine regime
    p_c_prime = 0.6884
    if last_p < p_c_prime - 0.05:
        regime = "LIQUID"
    elif abs(last_p - p_c_prime) < 0.05:
        regime = "CRITICAL"
    else:
        regime = "SOLID"
    
    print(f"Regime: {regime}")
    
    # Calculate α with current method
    alpha_mean, alpha_std, tau_region, msd_smoothed, alpha_local = calculate_alpha_for_p_smoothed(t, msd, last_p)
    
    print(f"Current α calculation:")
    print(f"  α = {alpha_mean:.3f} ± {alpha_std:.3f}")
    print(f"  τ_region = {tau_region:.0f}")
    
    # Theoretical α
    if regime == "LIQUID":
        alpha_theory = 1.0
    elif regime == "CRITICAL":
        alpha_theory = 0.53
    else:
        alpha_theory = 0.0
    
    print(f"Theoretical α = {alpha_theory}")
    print(f"Error = {abs(alpha_mean - alpha_theory):.3f}")
    
    # Create comprehensive plot
    fig, axes = plt.subplots(2, 3, figsize=(18, 12))
    fig.suptitle(f'Last Column Analysis: p = {last_p:.4f} ({regime} Regime)', fontsize=16)
    
    # Plot 1: Raw MSD vs time (log-log)
    ax1 = axes[0, 0]
    ax1.loglog(t, msd, 'b-', linewidth=2, label='Raw MSD')
    ax1.set_xlabel('Time τ')
    ax1.set_ylabel('MSD')
    ax1.set_title('Raw MSD vs Time (Log-Log)')
    ax1.legend()
    ax1.grid(True, alpha=0.3)
    
    # Plot 2: Smoothed MSD vs time (log-log)
    ax2 = axes[0, 1]
    ax2.loglog(t, msd_smoothed, 'r-', linewidth=2, label='Smoothed MSD')
    ax2.set_xlabel('Time τ')
    ax2.set_ylabel('MSD')
    ax2.set_title('Smoothed MSD vs Time (Log-Log)')
    ax2.legend()
    ax2.grid(True, alpha=0.3)
    
    # Plot 3: Raw vs Smoothed comparison
    ax3 = axes[0, 2]
    ax3.loglog(t, msd, 'b-', alpha=0.5, linewidth=1, label='Raw MSD')
    ax3.loglog(t, msd_smoothed, 'r-', linewidth=2, label='Smoothed MSD')
    ax3.set_xlabel('Time τ')
    ax3.set_ylabel('MSD')
    ax3.set_title('Raw vs Smoothed MSD')
    ax3.legend()
    ax3.grid(True, alpha=0.3)
    
    # Plot 4: Local α vs time
    ax4 = axes[1, 0]
    valid_mask = np.isfinite(alpha_local)
    ax4.semilogx(t[valid_mask], alpha_local[valid_mask], 'g-', linewidth=2, label='Local α')
    
    # Add theoretical α line
    ax4.axhline(y=alpha_theory, color='red', linestyle='--', alpha=0.7, label=f'Theoretical α = {alpha_theory}')
    
    # Mark the current α estimation region
    if not np.isnan(tau_region):
        ax4.axvline(x=tau_region, color='orange', linestyle=':', linewidth=3, label=f'Current τ_region = {tau_region:.0f}')
    
    ax4.set_xlabel('Time τ')
    ax4.set_ylabel('Local α')
    ax4.set_title('Local α vs Time')
    ax4.legend()
    ax4.grid(True, alpha=0.3)
    
    # Plot 5: MSD vs time (linear scale)
    ax5 = axes[1, 1]
    ax5.plot(t, msd_smoothed, 'r-', linewidth=2, label='Smoothed MSD')
    
    # Mark the current α estimation region
    if not np.isnan(tau_region):
        region_start = max(0, int(tau_region) - 1000)
        region_end = min(len(t), int(tau_region) + 1000)
        region_t = t[region_start:region_end]
        region_msd = msd_smoothed[region_start:region_end]
        ax5.plot(region_t, region_msd, 'orange', linewidth=4, label='Current α region')
    
    ax5.set_xlabel('Time τ')
    ax5.set_ylabel('MSD')
    ax5.set_title('MSD vs Time (Linear)')
    ax5.legend()
    ax5.grid(True, alpha=0.3)
    
    # Plot 6: Summary
    ax6 = axes[1, 2]
    ax6.axis('off')
    
    summary_text = f"""
    p = {last_p:.4f}
    Regime: {regime}
    
    Current Method:
    α = {alpha_mean:.3f} ± {alpha_std:.3f}
    τ_region = {tau_region:.0f}
    
    Theoretical:
    α = {alpha_theory}
    
    Error = {abs(alpha_mean - alpha_theory):.3f}
    """
    
    ax6.text(0.1, 0.8, summary_text, fontsize=12, fontfamily='monospace',
             verticalalignment='top', transform=ax6.transAxes,
             bbox=dict(boxstyle="round,pad=0.3", facecolor="lightgray", alpha=0.8))
    
    ax6.set_title('Summary')
    
    plt.tight_layout()
    
    # Save plot
    output_dir = "../paper_figures"
    os.makedirs(output_dir, exist_ok=True)
    plt.savefig(f"{output_dir}/last_column_analysis_p{last_p:.4f}.png", 
                dpi=300, bbox_inches='tight')
    
    print(f"\nPlot saved to: {output_dir}/last_column_analysis_p{last_p:.4f}.png")
    
    return fig

def main():
    """Main analysis function"""
    try:
        fig = plot_last_column_analysis()
        plt.close(fig)
        print("\nAnalysis complete!")
    except Exception as e:
        print(f"Error in analysis: {e}")

if __name__ == "__main__":
    main() 