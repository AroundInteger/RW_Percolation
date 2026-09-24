#!/usr/bin/env python3
"""
Plot Last Column Plateau Analysis from p_output.csv

This script analyzes the plateau region in the last column (p=0.7484)
and calculates α from the plateau where log MSD vs log t shows a clear flat region for t > 10^4.
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

def identify_plateau_region(t, msd, min_t=1e4, max_slope=0.1):
    """
    Identify plateau region in log MSD vs log t
    
    Parameters:
    - t: time array
    - msd: MSD array
    - min_t: minimum time to start looking for plateau
    - max_slope: maximum allowed slope for plateau region
    
    Returns:
    - plateau_start: start index of plateau
    - plateau_end: end index of plateau
    - plateau_alpha: α calculated from plateau
    """
    
    # Convert to log space
    log_t = np.log10(t[1:])  # Skip t=0
    log_msd = np.log10(msd[1:])  # Skip MSD=0
    
    # Find region where t > min_t
    t_mask = t[1:] >= min_t
    if not np.any(t_mask):
        return None, None, None
    
    log_t_region = log_t[t_mask]
    log_msd_region = log_msd[t_mask]
    t_region = t[1:][t_mask]
    
    # Calculate local slopes using sliding window
    window_size = min(20, len(log_t_region) // 4)
    if window_size < 5:
        window_size = 5
    
    slopes = []
    for i in range(window_size, len(log_t_region) - window_size):
        window_start = i - window_size // 2
        window_end = i + window_size // 2
        
        t_window = log_t_region[window_start:window_end]
        msd_window = log_msd_region[window_start:window_end]
        
        if np.all(np.isfinite(msd_window)) and np.all(np.isfinite(t_window)):
            coeffs = np.polyfit(t_window, msd_window, 1)
            slopes.append(coeffs[0])
        else:
            slopes.append(np.nan)
    
    # Find plateau region (where slope is close to 0)
    plateau_mask = np.abs(np.array(slopes)) < max_slope
    
    if not np.any(plateau_mask):
        return None, None, None
    
    # Find consecutive plateau regions
    plateau_regions = []
    start_idx = None
    
    for i, is_plateau in enumerate(plateau_mask):
        if is_plateau and start_idx is None:
            start_idx = i + window_size  # Adjust for window offset
        elif not is_plateau and start_idx is not None:
            if i + window_size - start_idx >= 10:  # Minimum plateau length
                plateau_regions.append((start_idx, i + window_size))
            start_idx = None
    
    # Handle case where plateau extends to end
    if start_idx is not None and len(plateau_mask) + window_size - start_idx >= 10:
        plateau_regions.append((start_idx, len(plateau_mask) + window_size))
    
    if not plateau_regions:
        return None, None, None
    
    # Take the longest plateau region
    longest_plateau = max(plateau_regions, key=lambda x: x[1] - x[0])
    plateau_start_idx, plateau_end_idx = longest_plateau
    
    # Convert back to original indices
    plateau_start = np.where(t == t_region[plateau_start_idx])[0][0]
    plateau_end = np.where(t == t_region[min(plateau_end_idx, len(t_region)-1)])[0][0]
    
    # Calculate α from plateau region
    plateau_t = log_t[plateau_start:plateau_end+1]
    plateau_msd = log_msd[plateau_start:plateau_end+1]
    
    if len(plateau_t) > 5:
        coeffs = np.polyfit(plateau_t, plateau_msd, 1)
        plateau_alpha = coeffs[0]
    else:
        plateau_alpha = np.nan
    
    return plateau_start, plateau_end, plateau_alpha

def calculate_alpha_from_plateau(t, msd, p, p_c_prime=0.6884):
    """Calculate α from plateau region for solid regime"""
    
    # Determine regime
    if p < p_c_prime - 0.05:
        regime = "LIQUID"
    elif abs(p - p_c_prime) < 0.05:
        regime = "CRITICAL"
    else:
        regime = "SOLID"
    
    if regime == "SOLID":
        # For solid regime, look for plateau in long-time region
        plateau_start, plateau_end, plateau_alpha = identify_plateau_region(t, msd, min_t=1e4, max_slope=0.1)
        
        if plateau_start is not None and plateau_end is not None:
            # Calculate α from plateau
            log_t = np.log10(t[1:])
            log_msd = np.log10(msd[1:])
            
            plateau_t = log_t[plateau_start:plateau_end+1]
            plateau_msd = log_msd[plateau_start:plateau_end+1]
            
            if len(plateau_t) > 5:
                coeffs = np.polyfit(plateau_t, plateau_msd, 1)
                alpha_mean = coeffs[0]
                
                # Calculate standard deviation
                residuals = plateau_msd - (coeffs[0] * plateau_t + coeffs[1])
                alpha_std = np.std(residuals)
                
                return alpha_mean, alpha_std, t[plateau_start], plateau_start, plateau_end
    
    # Fallback to original method
    return np.nan, np.nan, np.nan, None, None

def plot_plateau_analysis():
    """Plot plateau analysis of the last column"""
    
    print("=== PLATEAU ANALYSIS ===")
    print("Analyzing plateau region in the last column (p=0.7484)")
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
    regime = "SOLID"  # We know this is the solid regime
    
    print(f"Regime: {regime}")
    
    # Calculate α from plateau
    alpha_mean, alpha_std, tau_region, plateau_start, plateau_end = calculate_alpha_from_plateau(t, msd, last_p)
    
    print(f"Plateau α calculation:")
    print(f"  α = {alpha_mean:.3f} ± {alpha_std:.3f}")
    print(f"  τ_region = {tau_region:.0f}")
    print(f"  Plateau range: t = {t[plateau_start] if plateau_start else 'N/A'} to {t[plateau_end] if plateau_end else 'N/A'}")
    
    # Theoretical α
    alpha_theory = 0.0  # Solid regime
    
    print(f"Theoretical α = {alpha_theory}")
    print(f"Error = {abs(alpha_mean - alpha_theory):.3f}")
    
    # Create comprehensive plot
    fig, axes = plt.subplots(2, 3, figsize=(18, 12))
    fig.suptitle(f'Plateau Analysis: p = {last_p:.4f} ({regime} Regime)', fontsize=16)
    
    # Plot 1: Log MSD vs Log t (full range)
    ax1 = axes[0, 0]
    log_t = np.log10(t[1:])
    log_msd = np.log10(msd[1:])
    ax1.plot(log_t, log_msd, 'b-', linewidth=2, label='MSD')
    
    # Mark plateau region
    if plateau_start is not None and plateau_end is not None:
        plateau_log_t = log_t[plateau_start:plateau_end+1]
        plateau_log_msd = log_msd[plateau_start:plateau_end+1]
        ax1.plot(plateau_log_t, plateau_log_msd, 'r-', linewidth=4, label='Plateau region')
    
    ax1.set_xlabel('log₁₀(τ)')
    ax1.set_ylabel('log₁₀(MSD)')
    ax1.set_title('Log MSD vs Log Time (Full Range)')
    ax1.legend()
    ax1.grid(True, alpha=0.3)
    
    # Plot 2: Log MSD vs Log t (t > 10^4)
    ax2 = axes[0, 1]
    t_mask = t[1:] >= 1e4
    if np.any(t_mask):
        log_t_region = log_t[t_mask]
        log_msd_region = log_msd[t_mask]
        ax2.plot(log_t_region, log_msd_region, 'b-', linewidth=2, label='MSD (t > 10⁴)')
        
        # Mark plateau region
        if plateau_start is not None and plateau_end is not None:
            plateau_mask = (t[1:] >= 1e4) & (np.arange(len(t)-1) >= plateau_start) & (np.arange(len(t)-1) <= plateau_end)
            if np.any(plateau_mask):
                plateau_log_t = log_t[plateau_mask]
                plateau_log_msd = log_msd[plateau_mask]
                ax2.plot(plateau_log_t, plateau_log_msd, 'r-', linewidth=4, label='Plateau region')
    
    ax2.set_xlabel('log₁₀(τ)')
    ax2.set_ylabel('log₁₀(MSD)')
    ax2.set_title('Log MSD vs Log Time (t > 10⁴)')
    ax2.legend()
    ax2.grid(True, alpha=0.3)
    
    # Plot 3: MSD vs t (linear scale, t > 10^4)
    ax3 = axes[0, 2]
    t_mask = t >= 1e4
    if np.any(t_mask):
        t_region = t[t_mask]
        msd_region = msd[t_mask]
        ax3.plot(t_region, msd_region, 'b-', linewidth=2, label='MSD (t > 10⁴)')
        
        # Mark plateau region
        if plateau_start is not None and plateau_end is not None:
            plateau_mask = (t >= 1e4) & (np.arange(len(t)) >= plateau_start) & (np.arange(len(t)) <= plateau_end)
            if np.any(plateau_mask):
                plateau_t = t[plateau_mask]
                plateau_msd = msd[plateau_mask]
                ax3.plot(plateau_t, plateau_msd, 'r-', linewidth=4, label='Plateau region')
    
    ax3.set_xlabel('Time τ')
    ax3.set_ylabel('MSD')
    ax3.set_title('MSD vs Time (t > 10⁴)')
    ax3.legend()
    ax3.grid(True, alpha=0.3)
    
    # Plot 4: Local α vs time
    ax4 = axes[1, 0]
    
    # Calculate local α
    window_size = min(15, len(log_t) // 4)
    if window_size < 5:
        window_size = 5
    
    alpha_local = np.full_like(t, np.nan)
    for i in range(window_size, len(log_t) - window_size):
        window_start = i - window_size // 2
        window_end = i + window_size // 2
        t_window = log_t[window_start:window_end]
        msd_window = log_msd[window_start:window_end]
        
        if np.all(np.isfinite(msd_window)) and np.all(np.isfinite(t_window)):
            coeffs = np.polyfit(t_window, msd_window, 1)
            alpha_local[i+1] = coeffs[0]
    
    valid_mask = np.isfinite(alpha_local)
    ax4.semilogx(t[valid_mask], alpha_local[valid_mask], 'g-', linewidth=2, label='Local α')
    
    # Add theoretical α line
    ax4.axhline(y=alpha_theory, color='red', linestyle='--', alpha=0.7, label=f'Theoretical α = {alpha_theory}')
    
    # Mark plateau region
    if plateau_start is not None and plateau_end is not None:
        plateau_mask = (np.arange(len(t)) >= plateau_start) & (np.arange(len(t)) <= plateau_end) & valid_mask
        if np.any(plateau_mask):
            plateau_t = t[plateau_mask]
            plateau_alpha = alpha_local[plateau_mask]
            ax4.plot(plateau_t, plateau_alpha, 'orange', linewidth=4, label='Plateau α')
    
    ax4.set_xlabel('Time τ')
    ax4.set_ylabel('Local α')
    ax4.set_title('Local α vs Time')
    ax4.legend()
    ax4.grid(True, alpha=0.3)
    
    # Plot 5: Slope analysis
    ax5 = axes[1, 1]
    
    # Calculate slopes in plateau region
    if plateau_start is not None and plateau_end is not None:
        t_mask = t[1:] >= 1e4
        if np.any(t_mask):
            log_t_region = log_t[t_mask]
            log_msd_region = log_msd[t_mask]
            t_region = t[1:][t_mask]
            
            window_size = min(20, len(log_t_region) // 4)
            if window_size < 5:
                window_size = 5
            
            slopes = []
            slope_times = []
            
            for i in range(window_size, len(log_t_region) - window_size):
                window_start = i - window_size // 2
                window_end = i + window_size // 2
                
                t_window = log_t_region[window_start:window_end]
                msd_window = log_msd_region[window_start:window_end]
                
                if np.all(np.isfinite(msd_window)) and np.all(np.isfinite(t_window)):
                    coeffs = np.polyfit(t_window, msd_window, 1)
                    slopes.append(coeffs[0])
                    slope_times.append(t_region[i])
            
            if slopes:
                ax5.plot(slope_times, slopes, 'b-', linewidth=2, label='Local slope')
                ax5.axhline(y=0, color='red', linestyle='--', alpha=0.7, label='Slope = 0')
                ax5.axhline(y=0.1, color='orange', linestyle=':', alpha=0.7, label='Max slope = 0.1')
                ax5.axhline(y=-0.1, color='orange', linestyle=':', alpha=0.7)
    
    ax5.set_xlabel('Time τ')
    ax5.set_ylabel('Slope (d(log MSD)/d(log τ))')
    ax5.set_title('Slope Analysis')
    ax5.legend()
    ax5.grid(True, alpha=0.3)
    
    # Plot 6: Summary
    ax6 = axes[1, 2]
    ax6.axis('off')
    
    summary_text = f"""
    p = {last_p:.4f}
    Regime: {regime}
    
    Plateau Analysis:
    α = {alpha_mean:.3f} ± {alpha_std:.3f}
    τ_region = {tau_region:.0f}
    
    Plateau Range:
    t = {t[plateau_start] if plateau_start else 'N/A'} to {t[plateau_end] if plateau_end else 'N/A'}
    
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
    plt.savefig(f"{output_dir}/plateau_analysis_p{last_p:.4f}.png", 
                dpi=300, bbox_inches='tight')
    
    print(f"\nPlot saved to: {output_dir}/plateau_analysis_p{last_p:.4f}.png")
    
    return fig

def main():
    """Main analysis function"""
    try:
        fig = plot_plateau_analysis()
        plt.close(fig)
        print("\nAnalysis complete!")
    except Exception as e:
        print(f"Error in analysis: {e}")

if __name__ == "__main__":
    main() 