#!/usr/bin/env python3
"""
Final Direct Changepoint Detection - MATLAB Approach

This script implements the exact MATLAB approach:
y1 = log10(t) - 0.87  (upper boundary)
y2 = 0.4*log10(t) + 0.16  (lower boundary)
y = log10(MSD)

But with improved parameter tuning and focus on meaningful regions.
"""

import numpy as np
import matplotlib.pyplot as plt
import pandas as pd
import os
from scipy import stats

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

def detect_changepoints_matlab_style(t, msd, p_value):
    """
    Implement the exact MATLAB approach with improved parameters
    """
    # Filter valid data and focus on meaningful region
    valid_mask = np.isfinite(msd) & (msd > 0) & (t >= 100) & (t <= 1e4)
    t_valid = t[valid_mask]
    msd_valid = msd[valid_mask]
    
    if len(t_valid) < 50:
        return None, None, None, None, None
    
    log_t = np.log10(t_valid)
    log_msd = np.log10(msd_valid)
    
    # Use the exact MATLAB boundary equations
    # y1 = log10(t) - 0.87  (upper boundary)
    # y2 = 0.4*log10(t) + 0.16  (lower boundary)
    y1 = log_t - 0.87
    y2 = 0.4 * log_t + 0.16
    
    # Find crossings with adaptive tolerance
    msd_range = log_msd.max() - log_msd.min()
    tolerance = max(0.02, msd_range * 0.01)  # 1% of range, minimum 0.02
    
    # Find y1 crossings (upper boundary)
    y1_crossings = np.where(np.abs(log_msd - y1) < tolerance)[0]
    
    # Find y2 crossings (lower boundary)
    y2_crossings = np.where(np.abs(log_msd - y2) < tolerance)[0]
    
    # Get the first y1 crossing (critical point)
    y_cr_id = y1_crossings[0] if len(y1_crossings) > 0 else None
    
    # Get the last y2 crossing (anomalous diffusion start)
    y_ad_id = y2_crossings[-1] if len(y2_crossings) > 0 else None
    
    if y_cr_id is None:
        return None, None, None, None, None
    
    # Calculate τ_cr
    tau_cr = t_valid[y_cr_id]
    
    # Fit anomalous diffusion region if both points are available
    alpha = None
    r_squared = None
    
    if y_ad_id is not None and y_ad_id < y_cr_id:
        # Extract the anomalous diffusion region
        t_ad = log_t[y_ad_id:y_cr_id+1]
        msd_ad = log_msd[y_ad_id:y_cr_id+1]
        
        if len(t_ad) >= 3:
            # Fit linear relationship
            slope, intercept, r_value, p_value, std_err = stats.linregress(t_ad, msd_ad)
            alpha = slope
            r_squared = r_value**2
    
    return tau_cr, alpha, r_squared, y_cr_id, y_ad_id

def analyze_all_p_values_final(data, p_values, t):
    """
    Analyze all p-values using the final MATLAB-style method
    """
    results = []
    
    for p in p_values:
        msd_col = f'MSD_{p}'
        if msd_col not in data.columns:
            continue
        
        msd = data[msd_col].values
        
        # Detect changepoints
        tau_cr, alpha, r_squared, y_cr_id, y_ad_id = detect_changepoints_matlab_style(t, msd, p)
        
        # Determine regime
        p_c_prime = 0.6884
        if p < p_c_prime - 0.05:
            regime = "LIQUID"
        elif abs(p - p_c_prime) < 0.05:
            regime = "CRITICAL"
        else:
            regime = "SOLID"
        
        result = {
            'p': p,
            'regime': regime,
            'tau_cr': tau_cr,
            'alpha': alpha,
            'r_squared': r_squared,
            'y_cr_id': y_cr_id,
            'y_ad_id': y_ad_id
        }
        results.append(result)
        
        if tau_cr is not None:
            alpha_str = f"{alpha:.3f}" if alpha is not None else "N/A"
            r2_str = f"{r_squared:.3f}" if r_squared is not None else "N/A"
            print(f"p = {p:.4f} ({regime}): τ_cr = {tau_cr:.0f}, α = {alpha_str}, R² = {r2_str}")
        else:
            print(f"p = {p:.4f} ({regime}): No changepoint detected")
    
    return results

