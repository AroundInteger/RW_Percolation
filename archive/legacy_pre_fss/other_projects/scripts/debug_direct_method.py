#!/usr/bin/env python3
"""
Debug Direct Changepoint Detection

This script helps debug why the direct method is detecting very early changepoints.
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

def debug_boundary_crossings(t, msd, p_value):
    """
    Debug the boundary crossings for a specific p-value
    """
    # Filter valid data
    valid_mask = np.isfinite(msd) & (msd > 0) & (t <= 1e4)
    t_valid = t[valid_mask]
    msd_valid = msd[valid_mask]
    
    if len(t_valid) < 100:
        print(f"Not enough valid data for p = {p_value}")
        return
    
    log_t = np.log10(t_valid)
    log_msd = np.log10(msd_valid)
    
    print(f"\n=== DEBUG for p = {p_value} ===")
    print(f"log_t range: {log_t.min():.3f} to {log_t.max():.3f}")
    print(f"log_msd range: {log_msd.min():.3f} to {log_msd.max():.3f}")
    print(f"t range: {t_valid.min()} to {t_valid.max()}")
    print(f"MSD range: {msd_valid.min():.3f} to {msd_valid.max():.3f}")
    
    # Determine boundary parameters
    p_c_prime = 0.6884
    
    if p_value < p_c_prime - 0.05:
        expected_alpha = 1.0  # Liquid
        y1_offset = -0.5  # Upper boundary for liquid
        y2_slope = 0.8    # Lower boundary slope
        y2_offset = 0.3   # Lower boundary offset
    elif abs(p_value - p_c_prime) < 0.05:
        expected_alpha = 0.53  # Critical
        y1_offset = -0.87  # Original value
        y2_slope = 0.4     # Original value
        y2_offset = 0.16   # Original value
    else:
        expected_alpha = 0.0  # Solid
        y1_offset = -1.2   # Upper boundary for solid
        y2_slope = 0.3     # Lower boundary slope
        y2_offset = 0.1    # Lower boundary offset
    
    # Calculate boundaries
    y1 = log_t + y1_offset  # Upper boundary: log10(t) + offset
    y2 = y2_slope * log_t + y2_offset  # Lower boundary: slope * log10(t) + offset
    
    print(f"\nBoundary parameters:")
    print(f"  y1_offset = {y1_offset}")
    print(f"  y2_slope = {y2_slope}")
    print(f"  y2_offset = {y2_offset}")
    
    # Find crossings with tolerance
    tolerance = 0.01
    
    # Find crossings with y1 (upper boundary)
    y1_crossings = np.where(np.abs(log_msd - y1) < tolerance)[0]
    print(f"\ny1 crossings (tolerance = {tolerance}):")
    if len(y1_crossings) > 0:
        for i, idx in enumerate(y1_crossings[:5]):  # Show first 5
            print(f"  {i+1}: t = {t_valid[idx]}, log_t = {log_t[idx]:.3f}, log_msd = {log_msd[idx]:.3f}, y1 = {y1[idx]:.3f}")
        if len(y1_crossings) > 5:
            print(f"  ... and {len(y1_crossings) - 5} more")
    else:
        print("  No y1 crossings found")
    
    # Find crossings with y2 (lower boundary)
    y2_crossings = np.where(np.abs(log_msd - y2) < tolerance)[0]
    print(f"\ny2 crossings (tolerance = {tolerance}):")
    if len(y2_crossings) > 0:
        for i, idx in enumerate(y2_crossings[:5]):  # Show first 5
            print(f"  {i+1}: t = {t_valid[idx]}, log_t = {log_t[idx]:.3f}, log_msd = {log_msd[idx]:.3f}, y2 = {y2[idx]:.3f}")
        if len(y2_crossings) > 5:
            print(f"  ... and {len(y2_crossings) - 5} more")
    else:
        print("  No y2 crossings found")
    
    # Try different tolerances
    for tol in [0.05, 0.1, 0.2]:
        y1_crossings_tol = np.where(np.abs(log_msd - y1) < tol)[0]
        y2_crossings_tol = np.where(np.abs(log_msd - y2) < tol)[0]
        print(f"\nTolerance = {tol}:")
        print(f"  y1 crossings: {len(y1_crossings_tol)}")
        print(f"  y2 crossings: {len(y2_crossings_tol)}")
    
    # Plot for visual inspection
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(15, 6))
    
    # Plot 1: Log-log plot
    ax1.plot(log_t, log_msd, 'b-', linewidth=2, label=f'p = {p_value}')
    ax1.plot(log_t, y1, 'r--', linewidth=2, label=f'y1 = log(t) + {y1_offset}')
    ax1.plot(log_t, y2, 'g--', linewidth=2, label=f'y2 = {y2_slope}*log(t) + {y2_offset}')
    
    # Mark crossings
    if len(y1_crossings) > 0:
        ax1.plot(log_t[y1_crossings], log_msd[y1_crossings], 'ro', markersize=8, label='y1 crossings')
    if len(y2_crossings) > 0:
        ax1.plot(log_t[y2_crossings], log_msd[y2_crossings], 'go', markersize=8, label='y2 crossings')
    
    ax1.set_xlabel('log₁₀(t)')
    ax1.set_ylabel('log₁₀(MSD)')
    ax1.set_title(f'Log-Log Plot: p = {p_value}')
    ax1.legend()
    ax1.grid(True, alpha=0.3)
    
    # Plot 2: Linear plot
    ax2.loglog(t_valid, msd_valid, 'b-', linewidth=2, label=f'p = {p_value}')
    
    # Mark crossings in linear space
    if len(y1_crossings) > 0:
        ax2.axvline(x=t_valid[y1_crossings[0]], color='r', linestyle='--', 
                   label=f'First y1 crossing: t = {t_valid[y1_crossings[0]]}')
    if len(y2_crossings) > 0:
        ax2.axvline(x=t_valid[y2_crossings[-1]], color='g', linestyle='--', 
                   label=f'Last y2 crossing: t = {t_valid[y2_crossings[-1]]}')
    
    ax2.set_xlabel('Time t')
    ax2.set_ylabel('MSD')
    ax2.set_title(f'Linear Plot: p = {p_value}')
    ax2.legend()
    ax2.grid(True, alpha=0.3)
    
    plt.tight_layout()
    
    # Save plot
    output_dir = "../paper_figures"
    os.makedirs(output_dir, exist_ok=True)
    plt.savefig(f"{output_dir}/debug_p{p_value:.4f}.png", dpi=300, bbox_inches='tight')
    plt.close()
    
    print(f"\nDebug plot saved as: debug_p{p_value:.4f}.png")

def main():
    """Main debug function"""
    print("=== DEBUG DIRECT CHANGEPOINT DETECTION ===")
    
    try:
        # Load data
        data, p_values, t = load_p_output_data()
        print(f"Loaded data with {len(p_values)} p-values")
        
        # Debug specific p-values that showed early changepoints
        debug_p_values = [0.1000, 0.1500, 0.2000, 0.2500, 0.4000, 0.6384, 0.6884, 0.6984]
        
        for p in debug_p_values:
            if f'MSD_{p}' in data.columns:
                msd = data[f'MSD_{p}'].values
                debug_boundary_crossings(t, msd, p)
            else:
                print(f"\nNo data for p = {p}")
        
        print("\nDebug analysis complete!")
        
    except Exception as e:
        print(f"Error in debug analysis: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    main() 