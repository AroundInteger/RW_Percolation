#!/usr/bin/env python3
"""
Improved Direct Changepoint Detection

This script implements an improved version of the direct method with:
1. Better boundary parameters that focus on meaningful regions (t > 1000)
2. Adaptive tolerance based on data characteristics
3. More robust crossing detection
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

def determine_improved_boundaries(t, msd, p_value):
    """
    Determine improved boundary parameters that focus on meaningful regions
    """
    # Filter valid data and focus on meaningful region (t > 1000)
    valid_mask = np.isfinite(msd) & (msd > 0) & (t >= 1000) & (t <= 1e4)
    t_valid = t[valid_mask]
    msd_valid = msd[valid_mask]
    
    if len(t_valid) < 50:
        return None, None, None, None
    
    log_t = np.log10(t_valid)
    log_msd = np.log10(msd_valid)
    
    # Determine expected behavior based on p-value
    p_c_prime = 0.6884
    
    if p_value < p_c_prime - 0.05:
        # Liquid regime - expect α ≈ 1.0
        # Upper boundary: slightly above expected behavior
        y1_slope = 1.2
        y1_offset = -0.3
        # Lower boundary: slightly below expected behavior
        y2_slope = 0.8
        y2_offset = 0.2
    elif abs(p_value - p_c_prime) < 0.05:
        # Critical regime - expect α ≈ 0.53
        # Upper boundary: slightly above critical behavior
        y1_slope = 0.7
        y1_offset = 0.1
        # Lower boundary: slightly below critical behavior
        y2_slope = 0.4
        y2_offset = 0.0
    else:
        # Solid regime - expect α ≈ 0.0 (plateau)
        # Upper boundary: small positive slope
        y1_slope = 0.2
        y1_offset = 0.5
        # Lower boundary: negative slope (decreasing MSD)
        y2_slope = -0.1
        y2_offset = 1.0
    
    # Calculate boundaries
    y1 = y1_slope * log_t + y1_offset
    y2 = y2_slope * log_t + y2_offset
    
    return y1, y2, log_t, log_msd

def find_robust_crossings(log_t, log_msd, y1, y2, min_t_log=3.0):
    """
    Find robust crossing points with additional constraints
    """
    # Only consider crossings in meaningful region (log_t >= 3.0)
    meaningful_mask = log_t >= min_t_log
    if np.sum(meaningful_mask) < 10:
        return None, None
    
    log_t_meaningful = log_t[meaningful_mask]
    log_msd_meaningful = log_msd[meaningful_mask]
    y1_meaningful = y1[meaningful_mask]
    y2_meaningful = y2[meaningful_mask]
    
    # Adaptive tolerance based on data range
    msd_range = log_msd_meaningful.max() - log_msd_meaningful.min()
    tolerance = max(0.05, msd_range * 0.02)  # 2% of range, minimum 0.05
    
    # Find crossings with y1 (upper boundary)
    y1_crossings = np.where(np.abs(log_msd_meaningful - y1_meaningful) < tolerance)[0]
    
    # Find crossings with y2 (lower boundary)
    y2_crossings = np.where(np.abs(log_msd_meaningful - y2_meaningful) < tolerance)[0]
    
    # Get the first y1 crossing and last y2 crossing
    y_cr_id = y1_crossings[0] if len(y1_crossings) > 0 else None
    y_ad_id = y2_crossings[-1] if len(y2_crossings) > 0 else None
    
    # Convert back to original indices
    if y_cr_id is not None:
        y_cr_id = np.where(meaningful_mask)[0][y_cr_id]
    if y_ad_id is not None:
        y_ad_id = np.where(meaningful_mask)[0][y_ad_id]
    
    return y_cr_id, y_ad_id

def fit_anomalous_diffusion_region(log_t, log_msd, y_ad_id, y_cr_id):
    """
    Fit a line through the anomalous diffusion region
    """
    if y_ad_id is None or y_cr_id is None or y_ad_id >= y_cr_id:
        return None, None, None
    
    # Extract the anomalous diffusion region
    t_ad = log_t[y_ad_id:y_cr_id+1]
    msd_ad = log_msd[y_ad_id:y_cr_id+1]
    
    if len(t_ad) < 3:
        return None, None, None
    
    # Fit linear relationship
    slope, intercept, r_value, p_value, std_err = stats.linregress(t_ad, msd_ad)
    r_squared = r_value**2
    
    return slope, intercept, r_squared

def detect_improved_changepoints(t, msd, p_value):
    """
    Main function to detect changepoints using improved direct method
    """
    # Determine improved boundary parameters
    y1, y2, log_t, log_msd = determine_improved_boundaries(t, msd, p_value)
    
    if y1 is None:
        return None, None, None, None, None, None
    
    # Find robust crossing points
    y_cr_id, y_ad_id = find_robust_crossings(log_t, log_msd, y1, y2)
    
    if y_cr_id is None:
        return None, None, None, None, None, None
    
    # Calculate τ_cr (convert back to linear time)
    tau_cr = 10**log_t[y_cr_id]
    
    # Fit anomalous diffusion region
    alpha, intercept, r_squared = fit_anomalous_diffusion_region(log_t, log_msd, y_ad_id, y_cr_id)
    
    return tau_cr, alpha, r_squared, y_cr_id, y_ad_id, (y1, y2)

def analyze_all_p_values_improved(data, p_values, t):
    """
    Analyze all p-values using the improved direct method
    """
    results = []
    
    for p in p_values:
        msd_col = f'MSD_{p}'
        if msd_col not in data.columns:
            continue
        
        msd = data[msd_col].values
        
        # Detect changepoints
        tau_cr, alpha, r_squared, y_cr_id, y_ad_id, boundaries = detect_improved_changepoints(t, msd, p)
        
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

def create_improved_visualization(data, p_values, t, results):
    """
    Create visualization showing the improved direct method
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
    fig.suptitle('Improved Direct Changepoint Detection: Meaningful Region Focus', fontsize=16, fontweight='bold')
    
    colors = ['blue', 'red', 'green']
    regime_names = ['LIQUID', 'CRITICAL', 'SOLID']
    
    for idx, (p, color, regime) in enumerate(zip(available_p_values, colors, regime_names)):
        msd_col = f'MSD_{p}'
        if msd_col not in data.columns:
            continue
        
        msd = data[msd_col].values
        
        # Filter data for meaningful region
        valid_mask = np.isfinite(msd) & (msd > 0) & (t >= 1000) & (t <= 1e4)
        t_valid = t[valid_mask]
        msd_valid = msd[valid_mask]
        
        log_t = np.log10(t_valid)
        log_msd = np.log10(msd_valid)
        
        # Plot 1: Log-log plot with improved boundaries
        ax1 = axes[0, idx]
        ax1.plot(log_t, log_msd, color=color, linewidth=2, label=f'p = {p:.4f}')
        
        # Determine and plot improved boundaries
        y1, y2, _, _ = determine_improved_boundaries(t, msd, p)
        if y1 is not None:
            ax1.plot(log_t, y1, 'r--', linewidth=2, alpha=0.8, label='y1 (upper boundary)')
            ax1.plot(log_t, y2, 'g--', linewidth=2, alpha=0.8, label='y2 (lower boundary)')
        
        # Find and mark crossing points
        y_cr_id, y_ad_id = find_robust_crossings(log_t, log_msd, y1, y2)
        
        if y_cr_id is not None:
            ax1.plot(log_t[y_cr_id], log_msd[y_cr_id], '^m', markersize=10, 
                    label=f'τ_cr = {10**log_t[y_cr_id]:.0f}')
        
        if y_ad_id is not None:
            ax1.plot(log_t[y_ad_id], log_msd[y_ad_id], '^w', markersize=10, 
                    label=f'AD start = {10**log_t[y_ad_id]:.0f}')
        
        # Fit and plot anomalous diffusion region
        if y_ad_id is not None and y_cr_id is not None and y_ad_id < y_cr_id:
            alpha, intercept, r_squared = fit_anomalous_diffusion_region(log_t, log_msd, y_ad_id, y_cr_id)
            if alpha is not None:
                t_ad = np.linspace(log_t[y_ad_id], log_t[y_cr_id], 50)
                y_ad = alpha * t_ad + intercept
                ax1.plot(t_ad, y_ad, 'y:', linewidth=2, alpha=0.8, 
                        label=f'AD fit: α = {alpha:.3f}')
        
        ax1.set_xlabel('log₁₀(τ)')
        ax1.set_ylabel('log₁₀(MSD)')
        ax1.set_title(f'{regime}\np = {p:.4f}')
        ax1.legend(fontsize=8)
        ax1.grid(True, alpha=0.3)
        ax1.set_xlim(3, 4)  # Focus on meaningful region
        ax1.set_ylim(-0.5, 2)
        
        # Plot 2: MSD curves with τ_cr detection
        ax2 = axes[1, idx]
        ax2.loglog(t_valid, msd_valid, color=color, linewidth=2, label=f'p = {p:.4f}')
        
        # Mark τ_cr
        if y_cr_id is not None:
            tau_cr = 10**log_t[y_cr_id]
            ax2.axvline(x=tau_cr, color='orange', linestyle='--', linewidth=3, 
                       label=f'τ_cr = {tau_cr:.0f}')
        
        # Mark AD start
        if y_ad_id is not None:
            tau_ad = 10**log_t[y_ad_id]
            ax2.axvline(x=tau_ad, color='green', linestyle=':', linewidth=2, 
                       label=f'AD start = {tau_ad:.0f}')
        
        ax2.set_xlabel('Time τ')
        ax2.set_ylabel('MSD')
        ax2.set_title(f'{regime} - Time Domain')
        ax2.legend(fontsize=8)
        ax2.grid(True, alpha=0.3)
        ax2.set_xlim(1e3, 1e4)  # Focus on meaningful region
    
    plt.tight_layout()
    
    # Save plot
    output_dir = "../paper_figures"
    os.makedirs(output_dir, exist_ok=True)
    plt.savefig(f"{output_dir}/improved_direct_detection.png", 
                dpi=300, bbox_inches='tight')
    
    return fig

def main():
    """Main analysis function"""
    print("=== IMPROVED DIRECT CHANGEPOINT DETECTION ===")
    print("Focusing on meaningful regions (t >= 1000)")
    print("=" * 60)
    
    try:
        # Load data
        data, p_values, t = load_p_output_data()
        print(f"Loaded data with {len(p_values)} p-values")
        
        # Analyze all p-values
        print("\nAnalyzing all p-values...")
        results = analyze_all_p_values_improved(data, p_values, t)
        
        # Create visualizations
        print("\nCreating improved visualizations...")
        fig = create_improved_visualization(data, p_values, t, results)
        plt.close(fig)
        
        # Save results
        results_df = pd.DataFrame(results)
        output_file = "../paper_figures/improved_direct_results.csv"
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