def create_final_visualization(data, p_values, t, results):
    """
    Create final visualization showing the MATLAB-style method
    """
    # Select key p-values for detailed analysis
    p_c_prime = 0.6884
    key_p_values = [p_c_prime - 0.05, p_c_prime, p_c_prime + 0.05]
    
    # Find closest available p-values
    available_p_values = []
    for target_p in key_p_values:
        closest_p = min(p_values, key=lambda x: abs(x - target_p))
        available_p_values.append(closest_p)
    
    # Create figure
    fig, axes = plt.subplots(2, 3, figsize=(20, 12))
    fig.suptitle('Final Direct Changepoint Detection: MATLAB-Style Method', fontsize=16, fontweight='bold')
    
    colors = ['blue', 'red', 'green']
    regime_names = ['LIQUID', 'CRITICAL', 'SOLID']
    
    for idx, (p, color, regime) in enumerate(zip(available_p_values, colors, regime_names)):
        msd_col = f'MSD_{p}'
        if msd_col not in data.columns:
            continue
        
        msd = data[msd_col].values
        
        # Filter data for meaningful region
        valid_mask = np.isfinite(msd) & (msd > 0) & (t >= 100) & (t <= 1e4)
        t_valid = t[valid_mask]
        msd_valid = msd[valid_mask]
        
        log_t = np.log10(t_valid)
        log_msd = np.log10(msd_valid)
        
        # Plot 1: Log-log plot with MATLAB boundaries
        ax1 = axes[0, idx]
        ax1.plot(log_t, log_msd, color=color, linewidth=2, label=f'p = {p:.4f}')
        
        # Plot MATLAB boundaries
        y1 = log_t - 0.87
        y2 = 0.4 * log_t + 0.16
        ax1.plot(log_t, y1, 'r--', linewidth=2, alpha=0.8, label='y1 = log(t) - 0.87')
        ax1.plot(log_t, y2, 'g--', linewidth=2, alpha=0.8, label='y2 = 0.4*log(t) + 0.16')
        
        # Detect and mark crossing points
        tau_cr, alpha, r_squared, y_cr_id, y_ad_id = detect_changepoints_matlab_style(t, msd, p)
        
        if y_cr_id is not None:
            ax1.plot(log_t[y_cr_id], log_msd[y_cr_id], '^m', markersize=10, 
                    label=f'τ_cr = {tau_cr:.0f}')
        
        if y_ad_id is not None:
            ax1.plot(log_t[y_ad_id], log_msd[y_ad_id], '^w', markersize=10, 
                    label=f'AD start = {t_valid[y_ad_id]:.0f}')
        
        # Fit and plot anomalous diffusion region
        if y_ad_id is not None and y_cr_id is not None and y_ad_id < y_cr_id and alpha is not None:
            t_ad = np.linspace(log_t[y_ad_id], log_t[y_cr_id], 50)
            y_ad = alpha * t_ad + (log_msd[y_ad_id] - alpha * log_t[y_ad_id])
            ax1.plot(t_ad, y_ad, 'y:', linewidth=2, alpha=0.8, 
                    label=f'AD fit: α = {alpha:.3f}')
        
        ax1.set_xlabel('log₁₀(τ)')
        ax1.set_ylabel('log₁₀(MSD)')
        ax1.set_title(f'{regime}\np = {p:.4f}')
        ax1.legend(fontsize=8)
        ax1.grid(True, alpha=0.3)
        ax1.set_xlim(2, 4)  # Focus on meaningful region
        
        # Plot 2: MSD curves with τ_cr detection
        ax2 = axes[1, idx]
        ax2.loglog(t_valid, msd_valid, color=color, linewidth=2, label=f'p = {p:.4f}')
        
        # Mark τ_cr
        if tau_cr is not None:
            ax2.axvline(x=tau_cr, color='orange', linestyle='--', linewidth=3, 
                       label=f'τ_cr = {tau_cr:.0f}')
        
        # Mark AD start
        if y_ad_id is not None:
            tau_ad = t_valid[y_ad_id]
            ax2.axvline(x=tau_ad, color='green', linestyle=':', linewidth=2, 
                       label=f'AD start = {tau_ad:.0f}')
        
        ax2.set_xlabel('Time τ')
        ax2.set_ylabel('MSD')
        ax2.set_title(f'{regime} - Time Domain')
        ax2.legend(fontsize=8)
        ax2.grid(True, alpha=0.3)
        ax2.set_xlim(1e2, 1e4)  # Focus on meaningful region
    
    plt.tight_layout()
    
    # Save plot
    output_dir = "../paper_figures"
    os.makedirs(output_dir, exist_ok=True)
    plt.savefig(f"{output_dir}/final_direct_detection.png", 
                dpi=300, bbox_inches='tight')
    
    return fig

def main():
    """Main analysis function"""
    print("=== FINAL DIRECT CHANGEPOINT DETECTION ===")
    print("MATLAB-Style Method with Improved Parameters")
    print("=" * 60)
    
    try:
        # Load data
        data, p_values, t = load_p_output_data()
        print(f"Loaded data with {len(p_values)} p-values")
        
        # Analyze all p-values
        print("\nAnalyzing all p-values...")
        results = analyze_all_p_values_final(data, p_values, t)
        
        # Create visualizations
        print("\nCreating final visualizations...")
        fig = create_final_visualization(data, p_values, t, results)
        plt.close(fig)
        
        # Save results
        results_df = pd.DataFrame(results)
        output_file = "../paper_figures/final_direct_results.csv"
        results_df.to_csv(output_file, index=False)
        print(f"\nResults saved to: {output_file}")
        
        # Summary statistics
        print(f"\n{'='*60}")
        print("SUMMARY STATISTICS")
        print(f"{'='*60}")
        
        valid_results = [r for r in results if r['tau_cr'] is not None]
        if valid_results:
            print(f"\nτ_cr statistics:")
            tau_cr_vals = [r['tau_cr'] for r in valid_results]
            print(f"  Mean: {np.mean(tau_cr_vals):.0f}")
            print(f"  Median: {np.median(tau_cr_vals):.0f}")
            print(f"  Std: {np.std(tau_cr_vals):.0f}")
            print(f"  Range: {min(tau_cr_vals):.0f} - {max(tau_cr_vals):.0f}")
            
            print(f"\nα statistics:")
            alpha_vals = [r['alpha'] for r in valid_results if r['alpha'] is not None]
            if alpha_vals:
                print(f"  Mean: {np.mean(alpha_vals):.4f}")
                print(f"  Median: {np.median(alpha_vals):.4f}")
                print(f"  Range: {min(alpha_vals):.4f} - {max(alpha_vals):.4f}")
        
        print("\nAnalysis complete!")
        print("Check ../paper_figures/ for plots and results")
        
    except Exception as e:
        print(f"Error in analysis: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    main() 