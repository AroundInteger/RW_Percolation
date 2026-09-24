#!/usr/bin/env python3
"""
Robust τ_cr Analysis - Working Backwards from Maximum Steps

This script implements a robust strategy to estimate τ_cr by:
1. Working backwards from maximum steps (1,000,000)
2. Finding significant changepoints in log(t) vs log(MSD) relationship
3. Using adaptive methodology to identify transition regions
4. Investigating the power-law relationship τ_cr ∝ |p - p_c'|^ν
"""

import numpy as np
import matplotlib.pyplot as plt
import pandas as pd
import os
from scipy import stats
from scipy.signal import savgol_filter
from sklearn.linear_model import LinearRegression
from sklearn.metrics import r2_score

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

def calculate_local_alpha(t, msd, window_size=50, step_size=10):
    """Calculate local α using sliding window approach"""
    log_t = np.log10(t)
    log_msd = np.log10(msd)
    
    alphas = []
    r2_scores = []
    window_centers = []
    
    for i in range(0, len(t) - window_size, step_size):
        # Extract window
        t_window = log_t[i:i+window_size]
        msd_window = log_msd[i:i+window_size]
        
        # Remove any invalid values
        valid_mask = np.isfinite(msd_window) & (msd_window > -np.inf)
        if np.sum(valid_mask) < 10:  # Need at least 10 points
            continue
            
        t_valid = t_window[valid_mask]
        msd_valid = msd_window[valid_mask]
        
        # Fit linear relationship
        model = LinearRegression()
        model.fit(t_valid.reshape(-1, 1), msd_valid)
        alpha = model.coef_[0]
        r2 = model.score(t_valid.reshape(-1, 1), msd_valid)
        
        alphas.append(alpha)
        r2_scores.append(r2)
        window_centers.append(t[i + window_size//2])
    
    return np.array(alphas), np.array(r2_scores), np.array(window_centers)

def detect_changepoint_backwards(t, msd, min_window=100, max_window=500, threshold=0.1):
    """
    Detect changepoint by working backwards from maximum time
    
    Strategy:
    1. Start from the end (t_max) and work backwards
    2. Use sliding windows to calculate local α
    3. Detect significant changes in α or its derivative
    4. Identify the point where behavior changes from linear to non-linear
    """
    log_t = np.log10(t)
    log_msd = np.log10(msd)
    
    # Remove any invalid values
    valid_mask = np.isfinite(log_msd) & (log_msd > -np.inf)
    t_valid = log_t[valid_mask]
    msd_valid = log_msd[valid_mask]
    
    if len(t_valid) < max_window:
        return None, None, None
    
    # Calculate local α with different window sizes
    window_sizes = [min_window, (min_window + max_window)//2, max_window]
    changepoints = []
    
    for window_size in window_sizes:
        alphas, r2_scores, centers = calculate_local_alpha(
            t_valid, msd_valid, window_size=window_size, step_size=window_size//4
        )
        
        if len(alphas) < 3:
            continue
        
        # Calculate derivative of α
        alpha_derivative = np.gradient(alphas)
        
        # Find points where derivative exceeds threshold
        change_indices = np.where(np.abs(alpha_derivative) > threshold)[0]
        
        if len(change_indices) > 0:
            # Take the latest significant change (working backwards)
            latest_change_idx = change_indices[-1]
            changepoint_t = centers[latest_change_idx]
            changepoints.append(changepoint_t)
    
    if len(changepoints) == 0:
        return None, None, None
    
    # Use the median changepoint across different window sizes
    tau_cr = np.median(changepoints)
    
    # Calculate confidence interval
    tau_cr_std = np.std(changepoints)
    
    return tau_cr, tau_cr_std, changepoints

def adaptive_tau_cr_detection(t, msd, p_value):
    """
    Adaptive τ_cr detection based on percolation regime
    
    Strategy:
    1. Determine regime based on p-value
    2. Apply regime-specific detection criteria
    3. Use multiple methods and combine results
    """
    p_c_prime = 0.6884
    
    # Determine regime
    if p_value < p_c_prime - 0.05:
        regime = "LIQUID"
        # For liquid: look for transition from anomalous to regular diffusion
        expected_alpha_before = 1.0
        expected_alpha_after = 1.0
    elif abs(p_value - p_c_prime) < 0.05:
        regime = "CRITICAL"
        # For critical: look for transition from critical to regular diffusion
        expected_alpha_before = 0.53
        expected_alpha_after = 1.0
    else:
        regime = "SOLID"
        # For solid: look for transition from finite-size to plateau
        expected_alpha_before = 0.0
        expected_alpha_after = 0.0
    
    # Method 1: Backwards changepoint detection
    tau_cr1, std1, changes1 = detect_changepoint_backwards(t, msd)
    
    # Method 2: R²-based detection
    tau_cr2 = detect_r2_changepoint(t, msd, regime)
    
    # Method 3: Derivative-based detection
    tau_cr3 = detect_derivative_changepoint(t, msd, regime)
    
    # Combine results
    tau_cr_candidates = [tau_cr1, tau_cr2, tau_cr3]
    tau_cr_candidates = [t for t in tau_cr_candidates if t is not None]
    
    if len(tau_cr_candidates) == 0:
        return None, regime
    
    # Use median if multiple methods agree, otherwise use the most reliable
    if len(tau_cr_candidates) >= 2:
        tau_cr = np.median(tau_cr_candidates)
    else:
        tau_cr = tau_cr_candidates[0]
    
    return tau_cr, regime

def detect_r2_changepoint(t, msd, regime):
    """Detect changepoint based on R² of linear fit"""
    log_t = np.log10(t)
    log_msd = np.log10(msd)
    
    # Remove invalid values
    valid_mask = np.isfinite(log_msd) & (log_msd > -np.inf)
    t_valid = log_t[valid_mask]
    msd_valid = log_msd[valid_mask]
    
    if len(t_valid) < 100:
        return None
    
    # Calculate R² for sliding windows
    window_size = 100
    r2_scores = []
    window_centers = []
    
    for i in range(0, len(t_valid) - window_size, window_size//2):
        t_window = t_valid[i:i+window_size]
        msd_window = msd_valid[i:i+window_size]
        
        if len(t_window) < 10:
            continue
        
        # Fit linear relationship
        model = LinearRegression()
        model.fit(t_window.reshape(-1, 1), msd_window)
        r2 = model.score(t_window.reshape(-1, 1), msd_window)
        
        r2_scores.append(r2)
        window_centers.append(t_valid[i + window_size//2])
    
    if len(r2_scores) < 3:
        return None
    
    # Find point where R² drops significantly
    r2_array = np.array(r2_scores)
    r2_threshold = np.mean(r2_array) - 0.5 * np.std(r2_array)
    
    drop_indices = np.where(r2_array < r2_threshold)[0]
    
    if len(drop_indices) > 0:
        # Take the latest drop (working backwards)
        latest_drop_idx = drop_indices[-1]
        return window_centers[latest_drop_idx]
    
    return None

def detect_derivative_changepoint(t, msd, regime):
    """Detect changepoint based on MSD derivative"""
    log_t = np.log10(t)
    log_msd = np.log10(msd)
    
    # Remove invalid values
    valid_mask = np.isfinite(log_msd) & (log_msd > -np.inf)
    t_valid = log_t[valid_mask]
    msd_valid = log_msd[valid_mask]
    
    if len(t_valid) < 50:
        return None
    
    # Calculate first and second derivatives
    try:
        # Use Savitzky-Golay filter for smooth derivatives
        window_length = min(21, len(msd_valid)//3)
        if window_length % 2 == 0:
            window_length += 1
        
        if window_length < 3:
            return None
        
        msd_smooth = savgol_filter(msd_valid, window_length, 3)
        first_deriv = np.gradient(msd_smooth, t_valid)
        second_deriv = np.gradient(first_deriv, t_valid)
        
        # Find points where second derivative changes sign significantly
        second_deriv_threshold = np.std(second_deriv) * 2
        change_indices = np.where(np.abs(second_deriv) > second_deriv_threshold)[0]
        
        if len(change_indices) > 0:
            # Take the latest significant change (working backwards)
            latest_change_idx = change_indices[-1]
            return t_valid[latest_change_idx]
        
    except Exception as e:
        print(f"Warning: Derivative detection failed: {e}")
    
    return None

def analyze_power_law_scaling(tau_cr_results):
    """Analyze the power-law relationship τ_cr ∝ |p - p_c'|^ν"""
    p_c_prime = 0.6884
    
    # Extract valid results
    valid_results = []
    for p, tau_cr, regime in tau_cr_results:
        if tau_cr is not None and tau_cr > 0:
            valid_results.append((p, tau_cr, regime))
    
    if len(valid_results) < 5:
        print("Insufficient data for power-law analysis")
        return None, None, None
    
    # Separate by regime for analysis
    liquid_data = [(p, tau_cr) for p, tau_cr, regime in valid_results if regime == "LIQUID"]
    critical_data = [(p, tau_cr) for p, tau_cr, regime in valid_results if regime == "CRITICAL"]
    solid_data = [(p, tau_cr) for p, tau_cr, regime in valid_results if regime == "SOLID"]
    
    results = {}
    
    # Analyze each regime
    for regime_name, data in [("LIQUID", liquid_data), ("CRITICAL", critical_data), ("SOLID", solid_data)]:
        if len(data) < 3:
            continue
        
        p_values = np.array([p for p, tau_cr in data])
        tau_cr_values = np.array([tau_cr for p, tau_cr in data])
        
        # Calculate distance from critical point
        distance = np.abs(p_values - p_c_prime)
        
        # Fit power law: log(τ_cr) = ν * log(|p - p_c'|) + b
        valid_mask = (distance > 0) & (tau_cr_values > 0)
        if np.sum(valid_mask) < 3:
            continue
        
        log_distance = np.log10(distance[valid_mask])
        log_tau_cr = np.log10(tau_cr_values[valid_mask])
        
        # Linear fit
        slope, intercept, r_value, p_value, std_err = stats.linregress(log_distance, log_tau_cr)
        r_squared = r_value**2
        
        results[regime_name] = {
            'nu': slope,
            'intercept': intercept,
            'r_squared': r_squared,
            'p_values': p_values[valid_mask],
            'tau_cr_values': tau_cr_values[valid_mask],
            'distance': distance[valid_mask]
        }
        
        print(f"{regime_name} regime:")
        print(f"  ν = {slope:.4f} ± {std_err:.4f}")
        print(f"  R² = {r_squared:.4f}")
        print(f"  τ_cr ∝ |p - {p_c_prime}|^{slope:.4f}")
    
    return results

def plot_tau_cr_analysis(data, p_values, t, tau_cr_results):
    """Plot comprehensive τ_cr analysis"""
    
    # Create figure with multiple subplots
    fig, axes = plt.subplots(2, 3, figsize=(18, 12))
    fig.suptitle('Robust τ_cr Analysis: Working Backwards from Maximum Steps', fontsize=16)
    
    # Plot 1: Example MSD curve with τ_cr detection
    ax1 = axes[0, 0]
    example_p = 0.6884  # Critical point
    msd_col = f'MSD_{example_p}'
    if msd_col in data.columns:
        msd = data[msd_col].values
        ax1.loglog(t, msd, 'b-', linewidth=2, label='MSD')
        
        # Find τ_cr for this example
        tau_cr, regime = adaptive_tau_cr_detection(t, msd, example_p)
        if tau_cr is not None:
            ax1.axvline(x=tau_cr, color='r', linestyle='--', linewidth=2, label=f'τ_cr = {tau_cr:.0f}')
        
        ax1.set_xlabel('Time τ')
        ax1.set_ylabel('MSD')
        ax1.set_title(f'Example: p = {example_p} ({regime})')
        ax1.legend()
        ax1.grid(True, alpha=0.3)
    
    # Plot 2: τ_cr vs p
    ax2 = axes[0, 1]
    valid_results = [(p, tau_cr, regime) for p, tau_cr, regime in tau_cr_results if tau_cr is not None]
    
    if valid_results:
        p_vals = [p for p, tau_cr, regime in valid_results]
        tau_cr_vals = [tau_cr for p, tau_cr, regime in valid_results]
        regimes = [regime for p, tau_cr, regime in valid_results]
        
        # Color by regime
        colors = {'LIQUID': 'blue', 'CRITICAL': 'red', 'SOLID': 'green'}
        for regime in set(regimes):
            mask = [r == regime for r in regimes]
            ax2.scatter([p_vals[i] for i, m in enumerate(mask) if m],
                       [tau_cr_vals[i] for i, m in enumerate(mask) if m],
                       c=colors[regime], label=regime, s=50, alpha=0.7)
        
        ax2.set_xlabel('p (occupation probability)')
        ax2.set_ylabel('τ_cr')
        ax2.set_title('τ_cr vs p')
        ax2.set_yscale('log')
        ax2.legend()
        ax2.grid(True, alpha=0.3)
    
    # Plot 3: Power-law analysis
    ax3 = axes[0, 2]
    power_law_results = analyze_power_law_scaling(tau_cr_results)
    
    if power_law_results:
        p_c_prime = 0.6884
        colors = {'LIQUID': 'blue', 'CRITICAL': 'red', 'SOLID': 'green'}
        
        for regime, result in power_law_results.items():
            distance = result['distance']
            tau_cr_values = result['tau_cr_values']
            nu = result['nu']
            r_squared = result['r_squared']
            
            ax3.loglog(distance, tau_cr_values, 'o', c=colors[regime], 
                      label=f'{regime}: ν={nu:.3f}, R²={r_squared:.3f}')
            
            # Plot fitted line
            x_fit = np.logspace(np.log10(distance.min()), np.log10(distance.max()), 100)
            y_fit = 10**(result['intercept']) * x_fit**nu
            ax3.loglog(x_fit, y_fit, '--', c=colors[regime], alpha=0.7)
        
        ax3.set_xlabel('|p - p_c\'|')
        ax3.set_ylabel('τ_cr')
        ax3.set_title('Power-Law Scaling: τ_cr ∝ |p - p_c\'|^ν')
        ax3.legend()
        ax3.grid(True, alpha=0.3)
    
    # Plot 4: Local α analysis for example
    ax4 = axes[1, 0]
    if msd_col in data.columns:
        msd = data[msd_col].values
        alphas, r2_scores, centers = calculate_local_alpha(t, msd, window_size=100, step_size=20)
        
        if len(alphas) > 0:
            ax4.plot(centers, alphas, 'b-', linewidth=2, label='Local α')
            ax4.axhline(y=0.53, color='r', linestyle='--', alpha=0.7, label='Theoretical α')
            ax4.axhline(y=1.0, color='g', linestyle='--', alpha=0.7, label='Regular diffusion')
            
            ax4.set_xlabel('Time τ')
            ax4.set_ylabel('Local α')
            ax4.set_title('Local α Analysis')
            ax4.set_xscale('log')
            ax4.legend()
            ax4.grid(True, alpha=0.3)
    
    # Plot 5: R² analysis
    ax5 = axes[1, 1]
    if msd_col in data.columns:
        msd = data[msd_col].values
        log_t = np.log10(t)
        log_msd = np.log10(msd)
        
        # Calculate R² for sliding windows
        window_size = 100
        r2_scores = []
        window_centers = []
        
        for i in range(0, len(log_t) - window_size, window_size//2):
            t_window = log_t[i:i+window_size]
            msd_window = log_msd[i:i+window_size]
            
            valid_mask = np.isfinite(msd_window) & (msd_window > -np.inf)
            if np.sum(valid_mask) < 10:
                continue
            
            t_valid = t_window[valid_mask]
            msd_valid = msd_window[valid_mask]
            
            model = LinearRegression()
            model.fit(t_valid.reshape(-1, 1), msd_valid)
            r2 = model.score(t_valid.reshape(-1, 1), msd_valid)
            
            r2_scores.append(r2)
            window_centers.append(t[i + window_size//2])
        
        if r2_scores:
            ax5.plot(window_centers, r2_scores, 'g-', linewidth=2, label='R²')
            ax5.set_xlabel('Time τ')
            ax5.set_ylabel('R²')
            ax5.set_title('R² Analysis')
            ax5.set_xscale('log')
            ax5.legend()
            ax5.grid(True, alpha=0.3)
    
    # Plot 6: Summary table
    ax6 = axes[1, 2]
    ax6.axis('off')
    
    if valid_results:
        # Create summary table
        summary_data = []
        for p, tau_cr, regime in valid_results[:10]:  # Show first 10
            summary_data.append([
                f"{p:.4f}",
                regime,
                f"{tau_cr:.0f}"
            ])
        
        table = ax6.table(cellText=summary_data,
                         colLabels=['p', 'Regime', 'τ_cr'],
                         cellLoc='center',
                         loc='center')
        table.auto_set_font_size(False)
        table.set_fontsize(10)
        table.scale(1, 2)
        
        ax6.set_title('τ_cr Results Summary')
    
    plt.tight_layout()
    
    # Save plot
    output_dir = "../paper_figures"
    os.makedirs(output_dir, exist_ok=True)
    plt.savefig(f"{output_dir}/robust_tau_cr_analysis.png", 
                dpi=300, bbox_inches='tight')
    
    return fig

def main():
    """Main analysis function"""
    print("=== ROBUST τ_cr ANALYSIS ===")
    print("Working backwards from maximum steps to detect changepoints")
    print("=" * 60)
    
    try:
        # Load data
        data, p_values, t = load_p_output_data()
        print(f"Loaded data with {len(p_values)} p-values")
        
        # Analyze τ_cr for all p-values
        tau_cr_results = []
        
        for p in p_values:
            msd_col = f'MSD_{p}'
            if msd_col not in data.columns:
                continue
            
            msd = data[msd_col].values
            
            # Detect τ_cr using adaptive method
            tau_cr, regime = adaptive_tau_cr_detection(t, msd, p)
            
            tau_cr_results.append((p, tau_cr, regime))
            
            if tau_cr is not None:
                print(f"p = {p:.4f} ({regime}): τ_cr = {tau_cr:.0f}")
            else:
                print(f"p = {p:.4f} ({regime}): τ_cr = Not detected")
        
        # Create comprehensive plots
        print("\nCreating analysis plots...")
        fig = plot_tau_cr_analysis(data, p_values, t, tau_cr_results)
        plt.close(fig)
        
        # Save results
        results_df = pd.DataFrame(tau_cr_results, columns=['p', 'tau_cr', 'regime'])
        output_file = "../paper_figures/tau_cr_results.csv"
        results_df.to_csv(output_file, index=False)
        print(f"\nResults saved to: {output_file}")
        
        # Power-law analysis
        print("\n=== POWER-LAW ANALYSIS ===")
        power_law_results = analyze_power_law_scaling(tau_cr_results)
        
        if power_law_results:
            print("\nPower-law relationships found:")
            for regime, result in power_law_results.items():
                nu = result['nu']
                r_squared = result['r_squared']
                print(f"  {regime}: τ_cr ∝ |p - p_c'|^{nu:.4f} (R² = {r_squared:.4f})")
        
        print("\nAnalysis complete!")
        print("Check ../paper_figures/ for plots and results")
        
    except Exception as e:
        print(f"Error in analysis: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    main() 